FROM golang:1.16.6-alpine

RUN go get github.com/tomnomnom/waybackurls\
&& apk -U upgrade --no-cache \
&& apk add --no-cache bind-tools ca-certificates\
&& ls $GOPATH/bin\
&& cp /go/bin/waybackurls /usr/local/bin/waybackurls
COPY scope/wildcards.txt /app/wildcards.txt

ENTRYPOINT ["waybackurls"]
CMD ["--help"]