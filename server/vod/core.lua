require("resty.core")

local _M = {}

local function number_arg(x)
  local y = tonumber(x)
  if not y or y ~= y then
    return 0
  end
  return y
end

local function is_oid(x)
  if x then
    local m, err = ngx.re.match(x, "^[0-9a-fA-F]{24}$", "o")
    if m then
      return true
    end
  end
  return false
end

local function database()
  if not ngx.ctx.database then
    local conn, err = mongo.new(mongo_uri)
    if not conn then
      ngx.log(ngx.ERR, "failed to new mongodb connection: ", err)
      ngx.exit(ngx.HTTP_BAD_GATEWAY)
    end
    ngx.ctx.database = conn:db(mongo_db)
  end
  return ngx.ctx.database
end

local function redisc()
  if not ngx.ctx.redisc then
    local redisc, err = redis.new({
      url = redis_uri
    })
    if not redisc then
      ngx.log(ngx.ERR, "redis error: ", err)
      ngx.exit(ngx.HTTP_BAD_GATEWAY)
    end
    local ok, err = redisc:connect()
    if not ok then
      ngx.log(ngx.ERR, "redis error: ", err)
      ngx.exit(ngx.HTTP_BAD_GATEWAY)
    end
    ngx.ctx.redisc = redisc
  end
  return ngx.ctx.redisc
end

function _M.create_file(filename, prefix)
  return database():gridfs(prefix):create(filename)
end

function _M.open_file(id, prefix)
  if not is_oid(id) then
    return nil
  end
  if prefix == "" then
    prefix = nil
  end
  local file, err = database():gridfs(prefix):open(bson.oid(id))
  if not file then
    ngx.log(ngx.ERR, "mongodb error: ", err)
  end
  return file
end

function _M.remove_file(id, prefix)
  if not is_oid(id) then
    return
  end
  if prefix == "" then
    prefix = nil
  end
  database():gridfs(prefix):remove(bson.oid(id))
end

function _M.recv_files(prefix, chunk_size)
  if not chunk_size then
    chunk_size = 4096
  end
  local form, err = upload:new(chunk_size)
  if not form then
    ngx.log(ngx.ERR, err)
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local ids = {}
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
        file:write(res)
      end
    elseif tp == "part_end" then
      if file then
        local id, err = file:close()
        if not id then
          ngx.log(ngx.ERR, "mongodb error: "..err)
          ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end
        file = nil
        table.insert(ids, tostring(id))
      end
    elseif tp == "eof" then
      break
    end
  end
  return ids
end

function _M.add_video(raw)
  local db = database()
  local ids, err = db:collection("videos"):insert({
    raw = raw,
    date = bson.date(ngx.now() * 1000)
  })
  if not ids then
    ngx.log(ngx.ERR, "mongodb error: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  local id = tostring(ids[1])
  -- TODO: 获取视频格式信息
  return id
end

function _M.open_raw(id)
  if not is_oid(id) then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local db = database()
  local qry, err = db:collection("videos"):find_one(bson.oid(id), {
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
  if not is_oid(id) or not raw_meta then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local meta = json.decode(raw_meta)
  if not meta or not meta.format or not tonumber(meta.duration) or
     not tonumber(meta.bit_rate) then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end
  local db = database()
  local num, err = db:collection("videos"):update({
    _id = bson.oid(id),
    raw_meta = {
      ["$exists"] = false
    }
  }, {
    ["$set"] = {
      raw_meta = {
        format = meta.format,
        duration = tonumber(meta.duration),
        bit_rate = tonumber(meta.bit_rate)
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
end

return _M
