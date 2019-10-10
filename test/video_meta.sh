#! /bin/sh
# 转码指定视频

curl -v -G --data-urlencode "id=$1" \
     "http://localhost:2980/hls_vod/api/video_meta"

# 参数:
# id: 视频ID
# 返回:
# {
#   "id": "视频ID",
#   "date": 视频上传时间(unix时间戳),
#   "duration": 视频时长(秒),
#   "profiles": [
#     ... 视频转码规格
#   ]
# }
