ngx.req.read_body()
local args = ngx.req.get_post_args(8)
vod_core.transcode_task(args.id, args.profile, args.width, args.height,
                        args.logo_x, args.logo_y, args.logo_w, args.logo_h)
ngx.exit(ngx.HTTP_NO_CONTENT)
