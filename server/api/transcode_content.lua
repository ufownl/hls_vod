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
local args = ngx.req.get_post_args(8)
vod_core.transcode_task(args.id, args.profile, args.width, args.height,
                        args.logo_x, args.logo_y, args.logo_w, args.logo_h)
ngx.status = ngx.HTTP_ACCEPTED
ngx.say(json.encode({
  path = "/hls_vod/media/"..args.id.."_"..args.profile..".m3u8"
}))
