local file = vod_core.open_cover(ngx.var.cover)
local content, err = file:slurp()
if not content then
  ngx.log(ngx.ERR, "mongodb error: ", err)
  ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
ngx.ctx.cache_control = {
  public = true,
  max_age = 30 * 24 * 3600
}
ngx.header["Content-Type"] = "image/jpeg"
ngx.print(content)
