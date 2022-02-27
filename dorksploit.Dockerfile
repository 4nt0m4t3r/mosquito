FROM python:3.8-slim

WORKDIR /app
RUN apt update -y\
&& pip3 install google
COPY scripts/dorksploit.py ./dorksploit.py
COPY scope/wildcards.txt ./wildcards.txt
ENTRYPOINT ["python3"]
CMD ["--help"]