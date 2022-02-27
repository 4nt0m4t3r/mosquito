FROM python:3.7.3-alpine3.9

RUN apk update && \
    apk add git && \
    git clone https://github.com/GerbenJavado/LinkFinder.git && \
    cp -r LinkFinder/ /linkfinder/

WORKDIR /linkfinder/

RUN python3 setup.py install


RUN mkdir /linkfinder/artifact

ENTRYPOINT ["/linkfinder/linkfinder.py"]