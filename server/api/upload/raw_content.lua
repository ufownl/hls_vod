local ids = vod_core.recv_files("fs.raw")
local videos = {}
for i, v in ipairs(ids) do
  table.insert(videos, vod_core.add_video(v))
end
ngx.say(json.encode(videos))
