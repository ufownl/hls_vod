#! /bin/sh
# Remove a specific video

curl -v --data-urlencode "id=$1" \
     "http://localhost:2981/hls_vod/api/remove_video"

# Parameters:
# id: Video ID
# Return: None
