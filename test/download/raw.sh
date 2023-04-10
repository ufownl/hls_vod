#! /bin/sh
# Download a specific raw video

curl -v -G --data-urlencode "id=$1" \
     "http://localhost:2981/hls_vod/api/download/raw"

# Parameters:
# id: Video ID
# Return: Binary Data Stream
