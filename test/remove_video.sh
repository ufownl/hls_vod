#! /bin/sh
# 删除指定视频

curl -v --data-urlencode "id=$1" \
     "http://localhost:2980/hls_vod/api/remove_video"

# 参数:
# id: 视频ID
# 返回: 无
