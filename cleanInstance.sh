#!/bin/bash

# variables
user="$(whoami)"
workingDir=$(dirname "$(realpath "$0")")

set -e # to exit on exit 1
cd ${workingDir}

function isRoot(){
        if [ "$(id -u)" != "0" ]
        then
                printf "Not root! Exiting... \n"
                exit 1
        fi
}

# remove nextcloud bind mount
# remove crowdsec bind mount 
# remove certbot bind mount

isRoot

rm -r crowdsec/crowdsec-config-volume
rm -r nextcloud/*
rm -r certbot/*
