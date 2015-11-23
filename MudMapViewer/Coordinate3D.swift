//
//  Coordinate3D.swift
//  MudMapViewer
//
//  Created by Wil Hunt on 11/17/15.
//  Copyright © 2015 William Hunt. All rights reserved.
//

import Foundation

class Coordinate3D<T> : CustomStringConvertible {
    let x: T
    let y: T
    let z: T
    
    init(x: T, y: T, z: T) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    var description: String {
        return "(\(self.x), \(self.y), \(self.z))"
    }
}