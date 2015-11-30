//
//  MapView.swift
//  MudMapViewer
//
//  Created by Wil Hunt on 11/22/15.
//  Copyright © 2015 William Hunt. All rights reserved.
//

import Foundation
import AppKit

public class MapView : NSView
{
    var _currentRoomId: Int64? = 1174
    
    var _currentRoom: MapRoom?
    var _centerLocation: Coordinate3D<CGFloat>?
    var _zLevel: CGFloat?
    
    var _rooms = [Int64: MapRoom]()
    
    var _zoom: CGFloat = 10
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)

        // TODO: Move this to AppDelegate or somewhere else more appropriate.
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "updateState:", name: "MapViewUpdate", object: nil)
        asyncLoadMapElements()
    }

    // TODO: Move this to AppDelegate or somewhere else more appropriate.
    public func updateState(notification: NSNotification) {
        if let str = notification.object as? NSString {
            if let roomIdx = Int64(str as String) {
                if (_currentRoomId != roomIdx) {
                    _currentRoomId = roomIdx
                    if let newRoom = _rooms[roomIdx] {
                        _currentRoom = newRoom
                        _centerLocation = newRoom.location
                        setNeedsDisplayInRect(bounds)
                    } else {
                        _currentRoomId = roomIdx
                        _centerLocation = nil
                        asyncLoadMapElements()
                    }
                }
            }
        }
    }
    
    func asyncLoadMapElements() {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            let rooms = self.loadMapElements()
            dispatch_async(dispatch_get_main_queue()) {
                self._rooms = rooms
                self.setNeedsDisplayInRect(self.bounds)
            }
        }
    }
    
    func loadMapElements() -> [Int64: MapRoom] {
        var zoneRooms = [Int64: MapRoom]()
        do {
            let db = try MapDb()
            if let currentRoomId = _currentRoomId {
                _currentRoom = db.getRoomById(currentRoomId)
                if let centerRoom = _currentRoom {
                    zoneRooms = db.getRoomsByZoneId(centerRoom.zoneId)
                }
            }
        } catch {
            Swift.print("Error loading database.")
        }
        return zoneRooms
    }
    
    override public func mouseDown(theEvent: NSEvent) {
        let z: CGFloat
        if let center = centerLocation {
            z = center.z
        } else {
            z = 0
        }
        if let newLoc = map2DCoordsFromWindowCoords(theEvent.locationInWindow) {
            _centerLocation = Coordinate3D<CGFloat>(x: newLoc.x, y: newLoc.y, z: z)
            _currentRoom = nil
        }

        self.setNeedsDisplayInRect(bounds)
    }
    
    func map2DCoordsFromWindowCoords(loc: NSPoint) -> NSPoint? {
        if let center = centerLocation {
            let map2DCoords = NSPoint(
                x: (loc.x - self.bounds.midX) * _zoom + CGFloat(center.x),
                y: -(loc.y - self.bounds.midY) * _zoom + CGFloat(center.y)
            )
            
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
    
    override public func drawRect(dirtyRect: NSRect) {
        if let center = centerLocation {
            for (_, room) in _rooms {
                if (center.z == room.location.z) {
                    for exit in room._exits {
                        drawExit(exit, rect: dirtyRect)
                    }
                }
            }
            
            for (_, room) in _rooms {
                drawRoom(room, rect: dirtyRect)
            }
            
            markCurrentRoom()
        }
    }
    
    var centerLocation: Coordinate3D<CGFloat>? {
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
    
    func headingFromDirection(direction: Int) -> Double {
        let heading = M_PI_4 * Double(9 - direction) + M_PI_2
        return heading
    }
    
    func offsetLocation(location: NSPoint, direction dir: Int, distance dist: CGFloat) -> NSPoint {
        // East  : 3 -> 5 -> 6 -> 6 pi / 4 = 3 pi / 2 -> 4 pi / 2
        // North : 1 -> 7 -> 8 -> 8 pi / 4 = 2 pi     -> 5 pi / 2
        // West  : 7 -> 1 -> 2 -> 2 pi / 4 = pi / 2   -> pi
        // South : 5 -> 3 -> 4 -> 4 pi / 4 = pi       -> 3 pi / 2

        let heading = headingFromDirection(dir)
	Swift.print("Heading \(heading * 360.0 / 2 / M_PI)")
	let dx = CGFloat(cos(heading)) * dist
	let x = location.x + dx
	let dy = 0.0 + CGFloat(sin(heading)) * dist
	let y = location.y + dy
        
        return NSPoint(x: x, y: y)
    }
    
    func drawExit(exit: MapExit, rect: NSRect) {
        if (exit.direction < 9) {
            if let fromRoom = exit.fromRoom, toRoom = exit.toRoom {
                if let fromLoc = roomDrawLocation(fromRoom) {
		    let path = NSBezierPath()
		    path.moveToPoint(offsetLocation(fromLoc, direction: exit.direction, distance: _zoom / 2))
		    path.lineToPoint(offsetLocation(fromLoc, direction: exit.direction, distance: _zoom))
                    if (toRoom.zoneId == fromRoom.zoneId) {
			if (exit.directionTo < 9) {
                        if let toLoc = roomDrawLocation(toRoom) {
                            if (NSPointInRect(fromLoc, bounds) || NSPointInRect(toLoc, bounds)) {
				    path.lineToPoint(offsetLocation(toLoc, direction: exit.directionTo, distance: _zoom))
				    path.lineToPoint(offsetLocation(toLoc, direction: exit.directionTo, distance: _zoom / 2))
    //                                path.lineToPoint(toLoc)
				}
			    } else {
				Swift.print("Skipping \(exit) because fromLoc or toLoc was nil.")
			    }
			}
                                if (fromRoom._id == _currentRoomId || toRoom._id == _currentRoomId) {
                                    path.lineWidth = 2;
                                    NSColor.redColor().setStroke()
                                } else {
                                    NSColor.blackColor().setStroke()
                                }
                                path.stroke()
                    } else {
                        // Zone boundary. Draw a line to an imaginary square.
			let mapCoords = NSPoint(x: fromRoom.location.x, y: fromRoom.location.y)
			if let windowCoords = windowCoordsFromMap2DCoords(mapCoords) {
			    let targetLoc = offsetLocation(windowCoords, direction: exit.direction, distance: 2 * _zoom)
                            path.lineToPoint(targetLoc)
                            if (fromRoom._id == _currentRoomId || toRoom._id == _currentRoomId) {
                                path.lineWidth = 2;
                                NSColor.redColor().setStroke()
                            } else {
                                NSColor.blackColor().setStroke()
                            }
                            path.stroke();
                            let zoneDot = NSBezierPath(ovalInRect: NSMakeRect(targetLoc.x - _zoom/3, targetLoc.y - _zoom/3, 2*_zoom/3, 2*_zoom/3))
                            NSColor.grayColor().setFill()
                            zoneDot.fill()
                        }
                    }
                }
            } else {
                Swift.print("Skipping \(exit) because either fromRoom or toRoom is nil.")
            }
        } else {
            // Up or down
            if let fromRoom = exit.fromRoom {
                if let fromLoc = roomDrawLocation(fromRoom) {
                    if NSPointInRect(fromLoc, bounds) {
                        let yFac: CGFloat = (exit.direction == 9) ? 1 : -1
                        let path = NSBezierPath(ovalInRect: NSMakeRect(fromLoc.x + 2*_zoom / 3, fromLoc.y + yFac * 2 * _zoom / 3, _zoom / 4, _zoom / 4))
                        if (fromRoom._id == _currentRoomId) {
                            NSColor.redColor().setFill()
                        } else {
                            NSColor.blackColor().setFill()
                        }
                        path.fill()
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