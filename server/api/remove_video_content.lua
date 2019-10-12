ngx.req.read_body()
local args = ngx.req.get_post_args(1)
vod_core.remove_video(args.id)
