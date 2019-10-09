ngx.req.read_body()
local args = ngx.req.get_post_args(2)
vod_core.cover_task(args.id, args.ss)
ngx.exit(ngx.HTTP_NO_CONTENT)
