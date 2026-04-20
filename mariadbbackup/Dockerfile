FROM alpine:latest

RUN apk add --no-cache mariadb-client bash jq pigz

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
