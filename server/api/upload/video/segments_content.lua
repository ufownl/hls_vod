local args = ngx.req.get_uri_args(1)
if not args.profile then
  ngx.exit(ngx.HTTP_BAD_REQUEST)
end
local files = vod_core.recv_files("fs.segment")
vod_core.set_segments(ngx.var.video, args.profile, files)
ngx.exit(ngx.HTTP_NO_CONTENT)
