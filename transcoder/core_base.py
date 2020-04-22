import os
import re
import json
import m3u8
import requests
from abc import ABCMeta, abstractmethod

class CoreBase(metaclass=ABCMeta):
    _filename_pattern = re.compile('^attachment; filename="(.+)"$')

    def __init__(self, work_dir, api_entry, logo):
        self._work_dir = work_dir
        self._api_entry = api_entry
        self._logo = logo

    def __call__(self, raw_task):
        try:
            task = json.loads(raw_task)
            cmd = task["cmd"]
            vid = task["vid"]
            raw = self._download_raw(vid)
            if not raw or not os.path.isfile(raw):
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
        except OSError as e:
            print("system error: ", e)

    @abstractmethod
    def probe(self, raw):
        return None, "Not implemented."

    @abstractmethod
    def cover(self, raw, params):
        return None, "Not implemented."

    @abstractmethod
    def transcode(self, raw, params):
        return None, "Not implemented."

    def _download_raw(self, vid):
        try:
            r = requests.get(
                self._api_entry + "/hls_vod/api/download/raw",
                params = {
                    "id": vid
                }
            )
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
        meta, err = self.probe(raw)
        if not meta:
            self._report_error({
                "task": "probe",
                "id": vid,
                "error": err
            })
            return
        try:
            requests.post(
                self._api_entry + "/hls_vod/api/set_raw_meta",
                data = {
                    "id": vid,
                    "meta": json.dumps(meta)
                }
            )
        except requests.exceptions.RequestException as e:
            print("http error: ", e)

    def _handle_cover(self, vid, raw, params):
        cover, err = self.cover(raw, params)
        if not cover:
            self._report_error({
                "task": "cover",
                "id": vid,
                "error": err
            })
            return
        try:
            requests.post(
                self._api_entry + "/hls_vod/api/upload/" + vid + "/cover",
                files = {
                    "cover": open(cover, "rb")
                }
            )
        except requests.exceptions.RequestException as e:
            print("http error: ", e)
        except OSError as e:
            print("system error: ", e)
            self._report_error({
                "task": "cover",
                "id": vid,
                "error": repr(e)
            })
        finally:
            if os.path.isfile(cover):
                os.remove(cover)

    def _handle_transcode(self, vid, raw, params):
        profile = params["profile"]
        playlist, err = self.transcode(raw, params)
        if not playlist:
            self._report_error({
                "task": "transcode",
                "id": vid,
                "profile": profile,
                "error": err
            })
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
            self._report_error({
                "task": "transcode",
                "id": vid,
                "profile": profile,
                "error": repr(e)
            })
        finally:
            for seg in segments:
                ts_file = os.path.join(self._work_dir, seg.uri)
                if os.path.isfile(ts_file):
                    os.remove(ts_file)
            if os.path.isfile(playlist):
                os.remove(playlist)

    def _report_error(self, params):
        try:
            requests.post(
                self._api_entry + "/hls_vod/api/transcoder_error",
                data = params
            )
        except requests.exceptions.RequestException as e:
            print("http error: ", e)
