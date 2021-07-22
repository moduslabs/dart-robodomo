#!/bin/sh

if [ $# = 0 ]; then
  echo "Use: $0 path"
  exit 1
fi

if [ ! -d "$1" ]; then
  echo "'$1' is not a directory"
  exit 1
fi

if [ ! -f "$1/Dockerfile" ]; then
  echo "'$1/Dockerfile' does not exist"
  exit 1
fi

echo "BUILDING $1"
docker-compose build $1
