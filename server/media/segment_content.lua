local file = vod_core.open_segment(ngx.var.segment)
local content, err = file:slurp()
if not content then
  ngx.log(ngx.ERR, "mongodb error: ", err)
  ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
ngx.ctx.cache_control = {
  public = true,
  max_age = 30 * 24 * 3600
}
ngx.header["Content-Type"] = "video/mp2t"
ngx.print(content)
