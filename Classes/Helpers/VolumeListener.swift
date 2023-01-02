//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  VolumeListener.swift
//  Aroundly
//
//  Created by Riccardo Raneri on 22/10/12.
//
//

import AudioToolbox
import AVFoundation
import Foundation
import MediaPlayer

@objcMembers
class VolumeListener: NSObject {
    func dummyVolume() -> UIView? {
        // tell the system that "this window has an volume view inside it, so there is no need to show a system overlay"
        let vv = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 100, height: 100))
        vv.tag = 54870149
        return vv
    }

    var systemVolume: CGFloat = 0.0
    var runningVolumeNotification = false

    override init() {
        super.init()
        runningVolumeNotification = false

        // these 4 lines of code tell the system that "this app needs to play sound/music"
        systemVolume = CGFloat(AVAudioSession.sharedInstance().outputVolume)

        let myExamplePath = Bundle.main.path(forResource: "silence", ofType: "mp3")
        var p: AVAudioPlayer? = nil
        do {
            p = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: myExamplePath ?? ""))
        } catch {
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
        } catch {
        }
        p?.prepareToPlay()
        p?.stop()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
    }
}
