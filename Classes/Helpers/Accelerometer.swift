//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  Accelerometer.swift
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

import CoreMotion

let FREQUENCY = 100

@objcMembers
class Accelerometer: NSObject {
    private var current_z: Float = 0.0
    private var manager: CMMotionManager?

    func start() {
        manager = CMMotionManager()
        if manager?.isAccelerometerActive ?? false && manager?.isAccelerometerActive == nil {
            manager?.accelerometerUpdateInterval = 1.0 / Double(FREQUENCY)
            let acclerometerQueue = OperationQueue()
            manager?.startAccelerometerUpdates(to: acclerometerQueue, withHandler: { accelerometerData, error in
                if let doubleData = accelerometerData?.acceleration.z {
                    self.addData(Float(-doubleData))
                }
            })
        }
    }

    func stop() {
        manager?.stopAccelerometerUpdates()
    }

    func getCurrent() -> Float {
        return current_z
    }

    func addData(_ value: Float) {
        current_z = value
    }
}
