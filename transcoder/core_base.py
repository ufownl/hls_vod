import os
import re
import json
import m3u8
import requests
from abc import ABCMeta, abstractmethod

class CoreBase(metaclass=ABCMeta):
    _filename_pattern = re.compile('^attachment; filename="(.+)"$')

    def __init__(self, work_dir, api_entry):
        self._work_dir = work_dir
        self._api_entry = api_entry

    def __call__(self, raw_task):
        try:
            task = json.loads(raw_task)
            cmd = task["cmd"]
            vid = task["vid"]
            raw = self._download_raw(vid)
            if not raw:
                print("task error: ", "invalid video")
                return
            if cmd == "probe":
                self._handle_probe(vid, raw)
            elif cmd == "cover":
                self._handle_cover(vid, raw, task["params"])
            elif cmd == "transcode":
                self._handle_transcode(vid, raw, task["params"])
            else:
                print("task error: ", "invalid command")
            os.remove(raw)
        except json.decoder.JSONDecodeError as e:
            print("json error: ", e)
        except KeyError as e:
            print("key error: ", e)

    @abstractmethod
    def probe(self, raw):
        return None

    @abstractmethod
    def cover(self, raw, params):
        return None

    @abstractmethod
    def transcode(self, raw, params):
        return None

    def _download_raw(self, vid):
        try:
            url = self._api_entry + "/hls_vod/api/download/raw"
            r = requests.get(url, params={
                "id": vid
            })
            if r.status_code != requests.codes.ok:
                return None
            m = self._filename_pattern.match(r.headers["Content-Disposition"])
            if not m:
                return None
            _, ext = os.path.splitext(m.group(1))
            path = os.path.join(self._work_dir, vid + ext)
            with open(path, "wb") as f:
                for chunk in r.iter_content(chunk_size=4096):
                    f.write(chunk)
            return path
        except requests.exceptions.RequestException as e:
            print("http error: ", e)
            return None
        except OSError as e:
            print("system error: ", e)
            return None

    def _handle_probe(self, vid, raw):
        meta = self.probe(raw)
        if not meta:
            return
        try:
            url = self._api_entry + "/hls_vod/api/set_raw_meta"
            requests.post(url, data={
                "id": vid,
                "meta": json.dumps(meta)
            })
        except requests.exceptions.RequestException as e:
            print("http error: ", e)

    def _handle_cover(self, vid, raw, params):
        cover = self.cover(raw, params)
        if not cover:
            return
        try:
            url = self._api_entry + "/hls_vod/api/upload/" + vid + "/cover"
            requests.post(url, files={
                "cover": open(cover, "rb")
            })
        except requests.exceptions.RequestException as e:
            print("http error: ", e)
        except OSError as e:
            print("system error: ", e)
        finally:
            os.remove(cover)

    def _handle_transcode(self, vid, raw, params):
        profile = params["profile"]
        playlist = self.transcode(raw, params)
        if not playlist:
            return
        segments = m3u8.load(playlist).segments
        try:
            requests.post(
                self._api_entry + "/hls_vod/api/upload/" + vid + "/segments",
                params = dict(profile=profile),
                files = dict([("file_%d" % i, ("%s#%d@%f.ts" % (vid, i, seg.duration), open(os.path.join(self._work_dir, seg.uri), "rb"))) for i, seg in enumerate(segments)])
            )
        except requests.exceptions.RequestException as e:
            print("http error: ", e)
        except OSError as e:
            print("system error: ", e)
        finally:
            for seg in segments:
                os.remove(os.path.join(self._work_dir, seg.uri))
            os.remove(playlist)
