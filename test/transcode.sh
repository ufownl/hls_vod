#! /bin/sh
# Request to transcode a specific video

curl -v --data-urlencode "id=$1" \
     --data-urlencode "profile=$2" \
     --data-urlencode "width=$3" \
     --data-urlencode "height=$4" \
     --data-urlencode "logo_x=$5" \
     --data-urlencode "logo_y=$6" \
     --data-urlencode "logo_w=$7" \
     --data-urlencode "logo_h=$8" \
     "http://localhost:2980/hls_vod/api/transcode"

# Parameters:
# id: Video ID
# profile: Profile Name
# width/height: Width/Height of the Output Video (-1 means scaling in the aspect ratio, Optional, Default: -1)
# logo_x/logo_y: Position of LOGO Watermark (Optional, Default: 0)
# logo_w/logo_h: Width/Height of LOGO Watermark (-1 means scaling in the aspect ratio, Optional, Default: -1)
# Return:
# {
#   "path": "Resource Path of the Transcoded Video"
# }
