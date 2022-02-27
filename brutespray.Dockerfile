FROM python:3.8-slim

WORKDIR /app
RUN apt update -y\
&& apt install brutespray -y


COPY result/nmap.xml ./nmap.xml
ENTRYPOINT ["brutespray"]
