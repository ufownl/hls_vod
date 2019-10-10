local args = ngx.req.get_uri_args(1)
ngx.say(json.encode(vod_core.get_video_meta(args.id)))
