config = {
  -- MongoDB options
  mongo = {
    uri = "mongodb://127.0.0.1:27017",
    db = "hls_vod"
  },
  -- Redis options
  redis = {
    uri = "redis://127.0.0.1:6379/0"
  },
  -- HLS vod callbacks
  callbacks = {
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
}
