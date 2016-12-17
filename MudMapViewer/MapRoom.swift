//
//  MapRoom.swift
//  MudMapViewer
//
//  Created by Wil Hunt on 11/13/15.
//  Copyright © 2015 William Hunt. All rights reserved.
//

import Foundation
import AppKit

open class MapRoom : CustomStringConvertible, Hashable {
    var _db: MapDb
    let _id: Int64
    open fileprivate(set) var zoneId: Int64
    let _name: String
    let _idName: String
    let _labelDir: Int
    let _roomDescription: String
    let location: Coordinate3D<CGFloat>
    let _pathingCost: Float64
    let color: NSColor
    let _enabled: Bool

    var _exits = [MapExit]()
    
    init(db: MapDb, id:Int64, zoneId: Int64, name: String, roomDesc: String, location: Coordinate3D<Int64>, idName: String, labelDir: Int, pathingEntryCost: Float64, color: NSColor, enabled: Bool) {
        self._db = db
        self._id = id
        self.zoneId = zoneId
        self._name = name
        self._idName = idName
        self._labelDir = labelDir
        self._roomDescription = roomDesc
        self.location = Coordinate3D<CGFloat>(x: CGFloat(location.x), y: CGFloat(location.y), z: CGFloat(location.z))
        self._pathingCost = pathingEntryCost
        self.color = color
        self._enabled = enabled
    }
    
    open var description: String {
        return "<MapRoom id=\(self._id) zoneId=\(self.zoneId) name='\(self._name)' desc='\(self._roomDescription)' location=\(self.location) cost=\(self._pathingCost) color=\(self.color) enabled=\(self._enabled ? "true" : "false")/>"
    }
    
    open var hashValue: Int {
        return _id.hashValue
    }
    
    open var locationAsPoint: NSPoint {
        return NSPoint(x: CGFloat(location.x), y: CGFloat(location.y))
    }
    
    func addExit(_ exit: MapExit) {
        self._exits.append(exit)
    }
    
}

public func ==(lhs: MapRoom, rhs: MapRoom) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
