FROM python:3.8-slim

WORKDIR /app
RUN apt update -y\
&& apt install git -y \
&& git clone https://github.com/nsonaniya2010/SubDomainizer.git \
&& cd SubDomainizer \
&& pip3 install -r requirements.txt
COPY scope/wildcards.txt /app/wildcards.txt

ENTRYPOINT ["python3"]
CMD ["--help"]

