//
//  MudMapViewerTests.swift
//  MudMapViewerTests
//
//  Created by Wil Hunt on 11/13/15.
//  Copyright © 2015 William Hunt. All rights reserved.
//

import XCTest
@testable import MudMapViewer

class MudMapViewerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetRoomById() {
        do {
            let db = try MapDb()
            if let room = db.getRoomById(38800) {
                print("room:")
                print(room)
            }
        } catch {
            print(error)
            XCTFail("No exceptions should be thrown.")
        }
    }

    func testGetZoneRoomsByRoomId() {
        do {
            let db = try MapDb()
            if let room = db.getRoomById(38800) {
                let zoneId = room.zoneId
                
                let zoneRooms = db.getRoomsByZoneId(zoneId);
                
                print("zoneRooms")
                print(zoneRooms.count)
                print(zoneRooms)
            } else {
                XCTFail("Could not find test room")
            }
        } catch {
            print(error)
            XCTFail("No exceptions should be thrown.")
        }
    }

    //    func testPerformanceExample() {
        // This is an example of a performance test case.
//        self.measureBlock {
            // Put the code you want to measure the time of here.
//        }
//    }
    
}
