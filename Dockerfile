# FROM openjdk:buster
# #RUN set -eux; \
# #	apt-get update; \
# #	apt-get install -y \
# #		wget \
# #		gnupg \
# #	; \
# RUN wget -qO - https://artifacts.crowdin.com/repo/GPG-KEY-crowdin | apt-key add -; \
#   echo "deb https://artifacts.crowdin.com/repo/deb/ /" > /etc/apt/sources.list.d/crowdin.list; \
#   set -eux; \
#   apt-get update && apt-get install crowdin3;
#
# # Copies your code file from your action repository to the filesystem path `/` of the container
# COPY entrypoint.sh /entrypoint.sh
#
# CMD ['bash']
#
# # Code file to execute when the docker container starts up (`entrypoint.sh`)
# ENTRYPOINT ["/entrypoint.sh"]


FROM openjdk:buster

RUN wget https://artifacts.crowdin.com/repo/deb/crowdin3.deb -O crowdin.deb; \
  dpkg -i crowdin.deb;

WORKDIR /usr/crowdin-project

COPY ./ ./
COPY entrypoint.sh /entrypoint.sh
#RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
