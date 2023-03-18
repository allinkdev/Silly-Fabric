# Gradle JDK provisioning doesn't work on Alpine, so we're using Debian here
FROM debian:stable-slim

RUN apt-get update -y
RUN apt-get install git openjdk-17-jdk-headless adduser -y
RUN adduser --system --disabled-password --group builder
RUN mkdir /build/
RUN chown builder /build/

WORKDIR /build/
USER builder:builder