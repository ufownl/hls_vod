#! /bin/sh
# 下载原始视频

curl -v -G --data-urlencode "id=$1" \
     "http://localhost:2980/hls_vod/api/download/raw"

# 参数:
# id: 视频ID
# 返回: 文件二进制流
