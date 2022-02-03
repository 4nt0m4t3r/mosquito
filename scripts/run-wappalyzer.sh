#!/usr/bin/bash
while read p; do
  docker run wappalyzer "$p" >> result/wappalyzer
done <result/httpx
