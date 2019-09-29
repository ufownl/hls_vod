#! /bin/sh
# 上传原始视频

curl -F "filename=@$1" \
     "http://localhost:2980/hls_vod/upload/raw"

# 返回: ["视频ID", ...]
