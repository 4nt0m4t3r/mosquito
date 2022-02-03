FILE_WILDCARDS="${PWD}/scope/wildcards.txt"
FILE_ALIAS="${PWD}/scope/alias.txt"
FILE_DOMAINS="${PWD}/scope/domains.txt"
FILE_HTTPX="${PWD}/result/httpx"
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

build:
	docker build -f shosubgo.Dockerfile -t shosubgo .
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
	@for f in $(shell cat ${FILE_WILDCARDS});do docker run  waybackurls $${f} | grep -oE "http[s]?://[^\/]*/"  | sort -u  | grep $${f} | sed -E "s/http(s)?:\/\///g" | grep -oE ".*$${f}" | sort -u > ${PWD}/result/tmp-domains-waybackurl-$${f};done
	docker run  dorksploit dorksploit.py "intitle:Index Of" "wildcards.txt" > ${PWD}/result/indexof-dorksploit
	docker run  dorksploit dorksploit.py "filetype:pdf" "wildcards.txt" > ${PWD}/result/pdf-dorksploit
	docker run  findomain -f /app/wildcards.txt > ${PWD}/result/tmp-domains-findomain.txt
	docker run -v ${PWD}/result:/tool/artifacts amass enum -df /app/wildcards.txt -o /tool/artifacts/tmp-domains-amass
	@for f in $(shell cat ${FILE_WILDCARDS});do docker run  shosubgo -d $${f} -s ${SHODAN_API_TOKEN} > ${PWD}/result/tmp-domains-shosubgo-$${f};done
	@for f in $(shell cat ${FILE_WILDCARDS});do docker run  assetfinder $${f} > ${PWD}/result/tmp-domains-assetfinder-$${f};done
	@for f in $(shell cat ${FILE_WILDCARDS});do docker run -v ${PWD}/result:/tool/artifacts sublister /app/Sublist3r/sublist3r.py -d $${f} -o /tool/artifacts/tmp-domains-sublister-$${f};done
	docker run -v ${PWD}/result:/tool/artifacts subdomainizer /app/SubDomainizer/SubDomainizer.py -l /app/wildcards.txt -o /tool/artifacts/tmp-domains-subdomainizer
	docker run -v ${PWD}/result:/tool/artifacts subs -dL /app/wildcards.txt -silent -o /tool/artifacts/tmp-domains-subfinder 
	@for f in $(shell cat ${FILE_WILDCARDS});do cp wordlists/domains.txt ${PWD}/result/tmp-domains-wordlist-$${f} && sed  "s/$$/\.$${f}/" -i ${PWD}/result/tmp-domains-wordlist-$${f} ;done
	docker build -f massdns.Dockerfile -t massdns .
	docker run  massdns -r lists/resolvers.txt -t A -o S domains.txt > ${PWD}/result/tmp-massdns.txt
	cat ${PWD}/result/tmp-massdns.txt | grep -f ${PWD}/scope/wildcards.txt > ${PWD}/result/massdns.txt
	cat ${PWD}/result/massdns.txt | awk '{print $3}' | sort -u | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u > ${PWD}/result/ips-online.txt
	cut -d " " -f 1 ${PWD}/result/massdns.txt | sed -e "s/\.$$//" | sort -u > ${PWD}/result/tmp-hosts-online.txt
	docker build -f altdns.Dockerfile -t altdns .
	docker run -v ${PWD}/result:/tool/artifacts altdns -i tmp-hosts-online.txt -o data_output -w names.txt -s /tool/artifacts/altdns.txt
	cat ${PWD}/result/altdns.txt ${PWD}/result/tmp-hosts-online.txt | sort -u > ${PWD}/result/hosts-online.txt
	docker build -f masscan.Dockerfile -t masscan .
	docker run  masscan -iL /app/ips-online.txt --rate 10000 -p1-65535 > ${PWD}/result/tmp-masscan.out
	cat ${PWD}/result/tmp-masscan.out | cut -d" " -f 4,6 > ${PWD}/result/masscan.out
	docker build -f nmap.Dockerfile -t nmap .
	docker run -v ${PWD}/result:/app/artifacts nmap -Pn -sV -sC -p21,22,25,23,3306,5432,5900,1433 -iL ips-online.txt --min-rate 10000  -oX /app/artifacts/nmap.xml
	docker build -f brutespray.Dockerfile -t brutes .
	docker run -v ${PWD}/result:/app/artifacts  brutes --file nmap.xml -o /app/artifacts/login-cred
	cat ${PWD}/result/hosts-online.txt ${PWD}/scope/domains.txt | sort -u > ${PWD}/result/hosts-combined.txt
	docker build -f httpx.Dockerfile -t httpx .
	docker run  httpx -l /app/hosts-combined.txt -silent > ${PWD}/result/tmp-httpx
	docker run  dorksploit dorksploit.py "-www" "wildcards.txt" > ${PWD}/result/tmp-dorksploit
	cat ${PWD}/result/tmp-dorksploit | grep -oE "http[s]?://[^\/]*/" | sort -u > ${PWD}/result/dorksploit
	cat ${PWD}/result/dorksploit ${PWD}/result/tmp-httpx | sort -u > ${PWD}/result/httpx && rm ${PWD}/result/tmp* -f
	docker build -f fff-host.Dockerfile -t fff-host .
	docker run -v ${PWD}/result:/app fff-host httpx | fff -S -o root
	docker build -f eyewitness.Dockerfile -t eyewitness . 
	docker run -v ${PWD}/result:/tmp/EyeWitness eyewitness -f /app/httpx --web 
	docker build -f nuclei.Dockerfile -t nuclei .
	docker run nuclei -list /app/httpx > ${PWD}/result/nuclei
	docker build -f wappalyzer.Dockerfile -t wappalyzer .
	./scripts/run-wappalyzer.sh
	@for f in $(shell cat ${FILE_WILDCARDS});do docker run  waybackurls $${f}  | sort -u  | grep $${f}  | sort -u >> ${PWD}/result/directory_enumeration/tmp-directories;done
	docker run  dorksploit dorksploit.py "" "wildcards.txt" > ${PWD}/result/directory_enumeration/tmp-directories

	@for f in $(shell cat ${FILE_ALIAS});do ./scripts/github-urls.sh $${f} >> ${PWD}/result/dorking/github-urls;done
	@for f in $(shell cat ${FILE_HTTPX});do docker run -v ${PWD}/result:/linkfinder/artifact linkfinder -i $${f} -d -o cli >> ${PWD}/result/directory_enumeration/javascript;done
	@for f in $(shell cat ${PWD}/result/hosts-combined.txt);do docker run  otxurls $${f} >> ${PWD}/result/directory_enumeration/tmp-directories;done
	@for f in $(shell cat ${FILE_ALIAS} ${FILE_DOMAINS});do docker run  dorksploit dorksploit.py "inurl:$${f}" "s3.amazonaws.com" >> ${PWD}/result/dorking/aws-findings;done
	cat ${PWD}/result/directory_enumeration/tmp-directories | grep -E "^http" | sort -u | grep -Ev "\..{1,3}$$" > ${PWD}/result/directory_enumeration/tmp-directories-2
	docker build -f fff-dork.Dockerfile -t fff-dork .
	docker run fff-dork tmp-directories-2 | fff  | grep "\ 200\|\ 204\|\ 301\|\ 302\|\ 307\|\ 401\|\ 403"  | cut -d" " -f1 > ${PWD}/result/directory_enumeration/directories
	#rm -f ${PWD}/result/directory_enumeration/tmp-directories/tmp*
	docker build -f fff-save-dork.Dockerfile -t fff-save-dork .
	docker run -v ${PWD}/result:/app/root2 fff-save-dork directories | fff -S -o root2/root2
	docker build -f gf.Dockerfile -t gf .
	docker run gf meg-headers | sort -u > ${PWD}/result/leaks/meg-headers
	docker run gf base64 | sort -u > ${PWD}/result/leaks/base64
	docker run gf aws-keys | sort -u > ${PWD}/result/leaks/aws-keys
	docker run gf takeovers | sort -u > ${PWD}/result/leaks/takeovers
	docker run gf servers | sort -u > ${PWD}/result/leaks/servers
	docker run gf php-errors | sort -u > ${PWD}/result/leaks/php-errors
	docker run gf php-serialized | sort -u > ${PWD}/result/leaks/php-serialized
	docker run gf s3-buckets | sort -u > ${PWD}/result/leaks/s3-buckets
	docker run gf debug-pages | sort -u > ${PWD}/result/leaks/debug-pages




	 



		
