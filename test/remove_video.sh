#! /bin/sh
# Remove a specific video

curl -v --data-urlencode "id=$1" \
     "http://localhost:2980/hls_vod/api/remove_video"

# Parameters:
# id: Video ID
# Return: None
