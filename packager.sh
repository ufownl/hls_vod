#! /bin/bash

if [ ! -n "$1" ]
then
  echo "Usage: ./packager.sh <TARGET_DIR> [BRANCH]"
  exit 0
fi

TARGET_DIR=$1
SERVER_DIR="$TARGET_DIR/hls_vod_server"
TRANSCODER_DIR="$TARGET_DIR/hls_vod_transcoder"
if [ ! -n "$2" ]
then
  BRANCH="release"
else
  BRANCH=$2
fi
SUFFIX=`date +%Y%m%d%H%M%S`
EXPORT_DIR="/tmp/hls_vod_$SUFFIX"

set -e
mkdir "$EXPORT_DIR"
git archive $BRANCH | tar -xv -C "$EXPORT_DIR"
cd "$EXPORT_DIR"
mkdir "$SERVER_DIR"
mv server "$SERVER_DIR"
mv dbscripts "$SERVER_DIR"
mv transcoder "$TRANSCODER_DIR"
cd "$TARGET_DIR"
tar czvf hls_vod_server.tar.gz hls_vod_server
tar czvf hls_vod_transcoder.tar.gz hls_vod_transcoder
rm -r hls_vod_server hls_vod_transcoder
echo "Success!"
