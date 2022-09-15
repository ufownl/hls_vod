/*
 *  HLS vod, video-on-demand server using HLS protocol.
 *  Copyright (C) 2022  RangerUFO
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

sh.shardCollection(db + ".segments", {video: 1, profile: 1}, true)

sh.shardCollection(db + ".fs.raw.files", {_id: 1})
sh.shardCollection(db + ".fs.raw.chunks", {files_id: 1, n: 1}, true)

sh.shardCollection(db + ".fs.cover.files", {_id: 1})
sh.shardCollection(db + ".fs.cover.chunks", {files_id: 1, n: 1}, true)

sh.shardCollection(db + ".fs.segment.files", {_id: 1})
sh.shardCollection(db + ".fs.segment.chunks", {files_id: 1, n: 1}, true)
