FROM nextcloud:apache

RUN apt-get update && apt-get install -y procps smbclient graphicsmagick ffmpeg ghostscript
