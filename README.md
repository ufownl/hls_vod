# HLS vod

**HLS vod** is server software that provides video uploading, transcoding, storage, and delivery. It can be used as the origin server for websites and APPs that provide video-on-demand services. It consists of two parts: the *Web Server* and the *Transcoder*, the former provides video access and API services, and the latter provides online video transcoding.

## Contents

* [Web Server](#web-server)
  * [Dependencies](#dependencies)
  * [Run](#run)
  * [Video Access](#video-access)
  * [HTTP APIs](#http-apis)
    * [Upload Raw Video](#upload-raw-video)
    * [Download Raw Video](#download-raw-video)
    * [Extract Video Cover](#extract-video-cover)
    * [Video Transcode](#video-transcode)
    * [Query Videos](#query-videos)
    * [Query Video Meta-Data](#query-video-meta-data)
    * [Remove Video](#remove-video)
  * [Callbacks](#callbacks)
    * [*raw_meta* Callback](#raw_meta-callback)
    * [*cover* Callback](#cover-callback)
    * [*transcode* Callback](#transcode-callback)
* [Transcoder](#transcoder)
  * [Dependencies](#dependencies-1)
  * [Run](#run-1)

## Web Server

It provides video access and API services.

### Dependencies

* [OpenResty](https://openresty.org/)
  * [lua-resty-http](https://github.com/ledgetech/lua-resty-http)
  * [lua-resty-moongoo](https://github.com/isage/lua-resty-moongoo)
  * [lua-resty-redis-connector](https://github.com/ledgetech/lua-resty-redis-connector)

### Run

Before starting the *Web Server*, you need to start [MongoDB](https://www.mongodb.com/) and [Redis](https://redis.io/) and modify the corresponding configuration items in the *config.lua* file, so that the *Web Server* can correctly access the [MongoDB](https://www.mongodb.com/) and [Redis](https://redis.io/) services.

```bash
$ ./resolvers.sh
$ ./lua_ssl.sh
$ openresty -p . -c hls_vod.conf
```

### Video Access

* Video Cover: `http[s]://<Server Netloc>/hls_vod/media/<Video ID>.jpg`
* HLS Playlist: `http[s]://<Server Netloc>/hls_vod/media/<Video ID>_<Profile>.m3u8`

### HTTP APIs

#### Upload Raw Video

* URL: `http://<Server Hostname>:2981/hls_vod/api/upload/raw`
* Request Method: `POST`
* Request Content-Type: `multipart/form-data`
* HTTP Status: 200 means success
* Response Content-Type: `application/json`
* Response Body:

```json
[
  {
    "id": "<Video ID>",
    "filename": "<Filename of Raw Video>"
  },
  ...
]
```

#### Download Raw Video

* URL: `http://<Server Hostname>:2981/hls_vod/api/download/raw`
* Request Method: `GET`
* URL Parameters: 

Name | Type | Description
---- | ---- | -----------
id | string | Video ID

* HTTP Status: 200 means success
* Response Content-Type: `application/octet-stream`
* Response Body: Binary Data Stream

#### Extract Video Cover

* URL: `http://<Server Hostname>:2981/hls_vod/api/extract_cover`
* Request Method: `POST`
* Request Content-Type: `application/x-www-form-urlencoded`
* Request Parameters: 

Name | Type | Description
---- | ---- | -----------
id | string | Video ID
ss | double | Timeline Position of the Cover (second) *Optional Default: 0*

* HTTP Status: 202 means success
* Response Content-Type: `application/json`
* Response Body: 

```json
{
  "path": "<Resource Path of the Extracted Cover>"
}
```

#### Video Transcode

* URL: `http://<Server Hostname>:2981/hls_vod/api/transcode`
* Request Method: `POST`
* Request Content-Type: `application/x-www-form-urlencoded`
* Request Parameters: 

Name | Type | Description
---- | ---- | -----------
id | string | Video ID
profile | string | Profile Name
width/height | int | Width/Height of the Output Video (-1 means scaling in the aspect ratio) *Optional Default: -1*
logo_x/logo_y | int | Position of LOGO Watermark (0,0 means top left) *Optional Default: 0*
logo_w/logo_h | int | Width/Height of the LOGO Watermark (-1 means scaling in the aspect ratio) *Optional Default: -1*

* HTTP Status: 202 means success
* Response Content-Type: `application/json`
* Response Body: 

```json
{
  "path": "<Resource Path of the Transcoded Video>"
}
```

#### Query Videos

* URL: `http://<Server Hostname>:2981/hls_vod/api/videos`
* Request Method: `GET`
* URL Parameters: 

Name | Type | Description
---- | ---- | -----------
start/finish | double | Upload Time Range (Unix Timestamp) *Optional*
skip/limit | int | Parameters of Pagination *Optional*

* HTTP Status: 200 means success
* Response Content-Type: `application/json`
* Response Body: 

```json
{
  "videos": [
    {
      "id": "<Video ID>",
      "date": <Upload Time (Unix Timestamp)>,
      "duration": <Video Duration (second)>,
      "raw_width": <Width of Raw Video>,
      "raw_height": <Height of Raw Video>,
      "raw_rotation": <Rotation Angle of Raw Video (degree)>,
      "profiles": [
        "<Profile Name>",
        ...
      ]
    },
    ...
  ],
  "total": <Total Number of Videos>
}
```

#### Query Video Meta-Data

* URL: `http://<Server Hostname>:2981/hls_vod/api/video_meta`
* Request Method: `GET`
* URL Parameters: 

Name | Type | Description
---- | ---- | ----
id | string | Video ID

* HTTP Status: 200 means success
* Response Content-Type: `application/json`
* Response Body: 

```json
{
  "id": "<Video ID>",
  "date": <Upload Time (Unix Timestamp)>,
  "duration": <Video Duration (second)>,
  "raw_width": <Width of Raw Video>,
  "raw_height": <Height of Raw Video>,
  "raw_rotation": <Rotation Angle of Raw Video (degree)>,
  "profiles": [
    "<Profile Name>",
    ...
  ]
}
```

#### Remove Video

* URL: `http://<Server Hostname>:2981/hls_vod/api/remove_video`
* Request Method: `POST`
* Request Content-Type: `application/x-www-form-urlencoded`
* Request Parameters: 

Name | Type | Description
---- | ---- | -----------
id | string | Video ID

* HTTP Status: 204 means success

### Callbacks

**HLS vod** will call the callbacks set in *config.lua* when some specific events are completed, so that the upper business layer can respond to the changes in the video state. If the callback fails, the Web Server will repeat the callback every minute until it succeeds (up to 30 times).

#### *raw_meta* Callback

After the raw video is uploaded successfully, the *Web Server* will automatically request the *Transcoder* to parse the video. When the parsing is completed, this callback will be called to pass the meta-data of the video to the upper business layer. Then you can request extracting the video cover and transcoding the video in this callback.

* Request Method: `POST`
* Request Content-Type: `application/x-www-form-urlencoded`
* Request Parameters: 

*Parsing Succeeded*

Name | Type | Description
---- | ---- | -----------
id | string | Video ID
format | string | Format of Raw Video
duration | double | Video Duration (second)
bit_rate | int | Bitrate of Raw Video
width | int | Width of Raw Video
height | int | Height of Raw Video
rotation | int | Rotation Angle of Raw Video (degree)

*Parsing Failed*

Name | Type | Description
---- | ---- | -----------
id | string | Video ID
error | string | Error Description

* HTTP Status: 200/204 means success

#### *cover* Callback

This callback will be called after the video cover extracting is completed.

* Request Method: `POST`
* Request Content-Type: `application/x-www-form-urlencoded`
* Request Parameters: 

*Extracting Succeeded*

Name | Type | Description
---- | ---- | -----------
id | string | Video ID

*Extracting Failed*

Name | Type | Description
---- | ---- | -----------
id | string | Video ID
error | string | Error Description

* HTTP Status: 200/204 means success

#### *transcode* Callback

This callback will be called after the video transcoding is completed.

* Request Method: `POST`
* Request Content-Type: `application/x-www-form-urlencoded`
* Request Parameters: 

*Transcoding Succeeded*

Name | Type | Description
---- | ---- | -----------
id | string | Video ID
profile | string | Profile Name

*Transcoding Failed*

Name | Type | Description
---- | ---- | -----------
id | string | Video ID
profile | string | Profile Name
error | string | Error Description

* HTTP Status: 200/204 means success

## Transcoder

It provides the video parsing and transcoding services.

### Dependencies

* [Python3](https://www.python.org/)
  * [redis-py](https://github.com/andymccurdy/redis-py)
  * [m3u8](https://github.com/globocom/m3u8)
  * [requests](http://python-requests.org/)
  * [ffmpeg-python](https://github.com/kkroening/ffmpeg-python)

Install dependencies:
```bash
$ pip3 install -r requirements.txt
```

### Run

```bash
$ python3 transcoder.py --help
usage: transcoder.py [-h] [--work_dir WORK_DIR] [--workers WORKERS] [--api_entry API_ENTRY] [--logo LOGO]

Start the transcoder service.

optional arguments:
  -h, --help            show this help message and exit
  --work_dir WORK_DIR   set the work directory (default: /tmp)
  --workers WORKERS     set the number of worker processes (default: CPUs x2)
  --api_entry API_ENTRY
                        set the entry of platform APIs (default: http://127.0.0.1:2981)
  --logo LOGO           set the path of logo file
```
