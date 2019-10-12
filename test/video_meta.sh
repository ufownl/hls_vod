#! /bin/sh
# 获取指定视频元数据

curl -v -G --data-urlencode "id=$1" \
     "http://localhost:2980/hls_vod/api/video_meta"

# 参数:
# id: 视频ID
# 返回:
# {
#   "id": "视频ID",
#   "date": 视频上传时间(unix时间戳),
#   "duration": 视频时长(秒),
#   "raw_width": 原始视频宽度,
#   "raw_height": 原始视频高度,
#   "profiles": [
#     ... 视频转码规格
#   ]
# }
