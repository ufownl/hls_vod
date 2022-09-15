#! /bin/sh
# Query the videos

curl -v -G --data-urlencode "start=$1" \
     --data-urlencode "finish=$2" \
     --data-urlencode "skip=$3" \
     --data-urlencode "limit=$4" \
     "http://localhost:2980/hls_vod/api/videos"

# Parameters:
# start/finish: Upload Time Range (Unix Timestamp, Optional)
# skip/limit: Parameters of Pagination (Optional)
# Return:
# {
#   "videos": [
#     {
#       "id": "Video ID",
#       "date": Upload Time (Unix Timestamp),
#       "duration": Video Duratoin (second),
#       "raw_width": Width of Raw Video,
#       "raw_height": Height of Raw Video,
#       "profiles": [
#         "Profile Name",
#         ...
#       ]
#     },
#     ...
#   ],
#   "total": Total Number of Videos
# }
