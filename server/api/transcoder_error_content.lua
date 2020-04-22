ngx.req.read_body()
local args = ngx.req.get_post_args(4)
if args.task == "probe" then
  vod_core.probe_error(args.id, args.error)
elseif args.task == "cover" then
  vod_core.cover_error(args.id, args.error)
elseif args.task == "transcode" then
  vod_core.transcode_error(args.id, args.profile, args.error)
else
  ngx.exit(ngx.HTTP_BAD_REQUEST)
end
ngx.exit(ngx.HTTP_NO_CONTENT)
