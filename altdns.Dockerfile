FROM python:2-slim

WORKDIR /app
RUN apt update -y\
&& pip install py-altdns
COPY scripts/dorksploit.py ./dorksploit.py
COPY result/tmp-hosts-online.txt ./tmp-hosts-online.txt
COPY wordlists/names.txt ./names.txt
ENTRYPOINT ["altdns"]
CMD ["--help"]
