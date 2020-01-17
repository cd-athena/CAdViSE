#!/usr/bin/python

import sys
import os
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import time
url = sys.argv[1]
nbr_exp = int(sys.argv[2])
time_sec = int(sys.argv[3])



def runPlayer( url, time_sec):
    print(url)
    options = Options()
    options.add_argument('--headless')
    options.add_argument('--disable-gpu')  # Last I checked this was necessary.
    options.add_argument('--autoplay-policy=no-user-gesture-required')
    driver = webdriver.Chrome(chrome_options=options)
    #driver.implicitly_wait(10)
    driver.get(url)
    time.sleep(time_sec)
    driver.quit()
    #return


def main(time_sec,url,nbr_exp):
	i=0
	while i < nbr_exp:
		runPlayer(url,time_sec)
		i+=1
if __name__ == "__main__":
    main(time_sec,url,nbr_exp)
    
