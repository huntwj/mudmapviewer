//
//  main.swift
//  SendMapEvent
//
//  Created by Wil Hunt on 12/3/15.
//  Copyright © 2015 William Hunt. All rights reserved.
//

import Foundation

func moveToRoom(targetRoom: String) {
    let notificationCenter = NSDistributedNotificationCenter.defaultCenter()
    notificationCenter.postNotificationName("MapViewUpdate", object: targetRoom, userInfo: nil, deliverImmediately: true)
}

if Process.arguments.count > 1 {
    let targetRoom = Process.arguments[1]
    moveToRoom(targetRoom)
} else {
    print("No target room specified.")
}
