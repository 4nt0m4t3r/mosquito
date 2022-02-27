FROM alpine:edge

RUN apk --update --no-cache --virtual .build-deps add git build-base \
   && git clone --depth=1 https://github.com/blechschmidt/massdns.git \
   && cd massdns && make && apk del .build-deps
WORKDIR /massdns/

COPY result/ result/

RUN cat result/tmp-domains-* | sort | uniq > ./domains.txt
ENTRYPOINT ["./bin/massdns"]