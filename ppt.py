#!/usr/bin/python

import sys
import os
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import time
playerURL = sys.argv[1]
experiments = int(sys.argv[2])
duration = int(sys.argv[3])
mode = sys.argv[4]

def runPlayer(playerURL, duration):
    options = Options()
    if mode == "production":
        options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    options.add_argument('--autoplay-policy=no-user-gesture-required')
    driver = webdriver.Chrome(chrome_options=options)
    driver.get(playerURL)
    time.sleep(duration)
    driver.quit()

def main(duration, playerURL, experiments):
	i=0
	while i < experiments:
		runPlayer(playerURL, duration)
		i+=1

if __name__ == "__main__":
    main(duration, playerURL, experiments)
