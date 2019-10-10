local args = ngx.req.get_uri_args(4)
local videos, total =
  vod_core.get_videos(args.start, args.finish, args.skip, args.limit)
ngx.say(json.encode({
  videos = videos,
  total = total
}))
