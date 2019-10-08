local args = ngx.req.get_uri_args(1)
local file = vod_core.open_raw(args.id)
local content, err = file:slurp()
if not content then
  ngx.log(ngx.ERR, "mongodb error: ", err)
  ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
ngx.header["Content-Type"] = "application/octet-stream"
ngx.header["Content-Disposition"] =
  'attachment; filename="'..file:filename()..'"'
ngx.header["X-Content-MD5"] = file:md5()
ngx.print(content)
