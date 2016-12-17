//
//  main.swift
//  SendMapEvent
//
//  Created by Wil Hunt on 12/3/15.
//  Copyright © 2015 William Hunt. All rights reserved.
//

import Foundation

func moveToRoom(_ targetRoom: String) {
    let notificationCenter = DistributedNotificationCenter.default()
    notificationCenter.postNotificationName(NSNotification.Name(rawValue: "MapViewUpdate"), object: targetRoom, userInfo: nil, deliverImmediately: true)
}

if CommandLine.arguments.count > 1 {
    let targetRoom = CommandLine.arguments[1]
    moveToRoom(targetRoom)
} else {
    print("No target room specified.")
}
