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
            for stream in info["streams"]:
                if stream["codec_type"] == "video":
                    width = stream["width"]
                    height = stream["height"]
                    break
            return {
                "format": fmt["format_name"],
                "duration": fmt["duration"],
                "bit_rate": fmt["bit_rate"],
                "width": width,
                "height": height
            }
        except ffmpeg.Error as e:
            print("ffmpeg error: ", e)
            return None

    def cover(self, raw, params):
        base, _ = os.path.splitext(raw)
        cover = base + ".jpg"
        ss = params["ss"]
        try:
            ffmpeg.input(raw, ss=ss).output(cover, vframes=1).overwrite_output().run()
            return cover
        except ffmpeg.Error as e:
            print("ffmpeg error: ", e)
            return None

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
            if self._logo:
                logo = ffmpeg.input(self._logo).filter("scale", width=logo_w, height=logo_h)
                v = v.overlay(logo, x=logo_x, y=logo_y)
            a = stream.audio
            ffmpeg.output(v, a, playlist, hls_time=10, hls_list_size=0).overwrite_output().run()
            return playlist
        except ffmpeg.Error as e:
            print("ffmpeg error: ", e)
            return None
