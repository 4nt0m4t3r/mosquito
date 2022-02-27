# Build
FROM golang:1.16.6-alpine


RUN go get -u github.com/tomnomnom/gf\
&& cp /go/bin/gf /usr/local/bin/gf

COPY examples ~/.gf
WORKDIR /app
COPY result/root/* /app/



ENTRYPOINT ["gf"]
CMD ["--help"]