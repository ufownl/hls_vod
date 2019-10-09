ngx.req.read_body()
local args = ngx.req.get_post_args(4)
vod_core.transcode_task(args.id, args.profile, args.width, args.height)
ngx.exit(ngx.HTTP_NO_CONTENT)
