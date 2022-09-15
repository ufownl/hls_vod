# HLS vod

**HLS vod**是一款提供视频上传、转码、储存、发布功能的服务端软件，可用作提供视频点播服务的网站及APP的视频源站。本软件由*web server*和*transcoder*两部分组成，*web server*用于提供视频访问及API服务，*transcoder*用于处理视频转码请求。

## 目录

* [web server](#web-server)
  * [依赖项](#依赖项)
  * [运行](#运行)
  * [访问视频](#访问视频)
  * [HTTP APIs](#http-apis)
    * [上传视频源文件](#上传视频源文件)
    * [下载视频源文件](#下载视频源文件)
    * [提取视频封面](#提取视频封面)
    * [视频转码](#视频转码)
    * [获取视频列表](#获取视频列表)
    * [查询指定视频元数据](#查询指定视频元数据)
    * [删除指定视频](#删除指定视频)
  * [回调事件](#回调事件)
    * [raw_meta事件](#raw_meta事件)
    * [cover事件](#cover事件)
    * [transcode事件](#transcode事件)
* [transcoder](#transcoder)
  * [依赖项](#依赖项-1)
  * [运行](#运行-1)

## web server

用于提供视频访问及API服务。

### 依赖项

* [OpenResty](https://openresty.org/)
  * [lua-resty-http](https://github.com/ledgetech/lua-resty-http)
  * [lua-resty-moongoo](https://github.com/isage/lua-resty-moongoo)
  * [lua-resty-redis-connector](https://github.com/ledgetech/lua-resty-redis-connector)

### 运行

启动*web server*前需先启动[MongoDB](https://www.mongodb.com/)及[Redis](https://redis.io/)，并修改*config.lua*文件中相应的配置项，使*web server*能够正确访问[MongoDB](https://www.mongodb.com/)及[Redis](https://redis.io/)服务。

```bash
$ ./resolvers.sh
$ openresty -p . -c hls_vod.conf
```

### 访问视频

* 视频封面：`http[s]://<服务器地址>/hls_vod/media/<视频ID>.jpg`
* HLS播放列表：`http[s]://<服务器地址>/hls_vod/media/<视频ID>_<转码规格名称>.m3u8`

### HTTP APIs

#### 上传视频源文件

* URL：`http://<服务器地址>:2980/hls_vod/api/upload/raw`
* 请求方式：`POST`
* 请求类型：`multipart/form-data`
* 返回值：调用成功返回HTTP状态码200
* 返回类型：`application/json`
* 返回内容：

```json
[
  {
    "id": "<视频ID>",
    "filename": "<原始视频文件名>"
  },
  ...
]
```

#### 下载视频源文件

* URL：`http://<服务器地址>:2980/hls_vod/api/download/raw`
* 请求方式：`GET`
* URL参数：

名称 | 类型 | 说明
---- | ---- | ----
id | string | 视频ID

* 返回值：调用成功返回HTTP状态码200
* 返回类型：`application/octet-stream`
* 返回内容：文件二进制流

#### 提取视频封面

* URL：`http://<服务器地址>:2980/hls_vod/api/extract_cover`
* 请求方式：`POST`
* 请求类型：`application/x-www-form-urlencoded`
* 请求参数：

名称 | 类型 | 说明
---- | ---- | ----
id | string | 视频ID
ss | double | 封面截取时间(秒) *可选参数 默认值：0*

* 返回值：调用成功返回HTTP状态码204

#### 视频转码

* URL：`http://<服务器地址>:2980/hls_vod/api/transcode`
* 请求方式：`POST`
* 请求类型：`application/x-www-form-urlencoded`
* 请求参数：

名称 | 类型 | 说明
---- | ---- | ----
id | string | 视频ID
profile | string | 转码规格名称
width/height | int | 输出视频宽度/高度(-1表示按比例缩放) *可选参数 默认值: -1*
logo_x/logo_y | int | LOGO水印位置(0,0表示左上角) *可选参数 默认值: 0*
logo_w/logo_h | int | LOGO水印宽度/高度(-1表示按比例缩放) *可选参数 默认值: -1*

* 返回值：调用成功返回HTTP状态码204

#### 查询视频列表

* URL：`http://<服务器地址>:2980/hls_vod/api/videos`
* 请求方式：`GET`
* URL参数：

名称 | 类型 | 说明
---- | ---- | ----
start/finish | double | 上传时间范围(unix时间戳) *可选参数*
skip/limit | int | 分页参数 *可选参数*

* 返回值：调用成功返回HTTP状态码200
* 返回类型：`application/json`
* 返回内容：

```json
{
  "videos": [
    {
      "id": "<视频ID>",
      "date": <视频上传时间(unix时间戳)>,
      "duration": <视频时长(秒)>,
      "raw_width": <原始视频宽度>,
      "raw_height": <原始视频高度>,
      "profiles": [
        "<转码规格名称>",
        ...
      ]
    },
    ...
  ],
  "total": <视频总数量>
}
```

#### 查询指定视频元数据

* URL：`http://<服务器地址>:2980/hls_vod/api/video_meta`
* 请求方式：`GET`
* URL参数：

名称 | 类型 | 说明
---- | ---- | ----
id | string | 视频ID

* 返回值：调用成功返回HTTP状态码200
* 返回类型：`application/json`
* 返回内容：

```json
{
  "id": "<视频ID>",
  "date": <视频上传时间(unix时间戳)>,
  "duration": <视频时长(秒)>,
  "raw_width": <原始视频宽度>,
  "raw_height": <原始视频高度>,
  "profiles": [
    "<转码规格名称>",
    ...
  ]
}
```

#### 删除指定视频

* URL：`http://<服务器地址>:2980/hls_vod/api/remove_video`
* 请求方式：`POST`
* 请求类型：`application/x-www-form-urlencoded`
* 请求参数：

名称 | 类型 | 说明
---- | ---- | ----
id | string | 视频ID

* 返回值：调用成功返回HTTP状态码200

### 回调事件

**HLS vod**会在一些特定事件完成时调用*config.lua*中设置的回调接口，以方便业务层对视频状态的改变做出响应。若回调失败，*web server*会以1分钟为间隔重复回调，直到回调成功或总回调次数达到30次。

#### raw_meta事件

视频源文件上传成功后，*web server*会自动发起解析视频的请求，解析完成后会触发该回调事件返回源视频的元数据。业务层可在该回调事件接口中根据源视频的元数据发起截取视频封面和转码的请求。

* 请求方式：`POST`
* 请求类型：`application/x-www-form-urlencoded`
* 请求参数：

*解析成功*

名称 | 类型 | 说明
---- | ---- | ----
id | string | 视频ID
format | string | 源视频格式信息
duration | double | 视频时长(秒)
bit_rate | int | 源视频码率
width | int | 源视频宽度
height | int | 源视频高度

*解析失败*

名称 | 类型 | 说明
---- | ---- | ----
id | string | 视频ID
error | string | 错误信息

* 返回值：返回HTTP状态码200表示回调成功

#### cover事件

视频封面截取完成后触发该回调事件。

* 请求方式：`POST`
* 请求类型：`application/x-www-form-urlencoded`
* 请求参数：

*截取成功*

名称 | 类型 | 说明
---- | ---- | ----
id | string | 视频ID

*截取失败*

名称 | 类型 | 说明
---- | ---- | ----
id | string | 视频ID
error | string | 错误信息

* 返回值：返回HTTP状态码200表示回调成功

#### transcode事件

视频转码完成后触发该回调事件。

* 请求方式：`POST`
* 请求类型：`application/x-www-form-urlencoded`
* 请求参数：

*转码成功*

名称 | 类型 | 说明
---- | ---- | ----
id | string | 视频ID
profile | string | 转码规格名称

*转码失败*

名称 | 类型 | 说明
---- | ---- | ----
id | string | 视频ID
profile | string | 转码规格名称
error | string | 错误信息

* 返回值：返回HTTP状态码200表示回调成功

## transcoder

用于处理视频转码请求。

### 依赖项

* [Python3](https://www.python.org/)
  * [redis-py](https://github.com/andymccurdy/redis-py)
  * [m3u8](https://github.com/globocom/m3u8)
  * [requests](http://python-requests.org/)
  * [ffmpeg-python](https://github.com/kkroening/ffmpeg-python)

安装依赖项：
```bash
$ sudo -H pip3 install redis m3u8 requests ffmpeg-python
```

### 运行

```bash
$ python3 transcoder.py --help
usage: transcoder.py [-h] [--work_dir WORK_DIR] [--workers WORKERS] [--api_entry API_ENTRY] [--logo LOGO]

Start the transcoder service.

optional arguments:
  -h, --help            show this help message and exit
  --work_dir WORK_DIR   set the work directory (default: /tmp)
  --workers WORKERS     set the number of worker processes (default: CPUs x2)
  --api_entry API_ENTRY
                        set the entry of platform APIs (default: http://127.0.0.1:2980)
  --logo LOGO           set the path of logo file
```

命令行参数：

参数 | 说明
---- | ----
--work_dir | 设置工作目录 *默认值: /tmp*
--workers | 设置工作进程数量 *默认值: CPU数x2*
--api_entry | 设置API入口URI *默认值: http://127.0.0.1:2980*
--logo | 设置LOGO文件路径
