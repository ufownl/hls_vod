#! /bin/sh
# 设置原始视频信息

curl --data-urlencode "id=$1" \
     --data-urlencode "meta=$2" \
     "http://localhost:2980/hls_vod/api/set_raw_meta"

# 返回: 无
