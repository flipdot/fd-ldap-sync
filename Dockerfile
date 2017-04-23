FROM ubuntu:16.04

RUN apt update && \
    DEBIAN_FRONTEND=noninteractiv apt install -y slapd ldap-utils

ADD install.sh start.sh /

CMD "/start.sh"