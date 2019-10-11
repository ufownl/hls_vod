json = require("cjson.safe")
json.encode_empty_table_as_object(false)
rstring = require("resty.string")
upload = require("resty.upload")
http = require("resty.http")
bson = require("cbson")
mongo = require("resty.moongoo")
mongo_uri = "mongodb://127.0.0.1:27017"
mongo_db = "hls_vod"
redis = require("resty.redis.connector")
redis_uri = "redis://127.0.0.1:6379/0"
vod_core = require("vod.core")
-- HLS vod callbacks
vod_callback = {
  raw_meta = "http://127.0.0.1:2980/hls_vod/api/callback/raw_meta",
  cover = "http://127.0.0.1:2980/hls_vod/api/callback/cover",
  transcode = "http://127.0.0.1:2980/hls_vod/api/callback/transcode"
}
