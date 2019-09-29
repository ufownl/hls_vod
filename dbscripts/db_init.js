db.createCollection("videos")
db.videos.createIndex({date: -1})

db.createCollection("segments")
db.segments.createIndex({video: 1, profile: 1}, {unique: true})
