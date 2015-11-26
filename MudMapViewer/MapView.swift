//
//  MapView.swift
//  MudMapViewer
//
//  Created by Wil Hunt on 11/22/15.
//  Copyright © 2015 William Hunt. All rights reserved.
//

import Foundation
import AppKit

class MapView : NSView
{
    let _currentRoomId: Int64 = 1170
    
    var _currentRoom: MapRoom?
    var _centerLocation: Coordinate3D<Int64>?
    var _zLevel: Int64?
    
    var _rooms: [MapRoom] = []
    
    var _zoom: CGFloat = 10
    
    override func mouseDown(theEvent: NSEvent) {
        Swift.print(theEvent)
        let z: Int64
        if let center = centerLocation {
            z = center.z
        } else {
            z = 0
        }
        if let newLoc = map2DCoordsFromWindowCoords(theEvent.locationInWindow) {
            _centerLocation = Coordinate3D<Int64>(x: Int64(newLoc.x), y: Int64(newLoc.y), z: z)
            _currentRoom = nil
        }
        Swift.print("Center location: \(_centerLocation)")
        Swift.print("Current room: \(_currentRoom)")
        self.setNeedsDisplayInRect(bounds)
        
    }
    
    func map2DCoordsFromWindowCoords(loc: NSPoint) -> NSPoint? {
        if let center = centerLocation {
            let x = (loc.x - self.bounds.midX) * _zoom + CGFloat(center.x)
            let y = -(loc.y - self.bounds.midY) * _zoom + CGFloat(center.y)
            let map2DCoords = NSPoint(x: x, y: y)
            
            Swift.print("Window coords \(loc) -> Map 2D Coords \(map2DCoords) -> windowCoords \(windowCoordsFromMap2DCoords(map2DCoords))")
            return map2DCoords
        }
        return nil
    }
    
    func windowCoordsFromMap2DCoords(loc: NSPoint) -> NSPoint? {
        if let center = centerLocation {
            let dx = (loc.x - CGFloat(center.x))
            let dy = -(loc.y - CGFloat(center.y))
            
            let x: CGFloat = self.bounds.midX + dx / _zoom
            let y: CGFloat = self.bounds.midY + dy / _zoom
            return NSPoint(x: x, y: y)
        }
        return nil
    }
    
    override func drawRect(dirtyRect: NSRect) {
        let start = NSDate.timeIntervalSinceReferenceDate()
        do {
            let db = try MapDb()
            _currentRoom = db.getRoomById(_currentRoomId)
            if let centerRoom = _currentRoom {
                if let point1 = map2DCoordsFromWindowCoords(NSPoint(x:bounds.minX, y:bounds.minY)) {
                    Swift.print("point1: \(point1)")
                    if let point2 = map2DCoordsFromWindowCoords(NSPoint(x:bounds.maxX, y:bounds.maxY)) {
                        Swift.print("point2: \(point2)")
                        _rooms = db.getRoomsInRectByZoneId(centerRoom.zoneId, x1: Int64(point1.x), y1: Int64(point1.y),x2: Int64(point2.x), y2: Int64(point2.y))
                        for room in _rooms {
                            if (centerRoom.location.z == room.location.z) {
                                for exit in room.exits {
                                    drawExit(exit, rect: dirtyRect)
                                }
                            }
                        }
                        
                        for room in _rooms {
                            drawRoom(room, rect: dirtyRect)
                        }
                        
                        markCurrentRoom()
                    }
                }
            }
        } catch {
            Swift.print("Error loading database.")
        }
        let stop = NSDate.timeIntervalSinceReferenceDate()
        let duration = stop - start
        Swift.print("\(duration) secs")
    }
    
    var centerLocation: Coordinate3D<Int64>? {
        if (_centerLocation == nil) {
            if let currentRoom = _currentRoom {
                _centerLocation = currentRoom.location
            }
        }
        return _centerLocation
    }
    
    func roomDrawLocation(room: MapRoom) -> NSPoint? {
        let windowCoords = windowCoordsFromMap2DCoords(room.locationAsPoint)
        return windowCoords
    }
    
    func drawRoom(room: MapRoom, rect: NSRect) {
        if let targetLoc = roomDrawLocation(room) {
            let path = NSBezierPath(rect: NSMakeRect(targetLoc.x - _zoom/2, targetLoc.y - _zoom/2, _zoom, _zoom))
            room.color.setFill()
            path.fill()
        }
    }
    
    func drawExit(exit: MapExit, rect: NSRect) {
        if (exit.direction < 9) {
            let dir = exit.direction
            if (dir != 1 && dir != 3 && dir != 5 && dir != 7) {
                Swift.print("Direction: \(exit.direction)")
            }
            if let fromRoom = exit.fromRoom {
                if let toRoom = exit.toRoom {
                    if (toRoom.zoneId == fromRoom.zoneId) {
                        if let fromLoc = roomDrawLocation(fromRoom) {
                            if let toLoc = roomDrawLocation(toRoom) {
                                if (fromLoc.x != toLoc.x && fromLoc.y != toLoc.y) {
//                                    Swift.print("id: \(exit._id)")
//                                    Swift.print("fromLoc: \(fromLoc)")
//                                    Swift.print("toLoc: \(toLoc)")
                                }
                                if (NSPointInRect(fromLoc, bounds) || NSPointInRect(toLoc, bounds)) {
                                    let path = NSBezierPath()
                                    path.moveToPoint(fromLoc)
                                    path.lineToPoint(toLoc)
                                    NSColor.blackColor().setStroke()
                                    path.stroke()
                                }
                            }
                        }
                    } else {
                        // TODO: Draw exit stub for placeholder.
                    }
                }
            }
        }
    }
    
    func markCurrentRoom() {
        if let centerRoom = _currentRoom {
            if let targetLoc = roomDrawLocation(centerRoom) {
                let path = NSBezierPath(ovalInRect: NSMakeRect(targetLoc.x - _zoom/4, targetLoc.y - _zoom/4, _zoom / 2, _zoom / 2))
                NSColor.redColor().setFill()
                path.fill()
            }
        }
    }
}