ngx.req.read_body()
local args = ngx.req.get_post_args(2)
vod_core.cover_task(args.id, args.ss)
ngx.status = ngx.HTTP_ACCEPTED
ngx.say(json.encode({
  path = "/hls_vod/media/"..args.id..".jpg"
}))
