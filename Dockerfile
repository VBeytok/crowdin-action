FROM beytok/crowdin-cli

WORKDIR /usr/crowdin-project

COPY ./ ./
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
