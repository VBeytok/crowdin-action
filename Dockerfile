FROM crowdin/cli:latest

RUN apk --no-cache add curl git jq gnupg;

COPY . .
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
