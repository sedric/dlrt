#!/bin/bash

ENDPOINT="https://svod-be.roosterteeth.com"
DEPS="jq wget"

function usage()
{
  echo "Usage: $0 EpisodeURL"
  exit 1
}

[ -z "$1" ] && usage

for dep in $DEPS
do
  if ! hash $dep 2>/dev/null ; then
    echo "ERROR: Please install: $DEPS (they must be in your PATH)"
    exit 1
  fi
done

SHOW=$(echo $1 | rev | cut -d '/' -f 1 | rev)
SHOWURL="$ENDPOINT/api/v1/shows/$SHOW/seasons?order=asc"

echo "Trying to download $SHOW"
for seasonsuri in $(wget "$SHOWURL" -qO -  |jq -r '.data[].links["episodes"]')
do
  SEASONURL=$ENDPOINT$seasonsuri
  echo "Getting episodes list from $SEASONURL"
  for episodeuri in $(wget -qO - "$SEASONURL" |jq -r '.data[].links["self"]')
  do
    EPISODEURL=$ENDPOINT$episodeuri
    echo "Downloading from $EPISODEURL"
    $(dirname $0)/dlepisode.sh "$EPISODEURL"
  done
done
