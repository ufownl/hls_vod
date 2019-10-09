#! /bin/sh
# 提取视频封面

curl -v --data-urlencode "id=$1" \
     --data-urlencode "ss=$2" \
     "http://localhost:2980/hls_vod/api/extract_cover"

# 返回: 无
