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

ngx.req.read_body()
local args = ngx.req.get_post_args(4)
if args.task == "probe" then
  vod_core.probe_error(args.id, args.error)
elseif args.task == "cover" then
  vod_core.cover_error(args.id, args.error)
elseif args.task == "transcode" then
  vod_core.transcode_error(args.id, args.profile, args.error)
else
  ngx.exit(ngx.HTTP_BAD_REQUEST)
end
ngx.exit(ngx.HTTP_NO_CONTENT)
