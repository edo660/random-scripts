#!/bin/bash
#script will get the latest version of minecraft server, based off the latest release in versions.json
#requires CURL
#USAGE: ./getLatestMinecraftServer.sh /path/to/download/directory
if [ -z "$1" ]
  then
    echo "Usage: $0 /path/to/directory"
    exit 2
fi
MCVER=$(curl -s https://s3.amazonaws.com/Minecraft.Download/versions/versions.json | grep release | head -n 1 | cut -d '"' -f 4)
wget -N https://s3.amazonaws.com/Minecraft.Download/versions/$MCVER/minecraft_server.$MCVER.jar -O "${1}/minecraft_server.jar"