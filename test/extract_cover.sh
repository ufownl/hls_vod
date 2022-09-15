#! /bin/sh
# Extract the video cover

curl -v --data-urlencode "id=$1" \
     --data-urlencode "ss=$2" \
     "http://localhost:2980/hls_vod/api/extract_cover"

# Parameters:
# id: Video ID
# ss: Timeline Position of the Cover (second, Optional, Default: 0)
# Return:
# {
#   "path": "Resource Path of the Extracted Cover"
# }
