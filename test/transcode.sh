#! /bin/sh
# 转码指定视频

curl -v --data-urlencode "id=$1" \
     --data-urlencode "profile=$2" \
     --data-urlencode "width=$3" \
     --data-urlencode "height=$4" \
     --data-urlencode "logo_x=$5" \
     --data-urlencode "logo_y=$6" \
     --data-urlencode "logo_w=$7" \
     --data-urlencode "logo_h=$8" \
     "http://localhost:2980/hls_vod/api/transcode"

# 参数:
# id: 视频ID
# profile: 转码规格名称
# width/height: 输出视频宽度/高度(-1表示按比例缩放 可选参数 默认值: -1)
# logo_x/logo_y: LOGO水印位置(可选参数 默认值: 0)
# logo_w/logo_h: LOGO水印宽度/高度(-1表示按比例缩放 可选参数 默认值: -1)
# 返回:
# {
#   "path": "视频转码成功后的资源路径"
# }
