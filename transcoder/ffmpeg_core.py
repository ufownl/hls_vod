import os
import ffmpeg
from core_base import CoreBase
    

class FFmpegCore(CoreBase):
    def __init__(self, work_dir, api_entry):
        super(FFmpegCore, self).__init__(work_dir, api_entry)

    def probe(self, raw):
        try:
            fmt = ffmpeg.probe(raw)["format"]
            return {
                "format": fmt["format_name"],
                "duration": fmt["duration"],
                "bit_rate": fmt["bit_rate"]
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