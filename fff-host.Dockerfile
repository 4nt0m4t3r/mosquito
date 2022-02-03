# Build
FROM golang:1.16.6-alpine
WORKDIR /app

RUN go get -u github.com/tomnomnom/fff\
&& cp /go/bin/fff /usr/local/bin/fff
COPY result/httpx /app/httpx

ENTRYPOINT ["cat"]
CMD ["--help"]