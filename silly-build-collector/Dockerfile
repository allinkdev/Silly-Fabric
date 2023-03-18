FROM alpine

RUN apk --no-cache add aria2 unzip
RUN adduser -S -D -H builder
RUN mkdir /collect/
RUN chown builder /collect/

WORKDIR /collect/
USER builder