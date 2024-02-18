#   HLS vod, video-on-demand server using HLS protocol.
#   Copyright (C) 2022  RangerUFO
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.


import os
import ffmpeg
from core_base import CoreBase
    

class FFmpegCore(CoreBase):
    def __init__(self, work_dir, api_entry, logo):
        super(FFmpegCore, self).__init__(work_dir, api_entry, logo)

    def probe(self, raw):
        try:
            info = ffmpeg.probe(raw)
            fmt = info["format"]
            width = 0
            height = 0
            rotation = 0
            for stream in info["streams"]:
                if stream["codec_type"] == "video":
                    width = stream["width"]
                    height = stream["height"]
                    if "side_data_list" in stream:
                        for side_data in stream["side_data_list"]:
                            if "rotation" in side_data:
                                rotation = side_data["rotation"]
                                break
                    break
            return {
                "format": fmt["format_name"],
                "duration": fmt["duration"],
                "bit_rate": fmt["bit_rate"],
                "width": width,
                "height": height,
                "rotation": rotation
            }, None
        except ffmpeg.Error as e:
            print("ffmpeg error: ", e)
            return None, repr(e)

    def cover(self, raw, params):
        base, _ = os.path.splitext(raw)
        cover = base + ".jpg"
        ss = params["ss"]
        try:
            ffmpeg.input(raw, ss=ss, stream_loop=-1).output(cover, vframes=1).overwrite_output().run()
            return cover, None
        except ffmpeg.Error as e:
            print("ffmpeg error: ", e)
            return None, repr(e)

    def transcode(self, raw, params):
        base, _ = os.path.splitext(raw)
        playlist = base + ".m3u8"
        width = params["width"]
        height = params["height"]
        if self._logo:
            logo_x = params["logo_x"]
            logo_y = params["logo_y"]
            logo_w = params["logo_w"]
            logo_h = params["logo_h"]
        try:
            stream = ffmpeg.input(raw)
            v = stream.video.filter("scale", width=width, height=height)
            v = v.filter("pad", width="ceil(iw/2)*2", height="ceil(ih/2)*2")
            if self._logo:
                logo = ffmpeg.input(self._logo)
                logo = logo.filter("scale", width=logo_w, height=logo_h)
                v = v.overlay(logo, x=logo_x, y=logo_y)
            a = stream["a?"]
            ffmpeg.output(v, a, playlist, hls_time=10, hls_list_size=0).overwrite_output().run()
            return playlist, None
        except ffmpeg.Error as e:
            print("ffmpeg error: ", e)
            return None, repr(e)
