FROM caffix/amass as amass

WORKDIR /app
COPY scope/wildcards.txt /app/wildcards.txt
ENTRYPOINT ["amass"]
CMD ["--help"]

