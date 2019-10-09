#! /bin/sh
# 上传视频封面

curl -v -F "filename=@$2" \
     "http://localhost:2980/hls_vod/api/upload/$1/cover"

# 返回: 无
