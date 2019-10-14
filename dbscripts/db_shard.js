sh.shardCollection(db + ".segments", {video: 1, profile: 1}, true)

sh.shardCollection(db + ".fs.raw.files", {_id: 1})
sh.shardCollection(db + ".fs.raw.chunks", {files_id: 1, n: 1}, true)

sh.shardCollection(db + ".fs.cover.files", {_id: 1})
sh.shardCollection(db + ".fs.cover.chunks", {files_id: 1, n: 1}, true)

sh.shardCollection(db + ".fs.segment.files", {_id: 1})
sh.shardCollection(db + ".fs.segment.chunks", {files_id: 1, n: 1}, true)
