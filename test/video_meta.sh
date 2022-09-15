#! /bin/sh
# Query the meta-data of a specific video

curl -v -G --data-urlencode "id=$1" \
     "http://localhost:2980/hls_vod/api/video_meta"

# Parameters:
# id: Video ID
# Return:
# {
#   "id": "Video ID",
#   "date": upload Time (Unix Timestamp),
#   "duration": Video Duration (second),
#   "raw_width": Width of Raw Video,
#   "raw_height": Height of Raw Video,
#   "profiles": [
#     "Profile Name",
#     ...
#   ]
# }
