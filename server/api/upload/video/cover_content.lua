local ids = vod_core.recv_files("fs.cover", 4096, 1)
if ids[1] then
  vod_core.set_cover(ngx.var.video, ids[1])
end
ngx.exit(ngx.HTTP_NO_CONTENT)
