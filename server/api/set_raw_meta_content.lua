ngx.req.read_body()
local args = ngx.req.get_post_args(2)
vod_core.set_raw_meta(args.id, args.meta)
ngx.exit(ngx.HTTP_CREATED)
