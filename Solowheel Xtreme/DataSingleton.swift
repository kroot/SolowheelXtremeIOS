//
//  DataSingleton.swift
//  Solowheel Xtreme
//
//  Created by kroot on 10/13/15.
//

import Foundation

public let DataSingleton = DataSingletonClass()

public class DataSingletonClass {
    private init() {
        connected = false
        speed = ""
        batteryText = ""
        battery = 0
    }
    
    public var connected: Bool
    public var speed: String
    public var batteryText: String
    public var battery: Int
}