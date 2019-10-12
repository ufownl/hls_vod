local playlist = vod_core.get_playlist(ngx.var.video, ngx.var.profile)
ngx.ctx.cache_control = {
  public = true,
  max_age = 30 * 24 * 3600
}
ngx.header["Content-Type"] = "application/vnd.apple.mpegurl"
ngx.print(playlist)
