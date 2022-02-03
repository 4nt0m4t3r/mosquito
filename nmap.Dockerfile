FROM instrumentisto/nmap

WORKDIR /app
COPY result/ips-online.txt ./ips-online.txt
