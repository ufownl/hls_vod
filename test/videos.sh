#! /bin/sh
# 转码指定视频

curl -v -G --data-urlencode "start=$1" \
     --data-urlencode "finish=$2" \
     --data-urlencode "skip=$3" \
     --data-urlencode "limit=$4" \
     "http://localhost:2980/hls_vod/api/videos"

# 参数:
# start/finish: 上传时间范围(unix时间戳 可选参数)
# skip/limit: 分页参数(可选参数)
# 返回:
# {
#   "videos": [
#     {
#       "id": "视频ID",
#       "date": 视频上传时间(unix时间戳),
#       "duration": 视频时长(秒),
#       "profiles": [
#         ... 视频转码规格
#       ]
#     },
#     ...
#   ],
#   "total": 视频总数量
# }
