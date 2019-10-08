import os
import time
import argparse
import urllib
import redis
from multiprocessing import cpu_count, Process
from ffmpeg_core import FFmpegCore


def worker_entry(args, now, worker_idx):
    # Create the work directory of worker
    work_dir = os.path.join(args.work_dir, "transcoder_%s_%d" % (str(now).replace(".", "_"), worker_idx))
    os.mkdir(work_dir)
    # Create the redis instance
    redisc = redis.from_url(args.redis_uri)
    # Set the proxies of HTTP requests
    proxies = {}
    if not args.http_proxy is None:
        proxies["http"] = args.http_proxy
    if not args.https_proxy is None:
        proxies["https"] = args.https_proxy
    if not proxies:
        urllib.request.install_opener(urllib.request.build_opener(
            urllib.request.ProxyHandler(proxies),
            urllib.request.HTTPBasicAuthHandler(),
            urllib.request.HTTPHandler
        ))
    # Main loop
    core = FFmpegCore(work_dir, args.api_entry)
    while True:
        task = redisc.brpop("transcoding_tasks")
        if task:
            core(task[1])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Start the transcoder service.")
    parser.add_argument("--work_dir", help="set the work directory (default: /tmp)", type=str, default="/tmp")
    parser.add_argument("--workers", help="set the number of worker processes (default: CPUs x2)", type=int, default=cpu_count()*2)
    parser.add_argument("--redis_uri", help="set the URI of redis server (default: redis://127.0.0.1:6379/0)", type=str, default="redis://127.0.0.1:6379/0")
    parser.add_argument("--api_entry", help="set the entry of platform APIs (default: http://127.0.0.1:2980)", type=str, default="http://127.0.0.1:2980")
    parser.add_argument("--http_proxy", help="set the http proxy", type=str)
    parser.add_argument("--https_proxy", help="set the https proxy", type=str)
    args = parser.parse_args()

    now = time.time()
    processes = [Process(target=worker_entry, args=(args, now, i)) for i in range(args.workers)]
    for p in processes:
        p.start()
    for p in processes:
        p.join()
