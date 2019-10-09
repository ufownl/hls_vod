local files = vod_core.recv_files("fs.raw")
local videos = {}
for i, v in ipairs(files) do
  table.insert(videos, {
    id = vod_core.add_video(v.id),
    filename = v.filename
  })
end
ngx.say(json.encode(videos))
