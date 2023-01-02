//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  ViewController.swift
//  EyeSee
//
//  Created by Zewen Li on 7/4/13.
//  Copyright (c) 2013 Zewen Li. All rights reserved.
//

import AVFoundation
import CoreFoundation
import CoreGraphics
import CoreMedia
import CoreVideo
import UIKit
import CoreLocation
import MediaPlayer

//using namespace cv;
//a value for change Near Cam to far Cam
let A_near = 4.0
//a value for change Far Cam to Near Cam
let A_far = 2.0
//to make sure the curren camera is Near or Far
var isNear = true
//a value to make sure the object size is maintain same during the camera switch
var diff_scale:Float = 2.0
var near_FOV:Float = -1
var far_FOV:Float = -1
//True mean this device only have one camera
var is_Singal = false
//True mean this device is ipad
var is_Ipad = false
//True mean this device is IPhone pro
var is_Pro = false
//Near Camera
@available(iOS 13.0, *)
var nearCam: AVCaptureDevice.DeviceType = AVCaptureDevice.DeviceType.builtInUltraWideCamera
//Far Camera
@available(iOS 10.0, *)
var farCam: AVCaptureDevice.DeviceType = AVCaptureDevice.DeviceType.builtInWideAngleCamera

let INFOICONWIDTH = 35
let INFOBUTTONWIDTH = 35
let PLUSICONWIDTH = 30
let MINUSICONWIDTH = 30
let SLIDERWIDTH = 44
let SLIDERHEIGHT = 250
func degreeToRadians(_ x: Double) -> Double {
    Double.pi * x / 180.0
}
let OUTVBUTTONOFFSET = 30
let OUTHBUTTONOFFSET = 15
let BUTTONWIDTH = 55
let INBUTTONOFFSET = 10

let INFOBUTTONPORTRAITORIENTATIONY = 30
let INFOBUTTONLANDSCAPEORIENTATIONY = 20
let IADLANDSCAPEORIENTATIONY = UIScreen.main.bounds.size.width - CGFloat(IADLANDSCAPEHEIGHT)
let IADPORTRAITWIDTH = UIScreen.main.bounds.size.width
let IADLANDSCAPEWIDTH = UIScreen.main.bounds.size.height
let IADPORTRAITHEIGHT = 50
let IADLANDSCAPEHEIGHT = 32
let IPADIADPORTRAITHEIGHT = 66
let IPADIADLANDSCAPEHEIGHT = 66


let IS_IPHONE_4 = UIScreen.main.bounds.size.height == 480

// MARK: - resolution settings
let RESOLUTION_PHOTO = AVCaptureSession.Preset.photo
let RESOLUTION_MAX = AVCaptureSession.Preset.high
let RESOLUTION1 = AVCaptureSession.Preset.hd1920x1080
let RESOLUTION2 = AVCaptureSession.Preset.hd1280x720
let RESOLUTION3 = AVCaptureSession.Preset.iFrame960x540
let RESOLUTION4 = AVCaptureSession.Preset.vga640x480
let IP5RESOLUTION = RESOLUTION1
let IPADRESOLUTION = RESOLUTION1
let IP4RESOLUTION = RESOLUTION3
let IPMAXRESOLUTION = RESOLUTION_MAX


// ICON RESOURCES
let ADDPNG = "add.png"
let MINUSPNG = "minus.png"
let CANCELPNG = "cancel.png"
let FLASHONPNG = "flashon.png"
let FLASHOFFPNG = "flashoff.png"
let LOCKPNG = "lock.png"
let UNLOCKPNG = "unlock.png"
let ONESTABLEPNG = "onestable.png"
let TWOSTABLEPNG = "twostable.png"
let SLIDERTHUMB = "sliderthumb2.png"
let ROTATIONLOCKEDPNG = "rotation_locked.png"
let ROTATIONUNLOCKEDPNG = "rotation_unlocked.png"

// check focus change
let FRAMES = 50

// Get current orientation
let ORIENTATION = UIApplication.shared.statusBarOrientation

@available(iOS 10.0, *)
@objcMembers
class ViewController: UIViewController, UIAlertViewDelegate, UIGestureRecognizerDelegate {
    
    //xuan change show camera
    
    //  scrollview is the basis of the screen.
    @IBOutlet var scrollView: MyScrollView!
    //  image process logic class
    var imageProcess: ImageProcess?
    //  capture session is used to control frame flow from camerra
    var captureSession: AVCaptureSession?
    //  display current zoom rate on screen
    @IBOutlet var zoomRateLabel: UILabel?
    //  display current frame rate on screen.
    @IBOutlet var frameRateLabel: UILabel?
    //  display on screen to slide to change |currentZoomRate|
    @IBOutlet var zoomSlider: UISlider!
    //  Customize image button to show as increasing direction for zooming.
    @IBOutlet var sliderMaxButton: UIButton?
    //  Customize image button to show as decreasing direction for zooming.
    @IBOutlet var sliderMinButton: UIButton?
    //  Button used to change the stable direction.
    @IBOutlet var stableDirectionButton: UIButton!
    //  Flash on/off
    @IBOutlet var flashLightButton: UIButton!
    //  Lock screen on/off
    @IBOutlet var screenLockButton: UIButton!
    //  Save the locked screen to a picture
    @IBOutlet var saveButton: UIButton!
    //  Navigate to picture view
    @IBOutlet var photoButton: UIButton!
    @IBOutlet var flipButton: UIButton!
    //  Image Mode Button
    @IBOutlet var imageModeButton: UIButton!
    //  Fix Focus Button
    @IBOutlet var lockFocusButton: UIButton!
    //  Lock Portrait Button
    @IBOutlet var lockPortraitButton: UIButton!
    //  current zoomrate
    var currentZoomRate: Float = 0.0
    //  A help button for more information or settings
    @IBOutlet var infoButton: UIButton!
    //  to change it 1080p for ip4S
    var beforeLock = false
    //  lock state for application
    var isLocked = false
    //  stabilization state, if true then stabilization function is enabled
    var isStabilizationEnable = false
    //  state to indicate flash light on or off, true for on.
    var isFlashOn = false
    //  state indicate if stabilization for one direction or two. true for one
    var isHorizontalStable = false
    var isImageModeOn = false
    //  count the current frame number of image number, starts with 0
    var imageNo = 0
    //  accumulate the motion vector on x and y axis
    var motionX: Float = 0.0
    var motionY: Float = 0.0
    //  slider background
    @IBOutlet var sliderBackground: UIImageView!
    //  set up image orientation on screen.
    var imageOrientation = 0
    //  a state to indicate whether to hide all controls;
    var hideControls = false
    //  set Resolution according to different devices
    var currentResolution: String?
    //  feature detection window size
    var featureWindowWidth = 0
    var featureWindowHeight = 0
    //  correctify the scroll touch on screen
    var correctContentOffset = CGPoint.zero
    //  no function available for getting width and height from resolution settings.
    //  just memberize them.
    var resolutionWidth = 0
    var resolutionHeight = 0
    // an array to store variance for around successive 10 frames once lock button tapped
    var varQueue: [AnyHashable]?
    // store the highest variance's image
    var highVarImg: UIImage?
    var maxVariance = 0.0
    var maxVarImg: CGImage?
    var adjustingFocus = false
    var lockDelay = 0
    // volume control listener
    var volumeListener: VolumeListener?
    // check focus change
    var captureDevice: AVCaptureDevice?
    var counter = 0
    var lensPosition = 0
    var focusTimer: Date?
    // lock focus
    var lockLabel: String?
    @IBOutlet var message: UILabel!
    var helpViewController: HelpViewController?
    //@property (strong, nonatomic) ALAssetsLibrary *library;
    var fileNameNumber: UnsafeMutablePointer<Int>?
    // store photo data
    var photoData: [String]?
    
    //  used for time analysis.
    private var lastDate: Date?
    private var avgTimeForOneFrame: Float = 0.0
    private var avgTimeForAck: Float = 0.0
    private var avgTimeForConvert: Float = 0.0
    private var avgTimeForDetect: Float = 0.0
    private var avgTimeForTrack: Float = 0.0
    private var avgTimeForPostProcess: Float = 0.0
    private var avgFeaturePoints: Float = 0.0
    private var maxFrameRate: Float = 0.0
    private var minFrameRate: Float = 0.0
    @IBOutlet private var label: UILabel?
    private var lockTimer: Date?
    private var stableTimer: Date?
    // Accelerometer
    private var accelerometer: Accelerometer?
    // tap to focus
    private var isTapped = false
    private var isExposureAdjusted = false
    private var point = CGPoint.zero
    private var tapZoomRate: Float = 0.0
    private var tapLensPosition: Float = 0.0
    private var iso: Float = 0.0
    private var duration: CMTime!
    private var readyChangeBack = false
    private var lockInterfaceOrientation: UIInterfaceOrientation!
    private var startTimer: Date?
    // Lock Portrait mode boolean flag
    var portraitOnly: Bool = false
    var timer = Timer()
    var prevValOfCam = "default"
    var lensVals = [Float]()
    var cameraLayer : AVCaptureVideoPreviewLayer?
    var mirroredImageOrientation = 0
    var lockFocusButtonSelected = false
    var lockedCGImage: CGImage?
    var detectedObjects = [String]()
    var onlyOnce = Bool()
    var runCount = 0
    var imageCategories = [String]()
    var volumeView: MPVolumeView?
    var restoringVolume = false
    var systemVolume = Float()
    let locationManager = CLLocationManager()
    var networkAvailable = Bool()
    var firstTime = Bool()
    let GROUP_ID = AppDelegate.getGroupId()
    let STUDY_ID = AppDelegate.getStudyId()
    var pinchGesture = UIGestureRecognizer()
    var featuresDetected: Int = 0
    var messageText = ""
    var resetCount = 0
    
    var beginsound: Float = 0.5
    
    func stopPlaying() {
        accelerometer?.stop()
        do{
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            NSLog(error.localizedDescription)
        }
        captureSession?.stopRunning()
    }
    
    func resumePlaying() {
        scrollToCenter()
        if !(AppDelegate.isIpad()) {
            captureSession?.startRunning()
        } else {
            initialCapture(value: "default")
        }
        do{
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            NSLog(error.localizedDescription)
        }
        accelerometer?.start()
    }
    
    func lockAutoFocus() {
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if (device.hasMediaType(.video)) && (device.position == .back) {
                do {
                    try device.lockForConfiguration()
                } catch {
                }
                let location = CGPoint(x: 0.5, y: 0.5)
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = location
                }
                if device.isFocusModeSupported(.autoFocus) {
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = location
                } else {
                    print("exposure point not support\n")
                }
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
            }
        }
    }
    
    func resetFlashButton() {
        if isFlashOn {
            isFlashOn = false
            turnFlashOff()
            /*UIImage *flashOffImage = [UIImage imageNamed:@FLASHONPNG];
             [self.flashLightButton setImage:flashOffImage forState:UIControlStateNormal];*/
        }
    }
    
    func unlockAutoFocus() {
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if (device.hasMediaType(.video)) && (device.position == .back) {
                do {
                    try device.lockForConfiguration()
                } catch {
                }
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    let autofocusPoint = CGPoint(x: 0.5, y: 0.5)
                    device.focusPointOfInterest = autofocusPoint
                    device.focusMode = .continuousAutoFocus
                }
                //            if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
                //                [device setExposureMode:AVCaptureExposureModeLocked];
                //            }
                device.unlockForConfiguration()
            }
        }
    }
    
    func beforeEnterBackground() {
        if isFlashOn {
            flashButtonTapped(nil)
        }
        if isLocked {
            // trace touch event
            var seconds: Float = 0.0
            if let lockTimer = lockTimer {
                seconds = Float(Date().timeIntervalSince(lockTimer))
            }
            if seconds >= 1 {
                if isiPhone() {
                    Umeng.event("Snapshot", value: "iPhone", durations: Int((seconds) * 1000))
                }
                if isIpad() {
                    Umeng.event("Snapshot", value: "iPad", durations: Int((seconds) * 1000))
                }
            }
        }
//        storeData()
        // Send time interval
        var seconds: Float = 0.0
        if let startTimer = startTimer {
            seconds = Float(Date().timeIntervalSince(startTimer))
        }
        if seconds >= 1 {
            var mutableDictionary: [AnyHashable : Any] = [:]
            if checkAccessibilityEnabled() {
                if GROUP_ID != nil && STUDY_ID != nil {
                    mutableDictionary["\(STUDY_ID ?? "") VI"] = Umeng.appendGroup(to: isiPhone() ? "iPhone" : "iPad")
                } else {
                    mutableDictionary["VI"] = Umeng.appendGroup(to: isiPhone() ? "iPhone" : "iPad")
                }
                if isiPhone() {
                    MobClick.event("TimePeriod_iPhone", attributes: mutableDictionary, durations: Int32(Int((seconds) * 1000)))
                    // Use counter means this is a computing event
                    Umeng.event("TimePeriod_iPhone", attributes: [
                        "TimePeriod_iPhone VI": "iPhone"
                    ], counter: Int(ceil(seconds)))
                }
                if isIpad() {
                    MobClick.event("TimePeriod_iPad", attributes: mutableDictionary, durations: Int32(Int((seconds) * 1000)))
                    // Use counter means this is a computing event
                    Umeng.event("TimePeriod_iPad", attributes: [
                        "TimePeriod_iPad VI": "iPad"
                    ], counter: Int(ceil(seconds)))
                }
            } else {
                if isiPhone() {
                    Umeng.event("TimePeriod_iPhone", value: "iPhone", durations: Int((seconds) * 1000))
                    // Use counter means this is a computing event
                    Umeng.event("TimePeriod_iPhone", attributes: [
                        "TimePeriod_iPhone": "iPhone"
                    ], counter: Int(ceil(seconds)))
                    //[self umengEvent:@"CalTimeSum" attributes:@{@"Device": @"iPhone"} number:@(seconds)];
                }
                if isIpad() {
                    Umeng.event("TimePeriod_iPad", value: "iPad", durations: Int((seconds) * 1000))
                    Umeng.event("TimePeriod_iPad", attributes: [
                        "TimePeriod_iPad": "iPad"
                    ], counter: Int(ceil(seconds)))
                    //[self umengEvent:@"CalTimeSum" attributes:@{@"Device": @"iPad"} number:@(seconds)];
                }
            }
        }
        // Remove volume listener
        print("Before enter background")
        stopPlaying()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func applicationDidBecomeActive() {
        if isLocked {
            lockTimer = Date()
            //[MobClick beginEvent:@"Snapshot"];
        }
        if !SYSTEM_VERSION_LESS_THAN(version: "8.0") {
            focusTimer = Date()
            let offset = getOffset()
            lensPosition = getLevel(accelerometer?.getCurrent() ?? 0.0, offset: offset)
            let label = String(format: "%ld", lensPosition)
            sendFocusLevelMetrics(label: label)
        }
        // start image mode event
        if AppDelegate.isIpad() {
            Umeng.beginEvent("ImageMode_iPad", primarykey: "ImageMode_iPad", value: "Enh-Inv")
        }
        if AppDelegate.isiPhone() {
            Umeng.beginEvent("ImageMode_iPhone", primarykey: "ImageMode_iPhone", value: "Enh-Inv")
        }
        // Set start timer
        startTimer = Date()
        // Start volume listener
        initialVolumeListener()
        let userDefaults = UserDefaults.standard
        let object = userDefaults.object(forKey: "Zoom Scale") as? NSObject
        if object != nil {
            self.restoreZoom()
        }
        runCount = 0
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            print("Timer fired!")
            self.runCount += 1
            
            if self.runCount >= 2 {
                timer.invalidate()
            }
        }
        
        //xuan reset lockFocusButton
        if lockFocusButton.isSelected {
            let offset = getOffset()
            let level = getLevel(accelerometer?.getCurrent() ?? 0.0, offset: offset)

            lockFocusButtonSelected = false
            lockFocusButton.isSelected = false

            if captureDevice!.isFocusModeSupported(.continuousAutoFocus) {
                captureDevice!.focusMode = .continuousAutoFocus
                print("Focus unlocked")
            }
            // lock focus event end
            if isIpad() {
                Umeng.endEvent("LockFocus_iPad", primarykey: "LockFocus_iPad", value: lockLabel)
            } else {
                Umeng.endEvent("LockFocus_iPhone", primarykey: "LockFocus_iPhone", value: lockLabel)
            }
            // focus level event start
            let label = String(format: "%ld", level)
            sendFocusLevelMetrics(label: label)
            lensPosition = level
            focusTimer = Date()
        }
        
        getUserLocation()
        systemVolume = AVAudioSession.sharedInstance().outputVolume
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
                print("UnitImageSize timer fired!")
                self.checkCorrectedLensPosition()
            }
        } else {
            // Fallback on earlier versions
        }
//        if let token = UserDefaults.standard.string(forKey: "device_token") {
//            let alertVC = UIAlertController.init(title: "Device token", message: token, preferredStyle: UIAlertController.Style.alert)
//            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            self.present(alertVC, animated: true, completion: nil)
//        }
    }
    
    @objc func reachabilityChanged(note: Notification) {
        
        let reachability = note.object as! Reachability
        
        switch reachability.connection {
        case .wifi:
            print("Reachable via WiFi")
            networkAvailable = true
        case .cellular:
            print("Reachable via Cellular")
            networkAvailable = true
        case .unavailable:
            print("Network not reachable")
            networkAvailable = false
        case .none:
            print("None")
            networkAvailable = false
        }
    }
    
    // xuan lockFocusButtonTapped
    @IBAction func lockFocusButtonTapped(_ sender: Any) {
        let offset = getOffset()
        let level = getLevel(accelerometer?.getCurrent() ?? 0.0, offset: offset)
        if lockFocusButton.isSelected { // 如果已经开启了锁定 （解锁）
//            if(is_Singal){
//                initialCapture(value: "default")
//            }else{
//                initialCapture(value: "switch")
//            }
            let scale = zoomSlider.value
            setZoomScale(scale)
            
            lockFocusButtonSelected = false
            lockFocusButton.isSelected = false
            
            if captureDevice!.isFocusModeSupported(.continuousAutoFocus) {
                captureDevice!.focusMode = .continuousAutoFocus
                print("Focus unlocked")
            }
            
//            unlockAutoFocus()
            // lock focus event end
            if isIpad() {
                Umeng.endEvent("LockFocus_iPad", primarykey: "LockFocus_iPad", value: lockLabel)
            } else {
                Umeng.endEvent("LockFocus_iPhone", primarykey: "LockFocus_iPhone", value: lockLabel)
            }
            // focus level event start
            let label = String(format: "%ld", level)
            sendFocusLevelMetrics(label: label)
            lensPosition = level
            focusTimer = Date()
        } else { // 如果没有开启锁定 （上锁）
//            if(is_Singal){
//                initialCapture(value: "default")
//            }else{
//                initialCapture(value: "switch")
//            }
            
            lockLabel = String(format: "%ld", level)
            lockFocusButtonSelected = true
            // lock focus event start
            if isIpad() {
                Umeng.beginEvent("LockFocus_iPad", primarykey: "LockFocus_iPad", value: lockLabel)
            } else {
                Umeng.beginEvent("LockFocus_iPhone", primarykey: "LockFocus_iPhone", value: lockLabel)
            }
            
            // focus level event end
            var seconds: Float = 0.0
            if let focusTimer = focusTimer {
                seconds = Float(Date().timeIntervalSince(focusTimer))
            }
            if seconds >= 3 {
                let label = String(format: "%ld", lensPosition)
                sendFocusLevelMetrics(label: label)
//                if isiPhone() {
//                    Umeng.endEvent("FocusLevel_iPhone", primarykey: "FocusLevel_iPhone", value: label)
//                }
//                if isIpad() {
//                    Umeng.endEvent("FocusLevel_iPad", primarykey: "FocusLevel_iPad", value: label)
//                }
            }
            lockFocusButton.isSelected = true
//            lockFocus()
//            captureDevice
            if captureDevice!.isFocusModeSupported(.locked) {
                captureDevice!.focusMode = .locked
                print("Focus locked")
            }
        }
        storeData()
    }
    
    // MARK: -
    // MARK: Initial Functions
    
    func initialSettings() {
        
        currentZoomRate = 1
        avgFeaturePoints = 0
        scrollView.clipsToBounds = true
        avgTimeForAck = 0
        avgTimeForConvert = 0
        avgTimeForDetect = 0
        avgTimeForOneFrame = 0
        avgTimeForPostProcess = 0
        avgTimeForTrack = 0
        minFrameRate = 20
        maxFrameRate = 30
        imageNo = 0
        imageProcess = ImageProcess()
        //  set the flashLight by default off
        isFlashOn = false
        isStabilizationEnable = false
        //  set the horizontal stabilization true by default.
        isHorizontalStable = false
        motionX = 0
        motionY = 0
        isLocked = false
        beforeLock = false
        imageOrientation = UIImage.Orientation.right.rawValue
        mirroredImageOrientation = UIImage.Orientation.leftMirrored.rawValue
        hideControls = false
        correctContentOffset = CGPoint.zero
        scrollView.zoomScale = CGFloat(currentZoomRate)
        varQueue = []
        maxVariance = 0
        adjustingFocus = true
        counter = 0
        message.isHidden = true
        UIApplication.shared.isStatusBarHidden = true
        isTapped = false
        isExposureAdjusted = false
        readyChangeBack = false
        photoData = []
        onlyOnce = false
        zoomSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        //        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        //        scrollView.addGestureRecognizer(pinchGesture!)
        //    [self.scrollView setScrollEnabled:NO];
        if isIpad() {
            currentResolution = IPADRESOLUTION.rawValue
            scrollView.zoomScale = 1
            zoomSlider.value = 1
            let viewScale = fmin(Float((scrollView.imageView?.frame.size.width ?? 0) / ScreenWidth), Float((scrollView.imageView?.frame.size.height ?? 0) / ScreenHeight))
            setMinimalZoomScale(1 / viewScale)
//            scrollView.minimumZoomScale = 0.75
//            zoomSlider.minimumValue = 0.75
            featureWindowWidth = 192
            featureWindowHeight = 108
            resolutionWidth = 1080
            resolutionHeight = 1920
            imageProcess?.maxFeatureNumber = 20
            lockDelay = 10
            if beforeIpad2() {
                currentResolution = RESOLUTION2.rawValue
                scrollView.zoomScale = 1.2
                setMinimalZoomScale(1.2)
            }
            // Show flash button for iPad pro
            if isIpadPro() {
                print("ipad pro: \(flashLightButton.isHidden)")
                flashLightButton.isHidden = false
            }
            return
        }
        if isIphone5() {
            currentResolution = IP5RESOLUTION.rawValue
            scrollView.zoomScale = 1
            zoomSlider.value = 1
//            featureWindowWidth = 256
//            featureWindowHeight = 256
            imageProcess?.maxFeatureNumber = 10
            //scrollView.clipsToBounds = true
            scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: 1080, height: 1920))
//            scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: 2160, height: 3840))
            let viewScale = fmin(Float((scrollView.imageView?.frame.size.width ?? 0) / ScreenWidth), Float((scrollView.imageView?.frame.size.height ?? 0) / ScreenHeight))
            //        [self.scrollView setMinimumZoomScale:1/viewScale];
            //        [self.zoomSlider setMinimumValue:1/viewScale];
            setMinimalZoomScale(1 / viewScale)
//            print("\("minimal zoom scale: ")\(1 / viewScale)")
//            print("\("frame width scale: ")\(ScreenWidth)")
//            print("\("frame height scale: ")\(ScreenHeight)")
            resolutionWidth = 1080
            resolutionHeight = 1920
//            resolutionWidth = 2160
//            resolutionHeight = 3840
            lockDelay = 10
            return
        }
        if (isIphone4()) || (isIphone4S()) {
            currentResolution = IP4RESOLUTION.rawValue
            featureWindowWidth = 128
            featureWindowHeight = 72
            imageProcess?.maxFeatureNumber = 6
            scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: CGFloat(540 * currentZoomRate), height: CGFloat(960 * currentZoomRate)))
            let viewScale = fmin(Float((scrollView.imageView?.frame.size.width ?? 0) / ScreenWidth), Float((scrollView.imageView?.frame.size.height ?? 0) / ScreenHeight))
            scrollView.minimumZoomScale = CGFloat(1 / viewScale)
            zoomSlider.minimumValue = 1 / viewScale
            resolutionWidth = Int(540 * currentZoomRate)
            resolutionHeight = Int(960 * currentZoomRate)
            scrollView.zoomScale = 1
            lockDelay = isIphone4() ? 4 : 8
            return
        } else {
            return
        }
    }
    
    func initialControls() {
        //  Customizing the UISlider
        let maxImage = UIImage(named: "empty.png")
        let minImage = UIImage(named: "empty.png")
        var thumbImage: UIImage? = nil
        if let cg = (UIImage(named: String(utf8String: SLIDERTHUMB) ?? ""))?.cgImage {
            thumbImage = UIImage(cgImage: cg, scale: 2, orientation: .up)
        }
        UISlider.appearance().setMaximumTrackImage(maxImage, for: .normal)
        UISlider.appearance().setMinimumTrackImage(minImage, for: .normal)
        UISlider.appearance().setThumbImage(thumbImage, for: .normal)
        
        //  set the slider vertical on screen
        let transformRotate = CGAffineTransform(rotationAngle: CGFloat(degreeToRadians(-90)))
        zoomSlider.transform = transformRotate
        
        let bounds = UIScreen.main.bounds
        scrollView.frame = bounds
        saveButton.isHidden = true
        //[self.photoButton setHidden:YES];
        /*
         [self.infoButton.imageView setFrame:
         CGRectMake(0,
         0,
         INFOICONWIDTH,
         INFOICONWIDTH)];
         [self.infoButton setFrame:
         CGRectMake(bounds.size.width - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
         INFOBUTTONPORTRAITORIENTATIONY,
         INFOBUTTONWIDTH,
         INFOBUTTONWIDTH)];
         
         [self.sliderBackground setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH + 4,
         bounds.size.height/2 - SLIDERHEIGHT/2 + 14,
         SLIDERWIDTH - 10,
         SLIDERHEIGHT - 27)];
         
         [self.zoomSlider setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH,
         bounds.size.height/2 - SLIDERHEIGHT/2,
         SLIDERWIDTH,
         SLIDERHEIGHT)];
         
         
         [self.stableDirectionButton setFrame:
         CGRectMake(OUTHBUTTONOFFSET,
         bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
         BUTTONWIDTH,
         BUTTONWIDTH)];
         [self.flashLightButton setFrame:
         CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET + BUTTONWIDTH,
         bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
         BUTTONWIDTH,
         BUTTONWIDTH)];
         [self.screenLockButton setFrame:
         CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET*2 + 2*BUTTONWIDTH,
         bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
         BUTTONWIDTH,
         BUTTONWIDTH)];
         */
        
        scrollView.touchDelegate = self
        
    }
    
    func initialNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(beforeEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trackFeaturesNotif(notification:)), name: Notification.Name(rawValue: "TrackFeatures"), object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    func trackFeaturesNotif(notification: NSNotification) {
        DispatchQueue.main.async {
            self.message.isHidden = true
            if let count = notification.userInfo?["features"] as? Int {
                if let totalCount = notification.userInfo?["total"] as? Int {
                    self.featuresDetected = count
                    self.messageText = "features: \(count)"
                    self.message.text = self.messageText
                }
            }
        }
    }
    
    
    // Return zoom value between the minimum and maximum zoom values
    func minMaxZoom(_ factor: CGFloat) -> CGFloat {
        return min(min(max(factor, scrollView.minimumZoomScale), scrollView.maximumZoomScale), (captureDevice?.activeFormat.videoMaxZoomFactor)!)
    }
    
    var phoneModel: String {
        
        let identifier = UIDevice.current.modelName
            
        switch identifier {
            case "iPod5,1":                                 return "iPod Touch 5"
            case "iPod7,1":                                 return "iPod Touch 6"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone8,4":                               return "iPhone SE (1st generation)"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,5", "iPhone10,2":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS MAX"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPhone12,1":                              return "iPhone 11"
            case "iPhone12,3":                              return "iPhone 11 Pro"
            case "iPhone12,5":                              return "iPhone 11 Pro Max"
            case "iPhone12,8":                              return "iPhone SE (2nd generation)"
            case "iPhone13,1":                              return "iPhone 12 mini"
            case "iPhone13,2":                              return "iPhone 12"
            case "iPhone13,3":                              return "iPhone 12 Pro"
            case "iPhone13,4":                              return "iPhone 12 Pro Max"
            case "iPhone14,4":                              return "iPhone 13 mini"
            case "iPhone14,5":                              return "iPhone 13"
            case "iPhone14,2":                              return "iPhone 13 Pro"
            case "iPhone14,3":                              return "iPhone 13 Pro Max"
            case "iPhone14,6":                              return "iPhone SE (3rd generation)"
            case "iPhone14,7":                              return "iPhone 14"
            case "iPhone14,8":                              return "iPhone 14 Plus"
            case "iPhone15,2":                              return "iPhone 14 Pro"
            case "iPhone15,3":                              return "iPhone 14 Pro Max"
                
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
            case "iPad6,11", "iPad6,12":                    return "iPad 5"
            case "iPad7,5", "iPad7,6":                      return "iPad 6"
            case "iPad7,11", "iPad7,12":                    return "iPad 7"
            case "iPad11,6", "iPad11,7":                    return "iPad 8"
            case "iPad12,1", "iPad12,2":                    return "iPad 9"
     
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad11,3", "iPad11,4":                    return "iPad Air 3"
            case "iPad13,1", "iPad13,2":                    return "iPad Air 4"
            case "iPad13,16", "iPad13,17":                  return "iPad Air 5"
            
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
            case "iPad11,1", "iPad11,2":                    return "iPad Mini 5"
            case "iPad14,1", "iPad14,2":                    return "iPad Mini 6"
            case "iPad6,7", "iPad6,8", "iPad6,3", "iPad6,4", "iPad7,1", "iPad7,2", "iPad7,3", "iPad7,4", "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4", "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8", "iPad8,9", "iPad8,10", "iPad8,11", "iPad8,12":         return "iPad Pro"
            default:                                        return identifier
        }
    }
    
    func isPro() -> Bool {
        let range = (phoneModel.lowercased() as NSString?)?.range(of: "pro")
        if range?.location != NSNotFound {
            return true
        } else {
            return false
        }
    }
    
    // iphone8+ wide and Tele
    // iphone7+ wide and Tele
    func isPlus() -> Bool {
        let range = (phoneModel as NSString?)?.range(of: "14")
        if range?.location != NSNotFound {
            return false
        }
        let range1 = (phoneModel as NSString?)?.range(of: "6")
        if range1?.location != NSNotFound {
            return false
        }
        let range2 = (phoneModel as NSString?)?.range(of: "6s")
        if range2?.location != NSNotFound {
            return false
        }
        let range3 = (phoneModel.lowercased() as NSString?)?.range(of: "plus")
        if range3?.location != NSNotFound {
            return true
        } else {
            return false
        }
    }
    
    // chose the camera type
    func setUpOnce(){
        if isPlus() {
            if #available(iOS 13.0, *) {
                nearCam = AVCaptureDevice.DeviceType.builtInDualCamera
                print("test is plus")
            } else {
                is_Singal = true
            }
        }else if isPro() {
            is_Pro = true;
            if #available(iOS 13.0, *) {
                nearCam = AVCaptureDevice.DeviceType.builtInTripleCamera
                print("test is pro")
            }else{
                is_Singal = true
            }
        }else{
            if #available(iOS 13.0, *) {
                print("test is normal")
                nearCam = AVCaptureDevice.DeviceType.builtInDualWideCamera
            }else{
                is_Singal = true
            }
        }
    }
    
    //  initial capture settings from camerra flow
    func initialCapture(value: String) {
        //And we create a capture session
        captureSession = AVCaptureSession()
        //xuan initialCapture
        
        if (value == "default" || is_Singal) {
            captureDevice = AVCaptureDevice.default(for: .video)
        }
        
        if (value == "switch") {
            if #available(iOS 13.0, *) {
                captureDevice = AVCaptureDevice.default(nearCam, for: .video, position: .back)
            }else{
                captureDevice = AVCaptureDevice.default(for: .video)
                is_Singal = true;
            }
        }
//        }else{
//            if(isNear){
//                if #available(iOS 13.0, *) {
//                    captureDevice = AVCaptureDevice.default(nearCam, for: .video, position: .back)
////                    captureDevice?.dualCameraSwitchOverVideoZoomFactor
//                }
//                cameraType.text = "Near Camera :" + String(format:"%.1f",currentZoomRate)
//            }else{
//                if #available(iOS 13.0, *) {
//                    captureDevice = AVCaptureDevice.default(farCam, for: .video, position: .back)
//                }
//                cameraType.text = "Far Camera :" + String(format:"%.1f",currentZoomRate)
//            }
//            if(captureDevice?.isConnected == nil){
//                captureDevice = AVCaptureDevice.default(for: .video)
//                is_Singal = true
//            }
//        }
//        } else if (value == "telephoto") {
//            if #available(iOS 10.0, *) {
//                captureDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
//            } else {
//                captureDevice = AVCaptureDevice.default(for: .video)
//            }
//        } else if (value == "dualwide") {
//            if #available(iOS 13.0, *) {
//                captureDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back)
//            } else {
//                captureDevice = AVCaptureDevice.default(for: .video)
//            }
//        } else if (value == "dual") {
//            if #available(iOS 10.2, *) {
//                if let device = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
//                    captureDevice = device
//                    print("builtInDualCamera")
//                } else {
//                    captureDevice = AVCaptureDevice.default(for: .video)
//                    print("builtInDefaultCamera")
//                }
//            } else {
//                captureDevice = AVCaptureDevice.default(for: .video)
//                print("builtInDefaultCamera")
//            }
//        } else if (value == "wide") {
//            if #available(iOS 10.2, *) {
//                captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
//            } else {
//                captureDevice = AVCaptureDevice.default(for: .video)
//            }
//        } else {
//            captureDevice = AVCaptureDevice.default(for: .video)
//        }
        
        var error: Error?
        var captureInput: AVCaptureDeviceInput? = nil
        do {
            if let captureDevice = captureDevice {
                captureInput = try AVCaptureDeviceInput(device: captureDevice)
            }
        } catch {
        }
        if error == nil {
            if let captureInput = captureInput {
                if captureSession?.canAddInput(captureInput) ?? false {
                    captureSession?.addInput(captureInput)
                } else {
                    print("Video input add-to-session failed")
                }
            }
        } else {
            let errorAlert = UIAlertView(title: "Error", message: "No permission to get access to camera.", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
            errorAlert.show()
            print("Video input creation failed")
        }
        //We setupt the output
        let captureOutput = AVCaptureVideoDataOutput()
        /*While a frame is processes in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
         If you don't want this behaviour set the property to NO */
        captureOutput.alwaysDiscardsLateVideoFrames = true
        /*We specify a minimum duration for each frame (play with this settings to avoid having too many frames waiting
         in the queue because it can cause memory issues). It is similar to the inverse of the maximum framerate.
         In this example we set a min frame duration of 1/10 seconds so a maximum framerate of 10fps. We say that
         we are not able to process more than 10 frames per second.*/
        
        //We create a serial queue to handle the processing of our frames
        var queue: DispatchQueue
        queue = DispatchQueue(label: "cameraQueue")
        captureOutput.setSampleBufferDelegate(self, queue: queue)
        //        captureOutput.setSampleBufferDelegate(self, queue: queue)
        // Set the video output to store frame in BGRA (It is supposed to be faster)
        let key = kCVPixelBufferPixelFormatTypeKey as String
        let value = NSNumber(value: UInt32(kCVPixelFormatType_32BGRA))
        let videoSettings = [key : value]
        captureOutput.videoSettings = videoSettings
        
        // for ios 5.0  However, it does not work
        let conn = captureOutput.connection(with: .video)
        //        captureDevice?.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(minFrameRate))
        //        captureDevice?.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(maxFrameRate))
        
        //We add input and output
        captureSession?.addOutput(captureOutput)
        //We use medium quality, ont the iPhone 4 this demo would be laging too much, the conversion in UIImage and CGImage demands too much ressources for a 720p resolution.
        if !(captureSession?.canSetSessionPreset(AVCaptureSession.Preset.photo) ?? false) {
            print("REsolution 720p")
            currentResolution = RESOLUTION2.rawValue
            resolutionWidth = 720
            resolutionHeight = 1280
        } else {
            print("REsolution 1080p")
            captureSession?.sessionPreset = AVCaptureSession.Preset.photo
        }
        //captureSession?.sessionPreset = (rawValue: currentResolution!)
        
        do {
            try captureDevice?.lockForConfiguration()
            
            if try captureDevice?.lockForConfiguration() != nil && !SYSTEM_VERSION_LESS_THAN(version: "7.0") {
                captureDevice?.videoZoomFactor = CGFloat(captureDevice?.activeFormat.videoZoomFactorUpscaleThreshold ?? 1.0)
//                print(CGFloat(currentZoomRate))
//                if (prevValOfCam == "telephoto") {
//                    captureDevice?.ramp(toVideoZoomFactor: minMaxZoom(CGFloat(max(currentZoomRate, 1))), withRate: 1.0)
//                    print("Zoom level: \(minMaxZoom(CGFloat(max(currentZoomRate, 1))))")
//                } else {
//                    captureDevice?.ramp(toVideoZoomFactor: minMaxZoom(CGFloat(max(currentZoomRate, 1) * 2)), withRate: 1.0)
//                    print("Zoom level: \(minMaxZoom(CGFloat(max(currentZoomRate, 1) * 2)))")
//                }
//                let FOV = captureDevice?.activeFormat.videoFieldOfView
//                print(FOV!)
                captureDevice?.unlockForConfiguration()
            }
        } catch {
        }
        
        //We start the capture
        captureSession?.startRunning()
        
        // initial date time.
        lastDate = Date()
        
        // initial focus timer
        if SYSTEM_VERSION_LESS_THAN(version: "8.0") {
        } else {
            focusTimer = Date()
            //float angle = [self getAngle];
            let offset = getOffset()
            lensPosition = getLevel(accelerometer?.getCurrent() ?? 0.0, offset: offset)
            let label = String(format: "%ld", lensPosition)
            sendFocusLevelMetrics(label: label)
//            if isiPhone() {
//                Umeng.beginEvent("FocusLevel_iPhone", primarykey: "FocusLevel_iPhone", value: label)
//            }
//            if isIpad() {
//                Umeng.beginEvent("FocusLevel_iPad", primarykey: "FocusLevel_iPad", value: label)
//            }
        }
    }
    
    /*
     Zewen Li hasn't finished yet. Tested work, and resolution reached beyond 1920*1080, that's great.
     However, it didn't get focused. Currently no more time could spent on that, stopped here, sorry.
     this link may be of help.http://www.musicalgeometry.com/?p=1297
     - (void) switchToStillImageMode {
     
     [self.captureSession removeOutput:[self.captureSession.outputs objectAtIndex:0]];
     AVCaptureStillImageOutput *stillImageCaptureOutput = [[AVCaptureStillImageOutput alloc] init];
     NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
     [stillImageCaptureOutput setOutputSettings:outputSettings];
     [self.captureSession addOutput:stillImageCaptureOutput];
     self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
     
     [self lockAutoFocus];
     
     AVCaptureConnection *videoConnection = nil;
     for (AVCaptureConnection *connection in stillImageCaptureOutput.connections) {
     for (AVCaptureInputPort *port in [connection inputPorts]) {
     if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
     videoConnection = connection;
     break;
     }
     }
     if (videoConnection) {
     break;
     }
     }
     [stillImageCaptureOutput captureStillImageAsynchronouslyFromConnection:videoConnection
     completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
     NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
     UIImage *image = [[UIImage alloc] initWithData:imageData];
     [self.scrollView setImage:image];
     [image release];
     [self.scrollView setMinimumZoomScale:0];
     self.scrollView.zoomScale = 0.2;
     }];
     }
     */
    // Virgil change
    func initialVolumeListener() {
        
        volumeListener = VolumeListener()
//        if(getSystemVolumValue() == 0.0 || getSystemVolumValue() == 1.0){
            
//        }
        view.viewWithTag(54870149)?.removeFromSuperview()
        if let dummy = volumeListener?.dummyVolume() {
            view.addSubview(dummy)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(_:)), name: NSNotification.Name("SystemVolumeDidChange"), object: nil)
    }

    
    @objc func volumeChanged(_ notification: Notification?) {
        if (runCount > 1) {
            let volume = getSystemVolumValue()
            if CGFloat(volume) == volumeListener?.systemVolume {
                return
            }
            volumeListener?.systemVolume = CGFloat(volume)
            if !restoringVolume {
                lockButtonTapped(nil)
            }
            restoringVolume = !restoringVolume
            volumeView?.setVolume(systemVolume)
        }
    }
    
    func initialMotion() {
        accelerometer = Accelerometer()
        accelerometer?.start()
    }
    
    func showAlert(_ s: String?) {
        let av = UIAlertView(title: "Test", message: s ?? "", delegate: self, cancelButtonTitle: "OK")
        
        av.tapBlock = { alertView, buttonIndex in
            if buttonIndex == alertView.firstOtherButtonIndex {
                print("Username: \(alertView.textField(at: 0)?.text ?? "")")
                print("Password: \(alertView.textField(at: 1)?.text ?? "")")
            } else if buttonIndex == alertView.cancelButtonIndex {
                print("Cancelled.")
            }
        }
        
        av.shouldEnableFirstOtherButtonBlock = { alertView in
            return ((alertView.textField(at: 1)?.text)?.count ?? 0) > 0
        }
        
        av.show()
    }

    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }

    @objc func updateCounting(){
        self.message.text = "\(self.prevValOfCam) \(self.captureDevice?.lensPosition ?? 0.0)"
        lensVals.append(self.captureDevice?.lensPosition ?? 0.0)
        if (lensVals.count == 10 && (lensVals.max()! - lensVals.min()! <= 0.1)) {
            let avgVal = lensVals.reduce(0, +) / 10
            print("Average value: \(avgVal)")
            lensVals.removeAll()

            //DispatchQueue.main.async() {
            if #available(iOS 10.2, *) {
                print("10.2, *")
                if #available(iOS 13.0, *) {
                    print("13.0, *")
                    if (avgVal <= 0.4) {
                        if let device = AVCaptureDevice.default(.builtInDualWideCamera, for: AVMediaType.video, position: .back) {
                            if (prevValOfCam != "dualwide") {
                                print("dualwide")
                                self.captureDevice = device
                                self.prevValOfCam = "dualwide"
                                self.initialCapture(value: self.prevValOfCam)
                                self.message.text = "\(self.prevValOfCam) \(self.captureDevice?.lensPosition ?? 0.0)"
                            }
                        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
                            if (prevValOfCam != "wide") {
                                print("wide")
                                self.captureDevice = device
                                self.prevValOfCam = "wide"
                                self.initialCapture(value: self.prevValOfCam)
                                self.message.text = "\(self.prevValOfCam) \(self.captureDevice?.lensPosition ?? 0.0)"
                            }
                        } else {
                            if (prevValOfCam != "default") {
                                print("default")
                                self.prevValOfCam = "default"
                                self.initialCapture(value: self.prevValOfCam)
                                self.message.text = "\(self.prevValOfCam) \(self.captureDevice?.lensPosition ?? 0.0)"
                            }
                        }
                    }else if (avgVal >= 0.7){
                        if let device = AVCaptureDevice.default(.builtInTelephotoCamera, for: AVMediaType.video, position: .back) {
                            if (prevValOfCam != "telephoto") {
                                print("builtInTelephotoCamera")
                                self.captureDevice = device
                                self.prevValOfCam = "telephoto"
                                self.initialCapture(value: self.prevValOfCam)
                                self.message.text = "\(self.prevValOfCam) \(self.captureDevice?.lensPosition ?? 0.0)"
                            }
                        } else {
                            if (prevValOfCam != "default") {
                                print("default")
                                self.captureDevice = AVCaptureDevice.default(for: .video)
                                self.prevValOfCam = "default"
                                self.initialCapture(value: self.prevValOfCam)
                                self.message.text = "\(self.prevValOfCam) \(self.captureDevice?.lensPosition ?? 0.0)"
                            }
                        }
                    }
                } else {
                    if (avgVal <= 0.4) {
                        if (prevValOfCam != "default") {
                            //print("default")
                            self.captureDevice = AVCaptureDevice.default(for: .video)
                            self.prevValOfCam = "default"
                            self.initialCapture(value: self.prevValOfCam)
                            self.message.text = "\(self.prevValOfCam) \(self.captureDevice?.lensPosition ?? 0.0)"
                        }
                    } else if (avgVal >= 0.7) {
                        if let device = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
                            if (prevValOfCam != "dual") {
                                print("builtInDualCamera")
                                self.captureDevice = device
                                self.prevValOfCam = "dual"
                                self.initialCapture(value: "dual")
                                self.message.text = "\(self.prevValOfCam) \(self.captureDevice?.lensPosition ?? 0.0)"
                            }
                        } else if (self.prevValOfCam != "default") {
                            //print("default")
                            self.captureDevice = AVCaptureDevice.default(for: .video)
                            self.prevValOfCam = "default"
                            self.initialCapture(value: self.prevValOfCam)
                            self.message.text = "\(self.prevValOfCam) \(self.captureDevice?.lensPosition ?? 0.0)"
                        }
                    }
                    //captureDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)// Fallback on earlier versions
                }
            } else if (self.prevValOfCam != "default") {
                // Fallback on earlier versions
                //print("default")
                self.captureDevice = AVCaptureDevice.default(for: .video)
                self.prevValOfCam = "default"
                self.initialCapture(value: self.prevValOfCam)
                self.message.text = "\(self.prevValOfCam) \(self.captureDevice?.lensPosition ?? 0.0)"
            }
            //            self.scrollView.adjustImageViewCenter()
            //            self.scrollToCenter()
            // }
            self.message.text = "\(self.prevValOfCam) avgVal:\(avgVal)"
        } else if (lensVals.count == 10) {
            lensVals.removeAll()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        addSystemVolumNotification()
        setAccesibilityHints()
        lockAutoFocus()
        //[MobClick event:@"Test" label:@"Lock Auto Focus Successfully."];
        unlockAutoFocus()
        //[MobClick event:@"Test" label:@"Unlock Auto Focus Successfully."];
        //super.viewDidLoad()
        
        initialControls()
        //[MobClick event:@"Test" label:@"Init Controls Successfully."];
        initialSettings()
        //[MobClick event:@"Test" label:@"Init Settings Successfully."];
        initialNotification()
        //[MobClick event:@"Test" label:@"Init Notification Successfully."];
        initialMotion()
        //[MobClick event:@"Test" label:@"Init Motion Successfully."];
        scrollToCenter()
        //xuan viewDidLoad
        if isIpad() {
            is_Singal = true;
            initialCapture(value: "default")
        } else {
            setUpOnce()
            initialCapture(value: "switch")
        }
        //[MobClick event:@"Test" label:@"Init Capture Successfully."];
        setupControlsPosition()
        //[MobClick event:@"Test" label:@"Setup Controls Position Successfully."];
        initialVolumeListener()
        //[MobClick event:@"Test" label:@"Init Volume Listener Successfully."];
        //performSelector(onMainThread: #selector(adjustCurrentOrientation), with: nil, waitUntilDone: true)
        //[MobClick event:@"Test" label:@"Adjust Orientation Successfully."];
        scrollToCenter()
        //[MobClick event:@"Test" label:@"Scroll To Center Successfully."];
        retrieveData()
        //[MobClick event:@"Test" label:@"Retrieve Data Successfully."];
        // Set the start time for CalTimeSum event in Umeng SDK
        //scheduledTimerWithTimeInterval()
        setupImageCategories()
        
        volumeView = MPVolumeView(frame: .zero)

        guard (volumeView?.subviews.first(where: { $0 is UISlider }) as? UISlider) != nil else {
          assertionFailure("Unable to find the slider")
          return
        }

        volumeView?.clipsToBounds = true
        view.addSubview(volumeView!)
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 0.2
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.scrollView.addGestureRecognizer(lpgr)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addFocusObserver()
        //declare this property where it won't go out of scope relative to your listener
        let reachability = try! Reachability()
        //declare this inside of viewWillAppear
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.removeFocusObserver()
        let reachability = try! Reachability()
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
    }
    
    let flip_image = UIImage(named: "flip") as! UIImage
    let flip_mirror_image = UIImage(named: "flip-mirror") as! UIImage
    var isFlipped = false
    @IBAction func flipPressed(_ sender: Any) {
        lockPortraitButtonTapped(UIButton())
        if isFlipped {
            //scrollView.transform = CGAffineTransform.identity
            flipButton.setImage(flip_image, for: .normal)
            //flipButton.setBackgroundImage(flip_image, for: .normal)
            isFlipped = false
        } else {
            //scrollView.transform = CGAffineTransform(scaleX: -1, y: 1)
            flipButton.setImage(flip_mirror_image, for: .normal)
            //flipButton.setBackgroundImage(flip_mirror_image, for: .normal)
            isFlipped = true
        }
        storeData()
    }
    
    
    // MARK: - touches delegate management
    func handleSingleTap(_ tapRecognizer: UITapGestureRecognizer?) {
        print("single tap")
        let screenRect = UIScreen.main.bounds
        var screenWidth = Double(screenRect.size.width)
        var screenHeight = Double(screenRect.size.height)
        //NSLog(@"width = %f, height = %f", screenWidth, screenHeight);
        if screenWidth > screenHeight {
            let temp = screenHeight
            screenHeight = screenWidth
            screenWidth = temp
        }
        let oldPoint = tapRecognizer?.location(in: nil)
        // point of interest x is vertial axis y is horizental axis
        var point = CGPoint(x: CGFloat(Double(oldPoint?.y ?? 0.0) / screenHeight), y: CGFloat((screenWidth - Double(oldPoint?.x ?? 0.0)) / screenWidth))
        if ORIENTATION.isLandscape {
            point = CGPoint(x: CGFloat(Double(oldPoint?.y ?? 0.0) / screenHeight), y: CGFloat((screenWidth - Double(oldPoint?.x ?? 0.0)) / screenWidth))
        }
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.continuousAutoExposure) {
                var error: Error?
                do {
                    try device.lockForConfiguration()
                } catch {
                }
                let newPoint = CGPoint(x: CGFloat(point.x - 0.5) / CGFloat((CGFloat(currentZoomRate) / scrollView.minimumZoomScale)) + 0.5, y: (point.y - 0.5) / CGFloat((CGFloat(currentZoomRate) / scrollView.minimumZoomScale)) + 0.5)
                if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported && !lockFocusButton.isSelected {
                    device.focusPointOfInterest = newPoint
                    device.focusMode = .autoFocus
                }
                device.exposurePointOfInterest = newPoint
                device.exposureMode = .continuousAutoExposure
                device.unlockForConfiguration()
                isTapped = true
                self.point = newPoint
                tapZoomRate = currentZoomRate
                saveExposureInformation()
                //self.tapLensPosition = self.captureDevice.lensPosition;
            }
        }
//        DispatchQueue.main.async {
//            self.sendPhotoToAzureWithTag(self.scrollView.getImage())
//        }
    }
    
    func saveExposureInformation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.iso = self.captureDevice?.iso ?? 0.0
            self.duration = self.captureDevice?.exposureDuration
            self.isExposureAdjusted = true
        })
    }
    
    func umengEvent(_ eventId: String?, attributes: [AnyHashable : Any]?, number: NSNumber?) {
        let numberKey = "__ct__"
        var mutableDictionary = attributes
        mutableDictionary?[numberKey] = number?.stringValue ?? ""
        MobClick.event(eventId, attributes: mutableDictionary)
    }
    
    func adjustExposurePoint() {
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                let newPoint = CGPoint(x: (point.x - 0.5) / CGFloat((currentZoomRate / tapZoomRate)) + 0.5, y: (point.y - 0.5) / CGFloat((currentZoomRate / tapZoomRate)) + 0.5)
                print("point x = \(newPoint.x), point y = \(newPoint.y)")
                var error: Error?
                do {
                    try device.lockForConfiguration()
                } catch {
                }
                device.exposurePointOfInterest = newPoint
                device.exposureMode = .continuousAutoExposure
                device.unlockForConfiguration()
            }
        }
    }
    
    // MARK: - orientation rotation
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if portraitOnly {
            return .portrait
        }
        return .allButUpsideDown
    }

    /*
     - (void) setupControlsPosition {
     
     CGRect bounds = [[UIScreen mainScreen] bounds];
     ///--- portrait
     if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
     [self.stableDirectionButton setFrame:
     CGRectMake(OUTHBUTTONOFFSET,
     bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
     BUTTONWIDTH,
     BUTTONWIDTH)];
     [self.flashLightButton setFrame:
     CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET + BUTTONWIDTH,
     bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
     BUTTONWIDTH,
     BUTTONWIDTH)];
     [self.screenLockButton setFrame:
     CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET*2 + 2*BUTTONWIDTH,
     bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
     BUTTONWIDTH,
     BUTTONWIDTH)];
     [self.sliderBackground setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH + 4,
     bounds.size.height/2 - SLIDERHEIGHT/2 + 14,
     SLIDERWIDTH - 10,
     SLIDERHEIGHT - 27)];
     [self.zoomSlider setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH,
     bounds.size.height/2 - SLIDERHEIGHT / 2,
     SLIDERWIDTH,
     SLIDERHEIGHT)];
     
     [self.infoButton setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
     INFOBUTTONPORTRAITORIENTATIONY+IPADIADPORTRAITHEIGHT,
     INFOBUTTONWIDTH,
     INFOBUTTONWIDTH)];
     
     
     // if ([self isIpad])
     //     [self.iadView setFrame:CGRectMake(0, 0, IADPORTRAITWIDTH, IPADIADPORTRAITHEIGHT)];
     // else
     //     [self.iadView setFrame:CGRectMake(0, 0, IADPORTRAITWIDTH, IADPORTRAITHEIGHT)];
     }
     ///-- landscape
     else {
     [self.stableDirectionButton setFrame:
     CGRectMake(OUTHBUTTONOFFSET,
     bounds.size.width - BUTTONWIDTH - OUTVBUTTONOFFSET,
     BUTTONWIDTH,
     BUTTONWIDTH)];
     [self.flashLightButton setFrame:
     CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET + BUTTONWIDTH,
     bounds.size.width - BUTTONWIDTH - OUTVBUTTONOFFSET,
     BUTTONWIDTH,
     BUTTONWIDTH)];
     [self.screenLockButton setFrame:
     CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET*2 + 2*BUTTONWIDTH,
     bounds.size.width - BUTTONWIDTH - OUTVBUTTONOFFSET,
     BUTTONWIDTH,
     BUTTONWIDTH)];
     [self.sliderBackground setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH + 4,
     bounds.size.width/2 - SLIDERHEIGHT/2 + 14,
     SLIDERWIDTH - 10,
     SLIDERHEIGHT - 27)];
     [self.zoomSlider setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH,
     bounds.size.width/2 - SLIDERHEIGHT / 2,
     SLIDERWIDTH,
     SLIDERHEIGHT)];
     
     [self.infoButton setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
     INFOBUTTONLANDSCAPEORIENTATIONY,
     INFOBUTTONWIDTH,
     INFOBUTTONWIDTH)];
     if ([self isIpad]) {
     [self.infoButton setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
     INFOBUTTONPORTRAITORIENTATIONY+IPADIADPORTRAITHEIGHT,
     INFOBUTTONWIDTH,
     INFOBUTTONWIDTH)];
     //  [self.iadView setFrame:CGRectMake(0, 0, IADLANDSCAPEWIDTH, IPADIADPORTRAITHEIGHT)];
     }
     //if ([self isiPhone]) {
     //  [self.iadView setFrame:CGRectMake(0,
     //                                      IADLANDSCAPEORIENTATIONY,
     //                                      IADLANDSCAPEWIDTH,
     //                                      IPADIADLANDSCAPEHEIGHT)];
     //}
     }
     }
     */
    
    /////---- 10/07/2014 updated the layout: hide ad banner and move flash and screen lock buttons to right
    ///Position1
    @objc func setupControlsPosition() {
        let bounds = UIScreen.main.bounds
        ///--- portrait
        DispatchQueue.main.async{
            if ORIENTATION.isPortrait || self.portraitOnly {
                self.scrollView.frame = bounds
                self.stableDirectionButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET) + CGFloat((4 * OUTHBUTTONOFFSET)) , y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                self.flashLightButton.frame = CGRect(x: bounds.size.width - CGFloat((3 * OUTHBUTTONOFFSET)) - CGFloat((2 * INBUTTONOFFSET)) - CGFloat((2 * BUTTONWIDTH)), y: bounds.size.height - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                self.screenLockButton.frame = CGRect(x: bounds.size.width - CGFloat((3 * OUTHBUTTONOFFSET)) - CGFloat(INBUTTONOFFSET) - CGFloat(BUTTONWIDTH), y: bounds.size.height - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                self.sliderBackground.frame = CGRect(x: bounds.size.width - CGFloat(SLIDERWIDTH) + 4, y: bounds.size.height / 2 - CGFloat(SLIDERHEIGHT / 2) + 14, width: CGFloat(SLIDERWIDTH - 10), height: CGFloat(SLIDERHEIGHT - 27))
                self.zoomSlider.frame = CGRect(x: bounds.size.width - CGFloat(SLIDERWIDTH), y: bounds.size.height / 2 - CGFloat(SLIDERHEIGHT / 2), width: CGFloat(SLIDERWIDTH), height: CGFloat(SLIDERHEIGHT))
                self.flipButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))//CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: CGFloat(2 * OUTVBUTTONOFFSET) + CGFloat(BUTTONWIDTH), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
            
                self.infoButton.frame = CGRect(x: bounds.size.width - CGFloat(SLIDERWIDTH) + CGFloat((SLIDERWIDTH - INFOBUTTONWIDTH) / 2), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(INFOBUTTONWIDTH), height: CGFloat(INFOBUTTONWIDTH))
            // new save button
                self.saveButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: bounds.size.height - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
            // new photo button
                self.photoButton.frame = CGRect(x: bounds.size.width - CGFloat((3 * OUTHBUTTONOFFSET)) - CGFloat(INBUTTONOFFSET) - CGFloat(BUTTONWIDTH), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
            // new image mode button
                self.imageModeButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: bounds.size.height - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
            // lock portrait button
            //lockPortraitButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
//                CGRect(x: CGFloat(OUTHBUTTONOFFSET) + CGFloat((4 * OUTHBUTTONOFFSET)) , y: bounds.size.height - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
            // new fix focus button
                self.lockFocusButton.frame = CGRect(x: bounds.size.width - CGFloat((3 * OUTHBUTTONOFFSET)) - CGFloat((2 * INBUTTONOFFSET)) - CGFloat((2 * BUTTONWIDTH)), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
        } else {
            if SYSTEM_VERSION_LESS_THAN(version: "8.0") {
                self.stableDirectionButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: bounds.size.width - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                self.flashLightButton.frame = CGRect(x: bounds.size.height - CGFloat((4 * OUTHBUTTONOFFSET)) - CGFloat((2 * INBUTTONOFFSET)) - CGFloat((2 * BUTTONWIDTH)), y: bounds.size.width - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                self.screenLockButton.frame = CGRect(x: bounds.size.height - CGFloat((4 * OUTHBUTTONOFFSET)) - CGFloat(INBUTTONOFFSET) - CGFloat(BUTTONWIDTH), y: bounds.size.width - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                self.sliderBackground.frame = CGRect(x: bounds.size.height - CGFloat(SLIDERWIDTH) + 4, y: bounds.size.width / 2 - CGFloat(SLIDERHEIGHT / 2) + 14, width: CGFloat(SLIDERWIDTH - 10), height: CGFloat(SLIDERHEIGHT - 27))
                self.zoomSlider.frame = CGRect(x: bounds.size.height - CGFloat(SLIDERWIDTH), y: bounds.size.width / 2 - CGFloat(SLIDERHEIGHT / 2), width: CGFloat(SLIDERWIDTH), height: CGFloat(SLIDERHEIGHT))
                
                
                self.infoButton.frame = CGRect(x: bounds.size.height - CGFloat(SLIDERWIDTH) + CGFloat((SLIDERWIDTH - INFOBUTTONWIDTH) / 2), y: CGFloat(INFOBUTTONLANDSCAPEORIENTATIONY), width: CGFloat(INFOBUTTONWIDTH), height: CGFloat(INFOBUTTONWIDTH))
                if self.isIpad() {
                    self.infoButton.frame = CGRect(x: bounds.size.height - CGFloat(SLIDERWIDTH) + CGFloat((SLIDERWIDTH - INFOBUTTONWIDTH) / 2), y: CGFloat(INFOBUTTONPORTRAITORIENTATIONY + IPADIADPORTRAITHEIGHT), width: CGFloat(INFOBUTTONWIDTH), height: CGFloat(INFOBUTTONWIDTH))
                    self.flipButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET) + CGFloat((4 * OUTHBUTTONOFFSET)) , y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))//CGRect(x: CGFloat(OUTHBUTTONOFFSET) + CGFloat((4 * OUTHBUTTONOFFSET)) , y: bounds.size.height - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                }
                // new save button
                self.saveButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: bounds.size.width - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                // new photo button
                self.photoButton.frame = CGRect(x: bounds.size.height - CGFloat((4 * OUTHBUTTONOFFSET)) - CGFloat(INBUTTONOFFSET) - CGFloat(BUTTONWIDTH), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                // new image mode button
                self.imageModeButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                //lockPortraitButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET) + CGFloat((4 * OUTHBUTTONOFFSET)) , y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                // new fix focus button
                self.lockFocusButton.frame = CGRect(x: bounds.size.height - CGFloat((4 * OUTHBUTTONOFFSET)) - CGFloat((2 * INBUTTONOFFSET)) - CGFloat((2 * BUTTONWIDTH)), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
            } else {
                // update for iOS 8.0
                self.scrollView.frame = bounds
                //stableDirectionButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: bounds.size.height - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                self.stableDirectionButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET) + CGFloat((4 * OUTHBUTTONOFFSET)), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                self.flipButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))//CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: CGFloat(2 * OUTVBUTTONOFFSET) + CGFloat(BUTTONWIDTH), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                self.flashLightButton.frame = CGRect(x: bounds.size.width - CGFloat((4 * OUTHBUTTONOFFSET)) - CGFloat((2 * INBUTTONOFFSET)) - CGFloat((2 * BUTTONWIDTH)), y: bounds.size.height - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                self.screenLockButton.frame = CGRect(x: bounds.size.width - CGFloat((4 * OUTHBUTTONOFFSET)) - CGFloat(INBUTTONOFFSET) - CGFloat(BUTTONWIDTH), y: bounds.size.height - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                
                //                infoButton.frame = CGRect(x: bounds.size.width - CGFloat(SLIDERWIDTH) + CGFloat((SLIDERWIDTH - INFOBUTTONWIDTH) / 2), y: CGFloat(INFOBUTTONLANDSCAPEORIENTATIONY), width: CGFloat(INFOBUTTONWIDTH), height: CGFloat(INFOBUTTONWIDTH))
                self.sliderBackground.frame = CGRect(x: bounds.size.width - CGFloat(SLIDERWIDTH) + 4, y: bounds.size.height / 2 - CGFloat(SLIDERHEIGHT / 2) + 24, width: CGFloat(SLIDERWIDTH - 10), height: CGFloat(SLIDERHEIGHT - 27))
                self.zoomSlider.frame = CGRect(x: bounds.size.width - CGFloat(SLIDERWIDTH), y: bounds.size.height / 2 - CGFloat(SLIDERHEIGHT / 2) + 10, width: CGFloat(SLIDERWIDTH), height: CGFloat(SLIDERHEIGHT))
                if self.isIpad() {
                    //infoButton.frame = CGRect(x: bounds.size.width - CGFloat(SLIDERWIDTH) + CGFloat((SLIDERWIDTH - INFOBUTTONWIDTH) / 2), y: CGFloat(INFOBUTTONPORTRAITORIENTATIONY + IPADIADPORTRAITHEIGHT), width: CGFloat(INFOBUTTONWIDTH), height: CGFloat(INFOBUTTONWIDTH))
                    //flipButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET) + CGFloat((4 * OUTHBUTTONOFFSET)) , y: bounds.size.height - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                }
                // new save button
                self.saveButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: bounds.size.height - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                // new photo button
                self.photoButton.frame = CGRect(x: bounds.size.width - CGFloat((4 * OUTHBUTTONOFFSET)) - CGFloat(INBUTTONOFFSET) - CGFloat(BUTTONWIDTH), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                // new image mode button
                //imageModeButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                self.imageModeButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: bounds.size.height - CGFloat(BUTTONWIDTH) - CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                //lockPortraitButton.frame = CGRect(x: CGFloat(OUTHBUTTONOFFSET), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                // new fix focus button
                self.lockFocusButton.frame = CGRect(x: bounds.size.width - CGFloat((4 * OUTHBUTTONOFFSET)) - CGFloat((2 * INBUTTONOFFSET)) - CGFloat((2 * BUTTONWIDTH)), y: CGFloat(OUTVBUTTONOFFSET), width: CGFloat(BUTTONWIDTH), height: CGFloat(BUTTONWIDTH))
                self.infoButton.frame = CGRect(x: bounds.size.width - CGFloat(SLIDERWIDTH) + CGFloat((SLIDERWIDTH - INFOBUTTONWIDTH) / 2), y: CGFloat(INFOBUTTONLANDSCAPEORIENTATIONY), width: CGFloat(INFOBUTTONWIDTH), height: CGFloat(INFOBUTTONWIDTH))
            }
        }
        }
        recoverFlash()
    }
    
    @objc func adjustCurrentOrientation() {
        
        if (ORIENTATION == .portrait) /*|| (!self.isLocked)*/ {
            //            imageOrientation = UIImage.Orientation.right.rawValue
            if isIphone4() || isIphone4S() {
                scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: CGFloat(540 * currentZoomRate), height: CGFloat(960 * currentZoomRate)))
                //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
                //                                               [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
            }
            if isIphone5() {
                scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: CGFloat(1080 * currentZoomRate), height: CGFloat(1920 * currentZoomRate)))
//                scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: CGFloat(2160), height: CGFloat(3840)))
            }
            if isIpad() {
                //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080*self.currentZoomRate, 1920*self.currentZoomRate)];
                scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width * CGFloat(currentZoomRate), height: UIScreen.main.bounds.size.height * CGFloat(currentZoomRate)))
            }
        } else if ORIENTATION.isLandscape /*(!self.isLocked)*/ {
            
            //            if ORIENTATION == .landscapeRight {
            //                //imageOrientation = UIImage.Orientation.right.rawValue
            //                imageOrientation = UIImage.Orientation.up.rawValue
            //            } else {
            //                //imageOrientation = UIImage.Orientation.right.rawValue
            //                imageOrientation = UIImage.Orientation.down.rawValue
            //            }
            
            //if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            if isIphone4() || isIphone4S() {
                scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: CGFloat(960 * currentZoomRate), height: CGFloat(540 * currentZoomRate)))
                //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
                //                                               [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
            }
            if isIphone5() {
                scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: CGFloat(1920 * currentZoomRate), height: CGFloat(1080 * currentZoomRate)))
                //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate,
                //                                                 [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate)];
            }
            if isIpad() {
                //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1920*self.currentZoomRate, 1080*self.currentZoomRate)];
                scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width * CGFloat(currentZoomRate), height: UIScreen.main.bounds.size.height * CGFloat(currentZoomRate)))
            }
            /*} else {
             if ([self isIphone4] || [self isIphone4S]) {
             [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 540*self.currentZoomRate, 960*self.currentZoomRate)];
             //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
             //                                               [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
             }
             if ([self isIphone5]) {
             [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080*self.currentZoomRate, 1920*self.currentZoomRate)];
             //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
             //                                                 [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
             // width 768, height 1024
             }
             if ([self isIpad]) {
             //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080*self.currentZoomRate, 1920*self.currentZoomRate)];
             [self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
             [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
             }
             
             }*/
        }
        /*
         else if ((self.interfaceOrientation == UIInterfaceOrientationPortrait)&& (self.isLocked)) {
         self.imageOrientation = UIImageOrientationRight;
         if ([self isIphone4] || [self isIphone4S]) {
         [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 960*self.currentZoomRate, 540*self.currentZoomRate)];
         //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
         //                                               [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
         }
         if ([self isIphone5]) {
         [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1920*self.currentZoomRate, 1080*self.currentZoomRate)];
         //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
         //                                                 [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
         // width 768, height 1024
         }
         if ([self isIpad]) {
         //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080*self.currentZoomRate, 1920*self.currentZoomRate)];
         [self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
         [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
         }
         }
         
         else if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)&& (self.isLocked)) {
         
         if ([self isIphone4] || [self isIphone4S]) {
         [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 540*self.currentZoomRate, 960*self.currentZoomRate)];
         //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
         //                                               [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
         }
         if ([self isIphone5]) {
         [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080*self.currentZoomRate, 1920*self.currentZoomRate)];
         //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate,
         //                                                 [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate)];
         }
         if ([self isIpad]) {
         //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1920*self.currentZoomRate, 1080*self.currentZoomRate)];
         [self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate,
         [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate)];
         }
         
         if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
         self.imageOrientation = UIImageOrientationUp;
         }
         else {
         self.imageOrientation = UIImageOrientationDown;
         }
         }
         */
        
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        setupControlsPosition()
        //adjustCurrentOrientation()
        scrollView.adjustImageViewCenter()
        scrollToCenter()
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//        if UIDevice.current.orientation.isLandscape {
//            print("Landscape")
//        } else {
//            print("Portrait")
//        }
//    }
    
    override var shouldAutorotate: Bool {
        if !portraitOnly {
            return interfaceOrientation != .portraitUpsideDown
        } else {
            return true
        }
    }

    func saveImageFile(_ fileName: String?, save saveImage: UIImage?) {
        var fileName = fileName
        fileName = URL(fileURLWithPath: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents").absoluteString).appendingPathComponent(fileName ?? "").absoluteString
        let fileManager = FileManager.default
        if !(fileManager.fileExists(atPath: fileName ?? "")) {
            fileManager.createFile(atPath: fileName ?? "", contents: nil, attributes: nil)
        }
        let file = FileHandle(forUpdatingAtPath: fileName ?? "")
        if let fileName = URL.init(string: fileName ?? "") {
            let saveImageData = saveImage?.jpegData(compressionQuality: 1)
            try? saveImageData?.write(to: fileName)
        }
        file?.closeFile()
    }
    
    func readImageFile(_ fileName: String?) -> UIImage? {
        var fileName = fileName
        fileName = URL(fileURLWithPath: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents").absoluteString).appendingPathComponent(fileName ?? "").absoluteString
        let fileManager = FileManager.default
        if !(fileManager.fileExists(atPath: fileName ?? "")) {
            print("file \(fileName ?? "") not exist!\n")
            return nil
        }
        let imageFile = UIImage(contentsOfFile: fileName ?? "")
        return imageFile
    }
    
    // MARK: -
    // MARK: Capture Management
    func getDistance(_ g: Float, offset: Float) -> Float {
        if SYSTEM_VERSION_LESS_THAN(version: "8.0") {
            return 360
        }
        let lens = (captureDevice?.lensPosition ?? 0.0) - offset * g
        var distance = 1 / (-0.3929 * lens + 0.2986)
        if AppDelegate.isIpadAir() {
            distance = 1 / (-0.4985 * lens + 0.3524)
        }
        if distance < 0 || distance > 360 {
            distance = 360
        }
        return distance
    }
    
    // Map focus level
    func getLevel(_ g: Float, offset: Float) -> Int {
        let distance = getDistance(g, offset: offset)
        var focusLevel = 400
        if distance < 39.4 {
            // Divide by 1 can downward round float number into int
            let temp = Int((39.4 / distance) / 1)
            focusLevel = Int((39.4 / Double(temp)) / 1)
        } else if distance <= 394 {
            let temp = Int((394 / distance) / 1)
            focusLevel = (394 / temp) / 1
        }
        //NSLog(@"%@%ld", @"Focus level: ", (long)focusLevel);
        return focusLevel
    }
    
    func getAngle() -> Float {
        let g = accelerometer?.getCurrent() ?? 0.0
        //   float g = _accelerometer -> getCurrent();
        /*if (g > 1) {
         g = 1;
         }
         if (g < -1) {
         g = -1;
         }*/
        let angle: Float = acos(g) / .pi * 180
        print("g = \(g), angle = \(angle)")
        return 0
    }
    
    func getOffset() -> Float {
        /*if ([self isIphone5]) {
         return 0.14;
         }*/
        return 0.16
    }
    
    func getCorrectedLensPosition(_ g: Float, offset: Float) -> Float {
        if SYSTEM_VERSION_LESS_THAN(version: "8.0") {
            return 360
        }
        let lens = (captureDevice?.lensPosition ?? 0.0) - offset * g
        return lens
    }
    
    func checkFocusChange() {
        if counter == FRAMES {
            counter = 0
            //float angle = [self getAngle];
            let offset = getOffset()
            let level = getLevel(accelerometer?.getCurrent() ?? 0.0, offset: offset) //[self getLevel:_accelerometer -> getCurrent() offset:offset];
            //NSLog(@"focus level = %ld", (long)level);
            //[self displayMessage:[NSString stringWithFormat:@"level = %ld, lens = %.04f", (long)[self getLevel:_accelerometer -> getCurrent() offset:offset], self.captureDevice.lensPosition]];
            if level != lensPosition {
                var seconds: Float? = nil
                if let focusTimer = focusTimer {
                    seconds = Float(Date().timeIntervalSince(focusTimer))
                }
                if (seconds ?? 0.0) >= 3 {
                    let label = String(format: "%ld", lensPosition)
                    sendFocusLevelMetrics(label: label)
//                    if isiPhone() {
//                        Umeng.endEvent("FocusLevel_iPhone", primarykey: "FocusLevel_iPhone", value: label)
//                    }
//                    if isIpad() {
//                        Umeng.endEvent("FocusLevel_iPad", primarykey: "FocusLevel_iPad", value: label)
//                    }
                }
                let label = String(format: "%ld", level)
                sendFocusLevelMetrics(label: label)
//                if isiPhone() {
//                    Umeng.beginEvent("FocusLevel_iPhone", primarykey: "FocusLevel_iPhone", value: label)
//                }
//                if isIpad() {
//                    Umeng.beginEvent("FocusLevel_iPad", primarykey: "FocusLevel_iPad", value: label)
//                }
                lensPosition = level
                focusTimer = Date()
            }
        } else {
            counter += 1
        }
    }
    
    func sendUnitImageSizeOnZoomChange() {
        let offset = getOffset()
        let lens = getCorrectedLensPosition(accelerometer?.getCurrent() ?? 0.0, offset: offset)
        var reciDist = (-0.3929 * lens + 0.2986)
        if (reciDist.isLessThanOrEqualTo(0.02)) {
            reciDist = 0.02
        }
        let x = (reciDist) * currentZoomRate * 100
        let unitImageSize: Int = Int(x.rounded())
        let label = String(format: "%ld", unitImageSize)
        var mutableDictionary: [AnyHashable : Any] = [:]
        if checkAccessibilityEnabled() {
            if GROUP_ID != nil && STUDY_ID != nil {
                mutableDictionary["\(STUDY_ID ?? "") VI"] = Umeng.appendGroup(to: label)
            } else {
                mutableDictionary["VI"] = Umeng.appendGroup(to: label)
            }
            if isiPhone() {
                MobClick.beginEvent("UnitImageSize_iPhone", primarykey: "UnitImageSize_iPhone", attributes: mutableDictionary)
                MobClick.endEvent("UnitImageSize_iPhone", primarykey: "UnitImageSize_iPhone")
            }
            if isIpad() {
                MobClick.beginEvent("UnitImageSize_iPad", primarykey: "UnitImageSize_iPad", attributes: mutableDictionary)
                MobClick.endEvent("UnitImageSize_iPad", primarykey: "UnitImageSize_iPad")
            }
        } else {
            if isiPhone() {
                Umeng.beginEvent("UnitImageSize_iPhone", primarykey: "UnitImageSize_iPhone", value: label)
                Umeng.endEvent("UnitImageSize_iPhone", primarykey: "UnitImageSize_iPhone", value: label)
            }
            if isIpad() {
                Umeng.beginEvent("UnitImageSize_iPad", primarykey: "UnitImageSize_iPad", value: label)
                Umeng.endEvent("UnitImageSize_iPad", primarykey: "UnitImageSize_iPad", value: label)
            }
        }
        UserDefaults.standard.set(lens, forKey: "correctedLensPos")
    }
    
    //Positon1
    func checkCorrectedLensPosition() {
        let offset = getOffset()
        let lens = getCorrectedLensPosition(accelerometer?.getCurrent() ?? 0.0, offset: offset)
        if (UserDefaults.standard.value(forKey: "correctedLensPos") != nil) {
            let oldLensPos = UserDefaults.standard.float(forKey: "correctedLensPos")
            let diff = oldLensPos.isLess(than: lens) ? lens - oldLensPos : oldLensPos - lens
            if (!diff.isLess(than: 0.1)) {
                var reciDist = (-0.3929 * lens + 0.2986)
                if (reciDist.isLessThanOrEqualTo(0.02)) {
                    print("dikg: \(reciDist)")
                    reciDist = 0.02
                }
                let x = (reciDist) * currentZoomRate * 100
                let unitImageSize: Int = Int(x.rounded())
                let label = String(format: "%ld", unitImageSize)
                var mutableDictionary: [AnyHashable : Any] = [:]
                if checkAccessibilityEnabled() {
                    if GROUP_ID != nil && STUDY_ID != nil {
                        mutableDictionary["\(STUDY_ID ?? "") VI"] = Umeng.appendGroup(to: label)
                    } else {
                        mutableDictionary["VI"] = Umeng.appendGroup(to: label)
                    }
                    if isiPhone() {
                        MobClick.beginEvent("UnitImageSize_iPhone", primarykey: "UnitImageSize_iPhone", attributes: mutableDictionary)
                        MobClick.endEvent("UnitImageSize_iPhone", primarykey: "UnitImageSize_iPhone")
                    }
                    if isIpad() {
                        MobClick.beginEvent("UnitImageSize_iPad", primarykey: "UnitImageSize_iPad", attributes: mutableDictionary)
                        MobClick.endEvent("UnitImageSize_iPad", primarykey: "UnitImageSize_iPad")
                    }
                } else {
                    if isiPhone() {
                        Umeng.beginEvent("UnitImageSize_iPhone", primarykey: "UnitImageSize_iPhone", value: label)
                        Umeng.endEvent("UnitImageSize_iPhone", primarykey: "UnitImageSize_iPhone", value: label)
                    }
                    if isIpad() {
                        Umeng.beginEvent("UnitImageSize_iPad", primarykey: "UnitImageSize_iPad", value: label)
                        Umeng.endEvent("UnitImageSize_iPad", primarykey: "UnitImageSize_iPad", value: label)
                    }
                }
            }
        }
        UserDefaults.standard.set(lens, forKey: "correctedLensPos")
    }
    
    func checkAccessibilityEnabled() -> Bool {
        let largerText = UIApplication.shared.preferredContentSizeCategory.rawValue
        if (UIAccessibility.isVoiceOverRunning || UIAccessibility.isSpeakScreenEnabled || UIAccessibility.isSpeakSelectionEnabled || UIAccessibility.isInvertColorsEnabled || largerText.contains("Accessibility")) {
            return true
        }
        return false
    }
    
    func focusCanNotChange() -> Bool {
        if AppDelegate.beforeIpad2() {
            return true
        }
        return false
    }
    
    func addFilter(_ cgImageRef: CGImage?) -> UIImage? {
        // add filter
        var image: CIImage? = nil
        if let cgImageRef = cgImageRef {
            image = CIImage(cgImage: cgImageRef)
        }
        
        // color black and white
        let photoEffectMono = CIFilter(name: "CIPhotoEffectMono")
        photoEffectMono?.setDefaults()
        photoEffectMono?.setValue(image, forKey: "inputImage")
        image = photoEffectMono?.value(forKey: "outputImage") as? CIImage
        
        // color invert filter
        let colorInvertFilter = CIFilter(name: "CIColorInvert")
        colorInvertFilter?.setDefaults()
        colorInvertFilter?.setValue(image, forKey: "inputImage")
        image = colorInvertFilter?.value(forKey: "outputImage") as? CIImage
        
        // color control filter
        let colorControlsFilter = CIFilter(name: "CIColorControls")
        colorControlsFilter?.setDefaults()
        colorControlsFilter?.setValue(NSNumber(value: 5), forKey: "inputContrast")
        colorControlsFilter?.setValue(image, forKey: "inputImage")
        image = colorControlsFilter?.value(forKey: "outputImage") as? CIImage
        return makeUIImage(from: image)
    }
    
    func checkResetExposure() {
        if isExposureAdjusted {
            let captureDeviceIso = captureDevice?.iso ?? 0.0
            let exposureDuration = Float(captureDevice?.exposureDuration.value ?? Int64(0.0))
            
            if iso * Float(duration.value) / Float((captureDeviceIso * exposureDuration)) > 3 || Float(captureDeviceIso * exposureDuration) / (iso * Float(duration.value)) > 3 {
                isTapped = false
                isExposureAdjusted = false
                resetExposure()
                //NSLog(@"tapLensPosition = %f, lensPosition = %f", self.tapLensPosition, self.captureDevice.lensPosition);
                //NSLog(@"origina = %f, current = %f", self.ISO * self.duration.value, self.captureDevice.ISO * self.captureDevice.exposureDuration.value);
                print("reset exposure")
            }
        }
    }
    
    func makeUIImage(from ciImage: CIImage?) -> UIImage? {
        // create the CIContext instance, note that this must be done after _videoPreviewView is properly set up
        //EAGLContext *_eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        ////CIContext *cicontext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]}];
        //CIContext *cicontext = [CIContext contextWithEAGLContext:_eaglContext options:nil];
        //CIContext *cicontext = [CIContext contextWithOptions:nil];
        let cicontext = CIContext(options: [
            CIContextOption.workingColorSpace: NSNull()
        ])
        // finally!
        var returnImage: UIImage?
        var processedCGImage: CGImage? = nil
        if let ciImage = ciImage {
            processedCGImage = cicontext.createCGImage(ciImage, from: ciImage.extent ?? CGRect.zero)
        }
        if let processedCGImage = processedCGImage, let imageOrientation1 = UIImage.Orientation(rawValue: imageOrientation) {
            returnImage = UIImage(cgImage: processedCGImage, scale: 1, orientation: imageOrientation1)
        }
        return returnImage
    }
    
    // MARK: - controller activities
    func setMinimalZoomScale(_ minScale: Float) {
        print("Minimum zoom scale:\(minScale)")
        if (AppDelegate.isIpad()) {
            scrollView.minimumZoomScale = CGFloat(minScale)
            zoomSlider.minimumValue = minScale
        } else {
            scrollView.minimumZoomScale = 1
            zoomSlider.minimumValue = 1
        }
    }
    
    func getCamera(with deviceType: AVCaptureDevice.DeviceType) -> AVCaptureDevice? {
        guard let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] else {
            return nil
        }
        
        return devices.filter {
            $0.deviceType == deviceType
            }.first
    }
    
    func lockOneSecond(){
        if isIphone5() || isIpad() {
            print("Lock 111")
            isLocked = false
            beforeLock = true
            reSet()
        } else {
            beforeLock = true
            isLocked = false
            //  1080p
            currentResolution = IP5RESOLUTION.rawValue
            resolutionWidth = 1080
            resolutionHeight = 1920
            //  if 1080p not available set 720p
            if !(captureSession?.canSetSessionPreset(AVCaptureSession.Preset(rawValue: currentResolution!)) ?? false) {
                currentResolution = RESOLUTION2.rawValue
                resolutionWidth = 720
                resolutionHeight = 1280
            }
            captureSession?.beginConfiguration()
            captureSession?.sessionPreset = AVCaptureSession.Preset(rawValue: currentResolution!)
            captureSession?.commitConfiguration()
            recoverFlash()
            correctContentOffset = scrollView.contentOffset
            print("Decapitated: \(correctContentOffset)")
            reSet()
        }
    }
    
    func unLockOneSecond(){
        if isIphone5() || isIpad() {
            print("Lock 222")
            beforeLock = false
            isLocked = false
            scrollToCenter()
            reSet()
        }
        if isIphone4() || isIphone4S() {
            currentResolution = IP4RESOLUTION.rawValue
            captureSession?.beginConfiguration()
            captureSession?.sessionPreset = AVCaptureSession.Preset(rawValue: currentResolution!)
            captureSession?.commitConfiguration()
            recoverFlash()
            isLocked = false
            beforeLock = false
            adjustForLowResolution()
            scrollToCenter()
            resolutionWidth = 540
            resolutionHeight = 960
            reSet()
        }
    }
    
    func setCameraInput(){
        var error: Error?
        var captureInput: AVCaptureDeviceInput? = nil
        do {
            if let captureDevice = captureDevice {
                captureInput = try AVCaptureDeviceInput(device: captureDevice)
            }
        } catch {
        }
        if error == nil {
            if let captureInput = captureInput {
                print("test 333")
//                lockOneSecond()
                captureSession?.beginConfiguration()
                if let inputs = captureSession?.inputs as? [AVCaptureDeviceInput] {
                    captureSession?.removeInput(inputs[0])
                }
                captureSession?.addInput(captureInput)
//                unLockOneSecond()
                captureSession?.commitConfiguration()
            }
        } else {
            let errorAlert = UIAlertView(title: "Error", message: "No permission to get access to camera.", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
            errorAlert.show()
        }
    }
    
    func setZoomScale(_ ZoomScale: Float) {
        //xuan setZoomScale
//        if(is_Singal){
//            print("NO need to switch")
//        }else if (isPro()){
//
//        }else if #available(iOS 13.0, *) {
//            if(currentZoomRate > Float(A_near) && isNear){
//
//                captureDevice = AVCaptureDevice.default(farCam, for: .video, position: .back)
//                isNear = false;
//                cameraType.text = "Far Camera :" + String(format:"%.1f",currentZoomRate)
//
//                setCameraInput()
//
//            }else if(currentZoomRate < Float(A_far) && !isNear){
//
//                captureDevice = AVCaptureDevice.default(nearCam, for: .video, position: .back)
//
//                isNear = true;
//                cameraType.text = "Near Camera :" + String(format:"%.1f",currentZoomRate)
//
//                setCameraInput()
//            }
//        }
        
        if ((captureDevice?.hasMediaType(.video)) != nil) && (captureDevice?.position == .back) {
            do {
                try captureDevice?.lockForConfiguration()
            } catch {

            }
            self.currentZoomRate = ZoomScale
            zoomSlider.value = currentZoomRate

            //xuan setZoomScale2
//            print(captureDevice?.activeFormat.videoMaxZoomFactor as Any)
//            captureDevice?.ramp(toVideoZoomFactor: ceil(CGFloat(currentZoomRate)), withRate: 1.0)
            
            //to get the scale bettwen near camera and far camera
            if(near_FOV != -1 && far_FOV != -1){
                diff_scale = near_FOV/far_FOV
            }
            if(!isNear){
                captureDevice?.videoZoomFactor = minMaxZoom(CGFloat(max(currentZoomRate/diff_scale, 1)))
            }else{
                captureDevice?.videoZoomFactor = minMaxZoom(CGFloat(max(currentZoomRate, 1)))
            }
            
            if let FOV = captureDevice?.activeFormat.videoFieldOfView {
                if(isNear && near_FOV == -1){
                    let radians_FOV = FOV*Float((Double.pi/180.0));
                    near_FOV = tan(radians_FOV/2)
                    print("FOV nwide: ",near_FOV)
                }
                if(!isNear && far_FOV == -1){
                    let radians_FOV = FOV*Float((Double.pi/180.0));
                    far_FOV = tan(radians_FOV/2)
                    print("FOV fwide: ",far_FOV)
                }
                
            }
            scrollView.adjustImageViewCenter()
            scrollToCenter()
            captureDevice?.unlockForConfiguration()
        }
//        print("Current zoom rate:\(ZoomScale)")
//        self.currentZoomRate = ZoomScale
//        zoomSlider.value = currentZoomRate
//        scrollView.zoomScale = CGFloat(currentZoomRate)
//        scrollView.adjustImageViewCenter()
//        scrollToCenter()
    }
    
    func showHelp() {
        let screenBounds = view.bounds
        let fromFrame = CGRect(x: 0.0, y: screenBounds.size.height, width: screenBounds.size.width, height: screenBounds.size.height)
        let toFrame = screenBounds
        
        helpViewController = HelpViewController(nibName: "HelpViewController", bundle: nil)
        if let helpViewController = helpViewController {
            addChild(helpViewController)
        }
        helpViewController?.view.frame = fromFrame
        if let view = helpViewController?.view {
            self.view.addSubview(view)
        }
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn, animations: {
            self.helpViewController?.view.frame = toFrame
        }) { finished in
            self.helpViewController?.didMove(toParent: self)
        }
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        if isIpad() {
            Umeng.event("InfoButtonTouched", value: "iPad")
        } else {
            Umeng.event("InfoButtonTouched", value: "iPhone")
        }
        showHelp()
    }
    
    @IBAction func imageModeTapped() {
        if isImageModeOn {
            imageModeButton.isSelected = false
            if isIpad() {
                Umeng.endEvent("ImageMode_iPad", primarykey: "ImageMode_iPad", value: "Enh-Inv")
            }
            if isiPhone() {
                Umeng.endEvent("ImageMode_iPhone", primarykey: "ImageMode_iPhone", value: "Enh-Inv")
            }
        } else {
            if isIpad() {
                Umeng.beginEvent("ImageMode_iPad", primarykey: "ImageMode_iPad", value: "Enh-Inv")
            }
            if isiPhone() {
                Umeng.beginEvent("ImageMode_iPhone", primarykey: "ImageMode_iPhone", value: "Enh-Inv")
            }
            imageModeButton.isSelected = true
        }
        isImageModeOn = !isImageModeOn
        storeData()
    }
    
    func savePhoto(_ name: String?) {
//        let image = isFlipped && AppDelegate.isIpadPro() ? highVarImg?.fixedOrientation() : normalizedImage(highVarImg)
//        if (AppDelegate.isIpadPro()) {
//            alertViewForTesting(image)
//        }
        var image: UIImage?
        if (AppDelegate.isIpad()) {
            image = highVarImg?.fixedOrientation()
        } else {
            image = normalizedImage(highVarImg)
        }
        
        let pathArr = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let path = URL(fileURLWithPath: pathArr[0]).appendingPathComponent(name ?? "")
        if let data = image?.pngData() {
            do {
                try data.write(to: path)
            } catch (let error) {
                print (error.localizedDescription)
            }
            
        }
    }
    
    func flipHorizontally(_ image: UIImage?) -> UIImage? {
        if lockInterfaceOrientation.isLandscape {
            print("american pie")
            return image
        }
        
        print("Pink Floyd")
        
        /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly).
         Same thing as for the CALayer we are not in the main thread so ...*/
        // just change orientation for image rendering, its width and height does not change!!
        var originalUIImage: UIImage? = nil
        if let imageOrientation1 = UIImage.Orientation(rawValue: mirroredImageOrientation) {
            originalUIImage = UIImage(cgImage: self.lockedCGImage!, scale: image!.scale, orientation: imageOrientation1)
        }
        return originalUIImage
    }
    
    func normalizedImage(_ image: UIImage?) -> UIImage? {
        if lockInterfaceOrientation.isLandscape {
            return image
        }
        //alertViewForTesting(image)
        
        UIGraphicsBeginImageContextWithOptions(image?.size ?? CGSize.zero, _: false, _: image?.scale ?? 0.0)
        let imageSize = image?.size ?? .zero
        image?.draw(in: CGRect.init(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }
    
    func alertViewForTesting(_ arr: [String]) {
        let alertVC = UIAlertController.init(title: "Blackbox testing", message: "The following objects were detected: \(arr)", preferredStyle: UIAlertController.Style.alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertVC, animated: true, completion: nil)
    }
    
    func normalizedFlippedImage(_ image: UIImage?) -> UIImage? {
        if lockInterfaceOrientation.isLandscape {
            return image
        }
        UIGraphicsBeginImageContextWithOptions(image?.size ?? CGSize.zero, _: false, _: image?.scale ?? 0.0)
        let imageSize = image?.size ?? .zero
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: imageSize.width, y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        //        context.translateBy(x: -imageSize.width, y: imageSize.height)
        //        context.scaleBy(x: -(image?.scale ?? 0.0), y: -(image?.scale ?? 0.0))
        image?.draw(in: CGRect.init(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        //NSString *name = [NSString stringWithFormat:@"img%ld.data", (unsigned long)self.photoData.count];
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let date = Date()
        let name = dateFormatter.string(from: date)
        
//        retrieveData()
        photoData?.append(name)
        savePhoto(name)
        print(photoData as Any)
        storeData()
        
        saveButton.isHidden = true
        if AppDelegate.isiPhone() {
            Umeng.event("SavePicture", value: "iPhone")
        }
        if AppDelegate.isIpad() {
            Umeng.event("SavePicture", value: "iPad")
        }
    }
    
    
    func showPhotoViewController() {
        let screenBounds = view.bounds
        let fromFrame = CGRect(x: 0.0, y: screenBounds.size.height, width: screenBounds.size.width, height: screenBounds.size.height)
        let toFrame = screenBounds
        
        let photoStoryBoard = UIStoryboard(name: "Photo", bundle: nil)
        let navigationController = photoStoryBoard.instantiateInitialViewController() as? UINavigationController
        if let navigationController = navigationController {
            self.addChild(navigationController)
        }
        navigationController?.view.frame = fromFrame
        if let view = navigationController?.view {
            self.view.addSubview(view)
        }
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn, animations: {
            navigationController?.view.frame = toFrame
        }) { finished in
            navigationController?.didMove(toParent: self)
        }
    }
    
    func showEmpty() {
        let screenBounds = view.bounds
        let fromFrame = CGRect(x: 0.0, y: screenBounds.size.height, width: screenBounds.size.width, height: screenBounds.size.height)
        let toFrame = screenBounds
        
        let emptyStoryBoard = UIStoryboard(name: "Empty", bundle: nil)
        let navigationController = emptyStoryBoard.instantiateInitialViewController() as? UINavigationController
        if let navigationController = navigationController {
            addChild(navigationController)
        }
        navigationController?.view.frame = fromFrame
        if let view = navigationController?.view {
            self.view.addSubview(view)
        }
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn, animations: {
            navigationController?.view.frame = toFrame
        }) { finished in
            navigationController?.didMove(toParent: self)
        }
    }
    
    @IBAction func photoButtonTapped(_ sender: Any) {
        retrieveData()
        if photoData?.count == 0 {
            showEmpty()
        } else {
            showPhotoViewController()
        }
        if AppDelegate.isiPhone() {
            MobClick.beginEvent("ShowPicutures", label: "iPhone")
        }
        if AppDelegate.isIpad() {
            MobClick.beginEvent("ShowPicutures", label: "iPad")
        }
    }
    
    func resetExposure() {
        let devices = AVCaptureDevice.devices()
        var error: Error?
        for device in devices {
            if (device.hasMediaType(.video)) && (device.position == .back) {
                do {
                    try device.lockForConfiguration()
                } catch {
                }
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    let autoExposurePoint = CGPoint(x: 0.5, y: 0.5)
                    device.exposurePointOfInterest = autoExposurePoint
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
            }
        }
        unlockAutoFocus()
    }
    
    func lockFocus() {
        let devices = AVCaptureDevice.devices()
        var error: Error?
        for device in devices {
            if (device.hasMediaType(.video)) && (device.position == .back) {
                do {
                    try device.lockForConfiguration()
                } catch {
                }
                if device.isFocusModeSupported(.locked) {
                    device.focusMode = .locked
                    print("Focus locked")
                }
                
                device.unlockForConfiguration()
            }
        }
    }
    
    func unlockFocus() {
        let devices = AVCaptureDevice.devices()
        var error: Error?
        for device in devices {
            if (device.hasMediaType(.video)) && (device.position == .back) {
                do {
                    try device.lockForConfiguration()
                } catch {
                }
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                    print("Focus unlocked")
                }
                device.unlockForConfiguration()
            }
        }
    }
    
    //  hide all interface controls
    func hideAllControls() {
        stableDirectionButton.isHidden = true
        flashLightButton.isHidden = true
        screenLockButton.isHidden = true
        //[self.infoButton setHidden:YES];
        zoomSlider.isHidden = true
        sliderBackground.isHidden = true
        imageModeButton.isHidden = true
        lockFocusButton.isHidden = true
        photoButton.isHidden = true
        flipButton.isHidden = true
    }
    
    //  show all interface controls
    func showAllcontrols() {
        stableDirectionButton.isHidden = false
        flashLightButton.isHidden = false
        screenLockButton.isHidden = false
        //[self.infoButton setHidden:NO];
        zoomSlider.isHidden = false
        sliderBackground.isHidden = false
        if isIpad() && !isIpadPro() {
            flashLightButton.isHidden = true
        }
        imageModeButton.isHidden = false
        lockFocusButton.isHidden = false
        photoButton.isHidden = false
        flipButton.isHidden = false
    }
    
    @IBAction func zoomSliderChanged(_ sender: Any) {
        let scale = zoomSlider.value
        label?.text = "\(scale)"
        //        if ORIENTATION.isPortrait {
        //            imageOrientation = UIImage.Orientation.right.rawValue
        //        } else if ORIENTATION == .landscapeLeft {
        //            imageOrientation = UIImage.Orientation.down.rawValue
        //        } else {
        //            imageOrientation = UIImage.Orientation.up.rawValue
        //        }
        if isLocked {
            scrollView.setZoomScale(CGFloat(scale), animated: false)
            setZoomScale(scale)
        } else {
            scrollView.setZoomScale(CGFloat(scale), animated: false)
            setZoomScale(scale)
            currentZoomRate = scale
        }
        
        UserDefaults.standard.set(currentZoomRate, forKey: "Zoom Scale")
    }
    
    @objc func pinch(pinch: UIPinchGestureRecognizer) {
        let vZoomFactor = ((pinchGesture as! UIPinchGestureRecognizer).scale)
        print("pinch activated")
        var error: NSError!
            do{
                try captureDevice?.lockForConfiguration()
                defer {captureDevice?.unlockForConfiguration()}
                if (vZoomFactor <= captureDevice?.activeFormat.videoMaxZoomFactor ?? 1.0){
                    captureDevice?.videoZoomFactor = vZoomFactor
                    print("pinch \(vZoomFactor)")
                    
                    zoomSlider.value = Float(vZoomFactor)
                }else{
                    NSLog("Unable to set videoZoom: (max %f, asked %f)", captureDevice?.activeFormat.videoMaxZoomFactor ?? 1.0, vZoomFactor);
                }
            }catch error as NSError{
                 NSLog("Unable to set videoZoom: %@", error.localizedDescription);
            }catch _{

            }
    }
    
    @IBAction func horizontalStableButtonTapped(_ sender: Any) {
        if isHorizontalStable {
            isHorizontalStable = false
            stableDirectionButton.setImage(UIImage(named: String(utf8String: TWOSTABLEPNG) ?? ""), for: .normal)
        } else {
            isHorizontalStable = true
            stableDirectionButton.setImage(UIImage(named: String(utf8String: ONESTABLEPNG) ?? ""), for: .normal)
        }
        storeData()
    }
    
    //  lock auto focus
    func addFocusObserver() {
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if (device.hasMediaType(.video)) && (device.position == .back) {
                let flags: NSKeyValueObservingOptions = .new
                device.addObserver(self, forKeyPath: "adjustingFocus", options: flags, context: nil)
            }
        }
        self.addObserver(self, forKeyPath: "captureDevice.adjustingFocus", options: .new, context: nil)
    }
    
    func removeFocusObserver() {
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if (device.hasMediaType(.video)) && (device.position == .back) {
                device.removeObserver(self, forKeyPath: "adjustingFocus")
            }
        }
        self.removeObserver(self, forKeyPath: "captureDevice.adjustingFocus")
    }
    
    // callback
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "adjustingFocus" {
            if let newvalue = change?[NSKeyValueChangeKey.newKey] as? NSNumber,
                newvalue.intValue == 1 {
                if self.adjustingFocus && !self.adjustingFocus {
                    self.adjustingFocus = false
                } else {
                    self.adjustingFocus = true
                }
            }
            if isIphone5() {
                print("adjustingFocus")
                scrollView.adjustImageViewCenter()
                scrollToCenter()
            }
        }
        if keyPath == "currentZoomRate" {
            zoomSlider.value = currentZoomRate
            scrollView.zoomScale = CGFloat(currentZoomRate)
            print("currentZoomRate")
            scrollView.adjustImageViewCenter()
            scrollToCenter()
        }
    }
    
    //    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    ////        if (keyPath == "adjustingFocus") {
    ////            let adjustFocus = change?[.newKey] == NSNumber(value: 1)
    ////            //NSLog(@"Is adjusting focus? %@", adjustFocus ?@"YES":@"NO");
    ////            //NSLog(@"Change dictionary: %@", change);
    ////            if (adjustingFocus == true) && (adjustFocus == false) {
    ////                adjustingFocus = false
    ////            } else {
    ////                adjustingFocus = true
    ////            }
    ////        }
    //        if (keyPath == "currentZoomRate") {
    //        }
    //    }
    
    //  unlock auto focus
    func recoverFlash() {
        let device = AVCaptureDevice.default(for: .video)
        if isFlashOn {
            if (device?.torchMode == .off) {
                turnFlashOn()
            }
        } else {
            if (device?.torchMode == .on) {
                turnFlashOff()
            }
        }
    }
    
    func turnFlashOn() {
        let flashOffImage = UIImage(named: String(utf8String: FLASHOFFPNG) ?? "")
        flashLightButton.setImage(flashOffImage, for: .normal)
        let device = captureDevice//AVCaptureDevice.default(for: .video)
        if device?.hasTorch ?? false {
            do {
                try device?.lockForConfiguration()
            } catch {
            }
            device?.torchMode = .on
            if isIpadPro() {
                Umeng.beginEvent("Flashlight", primarykey: "Flashlight", value: "iPad")
            } else {
                Umeng.beginEvent("Flashlight", primarykey: "Flashlight", value: "iPhone")
            }
            //  use AVCaptureTorchModeOff to turn off
            device?.unlockForConfiguration()
        }
    }
    
    func turnFlashOff() {
        let flashOffImage = UIImage(named: String(utf8String: FLASHONPNG) ?? "")
        flashLightButton.setImage(flashOffImage, for: .normal)
        let device = captureDevice//AVCaptureDevice.default(for: .video)
        if device?.hasTorch ?? false {
            do {
                try device?.lockForConfiguration()
            } catch {
                print(error)
            }
            if isIpadPro() {
                Umeng.beginEvent("Flashlight", primarykey: "Flashlight", value: "iPad")
            } else {
                Umeng.endEvent("Flashlight", primarykey: "Flashlight", value: "iPhone")
            }
            device?.torchMode = .off
            
            //  use AVCaptureTorchModeOff to turn off
            device?.unlockForConfiguration()
        }
    }
    
    @IBAction func flashButtonTapped(_ sender: UIButton?) {
        if isFlashOn {
            isFlashOn = false
            turnFlashOff()
        } else {
            isFlashOn = true
            turnFlashOn()
        }
    }
    
    func adjustForHighResolution() {
        /* needs rescaling sicne resolution changed! for
         iphone4 and 4s other than iPhone5. */
        var adjustScale: Float = Float(540.0 / Double(resolutionWidth))
        //  iPhone4 needs further more zooming scale, no idea why!
        if isIphone4() {
            adjustScale = adjustScale * 1
        }
        DispatchQueue.main.async {
            let newMax = self.scrollView.maximumZoomScale * CGFloat(adjustScale)
            let newMin = self.scrollView.minimumZoomScale * CGFloat(adjustScale)
            self.scrollView.maximumZoomScale = newMax
            self.scrollView.minimumZoomScale = newMin
            self.currentZoomRate = Float(self.scrollView.zoomScale) * adjustScale
            self.scrollView.zoomScale = CGFloat(self.currentZoomRate)
            self.zoomSlider.maximumValue = Float(newMax)
            self.zoomSlider.minimumValue = Float(newMin)
            self.zoomSlider.setValue(self.currentZoomRate, animated: false)
        }
        
        //    self.correctContentOffset = CGPointMake(self.correctContentOffset.x*adjustScale, self.correctContentOffset.y*adjustScale);
        if ORIENTATION.isPortrait {
            scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: CGFloat(Float(resolutionWidth) * currentZoomRate), height: CGFloat(Float(resolutionHeight) * currentZoomRate)))
        } else {
            scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: CGFloat(Float(resolutionHeight) * currentZoomRate), height: CGFloat(Float(resolutionWidth) * currentZoomRate)))
        }
    }
    
    func adjustForLowResolution() {
        /* needs rescaling sicne resolution changed! for
         iphone4 and 4s other than iPhone5. */
        var adjustScale: Float = Float(Double(resolutionWidth) / 540.0)
        //  iPhone 4 needs more zooming scale, no idea why!
        if isIphone4() {
            adjustScale = adjustScale / 1
        }
        let newMax = scrollView.maximumZoomScale * CGFloat(adjustScale)
        let newMin = scrollView.minimumZoomScale * CGFloat(adjustScale)
        scrollView.maximumZoomScale = newMax
        scrollView.minimumZoomScale = newMin
        currentZoomRate = Float(scrollView.zoomScale) * adjustScale
        scrollView.zoomScale = CGFloat(currentZoomRate)
        zoomSlider.maximumValue = Float(newMax)
        zoomSlider.minimumValue = Float(newMin)
        zoomSlider.setValue(currentZoomRate, animated: false)
        //    self.correctContentOffset = CGPointMake(self.correctContentOffset.x*adjustScale, self.correctContentOffset.y*adjustScale);
        if ORIENTATION.isPortrait {
            scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: CGFloat(540 * currentZoomRate), height: CGFloat(960 * currentZoomRate)))
        } else {
            scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: CGFloat(960 * currentZoomRate), height: CGFloat(540 * currentZoomRate)))
        }
    }
    
    func scrollToCenter() {
        DispatchQueue.main.async {
//            let toCenter = CGPoint(x: self.scrollView.contentSize.width / 2 - self.scrollView.frame.size.width / 2, y: self.scrollView.contentSize.height / 2 - self.scrollView.frame.size.height / 2)
            let toCenter = CGPoint(x: self.scrollView.contentSize.width / 2 - self.scrollView.frame.size.width / 2, y: self.scrollView.contentSize.height / 2 - self.scrollView.frame.size.height / 2)
            self.scrollView.layoutIfNeeded()
            self.scrollView.setContentOffset(toCenter, animated: false)
        }
    }
    
    // enter background, end clock for locking.
    // recover from background, start clock for locking.
    @IBAction func lockButtonTapped(_ sender: UIButton?) {
        //     if touch to unlock screen
        lockOrNot()
    }
    
    //Tan change!!!
    //********获取系统当前音量大小
    private func getSystemVolumValue() -> Float {
        do{
            try AVAudioSession.sharedInstance().setActive(true)
        }catch let error as NSError{
            print("\(error)")
        }
        let currentVolume = AVAudioSession.sharedInstance().outputVolume
        return currentVolume
    }
    
    //调节系统音量大小
    private func setSysVolum(_ value: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = value
        }
    }


    
    func lockOrNot(){
        if isLocked {
            unlockScreen()
            return
        } else {
            lockScreen()
        }
        adjustCurrentOrientation()
        setupControlsPosition()
    }
    
    func unlockScreen() {
        print("Unlock phone")
        // change ui to unlocked
        unlockedUserInterface()
        // trace lock tapped.
        var seconds: Float = 0.0
        if let lockTimer = lockTimer {
            seconds = Float(Date().timeIntervalSince(lockTimer))
        }
        if seconds >= 1 {
            if isiPhone() {
                Umeng.event("Snapshot", value: "iPhone", durations: Int((seconds ?? 0.0)))
            }
            if isIpad() {
                Umeng.event("Snapshot", value: "iPad", durations: Int((seconds ?? 0.0)))
            }
        }
        //        [self.scrollView.pinchGestureRecognizer setEnabled:NO];
        //        [self.scrollView setScrollEnabled:NO];
        
        if isIphone5() || isIpad() {
            print("Lock 333 phone")
            beforeLock = false
            isLocked = false
            scrollToCenter()
            reSet()
        }
        if isIphone4() || isIphone4S() {
            print("Lock 444 phone")
            currentResolution = IP4RESOLUTION.rawValue
            captureSession?.beginConfiguration()
            captureSession?.sessionPreset = AVCaptureSession.Preset(rawValue: currentResolution!)
            captureSession?.commitConfiguration()
            recoverFlash()
            isLocked = false
            beforeLock = false
            adjustForLowResolution()
            scrollToCenter()
            resolutionWidth = 540
            resolutionHeight = 960
            reSet()
        }
        DispatchQueue.main.async {
            self.screenLockButton.setImage(UIImage(named: String(utf8String: UNLOCKPNG) ?? ""), for: .normal)
            self.storeData()
            self.restoreZoom()
        }
    }
    
    func lockScreen() {
        print("Lock phone")
        lockInterfaceOrientation = ORIENTATION
        print(lockInterfaceOrientation.rawValue)
//         change ui to locked
        lockedUserInterface()
//         trace lock tapped count
        lockTimer = Date()
        
        
        //        [self.scrollView.pinchGestureRecognizer setEnabled:YES];
        //        [self.scrollView setScrollEnabled:YES];
        
        if isIphone5() || isIpad() {
            isLocked = false
            beforeLock = true
            reSet()
        } else {
            beforeLock = true
            isLocked = false
            //  1080p
            currentResolution = IP5RESOLUTION.rawValue
            resolutionWidth = 1080
            resolutionHeight = 1920
            //  if 1080p not available set 720p
            if !(captureSession?.canSetSessionPreset(AVCaptureSession.Preset(rawValue: currentResolution!)) ?? false) {
                currentResolution = RESOLUTION2.rawValue
                resolutionWidth = 720
                resolutionHeight = 1280
            }
            captureSession?.beginConfiguration()
            captureSession?.sessionPreset = AVCaptureSession.Preset(rawValue: currentResolution!)
            captureSession?.commitConfiguration()
            recoverFlash()
            correctContentOffset = scrollView.contentOffset
            print("Decapitated: \(correctContentOffset)")
            reSet()
        }
        DispatchQueue.main.async{self.screenLockButton.setImage(UIImage(named: String(utf8String: LOCKPNG) ?? ""), for: .normal)}
        storeData()
    }
    
    func lockedUserInterface() {
        DispatchQueue.main.async{ [self] in
            self.stableDirectionButton.isHidden = true
            self.flashLightButton.isHidden = true
            self.saveButton.isHidden = false
            self.imageModeButton.isHidden = true
            self.flipButton.isHidden = true
            self.lockFocusButton.isHidden = true
        }
    }
    
    func unlockedUserInterface() {
        DispatchQueue.main.async{
            self.stableDirectionButton.isHidden = false
            if self.isIpad() && !self.isIpadPro() {
                self.flashLightButton.isHidden = true
            } else {
                self.flashLightButton.isHidden = false
            }
            self.saveButton.isHidden = true
            //[self.photoButton setHidden:YES];
            self.imageModeButton.isHidden = false
            self.flipButton.isHidden = false
            self.lockFocusButton.isHidden = false
        }
    }
    
    // MARK: -
    // MARK: Helper Functions
    func displayMessage(_ s: String?) {
        DispatchQueue.main.async(execute: {
            self.message.text = s
            self.message.isHidden = false
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            self.message.isHidden = true
        })
    }
    
    func isIphone4() -> Bool {
        return AppDelegate.isIphone4()
    }
    
    // for ip5 or higher device return true
    func isIphone5() -> Bool {
        return AppDelegate.isIphone5()
    }
    
    func isIphone4S() -> Bool {
        return AppDelegate.isIphone4S()
    }
    
    func isiPhone() -> Bool {
        return AppDelegate.isiPhone()
    }
    
    func isIpad() -> Bool {
        return AppDelegate.isIpad()
    }
    
    func beforeIpad2() -> Bool {
        return AppDelegate.beforeIpad2()
    }
    
    func isIpadPro() -> Bool {
        return AppDelegate.isIpadPro()
    }
    
    func deviceString() -> String? {
        return AppDelegate.deviceString()
    }
    
    func viewDidDismiss() {
        adjustCurrentOrientation()
    }
    
    //  reSet all settings
    func reSet() {
        motionX = 0
        motionY = 0
        imageNo = 0
        adjustingFocus = false
    }
    
    //  return true if stabilization is enabled, else false
    func checkStableEnableDisable() -> Bool {
        if isStabilizationEnable {
            return true
        } else {
            return false
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    /*- (ALAssetsLibrary *)library {
     if (!_library) {
     return [[ALAssetsLibrary alloc] init];
     }
     return _library;
     }*/
    
    // MARK: - Debug functions
    func systemOutput(_ content: String?, variable value: Float) {
        return
            print(String(format: content ?? "", value))
    }
    
    // MARK: - Memory management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        stopPlaying()
    }
    
    // MARK: - System Data Storage
    func storeData() {
        var svMagnifier: [AnyHashable : Any] = [:]
        svMagnifier["Photo Data"] = photoData
        svMagnifier["Image Mode"] = isImageModeOn
        svMagnifier["beforeLock"] = beforeLock
        svMagnifier["isFlipped"] = isFlipped
        //svMagnifier["isStabilizationEnable"] = isStabilizationEnable
        //svMagnifier["isHorizontalStable"] = isHorizontalStable
        svMagnifier["lockFocusButtonSelected"] = lockFocusButtonSelected
        UserDefaults.standard.set(svMagnifier, forKey: "SVMagnifier")
        UserDefaults.standard.synchronize()
    }
    func restoreZoom() {
        captureSession?.stopRunning()
        captureSession?.startRunning()
        let userDefaults = UserDefaults.standard
        let object = userDefaults.object(forKey: "Zoom Scale") as? NSObject
        if object != nil {
            //scrollView.setZoomScale(CGFloat(scale), animated: false)
            let zoom = userDefaults.float(forKey: "Zoom Scale")
            print("Scale: \(zoom)")
            zoomSlider.value = zoom
            scrollView.setZoomScale(CGFloat(zoom), animated: false)
            setZoomScale(zoom)
            //self.setZoomScale(zoom.isLess(than: 1.0) ? 1.0 : zoom)
        }
    }
    
    func retrieveData() {
        let svMagnifier = UserDefaults.standard.dictionary(forKey: "SVMagnifier")
        if svMagnifier != nil {
            photoData = svMagnifier?["Photo Data"] as? [String]
            //isImageModeOn = svMagnifier?["Image Mode"] as? Bool ?? false
            //beforeLock = svMagnifier?["beforeLock"] as? Bool ?? false
            //isFlipped = svMagnifier?["isFlipped"] as? Bool ?? false
            //isStabilizationEnable = svMagnifier?["isStabilizationEnable"] as? Bool ?? false
            //isHorizontalStable = svMagnifier?["isHorizontalStable"] as? Bool ?? false
            //lockFocusButtonSelected = svMagnifier?["lockFocusButtonSelected"] as? Bool ?? false
            
        }
        restoreZoom()
        if isImageModeOn {
            print("ImageMode on")
            isImageModeOn = !isImageModeOn
            imageModeTapped()
        }
        if isFlipped {
            print("Flip mode on")
            isFlipped = !isFlipped
            flipPressed(UIButton())
        }
//        if isHorizontalStable {
//            isHorizontalStable = !isHorizontalStable
//            horizontalStableButtonTapped(UIButton())
//        }
        
        if beforeLock {
            print("beforeLock")
            beforeLock = !beforeLock
            lockButtonTapped(UIButton())
        }
        
        if lockFocusButtonSelected {
            print("lockFocusButtonSelected")
            lockFocusButtonSelected = !lockFocusButtonSelected
            lockFocusButtonTapped(UIButton())
        }
    }
}

@available(iOS 10.0, *)
extension ViewController: MyScrollViewDelegate {
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        //    NSString *value = [NSString stringWithFormat:@"%f", self.currentZoomRate];
        //[MobClick event:@"UserExit" attributes:@{@"ZoomLevel": value}];
        //    [self umengEvent:@"UserExit" attributes:@{@"ZoomLevel": value} number:@(self.currentZoomRate)];
        currentZoomRate = Float(scrollView.zoomScale)
        //    if (self.currentZoomRate >= scrollView.maximumZoomScale) {
        //        self.currentZoomRate = scrollView.maximumZoomScale;
        //    }
        //    else if (self.currentZoomRate <= scrollView.minimumZoomScale) {
        //        self.currentZoomRate = scrollView.minimumZoomScale;
        //    }
        zoomSlider.setValue(currentZoomRate, animated: true)
        if isTapped {
            adjustExposurePoint()
        }
        
        print("did zoom")
    }
    
    func handleDoubleTap(gesture: UIGestureRecognizer?) {
        if hideControls {
            hideControls = false
            showAllcontrols()
        } else {
            if isiPhone() {
                Umeng.event("DoubleTouchHide", value: "iPhone")
            }
            if isIpad() {
                Umeng.event("DoubleTouchHide", value: "iPad")
            }
            hideControls = true
            hideAllControls()
        }
        print("double tap")
    }
    func touchesBegan(touches: Set<UITouch>?, with event: UIEvent?) {
        print("touches began")
    }

    func touchesEnded(touches: Set<UITouch>?, with event: UIEvent?) {
        // trace touch event
        let vZoomFactor = CGFloat(scrollView.zoomScale)
        var error: NSError!
            do{
                try captureDevice?.lockForConfiguration()
                defer {captureDevice?.unlockForConfiguration()}
                if (vZoomFactor <= captureDevice?.activeFormat.videoMaxZoomFactor ?? 1.0){
                    captureDevice?.videoZoomFactor = vZoomFactor
                    print("pinch \(vZoomFactor)")
                    zoomSlider.value = Float(vZoomFactor)
                }else{
                    NSLog("Unable to set videoZoom: (max %f, asked %f)", captureDevice?.activeFormat.videoMaxZoomFactor ?? 1.0, vZoomFactor);
                }
            }catch error as NSError{
                 NSLog("Unable to set videoZoom: %@", error.localizedDescription);
            }catch _{

            }
//        zoomSlider.value = Float(scrollView.zoomScale)
        // tan change begin
//        let currentVolume: Float = getSystemVolumValue()
//        print("volume num:",currentVolume)
//        print("volume num:",beginsound)
//        if(currentVolume != beginsound){
//            print("lock")
//            lockOrNot()
//            setSysVolum(beginsound)
//        }else if(isLocked){
//            unlockScreen()
//        }
//        print("volume num:",currentVolume)
//        print("volume num:",beginsound)
        
        // tan change end
        print("touches ended")
        
    }
    
    //MARK: - UILongPressGestureRecognizer Action -voliceChangeAction
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if (gestureRecognizer.state != UIGestureRecognizer.State.ended && !onlyOnce) {
            print("When longpress is started or running")
            self.message.isHidden = true
            var mutableDictionary: [AnyHashable : Any] = [:]
            stableTimer = Date()
            // trace touch event.
            if isHorizontalStable == false {
                //            [MobClick event:@"TouchCount" label:@"XYStabilization"];
                if checkAccessibilityEnabled() {
                    if GROUP_ID != nil && STUDY_ID != nil {
                        mutableDictionary["\(STUDY_ID ?? "") VI"] = Umeng.appendGroup(to: "XYStabilization")
                    } else {
                        mutableDictionary["VI"] = Umeng.appendGroup(to: "XYStabilization")
                    }
                    if isiPhone() {
                        MobClick.beginEvent("Stabilization_iPhone", primarykey: "Stabilization_iPhone", attributes: mutableDictionary)
                        MobClick.endEvent("Stabilization_iPhone", primarykey: "Stabilization_iPhone")
                    }
                    if isIpad() {
                        MobClick.beginEvent("Stabilization_iPad", primarykey: "Stabilization_iPad", attributes: mutableDictionary)
                        MobClick.endEvent("Stabilization_iPad", primarykey: "Stabilization_iPad")
                    }
                } else {
                    if isiPhone() {
                        Umeng.beginEvent("Stabilization_iPhone", primarykey: "Stabilization_iPhone", value: "XYStabilization")
                    }
                    if isIpad() {
                        Umeng.beginEvent("Stabilization_iPad", primarykey: "Stabilization_iPad", value: "XYStabilization")
                    }
                }
            } else {
                //            [MobClick event:@"TouchCount" label:@"VerticalStabilization"];
                if checkAccessibilityEnabled() {
                    if GROUP_ID != nil && STUDY_ID != nil {
                        mutableDictionary["\(STUDY_ID ?? "") VI"] = Umeng.appendGroup(to: "VerticalStabilization")
                    } else {
                        mutableDictionary["VI"] = Umeng.appendGroup(to: "VerticalStabilization")
                    }
                    if isiPhone() {
                        MobClick.beginEvent("Stabilization_iPhone", primarykey: "Stabilization_iPhone", attributes: mutableDictionary)
                        MobClick.endEvent("Stabilization_iPhone", primarykey: "Stabilization_iPhone")
                    }
                    if isIpad() {
                        MobClick.beginEvent("Stabilization_iPad", primarykey: "Stabilization_iPad", attributes: mutableDictionary)
                        MobClick.endEvent("Stabilization_iPad", primarykey: "Stabilization_iPad")
                    }
                } else {
                    if isiPhone() {
                        Umeng.beginEvent("Stabilization_iPhone", primarykey: "Stabilization_iPhone", value: "VerticalStabilization")
                    }
                    if isIpad() {
                        Umeng.beginEvent("Stabilization_iPad", primarykey: "Stabilization_iPad", value: "VerticalStabilization")
                    }
                }
            }
            // For test
            //NSDictionary *dictionary = [[NSMutableDictionary alloc] init];;
            //[dictionary setValue:@"123" forKey:groupID];
            //[MobClick beginEvent: @"Stabilization_iPhone" primarykey:@"Stabilizationsp_iPhone" attributes:dictionary];
            //[MobClick beginEvent:@"Stabilization_iPhone" label:[NSString stringWithFormat:@"%@%@", @"Schepens", groupID]];
            reSet()
            isStabilizationEnable = true
            // self.message.text = "longpress on, stable: \(isStabilizationEnable)"
            //    [self lockAutoFocus];
            DispatchQueue.main.async {
                if (!self.onlyOnce && !self.isLocked) {
//                    self.sendPhotoToAzureWithTag(self.scrollView.getImage())
                    self.onlyOnce = true
                }
            }
            
            
        } else if (gestureRecognizer.state == UIGestureRecognizer.State.ended || gestureRecognizer.state == UIGestureRecognizer.State.failed || gestureRecognizer.state == UIGestureRecognizer.State.cancelled) {
            print("When longpress is finished")
            print(gestureRecognizer.state.rawValue)
            zoomSlider.value = Float(scrollView.zoomScale)
            var mutableDictionary: [AnyHashable : Any] = [:]
            var seconds: Float? = nil
            if let stableTimer = stableTimer {
                seconds = Float(Date().timeIntervalSince(stableTimer))
            }
            
            if (seconds ?? 0.0) >= 1 {
                if isHorizontalStable == false {
                    if checkAccessibilityEnabled() {
                        if GROUP_ID != nil && STUDY_ID != nil {
                            mutableDictionary["\(STUDY_ID ?? "") VI"] = Umeng.appendGroup(to: "XYStabilization")
                        } else {
                            mutableDictionary["VI"] = Umeng.appendGroup(to: "XYStabilization")
                        }
                        if isiPhone() {
                            MobClick.beginEvent("Stabilization_iPhone", primarykey: "Stabilization_iPhone", attributes: mutableDictionary)
                            MobClick.endEvent("Stabilization_iPhone", primarykey: "Stabilization_iPhone")
                        }
                        if isIpad() {
                            MobClick.beginEvent("Stabilization_iPad", primarykey: "Stabilization_iPad", attributes: mutableDictionary)
                            MobClick.endEvent("Stabilization_iPad", primarykey: "Stabilization_iPad")
                        }
                    } else {
                        if isiPhone() {
                            Umeng.endEvent("Stabilization_iPhone", primarykey: "Stabilization_iPhone", value: "XYStabilization")
                        }
                        if isIpad() {
                            Umeng.endEvent("Stabilization_iPad", primarykey: "Stabilization_iPad", value: "XYStabilization")
                        }
                    }
                } else {
                    if checkAccessibilityEnabled() {
                        if GROUP_ID != nil && STUDY_ID != nil {
                            mutableDictionary["\(STUDY_ID ?? "") VI"] = Umeng.appendGroup(to: "VerticalStabilization")
                        } else {
                            mutableDictionary["VI"] = Umeng.appendGroup(to: "VerticalStabilization")
                        }
                        if isiPhone() {
                            MobClick.beginEvent("Stabilization_iPhone", primarykey: "Stabilization_iPhone", attributes: mutableDictionary)
                            MobClick.endEvent("Stabilization_iPhone", primarykey: "Stabilization_iPhone")
                        }
                        if isIpad() {
                            MobClick.beginEvent("Stabilization_iPad", primarykey: "Stabilization_iPad", attributes: mutableDictionary)
                            MobClick.endEvent("Stabilization_iPad", primarykey: "Stabilization_iPad")
                        }
                    } else {
                        if isiPhone() {
                            Umeng.endEvent("Stabilization_iPhone", primarykey: "Stabilization_iPhone", value: "VerticalStabilization")
                        }
                        if isIpad() {
                            Umeng.endEvent("Stabilization_iPad", primarykey: "Stabilization_iPad", value: "VerticalStabilization")
                        }
                    }
                }
            }
            //    [self unlockAutoFocus];
            isStabilizationEnable = false
            // self.message.text = "lngprss off, features:\(self.featuresDetected) stable: \(isStabilizationEnable)"
            onlyOnce = false
            reSet()
        }
    }
}

@available(iOS 10.0, *)
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //NSLog(@"lens aperture = %f, ISO = %f, exposure time = %lld", self.captureDevice.lensAperture, self.captureDevice.ISO, self.captureDevice.exposureDuration.value);
        /*if (self.readyChangeBack && self.captureDevice.adjustingFocus) {
         //[self unlockAutoFocus];
         self.readyChangeBack = false;
         NSLog(@"mode = %ld, x = %f, y = %f", (long)self.captureDevice.focusMode, self.captureDevice.focusPointOfInterest.x, self.captureDevice.focusPointOfInterest.y);
         }
         if (self.captureDevice.focusMode == AVCaptureFocusModeLocked && self.isTapped) {
         //NSLog(@"auto");
         [self unlockFocus];
         self.readyChangeBack = true;
         self.isTapped = false;
         NSLog(@"mode = %ld, x = %f, y = %f", (long)self.captureDevice.focusMode, self.captureDevice.focusPointOfInterest.x, self.captureDevice.focusPointOfInterest.y);
         }*/
        //NSLog(@"focus mode = %ld", (long)self.captureDevice.focusMode);
        /*if (self.isTapped && self.captureDevice.adjustingFocus) {
         [self resetExposure];
         self.isTapped = false;
         NSLog(@"reset exposure");
         }*/
        checkResetExposure()
        //NSLog(@"origina = %f, current = %f", self.ISO * self.duration.value, self.captureDevice.ISO * self.captureDevice.exposureDuration.value);
        
        if SYSTEM_VERSION_LESS_THAN(version: "8.0") || focusCanNotChange() {
        } else {
            DispatchQueue.main.async {
                if !self.lockFocusButton.isSelected {
                    self.checkFocusChange()
                }
            }
        }
        /*
         NSLog(@"imageview size: w:%f, h:%f, scrollview size:%f, %f\n", self.scrollView.imageView.frame.size.width, self.scrollView.imageView.frame.size.height, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
         NSLog(@"window: w %f, h %f\n", [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
         */
        if isLocked {
            return
        }
        
        // zewen li
        //[self performSelectorOnMainThread:@selector(adjustCurrentOrientation) withObject:nil waitUntilDone:YES];
        performSelector(onMainThread: #selector(setupControlsPosition), with: nil, waitUntilDone: true)
        
        
        /* time statics
         NSDate *captureOutputStartTime = [NSDate date];
         double intervalBetweenTwoFrames = [captureOutputStartTime timeIntervalSinceDate:self.lastDate];
         self.avgTimeForOneFrame += intervalBetweenTwoFrames;
         self.lastDate = [[NSDate date] retain];
         int currentFrameRate = 1 / intervalBetweenTwoFrames;
         NSString *frameRateString = [NSString stringWithFormat:@"%d",currentFrameRate];
         [self.frameRateLabel performSelectorOnMainThread:@selector(setText:) withObject:frameRateString waitUntilDone:YES];
         [self systemOutput:@"Total Time for one frame is:%f\n" variable:intervalBetweenTwoFrames];
         */
        
        /*We create an autorelease pool because as we are not in the main_queue our code is
         not executed in the main thread. So we have to create an autorelease pool for the thread we are in*/
        
        /*
         To restrict the camera rotation.
         Changed the camera orientation as per the device orientation so that it will maintain camera view.
         */
        if connection.isVideoOrientationSupported {
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight{
                //print("Landscape right")
                connection.videoOrientation = portraitOnly ? .landscapeRight : .portrait
            } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
                connection.videoOrientation = portraitOnly ? .landscapeRight : .portraitUpsideDown
                //print("Landscape left")
            } else if UIDevice.current.orientation == UIDeviceOrientation.portrait{
                connection.videoOrientation = .landscapeRight
                //print("Portrait")
            }
        }
        
        
        
        
        guard let imageBuffer =  CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        //Lock the image buffer
        CVPixelBufferLockBaseAddress(imageBuffer, [])
        //Get information about the image
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        var bytesPerRow: size_t? = nil
        bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        // screen width is 320, image width is 640 / 1920 / 1280
        var width: size_t? = nil
        width = CVPixelBufferGetWidth(imageBuffer)
        // screen height is 480, image height is 480 / 1080 / 720
        var height: size_t? = nil
        height = CVPixelBufferGetHeight(imageBuffer)
        //Create a CGImageRef from the CVImageBufferRef
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: baseAddress, width: width ?? 0, height: height ?? 0, bitsPerComponent: 8, bytesPerRow: bytesPerRow ?? 0, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        // create a cgimgRef from original source.
        let originalCGImage = context?.makeImage()
        
        /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly).
         Same thing as for the CALayer we are not in the main thread so ...*/
        // just change orientation for image rendering, its width and height does not change!!
        var originalUIImage: UIImage? = nil
        if let originalCGImage = originalCGImage, let imageOrientation1 = UIImage.Orientation(rawValue: isFlipped ? mirroredImageOrientation : imageOrientation) {
            originalUIImage = UIImage(cgImage: originalCGImage, scale: 1, orientation: imageOrientation1)
            
        }
        // add filter
        if isImageModeOn {
            originalUIImage = addFilter(originalCGImage)
        }
        if beforeLock {
            
            let processCGImageRef = originalCGImage?.cropping(to: CGRect(x: CGFloat(Int((width ?? 0) / 2) - featureWindowWidth / 2), y: CGFloat(Int((height ?? 0) / 2) - featureWindowHeight / 2), width: CGFloat(400), height: CGFloat(400)))
            // we crop a part of cgimage to uiimage to do feature detect and track.
            var processUIImage: UIImage? = nil
            if let processCGImageRef = processCGImageRef {
                processUIImage = UIImage(cgImage: processCGImageRef)
            }
            imageProcess?.setCurrentImageMat(processUIImage)
            
            let `var` = imageProcess?.calVariance() ?? 0.0
            
            if imageNo >= lockDelay {
                
                if isIphone5() || (isIpad()) {
                    isLocked = true
                    var finalImage: UIImage?
                    if isImageModeOn {
                        finalImage = addFilter(originalCGImage)
                    } else {
                        finalImage = highVarImg
                    }
                    DispatchQueue.main.async {
                        print("hola : \(self.zoomSlider.minimumValue != self.currentZoomRate)")
                        if (self.zoomSlider.minimumValue != self.currentZoomRate) {
                            self.scrollView.changeImageViewFrame(CGRect(x: 0, y: 0, width: CGFloat(finalImage?.size.width ?? 1080), height: CGFloat(finalImage?.size.height ?? 1920)))
                        }
                        self.scrollView.imageView?.image = finalImage
                        self.maxVariance = 0
                        // self.sendPhotoToAzureWithTag(self.highVarImg)
                    }
                }
                
                if (width != 960) && (isIphone4() || isIphone4S()) {
                    // show to screen.
                    adjustForHighResolution()
                    scrollView.setImage(highVarImg)
                    isLocked = true
                    DispatchQueue.main.async {
                        self.scrollView.setContentOffset(self.correctContentOffset, animated: false)
                        // self.sendPhotoToAzureWithTag(self.highVarImg)
                    }
                    maxVariance = 0
                }
            } else {
                if (maxVariance < `var`) || (maxVariance == 0) {
                    if let originalCGImage = originalCGImage, let imageOrientation1 = UIImage.Orientation(rawValue: isFlipped ? mirroredImageOrientation : imageOrientation) {
                        highVarImg = UIImage(cgImage: originalCGImage, scale: 1, orientation: imageOrientation1)
                    }
                    maxVariance = `var`
                }
            }
        } else {
            //  for ip4 resolution may not get changed that fast
            if false {
                //(([self isIphone4]) && (width != 960)) {
                // do nothing
            } else {
                // cut a particle of a cgimage to process fast feature detect
                let processCGImageRef = originalCGImage?.cropping(to: CGRect(x: CGFloat(Int((width ?? 0) / 2) - featureWindowWidth / 2), y: CGFloat(Int((height ?? 0) / 2) - featureWindowHeight / 2), width: CGFloat(400), height: CGFloat(400)))
                // we crop a part of cgimage to uiimage to do feature detect and track.
                var processUIImage: UIImage? = nil
                if let processCGImageRef = processCGImageRef {
                    processUIImage = UIImage(cgImage: processCGImageRef)
                }
                //  if stabilization function is disabled
                if !isStabilizationEnable {
                    scrollView.setImage(originalUIImage)
                    //scrollView.clipsToBounds = true
                } else {
                    if imageNo == 0 {
                        imageProcess?.setLastImageMat(processUIImage)
                        scrollView.setImage(originalUIImage)
                        //scrollView.clipsToBounds = true
                    } else {
                        // set up images
                        imageProcess?.setCurrentImageMat(processUIImage)
                        // calculate motion vector
                        let motionVector = imageProcess?.motionEstimation()
                        motionX += Float(motionVector?.x ?? 0.0)
                        motionY += Float(motionVector?.y ?? 0.0)
                        if (abs(motionX) > Float(250) || abs(motionY) > Float(250)) {
                            print("overload")
                            imageProcess?.setLastImageMat(processUIImage)
                            scrollView.setImage(originalUIImage)
                            motionX = 0.0
                            motionY = 0.0
                            resetCount += 1
                        } else {
                            //  there is no feature points or either no feature tracking points
                            if isHorizontalStable {
                                if ORIENTATION.isPortrait {
                                    motionY = 0
                                } else {
                                    motionX = 0
                                }
                            }
                            let windowBounds = UIScreen.main.bounds
                            var resultRect: CGRect = CGRect.zero
                            let _width: Float = Float(CVPixelBufferGetWidth(imageBuffer))
                            let _height: Float = Float(CVPixelBufferGetHeight(imageBuffer))
                            resultRect = imageProcess?.calculateMyCroppedImage(motionX, ypos: motionY, width: _width, height: _height, scale: currentZoomRate, bounds: CGRect(x: windowBounds.origin.x, y: windowBounds.origin.y, width: CGFloat(_width), height: CGFloat(_height))) ?? CGRect.zero
                            // to solve a bug only more than iOS 8.0
                            if SYSTEM_VERSION_LESS_THAN(version: "8.0") {
                            } else {
                                if ORIENTATION.isLandscape {
                                    let _width: Float = Float(CVPixelBufferGetWidth(imageBuffer))
                                    let _height: Float = Float(CVPixelBufferGetHeight(imageBuffer))
                                    resultRect = imageProcess?.calculateMyCroppedImage(motionX, ypos: motionY, width: _width, height: _height, scale: currentZoomRate, bounds: CGRect(x: windowBounds.origin.x, y: windowBounds.origin.y, width: (CGFloat(_height)), height: (CGFloat(_width)))) ?? CGRect.zero
                                }
                            }
                            
                            print("motionX \(motionX)")
                            print("motionY \(motionY)")
                            DispatchQueue.main.async {
                                self.message.text = "\(self.messageText) reset:\(self.resetCount) mX \(Int(self.motionX)) mY \(Int(self.motionY))"
                            }
                            print("\("image width: ")\(_width)")
                            print("\("image height: ")\(_height)")
                            print("\("zoomScale: ")\(currentZoomRate)")
                            
                            print("\("resultRect: ")\(resultRect)")
                            
                            //NSLog(@"result rect: origin:%f, %f: w:%f,h:%f\n", resultRect.origin.x, resultRect.origin.y, resultRect.size.width, resultRect.size.height);
                            //  cut from original to move the image
                            let finalProcessImage = originalUIImage?.cgImage?.cropping(to: resultRect)
                            var finalUIImage: UIImage? = nil
                            if let finalProcessImage = finalProcessImage, let imageOrientation1 = UIImage.Orientation(rawValue: isFlipped ? mirroredImageOrientation : imageOrientation) {
                                finalUIImage = UIImage(cgImage: finalProcessImage, scale: 1, orientation: imageOrientation1)
                            }
                            scrollView.setImage(finalUIImage)
                            imageProcess?.setLastImageMat(processUIImage)
                        }
                    }
                }
            }
        }
        
        //We unlock the  image buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer, [])
        imageNo += 1
        //[MobClick event:@"Test" label:@"Caputure runs successfully."];
        return
        
    }
    
    @IBAction func lockPortraitButtonTapped(_ sender: UIButton?) {
        portraitOnly = !portraitOnly
        if (portraitOnly) {
            AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
            //lockPortraitButton.setImage(UIImage(named: String(utf8String: ROTATIONLOCKEDPNG) ?? ""), for: .normal)
            willAnimateRotation(to: UIInterfaceOrientation.portrait, duration: 0.1)
        } else {
            AppUtility.lockOrientation(.allButUpsideDown, andRotateTo: ORIENTATION.isLandscape ? ORIENTATION == .landscapeLeft ? .landscapeLeft : .landscapeRight : .portrait)
            //lockPortraitButton.setImage(UIImage(named: String(utf8String: ROTATIONUNLOCKEDPNG) ?? ""), for: .normal)
        }
        storeData()
    }
}

@available(iOS 10.0, *)
struct AppUtility {

    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {

        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }

    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {

        self.lockOrientation(orientation)

        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }

}
public extension UIImage {
    func flipHorizontally() -> UIImage? {
        print("flipHorizontally")
        UIGraphicsBeginImageContextWithOptions(self.size, true, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        context.translateBy(x: self.size.width/2, y: self.size.height/2)
        context.scaleBy(x: -1.0, y: 1.0)
        context.translateBy(x: -self.size.width/2, y: -self.size.height/2)
        
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func fixedOrientation() -> UIImage? {
        
        guard imageOrientation != UIImage.Orientation.up else {
            //This is default orientation, don't need to do anything
            return self.copy() as? UIImage
        }
        
        guard let cgImage = self.cgImage else {
            //CGImage is not available
            return nil
        }
        
        guard let colorSpace = cgImage.colorSpace, let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil //Not able to create CGContext
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
            break
        case .left, .leftMirrored:
            print("leftMirrored")
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
            //transform = transform.translatedBy(x: -size.width, y: -size.height)
            break
        case .right, .rightMirrored:
            print("rightMirrored")
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
            break
        case .up, .upMirrored:
            break
        }
        
        //Flip image one more time if needed to, this is to prevent flipped image
//        switch imageOrientation {
//        case .upMirrored, .downMirrored:
//            transform.translatedBy(x: size.width, y: 0)
//            transform.scaledBy(x: -1, y: 1)
//            break
//        case .leftMirrored, .rightMirrored:
//            transform.translatedBy(x: size.height, y: 0)
//            transform.scaledBy(x: -1, y: 1)
//        case .up, .down, .left, .right:
//            break
//        }
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        guard let newCGImage = ctx.makeImage() else { return nil }
        return UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
    }
    
    func toBase64() -> String? {
        
        let imageData : NSData = self.jpegData(compressionQuality: 1.0)! as NSData
        return imageData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
    }
}
@available(iOS 10.0, *)
extension ViewController: CLLocationManagerDelegate {
    
    func sendPhotoToAzureWithTag(_ image: UIImage?) {
        let reachabilityManager = try! Reachability()
        if reachabilityManager.connection == .wifi || reachabilityManager.connection == .cellular {
            networkAvailable = true
            print("Network available")
        } else {
            networkAvailable = false
            print("Network unavailable")
        }
        if (networkAvailable) {
            if let image = image {
                let imageData = image.jpegData(compressionQuality: 1)
                if (imageData == nil) {
                    print("UIImageJPEGRepresentation return nil")
                    return
                }
                
                var path = "https://luolab-computer-vision.cognitiveservices.azure.com/vision/v2.1/analyze"
                let array = [
                    // Request parameters
                    "entities=true",
                    "visualFeatures=Categories"
                ]
                
                let string = array.joined(separator: "&")
                path = path + "?\(string)"
                var categories = [String]()
                
                print("\(path)")
                
                var request = URLRequest(url: URL(string: path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!)
                request.httpMethod = "POST"
                
                let body = NSMutableData()
                body.append(imageData!)
                
                request.httpBody = body as Data
                
                request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
                request.addValue("ff236fa4870a4eb694c8fc5493af01ff", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
                let session = URLSession.shared
                let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
                    do {
                        if let data = data {
                            let json = try JSONSerialization.jsonObject(with: data) as! Dictionary<String, Any>
                            print(json)
                            if json["categories"] != nil {
                                var min = 0.0
                                let array: NSArray = json["categories"] as! NSArray
                                for i in 0..<array.count {
                                    let item = array[i] as! [String: Any]
                                    if (item["score"] as! Double > min) {
                                        min = item["score"] as! Double
                                        print(item["name"] as! String)
                                        var str = item["name"] as! String
                                        str = str.components(separatedBy: "_")[0]
                                        //let newStr = str.replacingOccurrences(of: "_", with: "")
                                        categories.append(str)
                                    }
                                }
                            }
                            self.imageTagAPICall(image, categories: categories)
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                })
                
                task.resume()
                
                
            } else {
                print("do no harm")
            }
        }
    }
    
    func imageTagAPICall(_ image: UIImage?, categories: [String]) {
        let imageTagUrl = "https://luolab-computer-vision.cognitiveservices.azure.com/vision/v2.0/tag?language=en"
        if let image = image {
            let imageData = image.jpegData(compressionQuality: 1)
            if (imageData == nil) {
                print("UIImageJPEGRepresentation return nil")
                return
            }
            var request2 = URLRequest(url: URL(string: imageTagUrl)!)
            request2.httpMethod = "POST"
            let body = NSMutableData()
            body.append(imageData!)
            request2.httpBody = body as Data
            
            request2.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            request2.addValue("ff236fa4870a4eb694c8fc5493af01ff", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
            let session = URLSession.shared
            let task = session.dataTask(with: request2, completionHandler: { data, response, error -> Void in
                do {
                    if let data = data {
                        let json = try JSONSerialization.jsonObject(with: data) as! Dictionary<String, Any>
                        print(json)
                        if json["tags"] != nil {
                            let array: NSArray = json["tags"] as! NSArray
                            self.detectedObjects.removeAll()
                            for i in 0..<array.count {
                                let item = array[i] as! [String: Any]
                                if (item["confidence"] as! Double > 0.6) {
                                    print(item["name"] as! String)
                                    self.detectedObjects.append(item["name"] as! String)
                                }
                            }
                            
                            //                            if let desc = json["description"] as? [String: Any] {
                            
                            DispatchQueue.main.async {
                                //self.alertViewForTesting(self.detectedObjects)
                                //                            self.lockLabel = "\(self.captureDevice?.lensPosition ?? -1.0) \(self.currentZoomRate) \(self.detectedObjects.joined(separator: ","))"
                                self.lockLabel = "\(self.detectedObjects.joined(separator: ","))"
                                print(self.lockLabel!)
                                //                                    let commonElements = self.detectedObjects.filter(self.imageCategories.contains)
                                //                                    print("Common elements:\(commonElements)")
                                
                                var mutableDictionary: [AnyHashable : Any] = [:]
                                if self.checkAccessibilityEnabled() {
                                    mutableDictionary["VI"] = Umeng.appendGroup(to: self.lockLabel!)
                                } else if (categories.count > 0) {
//                                    mutableDictionary["\(categories.joined(separator: ","))"] = Umeng.appendGroup(to: self.lockLabel!)
                                    mutableDictionary["\(categories[0])"] = Umeng.appendGroup(to: self.lockLabel!)
                                } else {
                                    mutableDictionary["\(self.detectedObjects.count > 0 ? self.detectedObjects[0] : "")"] = Umeng.appendGroup(to: self.lockLabel!)
                                }
                                print(mutableDictionary)
                                if self.isIpad() {
                                    MobClick.beginEvent("ImageTag_iPad", primarykey: "ImageTag_iPad", attributes: mutableDictionary)
                                    MobClick.endEvent("ImageTag_iPad", primarykey: "ImageTag_iPad")
                                } else {
                                    MobClick.beginEvent("ImageTag_iPhone", primarykey: "ImageTag_iPhone", attributes: mutableDictionary)
                                    MobClick.endEvent("ImageTag_iPhone", primarykey: "ImageTag_iPhone")
                                }
                            }
                        } else {
                            print("JSON tags missing")
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            })
            
            task.resume()
        } else {
            print("Image is nil")
        }
    }
    
    func getUserLocation() {
        firstTime = true
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            switch(CLLocationManager.authorizationStatus()) {
                
            case .authorizedAlways, .authorizedWhenInUse:
                print("Authorize.")
                locationManager.startUpdatingLocation()
                break
                
            case .notDetermined:
                
                print("Not determined.")
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocation()
                break
                
            case .restricted:
                
                print("Restricted.")
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocation()
                break
                
            case .denied:
                
                print("Denied.")
            @unknown default:
                print("Fatal error")
            }
            //locationManager.startUpdatingLocation()
        }
        //        if #available(iOS 9.0, *) {
        //            locationManager.delegate = self
        //            locationManager.requestLocation()
        //        } else {
        //            // Fallback on earlier versions
        //            print("Version too low to enable location services.")
        //        }
    }
    
    // MARK: - Location Manager
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if (firstTime) {
            if let location = locations.first {
                print("Found user's location: \(location)")
                if (UserDefaults.standard.value(forKey: "savedLocation") != nil) {
                    let previousLocationEncoded = UserDefaults.standard.object(forKey: "savedLocation") as? Data
                    let previousLocationDecoded = NSKeyedUnarchiver.unarchiveObject(with: previousLocationEncoded!) as! CLLocation
                    print("savedLocation: \(previousLocationDecoded)")
                    let distanceInMeters = location.distance(from: previousLocationDecoded) // result is in meters
                    print("Distance in meters: \(distanceInMeters)")
                    var val:Double = 0.0
                    if (distanceInMeters <= 100) {
                        val = 0.1
                    } else if (distanceInMeters <= 500) {
                        val = 0.5
                    } else if (distanceInMeters <= 1000) {
                        val = 1.0
                    } else if (distanceInMeters <= 5000) {
                        val = 5.0
                    } else if (distanceInMeters <= 50000) {
                        val = 50.0
                    } else if (distanceInMeters <= 500000) {
                        val = 500.0
                    } else {
                        val = 1000.0
                    }
                    self.lockLabel = "\(val) km"
                    print(self.lockLabel!)
                    var mutableDictionary: [AnyHashable : Any] = [:]
                    if checkAccessibilityEnabled() {
                        if GROUP_ID != nil && STUDY_ID != nil {
                            mutableDictionary["\(STUDY_ID ?? "") VI"] = Umeng.appendGroup(to: self.lockLabel)
                        } else {
                            mutableDictionary["VI"] = Umeng.appendGroup(to: self.lockLabel)
                        }
                        if isiPhone() {
                            MobClick.beginEvent("UserMobility_iPhone", primarykey: "UserMobility_iPhone", attributes: mutableDictionary)
                            MobClick.endEvent("UserMobility_iPhone", primarykey: "UserMobility_iPhone")
                        }
                        if isIpad() {
                            MobClick.beginEvent("UserMobility_iPad", primarykey: "UserMobility_iPad", attributes: mutableDictionary)
                            MobClick.endEvent("UserMobility_iPad", primarykey: "UserMobility_iPad")
                        }
                    } else {
                        if #available(iOS 10.0, *) {
                            if (AppDelegate.isIpad()) {
                                Umeng.beginEvent("UserMobility_iPad", primarykey: "UserMobility_iPad", value: lockLabel!)
                                Umeng.endEvent("UserMobility_iPad", primarykey: "UserMobility_iPad", value: lockLabel!)
                            } else {
                                Umeng.beginEvent("UserMobility_iPhone", primarykey: "UserMobility_iPhone", value: lockLabel!)
                                Umeng.endEvent("UserMobility_iPhone", primarykey: "UserMobility_iPhone", value: lockLabel!)
                            }
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                    let encodedLocation = NSKeyedArchiver.archivedData(withRootObject: location)
                    UserDefaults.standard.set(encodedLocation, forKey: "savedLocation")
                } else {
                    let encodedLocation = NSKeyedArchiver.archivedData(withRootObject: location)
                    UserDefaults.standard.set(encodedLocation, forKey: "savedLocation")
                }
            }
            firstTime = false
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            print("Did change auth")
            // authorized location status when app is in use; update current location
            locationManager.startUpdatingLocation()
            // implement additional logic if needed...
        }
    }
    
    func setupImageCategories() {
        imageCategories.removeAll()
        imageCategories = ["abstract", " abstract_net", " abstract_nonphoto", " abstract_rect", " abstract_shape", " abstract_texture", "animal", "animal_bird",
                           "animal_cat", "animal_dog", "animal_horse", "animal_panda", "building", "building_arch", "building_brickwall", "building_church", "building_corner", "building_doorwindows", "building_pillar", "building_stair", "building_street", "dark","drink", "drink_can","dark_fire","dark_fireworks","sky_object","food","food_bread","food_fastfood","food_grilled","food_pizza","indoor","indoor_churchwindow","indoor_court","indoor_doorwindows","indoor_marketstore","indoor_room","indoor_venue","dark_light","others","outdoor","outdoor_city","outdoor_field","outdoor_grass","outdoor_house","outdoor_mountain","outdoor_oceanbeach","outdoor_playground","outdoor_railway","outdoor_road","outdoor_sportsfield","outdoor_stonerock","outdoor_street","outdoor_water","outdoor_waterside","people","people_baby",
                           
                           "people_crowd","people_group",
                           
                           "people_hand","people_many",
                           
                           "people_portrait","people_show",
                           
                           "people_tattoo",
                           
                           "people_young",
                           
                           "plant",
                           
                           "plant_branch",
                           
                           "plant_flower",
                           
                           "plant_leaves",
                           
                           "plant_tree",
                           
                           "object_screen",
                           
                           "object_sculpture",
                           
                           "sky_cloud",
                           
                           "sky_sun",
                           
                           "people_swimming",
                           
                           "outdoor_pool",
                           
                           "text",
                           
                           "text_mag",
                           
                           "text_map",
                           
                           "text_menu",
                           
                           "text_sign",
                           
                           "trans_bicycle",
                           
                           "trans_bus",
                           
                           "trans_car",
                           
                           "trans_trainstation"]
    }
    
    func setAccesibilityHints() {
        flipButton.accessibilityLabel = "Flip image button"
        imageModeButton.accessibilityLabel = "Image mode button"
        //lockPortraitButton.accessibilityLabel = "Portrait lock button"
        flashLightButton.accessibilityLabel = "Flashlight button"
        lockFocusButton.accessibilityLabel = "Lock Focus button"
        zoomSlider.accessibilityLabel = "Zoom slider"
        infoButton.accessibilityLabel = "Info"
        stableDirectionButton.accessibilityLabel = "Stable direction button"
        saveButton.accessibilityLabel = "Save Image button"
        screenLockButton.accessibilityLabel = "Screen lock button"
        photoButton.accessibilityLabel = "Open Gallery button"
    }
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .ended:
                sendUnitImageSizeOnZoomChange()
            default:
                break
            }
        }
    }
    
    func sendFocusLevelMetrics(label: String) {
        var mutableDictionary: [AnyHashable : Any] = [:]
        if checkAccessibilityEnabled() {
            if GROUP_ID != nil && STUDY_ID != nil {
                mutableDictionary["\(STUDY_ID ?? "") VI"] = Umeng.appendGroup(to: label)
            } else {
                mutableDictionary["VI"] = Umeng.appendGroup(to: label)
            }
            if isiPhone() {
                MobClick.beginEvent("FocusLevel_iPhone", primarykey: "FocusLevel_iPhone", attributes: mutableDictionary)
                MobClick.endEvent("FocusLevel_iPhone", primarykey: "FocusLevel_iPhone")
            }
            if isIpad() {
                MobClick.beginEvent("FocusLevel_iPad", primarykey: "FocusLevel_iPad", attributes: mutableDictionary)
                MobClick.endEvent("FocusLevel_iPad", primarykey: "FocusLevel_iPad")
            }
        } else {
            if isiPhone() {
                Umeng.beginEvent("FocusLevel_iPhone", primarykey: "FocusLevel_iPhone", value: label)
            }
            if isIpad() {
                Umeng.beginEvent("FocusLevel_iPad", primarykey: "FocusLevel_iPad", value: label)
            }
        }
    }
    
}
extension MPVolumeView {
    func setVolume(_ volume: Float) {
        DispatchQueue.main.async {
            let volumeView = MPVolumeView()
            let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
                slider?.value = volume
            }
        }
    }
}
