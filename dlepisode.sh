#!/bin/bash

URL=$1
EPISODE=$(echo $URL | rev | cut -d '/' -f 1 | rev)
DEPS="jq ffmpeg wget"
HEADERS="Accept-Language: en-us,en;q=0.5
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Encoding: gzip, deflate"

function usage()
{
  echo "Usage: $0 EpisodeURL"
  exit 1
}

# get_sub shortform longform
#   shortform : as they appear in playlist file
#   longform : as they will appear in file name
function get_sub()
{
  # En, fr, ... As found in webpages
  LANGSHORT=$1
  # English, French, ... As it will be written in file name
  LANGNAME=$2

  manifesturl=$(wget -qO- $STREAM_URL | grep -Eo "https://.*${LANGSHORT}_manifest.m3u8")
  if [ -z "$manifesturl" ]
  then
    echo "No $LANGNAME subtitles"
  else
    echo "Downloading $LANGNAME subtitles as $FILESNAME.$LANGNAME.srt"
    suburl="$(echo $manifesturl | rev | cut -d'/' -f2- |rev)/vtt_${LANGSHORT}.webvtt"
    wget $suburl -qO "$FILESNAME.$LANGNAME.srt"
  fi
}

[ -z "$1" ] && usage

for dep in $DEPS
do
  if ! hash $dep 2>/dev/null ; then
    echo "ERROR: Please install: $DEPS (they must be in your PATH)"
    exit 1
  fi
done

# There is 2 API :
# - the first one indicate videos metadatas (API)
# - the second one indicate the videos stream (STREAM API)
API_URL="https://svod-be.roosterteeth.com/api/v1/episodes/$EPISODE"
STREAM_API_URL="$API_URL/videos"

API=$(wget -qO- "$API_URL" 2>/dev/null)
SPONSOR=$(echo "$API" | jq -r '.data[].attributes["is_sponsors_only"]')

if [ "$SPONSOR" = "true" ]
then
  echo "You need to be authenticated to download this episode (not yet implemented)"
  exit 1
else
  STREAM_URL="$(wget -qO- "$STREAM_API_URL" | jq -r '.data[].attributes["url"]')"
fi

# Stuff to forge files name from API
SHOW=$(echo "$API"  | jq -r '.data[].attributes["show_title"]')
TITLE=$(echo "$API" | jq -r '.data[].attributes["title"]')
SNBR=$(echo "$API"  | jq -r '.data[].attributes["season_number"]')
EPNBR=$(echo "$API" | jq -r '.data[].attributes["number"]')
[ "$SNBR"  -lt 10 ] && SNBR=0$SNBR
[ "$EPNBR" -lt 10 ] && EPNBR=0$EPNBR

# Defining filename for Kodi
FILESNAME=$(echo "$SHOW - s${SNBR}e${EPNBR} - $TITLE")

if echo "$STREAM_URL" | grep -E "https?://roosterteeth.com/" || [ -z "$STREAM_URL" ] \
|| [[ "$STREAM_URL" =~ "parse error" ]]; then
  echo "ERROR: Couldn't get Rooster Teeth API URL"
  exit 1
fi

# if we got this far, $URL is now the URL to the actual video stream that ffmpeg
# can deal with
# But first... SUBTITLES ! :D
# French, because I am
get_sub fr French
# English because I'm pretty sure to get something as it's RT primary language
get_sub en English
echo "Downloading as $FILESNAME"
ffmpeg -y -headers "$HEADERS" \
       -i $(echo "$STREAM_URL" | head -n1) \
       -c copy -f mp4 \
       file:"$FILESNAME".mp4
