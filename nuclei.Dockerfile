FROM golang
RUN go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest

COPY result/httpx /app/httpx
ENTRYPOINT ["nuclei"]