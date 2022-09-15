#! /bin/sh
# 提取视频封面

curl -v --data-urlencode "id=$1" \
     --data-urlencode "ss=$2" \
     "http://localhost:2980/hls_vod/api/extract_cover"

# 参数:
# id: 视频ID
# ss: 封面截取时间(秒 可选参数 默认值: 0)
# 返回:
# {
#   "path": "封面提取成功后的资源路径"
# }
