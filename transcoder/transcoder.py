import os
import time
import argparse
import requests
import redis
from multiprocessing import cpu_count, Process
from ffmpeg_core import FFmpegCore


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
    parser.add_argument("--api_entry", help="set the entry of platform APIs (default: http://127.0.0.1:2980)", type=str, default="http://127.0.0.1:2980")
    parser.add_argument("--logo", help="set the path of logo file", type=str)
    args = parser.parse_args()

    redis_cfg = requests.get(args.api_entry + "/hls_vod/api/task_queue").json()["redis"]
    now = time.time()
    processes = [Process(target=worker_entry, args=(args, redis_cfg, now, i)) for i in range(args.workers)]
    for p in processes:
        p.start()
    for p in processes:
        p.join()
