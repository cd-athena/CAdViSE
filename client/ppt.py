#!/usr/bin/python

import sys
import os
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import time
playerURL = sys.argv[1]
duration = int(sys.argv[2])
mode = sys.argv[3]

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

def main(duration, playerURL):
    runPlayer(playerURL, duration)

if __name__ == "__main__":
    main(duration, playerURL)
