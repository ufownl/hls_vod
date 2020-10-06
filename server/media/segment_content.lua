local file = vod_core.open_segment(ngx.var.segment)
ngx.ctx.cache_control = {
  public = true,
  max_age = 30 * 24 * 3600
}
ngx.header["Content-Type"] = "video/mp2t"
while true do
  local chunk = file:read()
  if not chunk then
    break
  end
  ngx.print(chunk)
end
