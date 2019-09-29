json = require("cjson.safe")
json.encode_empty_table_as_object(false)
rstring = require("resty.string")
upload = require("resty.upload")
bson = require("cbson")
mongo = require("resty.moongoo")
mongo_uri = "mongodb://127.0.0.1:27017"
mongo_db = "hls_vod"
redis = require("resty.redis.connector")
redis_uri = "redis://127.0.0.1:6379/0"
vod_core = require("vod.core")
