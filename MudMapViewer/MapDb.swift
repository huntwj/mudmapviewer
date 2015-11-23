//
//  MapDb.swift
//  MudMapViewer
//
//  Created by Wil Hunt on 11/13/15.
//  Copyright © 2015 William Hunt. All rights reserved.
//

import Foundation
import AppKit

import SQLite

class MapDb {
    var _db: Connection!
    
    init() throws {
        _db = try Connection("/Users/wilh/tf.old/wotmud/map/test.dbm")
    }
    
    func getRoomById(roomId : Int64) -> MapRoom? {
        let roomTable = Table("ObjectTbl")
        let objId = Expression<Int64>("ObjID")
        let zoneId = Expression<Int64>("ZoneID")
        let name = Expression<String>("Name")
        let desc = Expression<String>("Desc")
        let color = Expression<Int64>("Color")
        
        let x = Expression<Int64>("X")
        let y = Expression<Int64>("Y")
        let z = Expression<Int64>("Z")
        
        let query = roomTable.filter(objId == roomId)
        for room in _db.prepare(query) {
            return MapRoom(db: self, id: room[objId], zoneId: room[zoneId],name: room[name], roomDesc: room[desc], location: Coordinate3D<Int64>(x: room[x], y: room[y], z: room[z]), pathingEntryCost: 0.0, color: colorFromInt(room[color]), enabled: true)
        }
        
        return nil
    }
    
    func getRoomsByZoneId(targetZoneId : Int64) -> [MapRoom] {
        let roomTable = Table("ObjectTbl")
        let objId = Expression<Int64>("ObjID")
        let zoneId = Expression<Int64>("ZoneID")
        let name = Expression<String>("Name")
        let desc = Expression<String>("Desc")
        let color = Expression<Int64>("Color")
        let x = Expression<Int64>("X")
        let y = Expression<Int64>("Y")
        let z = Expression<Int64>("Z")
        
        let query = roomTable.filter(zoneId == targetZoneId)
        var rooms: [MapRoom] = []
        for room in _db.prepare(query) {
            rooms.append(MapRoom(db: self, id: room[objId], zoneId: room[zoneId],name: room[name], roomDesc: room[desc], location: Coordinate3D<Int64>(x: room[x], y: room[y], z: room[z]), pathingEntryCost: 0.0, color: colorFromInt(room[color]), enabled: true))
        }
        
        return rooms
    }
    
    func getExitsForRoomId(roomId: Int64) -> [MapExit] {
        let exitsTable = Table("ExitTbl")
        let exitIdCol = Expression<Int64>("ExitID")
        let fromIdCol = Expression<Int64>("FromID")
        let toIdCol = Expression<Int64>("ToID")
        let directionCol = Expression<Int>("DirType")
        
        let query = exitsTable.filter(fromIdCol == roomId)
        var exits: [MapExit] = []
        for exit in _db.prepare(query) {
            exits.append(MapExit(db: self, id: exit[exitIdCol], fromRoomId: exit[fromIdCol], toRoomId: exit[toIdCol], direction: exit[directionCol]+1))
        }
        return exits
    }
    
    func colorFromInt(colorInt: Int64) -> NSColor {
        let byteSize: Int64 = 256
        let redInt = colorInt % byteSize
        var left = (colorInt - redInt) / byteSize
        let greenInt = left % byteSize
        left = (left - greenInt) / byteSize
        let blueInt = left % byteSize
        
        return NSColor(red: (CGFloat(redInt) / 255.0), green: (CGFloat(greenInt) / 255.0), blue: (CGFloat(blueInt) / 255.0), alpha: 1.0)

    }
}
