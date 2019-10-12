local files = vod_core.recv_files("fs.cover", 4096, 1)
if files[1] then
  vod_core.set_cover(ngx.var.video, files[1].id)
end
ngx.exit(ngx.HTTP_CREATED)
