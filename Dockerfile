FROM openjdk:buster

RUN wget https://artifacts.crowdin.com/repo/deb/crowdin3.deb -O crowdin.deb; \
  dpkg -i crowdin.deb;

WORKDIR /usr/crowdin-project

COPY ./ ./
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
