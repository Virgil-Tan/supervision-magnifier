//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  AppDelegate.swift
//  EyeSee
//
//  Created by Zewen Li on 7/4/13.
//  Copyright (c) 2013 Zewen Li. All rights reserved.
//

import Crashlytics
import UserNotifications

let UMENG_APPKEY = "62fe4e3418dd7d56eeb1459f"
private var unKnownDeviceAlerted = false

@available(iOS 10.0, *)
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    var viewController: ViewController?
    var orientationLock = UIInterfaceOrientationMask.allButUpsideDown

    class func deviceString() -> String? {
        // Device model numbers can be found here: https://www.theiphonewiki.com/wiki/Models
//        var systemInfo: utsname
//        uname(&systemInfo)
        let deviceString = UIDevice.current.modelName//String(cString: systemInfo.machine, encoding: .utf8)
        //NSLog(@"System string: %@", deviceString);
        if (deviceString as NSString?)?.range(of: "iPhone").location != NSNotFound {
            let r1 = (deviceString as NSString?)?.range(of: "iPhone")
            let r2 = (deviceString as NSString?)?.range(of: ",")
            let subString = NSRange(location: (r1?.location ?? 0) + (r1?.length ?? 0), length: (r2?.location ?? 0) - (r1?.location ?? 0) - (r1?.length ?? 0))
            let versionString = (deviceString as NSString?)?.substring(with: subString)
            //NSLog(@"version: %@", versionString);
            let version = Int(versionString ?? "") ?? 0
            
            if version == 3 {
                return "iPhone4"
            }
            if version == 4 {
                return "iPhone4S"
            }
            if version >= 5 {
                return "iPhone5"
            }
            if (deviceString == "iPhone1,1") {
                return "iPhone1G"
            }
            if (deviceString == "iPhone1,2") {
                return "iPhone3G"
            }
            if (deviceString == "iPhone2,1") {
                return "iPhone3GS"
            }
        }
        if (deviceString as NSString?)?.range(of: "iPad").location != NSNotFound {
            let versionString = self.getIPadVersion(deviceString)
            let version = Int(versionString ?? "") ?? 0
            if version >= 3 {
                return "iPad3"
            } else {
                // Treat all iPad before 3 as iPad2
                return "iPad2"
            }
        }
        if (deviceString as NSString?)?.range(of: "iPod").location != NSNotFound {
            if (deviceString == "iPod1,1") {
                return "iPod Touch 1G"
            }
            if (deviceString == "iPod2,1") {
                return "iPod Touch 2G"
            }
            if (deviceString == "iPod3,1") {
                return "iPhone4" //@"iPod Touch 3G"; // previous use same setting as 4.
            }
            if (deviceString == "iPod4,1") {
                return "iPhone4S" //@"iPod Touch 4G"; // support 1080, same setting as 4S.
            }
            //if ([deviceString isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G"; // same setting as 5, 5s.====> original zewen's code
            if (deviceString == "iPod5,1") {
                return "iPhone4s" //--- this is 5th generation iPod
            }
        }
        if (deviceString == "i386") {
            return "Simulator"
        }
        if (deviceString == "x86_64") {
            return "Simulator"
        } else {
            if unKnownDeviceAlerted == false {
                UIAlertView(title: "Warning:", message: "Device unknown. Unoptimized setting used. Please contact support.", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "Cancel").show()
                unKnownDeviceAlerted = true
            }
            return "iPhone4"
        }
    }
    
    class func isIphone5() -> Bool {
        let device = self.deviceString()
        let range = (device as NSString?)?.range(of: "iPhone5")
        if range?.location != NSNotFound {
            return true
        } else {
            return false
        }
    }

    class func isIphone4S() -> Bool {
        let device = self.deviceString()
        let range = (device as NSString?)?.range(of: "iPhone4S")
        if range?.location != NSNotFound {
            return true
        } else {
            return false
        }
    }

    class func isiPhone() -> Bool {
        let device = self.deviceString()
        let range = (device as NSString?)?.range(of: "iPhone")
        if range?.location != NSNotFound {
            return true
        } else {
            return false
        }
    }

    class func isIpad() -> Bool {
        let device = self.deviceString()
        let range = (device as NSString?)?.range(of: "iPad")
//        print(range?.location != NSNotFound)
        if range?.location != NSNotFound {
            return true
        } else {
            return false
        }
    }

    class func isIphone4() -> Bool {
        let device = self.deviceString()
        var range = (device as NSString?)?.range(of: "iPhone4")
        if range?.location != NSNotFound {
            range = (device as NSString?)?.range(of: "S")
            //  4s
            if range?.location != NSNotFound {
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }

    class func beforeIpad2() -> Bool {
        let device = self.deviceString()
        if (device == "iPad2") {
            return true
        } else {
            return false
        }
    }

    class func isIpadAir() -> Bool {
        let deviceModelName = self.deviceModelName()
        if (deviceModelName == "iPad4,1") || (deviceModelName == "iPad4,2") || (deviceModelName == "iPad4,3") || deviceModelName?.hasPrefix("iPad5") ?? false {
            return true
        }
        return false
    }

    class func isIpadPro() -> Bool {
        let deviceModelName = self.deviceModelName()
        if (deviceModelName == "iPad6,3") || (deviceModelName == "iPad6,4") || (deviceModelName == "iPad6,7") || (deviceModelName == "iPad6,8") {
            print("System string: \("inside")")
            return true
        }
        return false
    }

    class func getGroupId() -> String? {
        let Id = UserDefaults.standard.string(forKey: "groupId")
        return Id
    }

    class func getStudyId() -> String? {
        let Id = UserDefaults.standard.string(forKey: "studyId")
        return Id
    }

    deinit {
    }

    func umeng() {
//        UMAnalyticsConfig.sharedInstance()?.appKey = UMENG_APPKEY
//        UMAnalyticsConfig.sharedInstance()?.channelId = "App Store"
        UMCommonLogManager.setUp()
        UMConfigure.setLogEnabled(true)
        UMConfigure.initWithAppkey(UMENG_APPKEY, channel: "App Store")
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
//        MobClick.setAppVersion(version)
//        MobClick.start(withConfigure: UMAnalyticsConfig.sharedInstance())
//        MobClick.setLogEnabled(true)
        
        
        print(MobClick.version())
    }

    func onlineConfigCallBack(_ note: Notification?) {

        if let userInfo = note?.userInfo {
            print("online config has fininshed and note = \(userInfo)")
        }
    }

    // for ip5 or higher device return true
    // iPad4,1-3 iPad5
    class func deviceModelName() -> String? {
//        var systemInfo: utsname
//        uname(&systemInfo)
//        return String(cString: systemInfo.machine, encoding: .utf8)
        return UIDevice.current.modelName
    }

    class func getIPadVersion(_ deviceString: String?) -> String? {
        // When the version of device string is greater than 3, then
        // we treat it as an iPad with Retina Display
//        let r1 = (deviceString as NSString?)?.range(of: "iPad")
//        let r2 = (deviceString as NSString?)?.range(of: " ")
//        let subString = NSRange(location: (r1?.location ?? 0) + (r1?.length ?? 0), length: (r2?.location ?? 0) - (r1?.location ?? 0) - (r1?.length ?? 0))
        return String(deviceString?.split(separator: ",").last ?? "")
        //NSLog(@"version: %@", versionString);
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        registerForPushNotifications()
        UIApplication.shared.isIdleTimerDisabled = true
        // analytics
        //[Crashlytics startWithAPIKey:@"c07d0cb3bb98552cf380b81ef6a59fdf5c39b4d0"];
        umeng()
        if AppDelegate.isiPhone() {
            Umeng.event("Launched", value: "iPhone")
        }
        if AppDelegate.isIpad() {
            Umeng.event("Launched", value: "iPad")
        }

        unKnownDeviceAlerted = false

        //[self showDeviceInfo];

        window = UIWindow(frame: UIScreen.main.bounds)
        // Override point for customization after application launch.

        //  figure out device type
        if AppDelegate.isIpad() {
            viewController = ViewController(nibName: "IpadViewController", bundle: nil)
        }

        //  iPhone 4 and 4s use IP4ViewController.nib
        if AppDelegate.isIphone4() || (AppDelegate.isIphone4S()) {
            viewController = ViewController(nibName: "IP4ViewController", bundle: nil)
        }
        /*  old methods, depricated
            if ( ([device isEqualToString:@"Verizon iPhone 4"]) || ([device isEqualToString:@"iPhone 4"]) || ([device isEqualToString:@"iPhone 4S"]) ) {

            }*/
        //  Other devices and iPhone5 use viewcontroller
        if AppDelegate.isIphone5() {
            viewController = ViewController(nibName: "ViewController", bundle: nil)
        }
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        UNUserNotificationCenter.current().delegate = self // Fallback on earlier versions

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        //NSLog(@"current zoom rate = %f", self.viewController.currentZoomRate);

        // end lock focus event
//        if (self.viewController?.lockFocusButton.isSelected ?? false) {
//            self.viewController?.lockButtonTapped(nil)
//        }

        // end focus level event
        if SYSTEM_VERSION_LESS_THAN(version: "8.0") {
        } else {
            var seconds: Float? = nil
            if let focusTimer = self.viewController?.focusTimer {
                seconds = Float(Date().timeIntervalSince(focusTimer))
            }
            if (seconds ?? 0.0) >= 3 {
                let label = String(format: "%ld", Int(self.viewController?.lensPosition ?? 0))
                if AppDelegate.isiPhone() {
                    Umeng.endEvent("FocusLevel_iPhone", primarykey: "FocusLevel_iPhone", value: label)
                }
                if AppDelegate.isIpad() {
                    Umeng.endEvent("FocusLevel_iPad", primarykey: "FocusLevel_iPad", value: label)
                }
            }
        }

        // end show pictures event
        let controllers = self.viewController?.children
        if (controllers?.count ?? 0) > 0 {
            let viewController = controllers?[0] as? UIViewController
            if (viewController is HelpViewController) {
                let helpViewController = viewController as? HelpViewController
                helpViewController?.exitView()
            } else if (viewController is UINavigationController) {
                let naviViewController = controllers?[0] as? UINavigationController
                let rootViewController = naviViewController?.children[0] as? RootViewController
                if rootViewController != nil {
                    rootViewController?.exitView()
                }
            }
        }

        // end image mode event
        if self.viewController?.isImageModeOn != nil {
            if AppDelegate.isIpad() {
                Umeng.endEvent("ImageMode_iPad", primarykey: "ImageMode_iPad", value: "Enh-Inv")
            }
            if AppDelegate.isiPhone() {
                Umeng.endEvent("ImageMode_iPhone", primarykey: "ImageMode_iPhone", value: "Enh-Inv")
            }
        }
        let value = String(format: "%ld", Int(ceil(self.viewController?.currentZoomRate ?? 0)))
        //[MobClick event:@"UserExit" attributes:@{@"ZoomLevel": value}];
        if AppDelegate.isiPhone() {
            Umeng.event("Zoom_Exit_iPhone", value: value)
        }
        if AppDelegate.isIpad() {
            Umeng.event("Zoom_Exit_iPad", value: value)
        }
        //    [self umengEvent:@"UserExit" attributes:@{@"ZoomLevel": value} number:@(self.viewController.currentZoomRate)];

        if (self.viewController != nil) {
        self.viewController?.scrollView.zoomScale = self.viewController?.scrollView.minimumZoomScale ?? 0.0
        }
        self.viewController?.resetFlashButton()
    }

    func umengEvent(_ eventId: String?, attributes: [AnyHashable : Any]?, number: NSNumber?) {
        let numberKey = "__ct__"
        var mutableDictionary = attributes
        mutableDictionary?[numberKey] = number?.stringValue ?? ""
        MobClick.event(eventId, attributes: mutableDictionary)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        viewController?.stopPlaying()
        viewController?.beforeEnterBackground()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        viewController?.resumePlaying()
        viewController?.applicationDidBecomeActive()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            return self.orientationLock
    }
    
    func registerForPushNotifications() {
      //1
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current()
            .requestAuthorization(
              options: [.alert, .sound, .badge]) { [weak self] granted, _ in
              print("Permission granted: \(granted)")
              guard granted else { return }
              self?.getNotificationSettings()
            }
        } else {
            // Fallback on earlier versions
        }
    }

    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    class func registerForRemoteNotifications(withLaunchOptions launchOptions: [AnyHashable : Any]?, entity: UMessageRegisterEntity?, completionHandler: ((_ granted: Bool, _ error: Error?) -> Void)? = nil) {
        let entity = UMessageRegisterEntity()
        //type是对推送的几个参数的选择，可以选择一个或者多个。默认是三个全部打开，即：声音，弹窗，角标
        entity.types = Int(UMessageAuthorizationOptions.badge.rawValue | UMessageAuthorizationOptions.sound.rawValue | UMessageAuthorizationOptions.alert.rawValue)
        if (Int(UIDevice.current.systemVersion) ?? 0 >= 8) && (Int(UIDevice.current.systemVersion) ?? 0 < 10) {
        let action1 = UIMutableUserNotificationAction()
        action1.identifier = "action1_identifier"
        action1.title = "打开应用"
        action1.activationMode = .foreground //当点击的时候启动程序

        let action2 = UIMutableUserNotificationAction() //第二按钮
        action2.identifier = "action2_identifier"
        action2.title = "忽略"
        action2.activationMode = .background //当点击的时候不启动程序，在后台处理
        action2.isAuthenticationRequired = true //需要解锁才能处理，如果action.activationMode = UIUserNotificationActivationModeForeground;则这个属性被忽略；
        action2.isDestructive = true
            let actionCategory1 = UIMutableUserNotificationCategory()
                actionCategory1.identifier = "category1" //这组动作的唯一标示
                actionCategory1.setActions([action1, action2], for: .default)
                let categories = Set<AnyHashable>([actionCategory1])
                entity.categories = categories
        }
        
        if Int(UIDevice.current.systemVersion) ?? 0 >= 10 {
            let action1_ios10 = UNNotificationAction(identifier: "action1_identifier", title: "打开应用", options: .foreground)
            let action2_ios10 = UNNotificationAction(identifier: "action2_identifier", title: "忽略", options: .foreground)

            //UNNotificationCategoryOptionNone
            //UNNotificationCategoryOptionCustomDismissAction  清除通知被触发会走通知的代理方法
            //UNNotificationCategoryOptionAllowInCarPlay       适用于行车模式
            let category1_ios10 = UNNotificationCategory(identifier: "category1", actions: [action1_ios10, action2_ios10], intentIdentifiers: [], options: .customDismissAction)
            let categories = Set<AnyHashable>([category1_ios10])
            entity.categories = categories
        }
        
        UMessage.registerForRemoteNotifications(launchOptions: launchOptions, entity: entity, completionHandler: { granted, error in
            if granted {
            } else {
            }
        })
    }
    
    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
      let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
      let token = tokenParts.joined()
      print("Device Token: \(token)")
      UserDefaults.standard.set(token, forKey: "device_token")
        
    }

    func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
      print("Failed to register: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
         //....TODO
               //过滤掉Push的撤销功能，因为PushSDK内部已经调用的completionHandler(UIBackgroundFetchResultNewData)，
               //防止两次调用completionHandler引起崩溃
        if (userInfo["aps.recall"] == nil) {
            //completionHandler(UIBackgroundFetchResultNewData)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if notification.request.trigger is UNPushNotificationTrigger {
            UMessage.setAutoAlert(true)
            //必须加这句代码
            UMessage.didReceiveRemoteNotification(userInfo)
        } else {
            //应用处于前台时的本地推送接受
        }
        completionHandler([.sound, .badge, .alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("sgvihgibsfknhifd")
        let userInfo = response.notification.request.content.userInfo
        if response.notification.request.trigger is UNPushNotificationTrigger {
            //必须加这句代码
            UMessage.didReceiveRemoteNotification(userInfo)
            if let text = userInfo["website"] as? String {
                if let url = URL(string: text) {
                    UIApplication.shared.open(url)
                }
            }
        } else {
            //应用处于后台时的本地推送接受
        }
    }

}


public extension UIDevice {

    /// pares the deveice name as the standard name
    var modelName: String {

        #if targetEnvironment(simulator)
            let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]!
        #else
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8 , value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
        #endif

        switch identifier {
        case "iPod5,1":                                 return "iPod5,1"
        case "iPod7,1":                                 return "iPod7,1"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone3,1"
        case "iPhone4,1":                               return "iPhone4,1"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone5,1"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone5,3"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone6,1"
        case "iPhone7,2":                               return "iPhone7,2"
        case "iPhone7,1":                               return "iPhone7,1"
        case "iPhone8,1":                               return "iPhone8,1"
        case "iPhone8,2":                               return "iPhone8,2"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone9,1"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone9,2"
        case "iPhone8,4":                               return "iPhone8,4"
        case "iPhone10,1", "iPhone10,4":                return "iPhone10,1"
        case "iPhone10,2", "iPhone10,5":                return "iPhone10,2"
        case "iPhone10,3", "iPhone10,6":                return "iPhone10,3"
        case "iPhone11,2":                              return "iPhone11,2"
        case "iPhone11,4", "iPhone11,6":                return "iPhone11,4"
        case "iPhone11,8":                              return "iPhone11,8"
        case "iPhone12,1":                              return "iPhone12,1"
        case "iPhone12,3":                              return "iPhone12,3"
        case "iPhone12,5":                              return "iPhone12,5"
        case "iPhone12,8":                              return "iPhone12,8"
        case "iPhone13,1":                              return "iPhone13,1"
        case "iPhone13,2":                              return "iPhone13,2"
        case "iPhone13,3":                              return "iPhone13,3"
        case "iPhone13,4":                              return "iPhone13,4"
        case "iPhone14,4":                              return "iPhone14,4"
        case "iPhone14,5":                              return "iPhone14,5"
        case "iPhone14,2":                              return "iPhone14,2"
        case "iPhone14,3":                              return "iPhone14,3"
        case "iPhone14,6":                              return "iPhone14,6"
        case "iPhone14,7":                              return "iPhone14,7"
        case "iPhone14,8":                              return "iPhone14,8"
        case "iPhone15,2":                              return "iPhone15,2"
        case "iPhone15,3":                              return "iPhone15,3"
            
            
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad2,1"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad3,1"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad3,4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad4,1"
        case "iPad5,3", "iPad5,4":                      return "iPad5,3"
        case "iPad6,11", "iPad6,12":                    return "iPad6,11"
        case "iPad7,5", "iPad7,6":                      return "iPad7,5"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad2,5"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad4,4"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad4,7"
        case "iPad5,1", "iPad5,2":                      return "iPad5,1"
        case "iPad6,3", "iPad6,4":                      return "iPad6,3"
        case "iPad6,7", "iPad6,8":                      return "iPad6,7"
        case "iPad7,1", "iPad7,2":                      return "iPad7,1"
        case "iPad7,3", "iPad7,4":                      return "iPad7,3"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad8,1"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad8,5"
        case "AppleTV5,3":                              return "AppleTV5,3"
        case "AppleTV6,2":                              return "AppleTV6,2"
        case "AudioAccessory1,1":                       return "AudioAccessory1,1"
        default:                                        return identifier
        }
    }

}
