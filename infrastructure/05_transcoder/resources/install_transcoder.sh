#!/usr/bin/env bash
#
# Transcoder installation script.
#
# Arguments:
# $1 = public domain name (e.g. livevideo-transcoder.my-sample-domain.xyz)
# $2 = internal domain name (e.g. livevideo-transcoder-vpc.my-sample-domain.xyz)
#
# The following resources are expected in the /tmp folder:
# /tmp/nginx-transcoder.conf
# /tmp/application.properties
# /tmp/transcoder.jar
# /tmp/transcoder.service

PUBLIC_DOMAIN=$1
INTERNAL_DOMAIN=$2

# Update the distribution
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade

# Install JDK 11
echo "Install OpenJDK 11"
apt-get -y install software-properties-common
add-apt-repository -y ppa:linuxuprising/java
apt-get update
echo oracle-java11-installer shared/accepted-oracle-license-v1-2 select true | sudo /usr/bin/debconf-set-selections
apt-get -y install oracle-java11-installer

# Install FFMPEG
echo "Install Ffmpeg"
add-apt-repository -y ppa:jonathonf/ffmpeg-4
apt-get update
apt-get -y install ffmpeg

# Install Nginx
echo "Install Nginx"
apt-get -y install nginx

# Configure Nginx
echo "Configure Nginx"
export ESCAPED_PUBLIC_DOMAIN=$(echo ${PUBLIC_DOMAIN} | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')
export ESCAPED_INTERNAL_DOMAIN=$(echo ${INTERNAL_DOMAIN} | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')
sed -i "s/public\.example\.com/${ESCAPED_PUBLIC_DOMAIN}/" /tmp/nginx-transcoder.conf
sed -i "s/internal\.example\.com/${ESCAPED_INTERNAL_DOMAIN}/" /tmp/nginx-transcoder.conf
cp /tmp/nginx-transcoder.conf /etc/nginx/conf.d/transcoder.conf

# Configure the application
echo "Configure the transcoder app"
FFMPEG_PATH=/usr/bin/ffmpeg
export ESCAPED_FFMPEG_PATH=$(echo ${FFMPEG_PATH} | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')
sed -i "s/\(transcoding\.ffmpegExecutablePath=\).*\$/\1${ESCAPED_FFMPEG_PATH}/" /tmp/application.properties
mkdir -p /etc/transcoder
mkdir -p /opt/transcoder
cp /tmp/application.properties /etc/transcoder/
cp /tmp/transcoder.jar /opt/transcoder/
cp /tmp/transcoder.service /etc/systemd/system/

# Start and enable the application and Nginx
echo "Start the transcoder app and Nginx"
systemctl start transcoder.service
systemctl enable transcoder.service
systemctl start nginx
systemctl enable nginx