//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  Umeng.swift
//  SuperVision
//
//  Created by Jingchao on 9/14/16.
//  Copyright © 2016 Zewen Li. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
@objcMembers
class Umeng: NSObject {
        
    class func event(_ eventName: String?, value: String?) {
        let GROUP_ID = AppDelegate.getGroupId()
        let STUDY_ID = AppDelegate.getStudyId()
        
        if GROUP_ID != nil && STUDY_ID != nil {
            var mutableDictionary: [AnyHashable : Any] = [:]
            mutableDictionary[STUDY_ID!] = Umeng.appendGroup(to: value)
            MobClick.event(eventName, attributes: mutableDictionary)
        } else {
            MobClick.event(eventName, label: value)
        }
    }

    class func event(_ eventName: String?, value: String?, durations millisecond: Int) {
        let GROUP_ID = AppDelegate.getGroupId()
        let STUDY_ID = AppDelegate.getStudyId()

        if GROUP_ID != nil && STUDY_ID != nil {
            var mutableDictionary: [AnyHashable : Any] = [:]
            mutableDictionary[STUDY_ID!] = Umeng.appendGroup(to: value)
            MobClick.event(eventName, attributes: mutableDictionary, durations: Int32(millisecond))
        } else {
            MobClick.event(eventName, label: value, durations: Int32(millisecond))
        }
    }

    class func event(_ eventName: String?, attributes: [AnyHashable : Any]?, counter number: Int) {
        MobClick.event(eventName, attributes: attributes, counter: Int32(number))
    }

    class func endEvent(_ eventName: String?, primarykey keyName: String?, value: String?) {
        let GROUP_ID = AppDelegate.getGroupId()
        let STUDY_ID = AppDelegate.getStudyId()

        if (GROUP_ID != nil) && (STUDY_ID != nil) {
            MobClick.endEvent(eventName, primarykey: keyName)
        } else {
            MobClick.endEvent(eventName, label: value)
        }
    }

    class func beginEvent(_ eventName: String?, primarykey keyName: String?, value: String?) {
        let GROUP_ID = AppDelegate.getGroupId()
        let STUDY_ID = AppDelegate.getStudyId()

        if (GROUP_ID != nil) && (STUDY_ID != nil) {
            var mutableDictionary: [AnyHashable : Any] = [:]
            mutableDictionary[STUDY_ID!] = Umeng.appendGroup(to: value)
            MobClick.beginEvent(eventName, primarykey: keyName, attributes: mutableDictionary)
        } else {
            MobClick.beginEvent(eventName, label: value)
        }
    }

    // Send label value with group id as prefix to Umeng, only used for volunteers
    // A helper function to append groupId
    class func appendGroup(to value: String?) -> String? {
        // Make all uppercase
        let GROUP_ID = AppDelegate.getGroupId()
        let groupId = GROUP_ID?.uppercased() ?? ""
        return "\(groupId) \("-") \(value ?? "")"
    }
}

