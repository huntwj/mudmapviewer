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
    let _currentRoomId: Int64 = 19505
    
    var _currentRoom: MapRoom?
    var _centerLocation: NSPoint?
    var _zLevel: Int64?
    
    var _rooms: [MapRoom] = []
    
    var _zoom: CGFloat = 10
    
    override func mouseDown(theEvent: NSEvent) {
        Swift.print(theEvent)
//        _centerLocation = mapCoordFromWindowCoords(theEvent.loc)
    }
    
    func mapCoordFromWindowCoords(loc: NSPoint) {
        
    }
    
    override func drawRect(dirtyRect: NSRect) {
        do {
            let db = try MapDb()
            _currentRoom = db.getRoomById(_currentRoomId)
            if let centerRoom = _currentRoom {
                let midX = dirtyRect.midX
                let midY = dirtyRect.midY
                Swift.print("Center: (\(midX), \(midY))")
                _rooms = db.getRoomsByZoneId(centerRoom.zoneId)
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
        } catch {
            Swift.print("Error loading database.")
        }
    }
    
    var centerLocation: NSPoint? {
        if (_centerLocation == nil) {
            if let currentRoom = _currentRoom {
                _centerLocation = NSPoint(x: CGFloat(currentRoom.location.x), y: CGFloat(currentRoom.location.y))
            }
        }
        return _centerLocation
    }
    
    func roomDrawLocation(room: MapRoom) -> NSPoint? {
        if let centerRoom = _currentRoom {
            if (centerRoom.location.z == room.location.z) {
                let dx = CGFloat((room.location.x - centerRoom.location.x))
                let dy = -CGFloat((room.location.y - centerRoom.location.y))
                let x: CGFloat = self.bounds.midX + dx / _zoom
                let y: CGFloat = self.bounds.midY + dy / _zoom
                return NSPoint(x: x, y: y)
            }
        }
        return nil
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
                    if let fromLoc = roomDrawLocation(fromRoom) {
                        if let toLoc = roomDrawLocation(toRoom) {
                            if (fromLoc.x != toLoc.x && fromLoc.y != toLoc.y) {
                                Swift.print("id: \(exit._id)")
                                Swift.print("fromLoc: \(fromLoc)")
                                Swift.print("toLoc: \(toLoc)")
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