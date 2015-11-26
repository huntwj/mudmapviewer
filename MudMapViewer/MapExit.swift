//
//  MapExit.swift
//  MudMapViewer
//
//  Created by Wil Hunt on 11/22/15.
//  Copyright © 2015 William Hunt. All rights reserved.
//

import Foundation

class MapExit : CustomStringConvertible, Hashable
{
    let _db: MapDb
    let _id: Int64
    let _fromRoomId: Int64
    let _toRoomId: Int64
    let direction: Int
    
    var _fromRoom: MapRoom?
    var _toRoom: MapRoom?
    
    init(db: MapDb, id: Int64, fromRoomId: Int64, toRoomId: Int64, direction: Int) {
        _db = db
        _id = id
        _fromRoomId = fromRoomId
        _toRoomId = toRoomId
        self.direction = direction
    }
    
    var fromRoom: MapRoom? {
        if (_fromRoom == nil) {
            _fromRoom = _db.getRoomById(_fromRoomId)
        }
        return _fromRoom
    }
    
    var toRoom: MapRoom? {
        if (_toRoom == nil) {
            _toRoom = _db.getRoomById(_toRoomId)
        }
        return _toRoom
    }
    
    var hashValue: Int {
        return _id.hashValue;
    }
    
    var description: String {
        return "Exit (\(_id)) (\(direction)) from \(_fromRoomId) to \(_toRoomId)"
    }
}

func ==(lhs: MapExit, rhs: MapExit) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
