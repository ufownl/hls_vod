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

function config()
  return {
    -- MongoDB options
    mongo = {
      uri = "mongodb://127.0.0.1:27017",
      db = "hls_vod"
    },
    -- Redis options
    redis = {
      uri = "redis://127.0.0.1:6379/0",
      tq = "transcoder_tasks@hls_vod"
    },
    -- HLS vod callbacks
    callbacks = {
      raw_meta = {
        "http://127.0.0.1:2980/hls_vod/api/callback/raw_meta"
      },
      cover = {
        "http://127.0.0.1:2980/hls_vod/api/callback/cover"
      },
      transcode = {
        "http://127.0.0.1:2980/hls_vod/api/callback/transcode"
      }
    }
  }
end
