Реалізація [платних апок](https://crowdin.atlassian.net/browse/CN-27516) відбуваєтсья завдяки ендпоінту:

```shell
curl --location --request GET 'https://crowdin.com/api/v2/applications/{app-identifier}/subscription' \
--header 'Authorization: Bearer {api_token}' \
```

У даного ендпоінта є такі респонси:

- `Status: 402 Payment Required` повертається коли ще не придбанна апка. Детальні [Link to Header](#402-payment-required)нижче.
```json
{
    "subscribe_link": "https://crowdin.com/checkout?subscribe=B0jzuQUWg7zDXGRGMFux%2FefxWLJsL4lF7XsNIrBYSqyhiJbid%2BKNo6SH5cg2FgRorsg4HT7i0zjOP8jmoQpYkUVWHHuIcrNb3NJDAlw%2FFkg%2BfifI3fslCSKXsGMtJ6jGFmciX34sJC8GW8EMA9LzfBeLg0EuICziprxqo7w3tvqdUwXkxMVT5zKd7pib%2FyHLX1TmGFaqd8RMi%2B5%2F50xdYniPZtdB08%2BdEnlxROSVaay%2BA3k04f9cIXAd8LuVyJLj%2FjJunpvkSy4qZQqvDad1syw%2FBzhLO3TYQHS52WjUfxHTa9zUGZD81Q%2B5sFb9TF38L2e2%2BlL6DWnm8%2B0jhE6Wywj7QrgidujprkzInmsSh4TUS%2B59uGzPA%2FOrWsUCh3%2BtuLt5iGhlwLVq5XjZPjzzzU1tZYGDvskZenIQohmICbU6HttOtLw2xGsG%2F2kx7YhKZcxga5fbcLVTs5fAp1rL4HymcJjfyktC7hZEOpoqEktQW%2BHwP47KdRHJh5SOdC8b2RTcMiX9SK%2Fp0pTOOAhWY9oHgfHvX2V6AWjnU5ImE4%3D"
}
```

- `Status: 200 OK` повертається коли апка придбанна, хука з fastspring обробленна і експаєр не настав
```json
{
    "expires": "2022-05-21T00:00:00+00:00"
}
```

- `Status: 400 Bad Request` повертаєтсья коли ідентифікатора апки не існує на fastspring або payment_plan_add_on
```json
{
    "error": {
        "message": "App identifier not found",
        "code": 400
    }
}
```

Придбані апки зберігаються в `plan_apps`

| plan_id  | identifier            | product_key                       | price  | status | expires             | updated_at          | created_at          |
|----------|-----------------------|-----------------------------------|--------|--------|---------------------|---------------------|---------------------|
| 3008555  | crowdin-test-app      | crowdin-app-crowdin-test-app      | NULL   | 0      | 0000-00-00 00:00:00 | 2022-04-25 21:58:13 | 2022-04-25 21:58:13 |
| 3008555  | crowdin-test-app-paid | crowdin-app-crowdin-test-app-paid | NULL   | 2      | 0000-00-00 00:00:00 | 2022-04-25 21:58:13 | 2022-04-25 21:58:13 |
| 3008555  | hubspot-app           | crowdin-app-hubspot-app           | 123.00 | 1      | 2022-05-22 17:21:32 | 2022-04-22 17:22:03 | 2022-04-22 17:21:59 |

- `identifier` - ідентифікатор апки
- `product_key` - ключ платної апки який розміщений в `payment_plan_add_on` формується з індефікатора(**всі "_" переводяться "-"**) апки з префіксом `crowdin-app-`
- `status` - в апки на даний момент є три статуси
    - `0` - APP_DISABLED
    - `1` - APP_ACTIVE
    - `2` - APP_PENDING

На даному прикладі:
- `crowdin-test-app` тільки згенерована лінка на покупку але ще **не оплачена**
- `crowdin-test-app-paid` вже оплачена клієнтом, але ще хука `order.completed` з fastspring не прийшла або необроблена кроном
- `hubspot-app` вже куплена і хука з fastspring оброблена

Вся логіка ендпоінта розташована в `ApplicationSubscriptionService.php`

### 402 Payment Required

Респонс вертає лінку для купівлі апки на 3 можливих види планів.
- Місячний
- Річний
- Без плану

За всю логіку по відображенню відповідавє `CheckoutTrait::getDisplayData`

### Місячний план
![Monthly](_data/app-checkout-in-monthly.png)

Ціна генерується відповідності до `appPrice * daysToExpire / DEFAULT_BILLING_CYCLE_DAYS`

Після оплати(**billing_controller::subscribe**), змінюємо статус апки на `APP_PENDING` і створюється ордер на fastspring. Дальше фастспрінг відсилає хуку нам що `order.completed`, ми обробляємо кроном `minutely`. Коли обробляємо `FastSpringHookHandler::processCrowdinAppSubscribeCompleted` ми апдейтимо підписку на fastspring і додаємо апку аддоном, а також сетимо експаєр для апки.

### Річний план

![Annual](_data/app-checkout-in-annual.png)

Даний випадок коли на балансі **достатньо** грошей для підписки тобто якщо клієнт підпишиться на апку і його експаєр **не буде меньший** за 2 місяці(61 день)

Ціна генерується відповідності до `appPrice * daysToNextCharge / DEFAULT_BILLING_CYCLE_DAYS`

При покупці(**checkout_controller::confirm_payment**) зразу спишиться з балансу ціна апки, а також сетимо експаєр для апки, і при слідуючому `nextChargeDate` буде списана ціна плану + апки, тобто експаєр відбудеться скоріше пропорційно ціні апки.

![Annual balance lower two month](_data/app-checkout-in-annual-lower-two-month.png)

Даний випадок коли на балансі **не достатньо** грошей для підписки тобто якщо клієнт підпишиться на апку і його експаєр **меньший** за 2 місяці(61 день)

Ціна генерується відповідності до `appPrice * daysToExpire / DEFAULT_BILLING_CYCLE_DAYS`

Після оплати(**billing_controller::subscribe**), відбувається все те що з місячною окрім того коли обробляємо хуку то додаємо суму до балансу(`BillingService::fillBalance `), а також сетимо експаєр для апки.

### Без плану
![Annual balance lower two month](_data/app-checkout-in-no-plan.png)

В даному кейсі створюється лінка на безкоштовний план(`crowdin-blank`) на фастспрінг і до неї додається апка.

Після оплати(**billing_controller::subscribe**), активуєтсья підписка(`subscription.activated`) і також створюється ордер на fastspring. Коли обробляємо `FastSpringHookHandler::processPlanOrderCompleted` ми сетимо експаєр для апки і апдейтимо план `getBilling()->subscribeCrowdinBlankPlan`
