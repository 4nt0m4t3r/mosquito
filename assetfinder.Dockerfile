# Build
FROM golang:1.16.6-alpine
RUN go get -u github.com/tomnomnom/assetfinder\
&& apk -U upgrade --no-cache \
&& apk add --no-cache bind-tools ca-certificates\
&& ls $GOPATH/bin\
&& cp /go/bin/assetfinder /usr/local/bin/assetfinder
COPY scope/wildcards.txt /app/wildcards.txt

ENTRYPOINT ["assetfinder"]

