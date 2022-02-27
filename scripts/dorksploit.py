#!/usr/bin/env/python3

try:
    from googlesearch import search

except ImportError:
    print("")

import sys
import time

def dorks():
        query = sys.argv[1]
        host_file = sys.argv[2]
        requ = 0
        counter = 0
        lines=[]
        try:
            with open(host_file, 'r') as file:
                lines = file.readlines()
        
            
        except FileNotFoundError:
            lines=[host_file]

        for line in lines:
            dork = "site:"+line.strip() + " "+ query
            for results in search(dork, tld="com", lang="en", num=10000, start=0, stop=None, pause=2):
                counter = counter + 1
                time.sleep(0.1)
                print(results)
                time.sleep(0.1)



        sys.exit()


if __name__ == "__main__":
    try:
        dorks()
    except Exception as e: 
        print(e)