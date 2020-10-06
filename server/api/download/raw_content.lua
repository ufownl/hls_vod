local args = ngx.req.get_uri_args(1)
local file = vod_core.open_raw(args.id)
ngx.header["Content-Type"] = "application/octet-stream"
ngx.header["Content-Disposition"] =
  'attachment; filename="'..file:filename()..'"'
ngx.header["X-Content-MD5"] = file:md5()
while true do
  local chunk = file:read()
  if not chunk then
    break
  end
  ngx.print(chunk)
end
