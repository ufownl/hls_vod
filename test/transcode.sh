#! /bin/sh
# 转码指定视频

curl -v --data-urlencode "id=$1" \
     --data-urlencode "profile=$2" \
     --data-urlencode "width=$3" \
     --data-urlencode "height=$4" \
     "http://localhost:2980/hls_vod/api/transcode"

# 参数:
# id: 视频ID
# profile: 转码配置名称
# width: 输出视频宽度(-1 表示按比例缩放)
# height: 输出视频高度(-1 表示按比例缩放)
# 返回: 无
