# Build
FROM golang:1.16.6-alpine
RUN go get -u github.com/d3ftx/shosubgo\
&& apk -U upgrade --no-cache \
&& apk add --no-cache bind-tools ca-certificates\
&& ls $GOPATH/bin\
&& cp /go/bin/shosubgo /usr/local/bin/shosubgo
COPY scope/wildcards.txt /app/wildcards.txt

ENTRYPOINT ["shosubgo"]
CMD ["--help"]

