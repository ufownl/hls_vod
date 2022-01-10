vod_core.keepalive()
ngx.header["Access-Control-Allow-Origin"] = "*"
ngx.header["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE"
ngx.header["Access-Control-Allow-Headers"] =
  "Keep-Alive,User-Agent,Authorization,Content-Type"
if ngx.HTTP_OK <= ngx.status and ngx.status < ngx.HTTP_SPECIAL_RESPONSE then
  if ngx.ctx.cache_control then
    local directives = {}
    if ngx.ctx.cache_control.public then
      table.insert(directives, "public")
    else
      table.insert(directives, "private")
    end
    local max_age = tonumber(ngx.ctx.cache_control.max_age)
    if max_age then
      ngx.header["Expires"] = ngx.http_time(ngx.time() + max_age)
      table.insert(directives, "max-age="..max_age)
    end
    ngx.header["Cache-Control"] = table.concat(directives, ", ")
  else
    ngx.header["Expires"] = "-1"
    ngx.header["Cache-Control"] = "no-store"
    ngx.header["Pragma"] = "no-cache"
  end
end
