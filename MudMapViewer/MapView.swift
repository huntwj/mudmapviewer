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
    var _centerLocation: Coordinate3D<Int64>?
    var _zLevel: Int64?
    
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
    
    func headingFromDirection(direction: Int) -> Double {
	let heading = M_PI_4 * Double(9 - direction) + M_PI_2
	return heading
    }

    func offsetLocation(location: Coordinate3D<Int64>, direction dir: Int, distance dist: Double) -> NSPoint {
	// East  : 3 -> 5 -> 6 -> 6 pi / 4 = 3 pi / 2 -> 4 pi / 2
	// North : 1 -> 7 -> 8 -> 8 pi / 4 = 2 pi     -> 5 pi / 2
	// West  : 7 -> 1 -> 2 -> 2 pi / 4 = pi / 2   -> pi
	// South : 5 -> 3 -> 4 -> 4 pi / 4 = pi       -> 3 pi / 2
	let heading = headingFromDirection(dir)
	let x = Double(location.x) + cos(heading) * dist
	let y = Double(location.y) - sin(heading) * dist

	return NSPoint(x: x, y: y)
    }

    func drawExit(exit: MapExit, rect: NSRect) {
        if (exit.direction < 9) {
            if let fromRoom = exit.fromRoom, toRoom = exit.toRoom {
		if let fromLoc = roomDrawLocation(fromRoom) {
                if (toRoom.zoneId == fromRoom.zoneId) {
			if let toLoc = roomDrawLocation(toRoom) {
                        if (NSPointInRect(fromLoc, bounds) || NSPointInRect(toLoc, bounds)) {
                            let path = NSBezierPath()
                            path.moveToPoint(fromLoc)
                            path.lineToPoint(toLoc)
                            NSColor.blackColor().setStroke()
                            path.stroke()
                        }
                    } else {
                        Swift.print("Skipping \(exit) because fromLoc or toLoc was nil.")
                    }
		    } else {
			// Zone boundary. Draw a line to an imaginary square.
			let path = NSBezierPath()
			path.moveToPoint(fromLoc)
			let mapCoords = offsetLocation(fromRoom.location, direction: exit.direction, distance: 240)
			if let targetLoc = windowCoordsFromMap2DCoords(mapCoords) {
			    path.lineToPoint(targetLoc)
			    NSColor.blackColor().setStroke()
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