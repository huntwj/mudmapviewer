//
//  MapRoom.swift
//  MudMapViewer
//
//  Created by Wil Hunt on 11/13/15.
//  Copyright © 2015 William Hunt. All rights reserved.
//

import Foundation
import AppKit

public class MapRoom : CustomStringConvertible, Hashable {
    var _db: MapDb
    let _id: Int64
    public private(set) var zoneId: Int64
    let _name: String
    let _roomDescription: String
    let location: Coordinate3D<Int64>
    let _pathingCost: Float64
    let color: NSColor
    let _enabled: Bool
    
    var _exits: [MapExit]?
    
    init(db: MapDb, id:Int64, zoneId: Int64, name: String, roomDesc: String, location: Coordinate3D<Int64>, pathingEntryCost: Float64, color: NSColor, enabled: Bool) {
        self._db = db
        self._id = id
        self.zoneId = zoneId
        self._name = name
        self._roomDescription = roomDesc
        self.location = location
        self._pathingCost = pathingEntryCost
        self.color = color
        self._enabled = enabled
    }
    
    internal var exits: [MapExit] {
        if (_exits == nil) {
            _exits = _db.getExitsForRoomId(_id)
        }
        if let ex = _exits {
            return ex
        } else {
            return []
        }
    }
    
    public var description: String {
        return "<MapRoom id=\(self._id) zoneId=\(self.zoneId) name='\(self._name)' desc='\(self._roomDescription)' location=\(self.location) cost=\(self._pathingCost) color=\(self.color) enabled=\(self._enabled ? "true" : "false")/>"
    }
    
    public var hashValue: Int {
        return _id.hashValue
    }
    
    public var locationAsPoint: NSPoint {
        return NSPoint(x: CGFloat(location.x), y: CGFloat(location.y))
    }
    
    func addExit(exit: MapExit) {
        if var exits = _exits {
            exits.append(exit)
        } else {
            _exits = [exit]
        }
    }
    
}

public func ==(lhs: MapRoom, rhs: MapRoom) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
