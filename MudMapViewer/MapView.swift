//
//  MapView.swift
//  MudMapViewer
//
//  Created by Wil Hunt on 11/22/15.
//  Copyright © 2015 William Hunt. All rights reserved.
//

import Foundation
import AppKit

open class MapView : NSView
{
    var _currentRoomId: Int64? = 4225
    
    var _currentRoom: MapRoom?
    var _centerLocation: Coordinate3D<CGFloat>?
    var _zLevel: CGFloat?
    
    var _rooms = [Int64: MapRoom]()
    
    var _zoom: CGFloat = 10
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)

        // TODO: Move this to AppDelegate or somewhere else more appropriate.
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(MapView.updateState), name: NSNotification.Name(rawValue: "MapViewUpdate"), object: nil)
        do {
            try asyncLoadMapElements()
        } catch {
            // Swallow it.
        }
    }

    // TODO: Move this to AppDelegate or somewhere else more appropriate.
    open func updateState(_ notification: Notification) {
        if let str = notification.object as? NSString {
            if (str == "reload") {
                do {
                    try asyncLoadMapElements()
                } catch {
                    // Swallow?
                }
            }
            else if let roomIdx = Int64(str as String) {
                if (_currentRoomId != roomIdx) {
                    _currentRoomId = roomIdx
                    if let newRoom = _rooms[roomIdx] {
                        _currentRoom = newRoom
                        _centerLocation = newRoom.location
                        setNeedsDisplay(bounds)
                    } else {
                        _currentRoomId = roomIdx
                        _centerLocation = nil
                        do {
                            try asyncLoadMapElements()
                        } catch {
                            // Swallow it.
                        }
                    }
                }
            }
        }
    }
    
    func asyncLoadMapElements() throws {
        let priority = DispatchQueue.GlobalQueuePriority.default
        DispatchQueue.global(priority: priority).async {
            do {
            let rooms = try self.loadMapElements()
            DispatchQueue.main.async {
                self._rooms = rooms
                self.setNeedsDisplay(self.bounds)
            }
            } catch {}
        }
    }
    
    func loadMapElements() throws -> [Int64: MapRoom] {
        var zoneRooms = [Int64: MapRoom]()
        do {
            let db = try MapDb()
            if let currentRoomId = _currentRoomId {
                _currentRoom = try db.getRoomById(currentRoomId)
                if let centerRoom = _currentRoom {
                    zoneRooms = try db.getRoomsByZoneId(centerRoom.zoneId)
                }
            }
        } catch {
            Swift.print("Error loading database.")
        }
        return zoneRooms
    }
    
    override open func mouseDown(with theEvent: NSEvent) {
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

        self.setNeedsDisplay(bounds)
    }
    
    func map2DCoordsFromWindowCoords(_ loc: NSPoint) -> NSPoint? {
        if let center = centerLocation {
            let map2DCoords = NSPoint(
                x: (loc.x - self.bounds.midX) * _zoom + CGFloat(center.x),
                y: -(loc.y - self.bounds.midY) * _zoom + CGFloat(center.y)
            )
            
            return map2DCoords
        }
        return nil
    }
    
    func windowCoordsFromMap2DCoords(_ loc: NSPoint) -> NSPoint? {
        if let center = centerLocation {
            let dx = (loc.x - CGFloat(center.x))
            let dy = -(loc.y - CGFloat(center.y))
            
            let x: CGFloat = self.bounds.midX + dx / _zoom
            let y: CGFloat = self.bounds.midY + dy / _zoom
            return NSPoint(x: x, y: y)
        }
        return nil
    }
    
    override open func draw(_ dirtyRect: NSRect) {
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
    
    func roomDrawLocation(_ room: MapRoom) -> NSPoint? {
        let windowCoords = windowCoordsFromMap2DCoords(room.locationAsPoint)
        return windowCoords
    }
    
    func drawRoom(_ room: MapRoom, rect: NSRect) {
        if let targetLoc = roomDrawLocation(room) {
            let adjustedLoc = NSMakeRect(targetLoc.x - _zoom/2, targetLoc.y - _zoom/2, _zoom, _zoom)
            let path = NSBezierPath(rect: adjustedLoc)
            room.color.setFill()
            path.fill()
            NSColor.black.setStroke();
            if let idName: String = room._idName {
                let maxWidth: CGFloat = 1000.0
                let adjZoom = 1.25 * _zoom
                let textRect: NSRect
                let paraStyle = NSMutableParagraphStyle()
                switch room._labelDir {
                case 1:
                    paraStyle.alignment = NSTextAlignment.center
                    textRect = NSMakeRect(adjustedLoc.origin.x - maxWidth / 2 + _zoom / 2,
                                          adjustedLoc.origin.y, maxWidth, 2 * adjZoom)
                case 2:
                    textRect = NSMakeRect(adjustedLoc.origin.x + adjZoom, adjustedLoc.origin.y, maxWidth, 2 * adjZoom)
                case 3:
                    textRect = NSMakeRect(adjustedLoc.origin.x + adjZoom, adjustedLoc.origin.y - adjZoom, maxWidth, 2 * adjZoom)
                case 4:
                    textRect = NSMakeRect(adjustedLoc.origin.x + adjZoom, adjustedLoc.origin.y - 2 * adjZoom, maxWidth, 2 * adjZoom)
                case 5:
                    paraStyle.alignment = NSTextAlignment.center
                    textRect = NSMakeRect(adjustedLoc.origin.x - maxWidth / 2 + _zoom / 2, adjustedLoc.origin.y - 2 * adjZoom, maxWidth, 2 * adjZoom)
                case 6:
                    paraStyle.alignment = NSTextAlignment.right
                    textRect = NSMakeRect(adjustedLoc.origin.x - maxWidth, adjustedLoc.origin.y - 2 * adjZoom, maxWidth, 2 * adjZoom)
                case 7:
                    paraStyle.alignment = NSTextAlignment.right
                    textRect = NSMakeRect(adjustedLoc.origin.x - maxWidth - adjZoom / 8, adjustedLoc.origin.y - adjZoom, maxWidth, 2 * adjZoom)
                case 8:
                    paraStyle.alignment = NSTextAlignment.right
                    textRect = NSMakeRect(adjustedLoc.origin.x - maxWidth - adjZoom / 8, adjustedLoc.origin.y, maxWidth, 2 * adjZoom)
                case 10:
                    paraStyle.alignment = NSTextAlignment.center
                    textRect = NSMakeRect(adjustedLoc.origin.x - maxWidth / 2 + _zoom / 2,
                                          adjustedLoc.origin.y - adjZoom, maxWidth, 2 * adjZoom)
                case 11:
                    paraStyle.alignment = NSTextAlignment.center
                    textRect = NSMakeRect(adjustedLoc.origin.x - maxWidth / 2 + _zoom / 2,
                                          adjustedLoc.origin.y - adjZoom, maxWidth, 2 * adjZoom)
                default:
                    return
                }
                let attributes = [NSParagraphStyleAttributeName: paraStyle]
                idName.draw(in: textRect, withAttributes: attributes);
            }
        }
    }
    
    func headingFromDirection(_ direction: Int) -> Double {
        let heading = M_PI_4 * Double(9 - direction) + M_PI_2
        return heading
    }
    
    func offsetLocation(_ location: NSPoint, direction dir: Int, distance dist: CGFloat) -> NSPoint {
        // East  : 3 -> 5 -> 6 -> 6 pi / 4 = 3 pi / 2 -> 4 pi / 2
        // North : 1 -> 7 -> 8 -> 8 pi / 4 = 2 pi     -> 5 pi / 2
        // West  : 7 -> 1 -> 2 -> 2 pi / 4 = pi / 2   -> pi
        // South : 5 -> 3 -> 4 -> 4 pi / 4 = pi       -> 3 pi / 2
        
        let heading = headingFromDirection(dir)
        var dx = CGFloat(cos(heading)) * dist
        var dy = 0.0 + CGFloat(sin(heading)) * dist
        if (dir % 2 == 0) {
            dx *= sqrt(2.0)
            dy *= sqrt(2.0)
        }
        let x = location.x + dx
        let y = location.y + dy
        
        return NSPoint(x: x, y: y)
    }
    
    func hypot(v: NSPoint) -> CGFloat {
        return sqrt(v.x*v.x + v.y*v.y)
    }
    
    func arrowCap(path: NSBezierPath, v1: NSPoint, v2: NSPoint) {
        let diff = NSPoint(x: (v2.x - v1.x) / 2, y: (v2.y - v1.y) / 2)
        let perp = NSPoint(x: -diff.y, y: diff.x)
        let hyp = hypot(v: perp)
        let unitPerp = NSPoint(x: _zoom * perp.x / hyp / 4, y: _zoom * perp.y / hyp / 4)
        let start = NSPoint(x: v1.x + diff.x + unitPerp.x, y: v1.y + diff.y + unitPerp.y)
        let finish = NSPoint(x: v1.x + diff.x - unitPerp.x, y: v1.y + diff.y - unitPerp.y)
        path.move(to: start)
        path.line(to: v2)
        path.line(to: finish)
    }
    
    func drawExit(_ exit: MapExit, rect: NSRect) {
        if (exit.direction < 9) {
            if let fromRoom = exit.fromRoom, let toRoom = exit.toRoom {
                if let fromLoc = roomDrawLocation(fromRoom) {
                    let path = NSBezierPath()
                    path.move(to: offsetLocation(fromLoc, direction: exit.direction, distance: _zoom / 2))
                    path.line(to: offsetLocation(fromLoc, direction: exit.direction, distance: _zoom))
                    if (toRoom.zoneId == fromRoom.zoneId) {
                        if (exit.directionTo < 9) {
                            if let toLoc = roomDrawLocation(toRoom) {
                                if (NSPointInRect(fromLoc, bounds) || NSPointInRect(toLoc, bounds)) {
                                    let v1 = offsetLocation(toLoc, direction: exit.directionTo, distance: _zoom)
                                    path.line(to: v1)
                                    let v2 = offsetLocation(toLoc, direction: exit.directionTo, distance: _zoom / 2)
                                    path.line(to: v2)
    //                                path.lineToPoint(toLoc)
                                    if (exit._oneWay) {
                                        arrowCap(path: path, v1: v1, v2: v2)
                                    }
                                }
                            } else {
                                Swift.print("Skipping \(exit) because fromLoc or toLoc was nil.")
                            }
                        }
                        if (fromRoom._id == _currentRoomId || toRoom._id == _currentRoomId) {
//                            path.lineWidth = 2;
                            NSColor.red.setStroke()
                        } else {
                            NSColor.black.setStroke()
                        }
                        path.stroke()
                    } else {
                        // Zone boundary. Draw a line to an imaginary square.
                        let mapCoords = NSPoint(x: fromRoom.location.x, y: fromRoom.location.y)
                        if let windowCoords = windowCoordsFromMap2DCoords(mapCoords) {
                            let targetLoc = offsetLocation(windowCoords, direction: exit.direction, distance: 2 * _zoom)
                            path.line(to: targetLoc)
                            if (fromRoom._id == _currentRoomId || toRoom._id == _currentRoomId) {
//                                path.lineWidth = 2;
                                NSColor.red.setStroke()
                            } else {
                                NSColor.black.setStroke()
                            }
                            path.stroke();
                            let zoneDot = NSBezierPath(ovalIn: NSMakeRect(targetLoc.x - _zoom/3, targetLoc.y - _zoom/3, 2*_zoom/3, 2*_zoom/3))
                            NSColor.gray.setFill()
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
                        let path = NSBezierPath(ovalIn: NSMakeRect(fromLoc.x + 2*_zoom / 3, fromLoc.y + yFac * 2 * _zoom / 3, _zoom / 4, _zoom / 4))
                        if (fromRoom._id == _currentRoomId) {
                            NSColor.red.setFill()
                        } else {
                            NSColor.black.setFill()
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
                let path = NSBezierPath(ovalIn: NSMakeRect(targetLoc.x - _zoom/4, targetLoc.y - _zoom/4, _zoom / 2, _zoom / 2))
                NSColor.red.setFill()
                path.fill()
            }
        }
    }
}
