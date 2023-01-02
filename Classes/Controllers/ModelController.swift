//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  ModelController.swift
//  Photo Example
//
//  Created by Pengfei Tan on 10/27/15.
//  Copyright © 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

import UIKit
@objcMembers
class ModelController: NSObject, UIPageViewControllerDataSource {
    
    var photoViewControllers: [DataViewController] = []
    
    private var storyboard: UIStoryboard?
    
    func viewController(at index: Int, storyboard: UIStoryboard?) -> DataViewController? {
        // Return the data view controller for the given index.
        if (pageData.count == 0) || (index >= pageData.count) {
            return nil
        }
        // Create a new view controller and pass suitable data.
        let dataViewController = storyboard?.instantiateViewController(withIdentifier: "DataViewController") as? DataViewController
        dataViewController?.dataObject = pageData[index]
        return dataViewController
    }
    
    func indexOf(_ viewController: DataViewController?) -> Int {
        if let dataObject = viewController?.dataObject {
            return pageData.firstIndex(of: dataObject) ?? 0
        }
        return 0
    }

    func removeObject(at index: Int) {
        deletePhoto(pageData[index])
        pageData.remove(at: index)
        self.photoViewControllers = pageData.map({ (obj) in
            let dataViewController = self.storyboard?.instantiateViewController(withIdentifier: "DataViewController") as? DataViewController
            dataViewController?.dataObject = obj
            return dataViewController
        }).compactMap({$0})
    }

    func getTitle(_ viewController: DataViewController?) -> String? {
        return String(format: "%lu/%lu", UInt(indexOf(viewController)) + 1, UInt(pageData.count))
    }

    func getData() -> [String]? {
        return pageData
    }

    func getLastViewController() -> DataViewController? {
        return photoViewControllers.last
    }

    func isEmpty() -> Bool {
        return pageData.count == 0
    }

    private var pageData: [String] = []

    init(_ array: [String], storyboard: UIStoryboard?) {
        super.init()
        pageData = array
        self.storyboard = storyboard
        self.photoViewControllers = pageData.map({ (obj) in
            let dataViewController = storyboard?.instantiateViewController(withIdentifier: "DataViewController") as? DataViewController
            dataViewController?.dataObject = obj
            return dataViewController
        }).compactMap({$0})
    }

    func deletePhoto(_ name: String?) {
        let pathArr = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let path = URL(fileURLWithPath: pathArr[0]).appendingPathComponent(name ?? "").absoluteString
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
        }
        storeData()
    }

    func storeData() {
        var svMagnifier: [AnyHashable : Any] = [:]
        svMagnifier["Photo Data"] = pageData
        UserDefaults.standard.set(svMagnifier, forKey: "SVMagnifier")
        UserDefaults.standard.synchronize()
    }

    func retrieveData() {
        let svMagnifier = UserDefaults.standard.dictionary(forKey: "SVMagnifier")
        if svMagnifier != nil {
            pageData = (svMagnifier?["Photo Data"] as? [String]) ?? []
        }
    }

// MARK: - Page View Controller Data Source
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = indexOf(viewController as? DataViewController)
        index -= 1
        if (index < 0) {
            return nil
        }
        return photoViewControllers[index]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = indexOf(viewController as? DataViewController)
        index += 1
        if index >= pageData.count {
            return nil
        }
        return photoViewControllers[index]
    }
}

/*
 A controller object that manages a simple model -- a collection of month names.

 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.

 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */
