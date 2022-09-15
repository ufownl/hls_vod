#! /bin/sh
# Upload the raw videos

curl -v -F "filename=@$1" \
     "http://localhost:2980/hls_vod/api/upload/raw"

# 返回:
# [
#   {
#     "id": "Video ID",
#     "filename": "Filename of Raw Video"
#   },
#   ...
# ]
