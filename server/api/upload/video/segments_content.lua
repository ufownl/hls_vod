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

local args = ngx.req.get_uri_args(1)
if not args.profile then
  ngx.exit(ngx.HTTP_BAD_REQUEST)
end
local files = vod_core.recv_files("fs.segment")
vod_core.set_segments(ngx.var.video, args.profile, files)
ngx.exit(ngx.HTTP_NO_CONTENT)
