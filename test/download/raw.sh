#! /bin/sh
# 下载原始视频

curl -G --data-urlencode "id=$1" \
     "http://localhost:2980/hls_vod/download/raw"

# 返回: 文件数据二进制流
