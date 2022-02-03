FROM adarnimrod/masscan

WORKDIR /app
COPY result/ips-online.txt ./ips-online.txt
ENTRYPOINT [ "masscan" ]
CMD ["--help"]