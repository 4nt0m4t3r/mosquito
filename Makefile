ifneq (,$(wildcard ./.env))
    include .env
    export
endif
FILE_WILDCARDS=${PWD}/scope/wildcards.txt
FILE_ALIAS=${PWD}/scope/alias.txt
FILE_DOMAINS=${PWD}/scope/domains.txt
RESULT_DIR=${PWD}/result
SCRIPT_DIR=${PWD}/scripts
FILE_HTTPX=${RESULT_DIR}/httpx"
OUT_DOMAINS=${PWD}/scope/out-of-scope-domains.txt

build:
	docker build -f assetfinder.Dockerfile -t assetfinder .
	docker build -f sublister.Dockerfile -t sublister .
	docker build -f subdomainizer.Dockerfile -t subdomainizer .
	docker build -f subfinder.Dockerfile -t subs .
	docker build -f amass.Dockerfile -t amass .
	docker build -f dorksploit.Dockerfile -t dorksploit .
	docker build -f findomain.Dockerfile -t findomain .
	docker build -f waybackurls.Dockerfile -t waybackurls .
	docker build -f github-dorks.Dockerfile -t github-dorks .
	docker build -f linkfinder.Dockerfile -t linkfinder .
	docker build -f otxurls.Dockerfile -t otxurls .

run:
	@for f in $(shell cat ${FILE_WILDCARDS});do docker run  waybackurls $${f} | grep -oE "http[s]?://[^\/]*/"  | sort -u  | grep $${f} | sed -E "s/http(s)?:\/\///g" | grep -oE ".*$${f}" | sort -u > ${RESULT_DIR}/tmp-domains-waybackurl-$${f};done
	docker run  dorksploit dorksploit.py "intitle:Index Of" "wildcards.txt" > ${RESULT_DIR}/indexof-dorksploit
	docker run  dorksploit dorksploit.py "filetype:pdf" "wildcards.txt" > ${RESULT_DIR}/pdf-dorksploit
	docker run  findomain -f /app/wildcards.txt > ${RESULT_DIR}/tmp-domains-findomain.txt
	docker run --user="root" amass enum -df wildcards.txt > ${RESULT_DIR}/tmp-domains-amass
	@for f in $(shell cat ${FILE_WILDCARDS});do ./scripts/shosubgo -d $${f} -s ${SHODAN_API_TOKEN} > ${RESULT_DIR}/tmp-domains-shosubgo-$${f};done
	@for f in $(shell cat ${FILE_WILDCARDS});do docker run  assetfinder $${f} > ${RESULT_DIR}/tmp-domains-assetfinder-$${f};done
	@for f in $(shell cat ${FILE_WILDCARDS});do docker run -v ${RESULT_DIR}:/tool/artifacts sublister /app/Sublist3r/sublist3r.py -d $${f} -o /tool/artifacts/tmp-domains-sublister-$${f};done
	docker run -v ${RESULT_DIR}:/tool/artifacts subdomainizer /app/SubDomainizer/SubDomainizer.py -l /app/wildcards.txt -o /tool/artifacts/tmp-domains-subdomainizer
	docker run -v ${RESULT_DIR}:/tool/artifacts subs -dL /app/wildcards.txt -silent -o /tool/artifacts/tmp-domains-subfinder 
	# @for f in $(shell cat ${FILE_WILDCARDS});do cp wordlists/domains.txt ${RESULT_DIR}/tmp-domains-wordlist-$${f} && sed  "s/$$/\.$${f}/" -i ${RESULT_DIR}/tmp-domains-wordlist-$${f} ;done
	docker build -f massdns.Dockerfile -t massdns .
	docker run  massdns -r lists/resolvers.txt -t A -o S domains.txt > ${RESULT_DIR}/tmp-massdns.txt
	cat ${RESULT_DIR}/tmp-massdns.txt | grep -f scope/wildcards.txt > ${RESULT_DIR}/massdns.txt
	cat ${RESULT_DIR}/massdns.txt | awk '{print $3}' | sort -u | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u > ${RESULT_DIR}/ips-online.txt
	cut -d " " -f 1 ${RESULT_DIR}/massdns.txt | sed -e "s/\.$$//" | sort -u > ${RESULT_DIR}/tmp-hosts-online.txt
	docker build -f altdns.Dockerfile -t altdns .
	docker run -v ${RESULT_DIR}:/tool/artifacts altdns -i tmp-hosts-online.txt -o data_output -w names.txt -s /tool/artifacts/altdns.txt
	cat ${RESULT_DIR}/altdns.txt ${RESULT_DIR}/tmp-hosts-online.txt | sort -u > ${RESULT_DIR}/hosts-online.txt
	docker build -f masscan.Dockerfile -t masscan .
	docker run  masscan -iL /app/ips-online.txt --rate 10000 -p1-65535 > ${RESULT_DIR}/tmp-masscan.out
	cat ${RESULT_DIR}/tmp-masscan.out | cut -d" " -f 4,6 > ${RESULT_DIR}/masscan.out
	docker build -f nmap.Dockerfile -t nmap .
	docker run -v ${RESULT_DIR}:/app/artifacts nmap -Pn -sV -sC -iL ips-online.txt --min-rate 10000  -oX /app/artifacts/nmap.xml
	docker build -f brutespray.Dockerfile -t brutes .
	docker run -v ${RESULT_DIR}:/app/artifacts  brutes --file nmap.xml -o /app/artifacts/login-cred
	cat ${RESULT_DIR}/hosts-online.txt scope/domains.txt | sort -u > ${RESULT_DIR}/hosts-combined.txt
	docker build -f httpx.Dockerfile -t httpx .
	docker run  httpx -l /app/hosts-combined.txt -silent > ${RESULT_DIR}/tmp-httpx
	docker run  dorksploit dorksploit.py "-www" "wildcards.txt" > ${RESULT_DIR}/tmp-dorksploit
	cat ${RESULT_DIR}/tmp-dorksploit | grep -oE "http[s]?://[^\/]*/" | sort -u > ${RESULT_DIR}/dorksploit
	cat ${RESULT_DIR}/dorksploit ${RESULT_DIR}/tmp-httpx | sort -u > ${RESULT_DIR}/tmp-2-httpx 
	cat ${RESULT_DIR}/tmp-2-httpx | grep -vf ${OUT_DOMAINS} > ${RESULT_DIR}/httpx && rm ${RESULT_DIR}/tmp* -f
	cat  ${RESULT_DIR}/httpx | ${SCRIPT_DIR}/fff -S -o ${RESULT_DIR}/root
	docker build -f eyewitness.Dockerfile -t eyewitness . 
	docker run -v ${RESULT_DIR}:/tmp/EyeWitness eyewitness -f /app/httpx --web 
	docker build -f nuclei.Dockerfile -t nuclei .
	docker run nuclei -list /app/httpx > ${RESULT_DIR}/nuclei
	docker build -f wappalyzer.Dockerfile -t wappalyzer .
	./scripts/run-wappalyzer.sh
	@for f in $(shell cat ${FILE_WILDCARDS});do docker run  waybackurls $${f}  | sort -u  | grep $${f}  | sort -u >> ${RESULT_DIR}/directory_enumeration/tmp-directories;done
	docker run  dorksploit dorksploit.py "" "wildcards.txt" > ${RESULT_DIR}/directory_enumeration/tmp-directories
	@for f in $(shell cat ${FILE_ALIAS});do ./scripts/github-urls.sh $${f} >> ${RESULT_DIR}/dorking/github-urls;done
	@for f in $(shell cat ${FILE_HTTPX});do docker run -v ${RESULT_DIR}:/linkfinder/artifact linkfinder -i $${f} -d -o cli >> ${RESULT_DIR}/directory_enumeration/javascript;done
	@for f in $(shell cat ${RESULT_DIR}/hosts-combined.txt);do docker run  otxurls $${f} >> ${RESULT_DIR}/directory_enumeration/tmp-directories;done
	@for f in $(shell cat ${FILE_ALIAS} ${FILE_DOMAINS});do docker run  dorksploit dorksploit.py "inurl:$${f}" "s3.amazonaws.com" >> ${RESULT_DIR}/dorking/aws-findings;done
	cat ${RESULT_DIR}/directory_enumeration/tmp-directories | grep -E "^http" | sort -u | grep -Ev "\..{1,3}$$" > ${RESULT_DIR}/directory_enumeration/tmp-directories-2
	rm -f ${RESULT_DIR}/directory_enumeration/tmp-directories/tmp*
	docker build -f gf.Dockerfile -t gf .
	docker run gf meg-headers | sort -u > ${RESULT_DIR}/leaks/meg-headers
	docker run gf base64 | sort -u > ${RESULT_DIR}/leaks/base64
	docker run gf aws-keys | sort -u > ${RESULT_DIR}/leaks/aws-keys
	docker run gf takeovers | sort -u > ${RESULT_DIR}/leaks/takeovers
	docker run gf servers | sort -u > ${RESULT_DIR}/leaks/servers
	docker run gf php-errors | sort -u > ${RESULT_DIR}/leaks/php-errors
	docker run gf php-serialized | sort -u > ${RESULT_DIR}/leaks/php-serialized
	docker run gf s3-buckets | sort -u > ${RESULT_DIR}/leaks/s3-buckets
	docker run gf debug-pages | sort -u > ${RESULT_DIR}/leaks/debug-pages