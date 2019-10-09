#! /bin/sh
# 上传原始视频

curl -v -F "filename=@$1" \
     "http://localhost:2980/hls_vod/api/upload/raw"

# 返回:
# [
#   {
#     "id": "视频ID",
#     "filename": "原始视频文件名"
#   },
#   ...
# ]
