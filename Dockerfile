FROM beytok/crowdin-cli

RUN apk --no-cache add git jq;
# RUN apt-get update \
#   && apt-get install -y --no-install-recommends \
#     curl \
#     git \
#     jq;

WORKDIR /usr/crowdin-project

COPY . .
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
