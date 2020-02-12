#!/bin/bash


############################################################
# selenium/base:3.141.59-zinc
############################################################

sudo su

echo "deb http://archive.ubuntu.com/ubuntu bionic main universe" > /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu bionic-updates main universe" >> /etc/apt/sources.list
echo "deb http://security.ubuntu.com/ubuntu bionic-security main universe" >> /etc/apt/sources.list

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

apt-get -qqy update
apt-get -qqy --no-install-recommends install \
  bzip2 \
  ca-certificates \
  openjdk-8-jre-headless \
  tzdata \
  sudo \
  unzip \
  wget \
  jq \
  curl \
  supervisor \
  gnupg2

rm -rf /var/lib/apt/lists/* /var/cache/apt/*
sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security

export TZ="UTC"

echo "${TZ}" > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

useradd seluser --shell /bin/bash --create-home
usermod -a -G sudo seluser
echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers
echo 'seluser:secret' | chpasswd

export HOME=/home/seluser

cp check-grid.sh /opt/bin/
cp entry_point.sh /opt/bin/
cp supervisord.conf /etc

mkdir -p /opt/selenium /var/log/supervisor
touch /opt/selenium/config.json
chmod -R 777 /opt/selenium /var/log/supervisor /etc/passwd
wget --no-verbose https://selenium-release.storage.googleapis.com/3.141/selenium-server-standalone-3.141.59.jar -O /opt/selenium/selenium-server-standalone.jar
chgrp -R 0 /opt/selenium ${HOME} /var/log/supervisor \
chmod -R g=u /opt/selenium ${HOME} /var/log/supervisor


############################################################
# selenium/node-base:3.141.59-zinc
############################################################


apt-get update -qqy
apt-get -qqy install xvfb
rm -rf /var/lib/apt/lists/* /var/cache/apt/*

export LANG_WHICH=en
export LANG_WHERE=US
export ENCODING="UTF-8"
export LANGUAGE='${LANG_WHICH}_${LANG_WHERE}.${ENCODING}'
export LANG=${LANGUAGE}

apt-get -qqy update
apt-get -qqy --no-install-recommends install \
  language-pack-en \
  tzdata \
  locales
locale-gen ${LANGUAGE}
dpkg-reconfigure --frontend noninteractive locales
apt-get -qyy autoremove
rm -rf /var/lib/apt/lists/*
apt-get -qyy clean

apt-get -qqy update
apt-get -qqy --no-install-recommends install \
  libfontconfig \
  libfreetype6 \
  xfonts-cyrillic \
  xfonts-scalable \
  fonts-liberation \
  fonts-ipafont-gothic \
  fonts-wqy-zenhei \
  fonts-tlwg-loma-otf \
  ttf-ubuntu-font-family
rm -rf /var/lib/apt/lists/*
apt-get -qyy clean

cp start-selenium-node.sh /opt/bin/
cp start-xvfb.sh /opt/bin/
cp selenium.conf /etc/supervisor/conf.d/

export SCREEN_WIDTH=1360
export SCREEN_HEIGHT=1020
export SCREEN_DEPTH=24
export SCREEN_DPI=96
export DISPLAY=:99.0
export START_XVFB=true

export NODE_MAX_INSTANCES=1
export NODE_MAX_SESSION=1
export NODE_HOST=0.0.0.0
export NODE_PORT=5555
export NODE_REGISTER_CYCLE=5000
export NODE_POLLING=5000
export NODE_UNREGISTER_IF_STILL_DOWN_AFTER=60000
export NODE_DOWN_POLLING_LIMIT=2
export NODE_APPLICATION_NAME=""
export GRID_DEBUG=false

# Following line fixes https://github.com/SeleniumHQ/docker-selenium/issues/87
export DBUS_SESSION_BUS_ADDRESS=/dev/null

mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix


############################################################
# selenium/node-chrome:3.141.59-zinc
############################################################


export CHROME_VERSION="google-chrome-stable"
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
apt-get update -qqy
apt-get -qqy install ${CHROME_VERSION:-google-chrome-stable}
rm /etc/apt/sources.list.d/google-chrome.list
rm -rf /var/lib/apt/lists/* /var/cache/apt/*

cp wrap_chrome_binary /opt/bin/wrap_chrome_binary
/opt/bin/wrap_chrome_binary

export CHROME_DRIVER_VERSION

if [ -z "$CHROME_DRIVER_VERSION" ];
  then CHROME_MAJOR_VERSION=$(google-chrome --version | sed -E "s/.* ([0-9]+)(\.[0-9]+){3}.*/\1/")
    CHROME_DRIVER_VERSION=$(wget --no-verbose -O - "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_MAJOR_VERSION}");
  fi

echo "Using chromedriver version: "$CHROME_DRIVER_VERSION
wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip
rm -rf /opt/selenium/chromedriver
unzip /tmp/chromedriver_linux64.zip -d /opt/selenium
rm /tmp/chromedriver_linux64.zip
mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION
chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION
sudo ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

cp generate_config /opt/bin/generate_config
/opt/bin/generate_config > /opt/selenium/config.json


############################################################
# selenium/node-chrome-debug
############################################################


apt-get update -qqy
apt-get -qqy install \
  x11vnc \
  fluxbox
rm -rf /var/lib/apt/lists/* /var/cache/apt/*

sudo -u seluser mkdir -p ${HOME}/.vnc
sudo -u seluser x11vnc -storepasswd secret ${HOME}/.vnc/passwd

sudo chmod -R 777 ${HOME}
sudo chgrp -R 0 ${HOME}
sudo chmod -R g=u ${HOME}

cp start-fluxbox.sh /opt/bin/
cp start-vnc.sh /opt/bin/

cp selenium-debug.conf /etc/supervisor/conf.d/
