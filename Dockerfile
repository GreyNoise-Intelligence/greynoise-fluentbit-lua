FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y curl git openssl libssl-dev luarocks liblua5.2-0 g++ software-properties-common

RUN curl -s https://packages.fluentbit.io/fluentbit.key | apt-key add -

RUN apt-add-repository 'deb https://packages.fluentbit.io/ubuntu/focal focal main'

RUN apt-get update -y && apt-get install -y td-agent-bit

RUN luarocks install busted && \
    luarocks install lua-requests && \
    luarocks install lua-lru && \
    luarocks install luabitop && \
    luarocks install lua-cjson

RUN mkdir -p /opt
ADD ./greynoise /opt/greynoise
WORKDIR /opt/greynoise

ENTRYPOINT ["/opt/td-agent-bit/bin/td-agent-bit"]
