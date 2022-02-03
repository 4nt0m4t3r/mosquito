# Build
FROM golang:1.16.6-alpine


RUN go get -u github.com/tomnomnom/gf\
&& cp /go/bin/gf /usr/local/bin/gf

COPY examples /app/examples
RUN cp -r /app/examples ~/.gf
WORKDIR /app
COPY root/* /app/
COPY root2/* /app/


ENTRYPOINT ["gf"]
CMD ["--help"]