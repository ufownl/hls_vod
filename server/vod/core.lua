require("resty.core")

local _M = {}

local function number_arg(x)
  local y = tonumber(x)
  if not y or y ~= y then
    return 0
  end
  return y
end

local function database()
  if not ngx.ctx.database then
    local conn, err = mongo.new(config().mongo.uri)
    if not conn then
      ngx.log(ngx.ERR, "failed to new mongodb connection: ", err)
      ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end
    ngx.ctx.database = {
      conn = conn,
      db = conn:db(config().mongo.db)
    }
  end
  return ngx.ctx.database.db
end

local function redisc()
  if not ngx.ctx.redisc then
    local connector, err = redis.new({
      url = config().redis.uri
    })
    if not connector then
      ngx.log(ngx.ERR, "redis error: ", err)
      ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end
    local redisc, err = connector:connect()
    if not redisc then
      ngx.log(ngx.ERR, "redis error: ", err)
      ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end
    ngx.ctx.redisc = redisc
  end
  return ngx.ctx.redisc
end

local function generate_id()
  local generate_oid = require("resty.moongoo.utils").generate_oid
  local b64 = ngx.encode_base64(ngx.sha1_bin(tostring(generate_oid())), true)
  local id, n, err = ngx.re.gsub(b64, "[+/]", function(m)
    if m[0] == "+" then
      return "-"
    elseif m[0] == "/" then
      return "_"
    else
      return m[0]
    end
  end, "o")
  if not id then
    ngx.log(ngx.ERR, "regex error: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  return id
end

local function callback(url, body, count)
  if not count then
    count = 0
  end
  local httpc = http.new()
  local res, err = httpc:request_uri(url, {
    method = "POST",
    headers = {
      ["Content-Type"] = "application/x-www-form-urlencoded"
    },
    body = body
  })
  if res then
    if res.status == ngx.HTTP_OK then
      return
    end
  else
    ngx.log(ngx.ERR, "http error: ", err)
  end
  count = count + 1
  if count < 30 then
    ngx.timer.at(60, function(premature)
      if premature then
        return
      end
      callback(url, body, count)
    end)
  end
end

function _M.keepalive()
  if ngx.ctx.database then
    ngx.ctx.database.conn:close()
  end
  if ngx.ctx.redisc then
    ngx.ctx.redisc:set_keepalive()
  end
end

function _M.create_file(filename, prefix)
  return database():gridfs(prefix):create(filename, {
    _id = generate_id()
  }, false)
end

function _M.open_file(id, prefix)
  if not id then
    return nil
  end
  if prefix == "" then
    prefix = nil
  end
  local file, err = database():gridfs(prefix):open(id)
  if not file then
    ngx.log(ngx.ERR, "mongodb error: ", err)
  end
  return file
end

function _M.remove_file(id, prefix)
  if not id then
    return
  end
  if prefix == "" then
    prefix = nil
  end
  database():gridfs(prefix):remove(id)
end

function _M.recv_files(prefix, chunk_size, max_num)
  if not chunk_size then
    chunk_size = 4096
  end
  local form, err = upload:new(chunk_size)
  if not form then
    ngx.log(ngx.ERR, err)
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local files = {}
  local file
  while true do
    local tp, res, err = form:read()
    if not tp then
      ngx.log(ngx.ERR, err)
      ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    if tp == "header" then
      if res[1] == "Content-Disposition" then
        local filename = ngx.re.match(res[2], '.+filename="(.+)"', "o")
        if filename then
          file = _M.create_file(filename[1], prefix)
          if not file then
            ngx.log(ngx.ERR, "Could not create file: "..filename[1])
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
          end
        end
      end
    elseif tp == "body" then
      if file then
        local ok, err = file:write(res)
        if not ok then
          ngx.log(ngx.ERR, "mongodb error: "..err)
          ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end
      end
    elseif tp == "part_end" then
      if file then
        local id, err = file:close()
        if not id then
          ngx.log(ngx.ERR, "mongodb error: "..err)
          ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end
        table.insert(files, {
          id = id,
          filename = file:filename()
        })
        file = nil
        if tonumber(max_num) and #files >= tonumber(max_num) then
          break
        end
      end
    elseif tp == "eof" then
      break
    end
  end
  return files
end

function _M.add_video(raw)
  local db = database()
  local ids, err = db:collection("videos"):insert({
    _id = generate_id(),
    raw = raw,
    date = bson.date(ngx.now() * 1000)
  })
  if not ids then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  local id = ids[1]
  redisc():lpush("transcoding_tasks", json.encode({
    cmd = "probe",
    vid = id
  }))
  return id
end

function _M.open_raw(id)
  if not id then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local db = database()
  local qry, err = db:collection("videos"):find_one({
    _id = id
  }, {
    raw = 1
  })
  if not qry then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  if qry == bson.null() then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  local file = _M.open_file(qry.raw, "fs.raw")
  if not file then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  return file
end

function _M.set_raw_meta(id, raw_meta)
  if not id or not raw_meta then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local meta = json.decode(raw_meta)
  if not meta or not meta.format or not tonumber(meta.duration) or
     not tonumber(meta.bit_rate) or not tonumber(meta.width) or
     not tonumber(meta.height) then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local db = database()
  local num, err = db:collection("videos"):update({
    _id = id,
    raw_meta = {
      ["$exists"] = false
    }
  }, {
    ["$set"] = {
      raw_meta = {
        format = meta.format,
        duration = tonumber(meta.duration),
        bit_rate = tonumber(meta.bit_rate),
        width = tonumber(meta.width),
        height = tonumber(meta.height)
      }
    }
  })
  if not num then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  if num <= 0 then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  meta.id = id
  ngx.timer.at(0, function(premature, body)
    if premature then
      return
    end
    for i, v in ipairs(config().callbacks.raw_meta) do
      callback(v, body)
    end
  end, ngx.encode_args(meta))
end

function _M.probe_error(id, error)
  if not id or not error then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  ngx.timer.at(0, function(premature, body)
    if premature then
      return
    end
    for i, v in ipairs(config().callbacks.raw_meta) do
      callback(v, body)
    end
  end, ngx.encode_args({
    id = id,
    error = error
  }))
end

function _M.cover_task(id, ss)
  if not id then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local db = database()
  local num, err = db:collection("videos"):update({
    _id = id,
    cover = {
      ["$exists"] = false
    }
  }, {
    ["$set"] = {
      cover = ""
    }
  })
  if not num then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  if num <= 0 then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  redisc():lpush("transcoding_tasks", json.encode({
    cmd = "cover",
    vid = id,
    params = {
      ss = number_arg(ss)
    }
  }))
end

function _M.set_cover(id, cover)
  local db = database()
  local num, err = db:collection("videos"):update({
    _id = id,
    cover = ""
  }, {
    ["$set"] = {
      cover = cover
    }
  })
  if not num then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  if num <= 0 then
    _M.remove_file(cover, "fs.cover")
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  ngx.timer.at(0, function(premature, body)
    if premature then
      return
    end
    for i, v in ipairs(config().callbacks.cover) do
      callback(v, body)
    end
  end, ngx.encode_args({
    id = id
  }))
end

function _M.cover_error(id, error)
  if not id or not error then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local db = database()
  local num, err = db:collection("videos"):update({
    _id = id,
    cover = ""
  }, {
    ["$unset"] = {
      cover = 1
    }
  })
  if not num then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  if num <= 0 then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  ngx.timer.at(0, function(premature, body)
    if premature then
      return
    end
    for i, v in ipairs(config().callbacks.cover) do
      callback(v, body)
    end
  end, ngx.encode_args({
    id = id,
    error = error
  }))
end

function _M.transcode_task(id, profile, width, height, logo_x, logo_y, logo_w,
                           logo_h)
  if not id or not profile then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  if not tonumber(width) then
    width = -1
  end
  if not tonumber(height) then
    height = -1
  end
  if not tonumber(logo_x) then
    logo_x = 0
  end
  if not tonumber(logo_y) then
    logo_y = 0
  end
  if not tonumber(logo_w) then
    logo_w = -1
  end
  if not tonumber(logo_h) then
    logo_h = -1
  end
  local db = database()
  local qry, err = db:collection("videos"):find_one({
    _id = id
  }, {
    _id = 1
  })
  if not qry then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  if qry == bson.null() then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  local ids, err = db:collection("segments"):insert({
    video = id,
    profile = profile
  })
  if not ids then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  if err <= 0 then
    ngx.exit(ngx.HTTP_CONFLICT)
  end
  redisc():lpush("transcoding_tasks", json.encode({
    cmd = "transcode",
    vid = id,
    params = {
      profile = profile,
      width = tonumber(width),
      height = tonumber(height),
      logo_x = tonumber(logo_x),
      logo_y = tonumber(logo_y),
      logo_w = tonumber(logo_w),
      logo_h = tonumber(logo_h)
    }
  }))
end

function _M.set_segments(id, profile, files)
  local function cleanup()
    for i, v in ipairs(files) do
      _M.remove_file(v.id, "fs.segment")
    end
  end
  local segments = {}
  for i, v in ipairs(files) do
    local m =
      ngx.re.match(v.filename, "\\S+#([0-9]+)@([0-9]+(\\.[0-9]+)?)\\.ts", "o")
    if not m then
      cleanup()
      ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    table.insert(segments, {
      id = v.id,
      index = tonumber(m[1]),
      duration = tonumber(m[2])
    })
  end
  table.sort(segments, function(lhs, rhs)
    return lhs.index < rhs.index
  end)
  local db = database()
  local num, err = db:collection("segments"):update({
    video = id,
    profile = profile,
    segments = {
      ["$exists"] = false
    }
  }, {
    ["$set"] = {
      segments = segments
    }
  })
  if not num then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  if num <= 0 then
    cleanup()
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  ngx.timer.at(0, function(premature, body)
    if premature then
      return
    end
    for i, v in ipairs(config().callbacks.transcode) do
      callback(v, body)
    end
  end, ngx.encode_args({
    id = id,
    profile = profile
  }))
end

function _M.transcode_error(id, profile, error)
  if not id or not profile or not error then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local db = database()
  local num, err = db:collection("segments"):remove({
    video = id,
    profile = profile,
    segments = {
      ["$exists"] = false
    }
  })
  if not num then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  if num <= 0 then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  ngx.timer.at(0, function(premature, body)
    if premature then
      return
    end
    for i, v in ipairs(config().callbacks.transcode) do
      callback(v, body)
    end
  end, ngx.encode_args({
    id = id,
    profile = profile,
    error = error
  }))
end

function _M.get_playlist(id, profile)
  if not id or not profile then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local db = database()
  local qry, err = db:collection("segments"):find_one({
    video = id,
    profile = profile,
    segments = {
      ["$exists"] = true
    }
  }, {
    segments = 1
  })
  if not qry then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  if qry == bson.null() then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  local target_duration = 0
  for i, v in ipairs(qry.segments) do
    if v.duration > target_duration then
      target_duration = v.duration
    end
  end
  local lines = {
    "#EXTM3U",
    "#EXT-X-VERSION:3",
    "#EXT-X-TARGETDURATION:"..math.ceil(target_duration),
    "#EXT-X-MEDIA-SEQUENCE:0"
  }
  for i, v in ipairs(qry.segments) do
    table.insert(lines, "#EXTINF:"..v.duration..",")
    table.insert(lines, v.id..".ts")
  end
  table.insert(lines, "#EXT-X-ENDLIST")
  return table.concat(lines, "\n")
end

function _M.open_segment(id)
  local file = _M.open_file(id, "fs.segment")
  if not file then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  return file
end

function _M.open_cover(id)
  if not id then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local db = database()
  local qry, err = db:collection("videos"):find_one({
    _id = id
  }, {
    cover = 1
  })
  if not qry then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  if qry == bson.null() then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  local file = _M.open_file(qry.cover, "fs.cover")
  if not file then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  return file
end

function _M.get_video_meta(id)
  if not id then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local db = database()
  local video_qry, err = db:collection("videos"):find_one({
    _id = id
  }, {
    date = 1,
    raw_meta = 1
  })
  if not video_qry then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  if video_qry == bson.null() then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  local meta = {
    id = id,
    date = tonumber(tostring(video_qry.date)) / 1000,
    profiles = {}
  }
  if video_qry.raw_meta then
    meta.duration = video_qry.raw_meta.duration
    meta.raw_width = video_qry.raw_meta.width
    meta.raw_height = video_qry.raw_meta.height
  end
  local segment_qry = db:collection("segments"):find({
    video = id,
    segments = {
      ["$exists"] = true
    }
  }, {
    profile = 1
  })
  for i, v in ipairs(segment_qry:all()) do
    table.insert(meta.profiles, v.profile)
  end
  return meta
end

function _M.remove_video(id)
  if not id then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local db = database()
  db:collection("segments"):update({
    video = id,
    segments = {
      ["$exists"] = false
    }
  }, {
    ["$set"] = {
      segments = {}
    }
  }, {
    multi = true
  })
  local segment_qry = db:collection("segments"):find({
    video = id
  }, {
    segments = 1
  })
  for i, v in ipairs(segment_qry:all()) do
    for j, seg in ipairs(v.segments) do
      _M.remove_file(seg.id, "fs.segment")
    end
  end
  db:collection("segments"):remove({
    video = id
  })
  db:collection("videos"):update({
    _id = id,
    cover = ""
  }, {
    ["$set"] = {
      cover = "removing"
    }
  })
  local video_qry, err = db:collection("videos"):find_and_modify({
    _id = id
  }, {
    remove = true
  })
  if video_qry then
    if video_qry ~= bson.null() then
      _M.remove_file(video_qry.raw, "fs.raw")
      _M.remove_file(video_qry.cover, "fs.cover")
    end
  else
    ngx.log(ngx.ERR, "mongodb error: ", err)
  end
end

function _M.get_videos(start, finish, skip, limit)
  local filter = {}
  if tonumber(start) then
    if not filter.date then
      filter.date = {}
    end
    filter.date["$gte"] = bson.date(start * 1000)
  end
  if tonumber(finish) then
    if not filter.date then
      filter.date = {}
    end
    filter.date["$lt"] = bson.date(finish * 1000)
  end
  local db = database()
  local video_qry = db:collection("videos"):find(filter, {
    date = 1,
    raw_meta = 1
  }):sort({
    date = -1
  })
  local total = video_qry:count()
  if tonumber(skip) then
    video_qry:skip(tonumber(skip))
  end
  if tonumber(limit) then
    video_qry:limit(tonumber(limit))
  end
  local videos = {}
  for i, v in ipairs(video_qry:all()) do
    local id = tostring(v._id)
    local meta = {
      id = id,
      date = tonumber(tostring(v.date)) / 1000,
      profiles = {}
    }
    if v.raw_meta then
      meta.duration = v.raw_meta.duration
      meta.raw_width = v.raw_meta.width
      meta.raw_height = v.raw_meta.height
    end
    local segment_qry = db:collection("segments"):find({
      video = id,
      segments = {
        ["$exists"] = true
      }
    }, {
      profile = 1
    })
    for j, seg in ipairs(segment_qry:all()) do
      table.insert(meta.profiles, seg.profile)
    end
    table.insert(videos, meta)
  end
  return videos, total:number()
end

return _M
