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
import time
import argparse
import requests
import redis
from urllib.parse import urlparse
from multiprocessing import cpu_count, Process
from ffmpeg_core import FFmpegCore


def query_redis_cfg(args):
    cfg = requests.get(args.api_entry + "/hls_vod/api/task_queue").json()["redis"]
    r = urlparse(cfg["uri"])
    if r.hostname == "127.0.0.1" or r.hostname == "localhost":
        hostname = urlparse(args.api_entry).hostname
        cfg["uri"] = r._replace(netloc=(hostname if r.port is None else "{}:{}".format(hostname, r.port))).geturl()
    return cfg


def worker_entry(args, redis_cfg, now, worker_idx):
    # Create the work directory of worker
    work_dir = os.path.join(args.work_dir, "transcoder_%s_%d" % (str(now).replace(".", "_"), worker_idx))
    os.mkdir(work_dir)
    # Create the redis instance
    redisc = redis.from_url(redis_cfg["uri"])
    # Main loop
    core = FFmpegCore(work_dir, args.api_entry, args.logo)
    while True:
        task = redisc.brpop(redis_cfg["tq"])
        if task:
            core(task[1].decode())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Start the transcoder service.")
    parser.add_argument("--work_dir", help="set the work directory (default: /tmp)", type=str, default="/tmp")
    parser.add_argument("--workers", help="set the number of worker processes (default: CPUs x2)", type=int, default=cpu_count()*2)
    parser.add_argument("--api_entry", help="set the entry of platform APIs (default: http://127.0.0.1:2981)", type=str, default="http://127.0.0.1:2981")
    parser.add_argument("--logo", help="set the path of logo file", type=str)
    args = parser.parse_args()

    print("HLS_vod  Copyright (C) 2022  RangerUFO")
    redis_cfg = query_redis_cfg(args)
    now = time.time()
    processes = [Process(target=worker_entry, args=(args, redis_cfg, now, i)) for i in range(args.workers)]
    for p in processes:
        p.start()
    for p in processes:
        p.join()
