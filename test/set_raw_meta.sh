#! /bin/sh
# 设置原始视频信息

curl --data-urlencode "id=$1" \
     --data-urlencode "meta=$2" \
     "http://localhost:2980/hls_vod/api/set_raw_meta"

# 参数:
# id: 视频ID
# meta: 原始视频meta信息
# 返回: 无
