-- MongoDB options
mongo_uri = "mongodb://127.0.0.1:27017"
mongo_db = "hls_vod"
-- Redis options
redis_uri = "redis://127.0.0.1:6379/0"
-- HLS vod callbacks
vod_callback = {
  raw_meta = {
    "http://127.0.0.1:2980/hls_vod/api/callback/raw_meta"
  },
  cover = {
    "http://127.0.0.1:2980/hls_vod/api/callback/cover"
  },
  transcode = {
    "http://127.0.0.1:2980/hls_vod/api/callback/transcode"
  }
}
