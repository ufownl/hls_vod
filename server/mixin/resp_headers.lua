--[[
--  HLS vod, video-on-demand server using HLS protocol.
--  Copyright (C) 2022  RangerUFO
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]

vod_core.keepalive()
if ngx.status >= ngx.HTTP_OK then
  ngx.header["Access-Control-Allow-Origin"] = "*"
  ngx.header["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE"
  ngx.header["Access-Control-Allow-Headers"] = "Keep-Alive,User-Agent,Authorization,Content-Type"
  if ngx.status < ngx.HTTP_SPECIAL_RESPONSE then
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
end
