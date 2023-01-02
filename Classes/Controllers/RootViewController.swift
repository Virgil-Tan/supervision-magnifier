//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  RootViewController.swift
//  Photo Example
//
//  Created by Pengfei Tan on 10/27/15.
//  Copyright © 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
class RootViewController: UIViewController, UIPageViewControllerDelegate {
    var pageViewController: UIPageViewController?
    var toolbar: UIToolbar?

    func exitView() {
        backButtonTapped(nil)
    }

    private var modelController: ModelController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Configure the page view controller and add it as a child view controller.
        let options = [UIPageViewController.OptionsKey.interPageSpacing: 50]
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: options)
        pageViewController?.delegate = self

        let viewController = navigationController?.parent as? ViewController
        modelController = ModelController.init(viewController?.photoData ?? [], storyboard: storyboard)
        if let startingViewController = modelController?.getLastViewController() {
            pageViewController?.setViewControllers([startingViewController], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
            navigationItem.title = modelController?.getTitle(startingViewController)
        }

        pageViewController?.dataSource = modelController

        if let pageViewController = pageViewController {
            addChild(pageViewController)
        }
        if let view = pageViewController?.view {
            self.view.addSubview(view)
        }

        // Set navigation item

        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        let pageViewRect = view.bounds
        print("view bounds are: \(pageViewRect.size.height), \(pageViewRect.size.width)")
        /*if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                pageViewRect = CGRectInset(pageViewRect, 40.0, 40.0);
            }*/
        pageViewController?.view.frame = pageViewRect

        pageViewController?.didMove(toParent: self)

        // Add the page view controller's gesture recognizers to the book view controller's view so that the gestures are started more easily.
        view.gestureRecognizers = pageViewController?.gestureRecognizers

        // Configurations
        configureToolBar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @available(iOS 10.0, *)
    @IBAction func backButtonTapped(_ sender: UIButton?) {
        //NSLog(@"Back");
        if AppDelegate.isiPhone() {
            MobClick.endEvent("ShowPicutures", label: "iPhone")
        }
        if AppDelegate.isIpad() {
            MobClick.endEvent("ShowPicutures", label: "iPad")
        }
        let viewController = navigationController?.parent as? ViewController
        viewController?.photoData = modelController?.getData()

        let screenBounds = navigationController?.view.bounds
        let toFrame = CGRect(x: 0.0, y: CGFloat(fmax(Float(screenBounds?.size.width ?? 0.0), Float(screenBounds?.size.height ?? 0.0))), width: screenBounds?.size.width ?? 0.0, height: screenBounds?.size.height ?? 0.0)
        navigationController?.willMove(toParent: nil)
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            self.navigationController?.view.frame = toFrame
        }) { finished in
            self.navigationController?.view.removeFromSuperview()
        }
        navigationController?.removeFromParent()
    }

// MARK: - Configuration on toolbar
    func configureToolBar() {
        //CGRect frame = CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - 44,
        //[[UIScreen mainScreen] bounds].size.width, 44);
        // Set bar items
        let flexibleSpaceButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let shareButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareAction(_:)))
        let deleteButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAction(_:)))
        // Set bar items
        toolbarItems = [shareButtonItem, flexibleSpaceButtonItem, deleteButtonItem]
        if navigationController?.isToolbarHidden != nil {
            navigationController?.isToolbarHidden = false
        }
    }

    @objc func deleteAction(_ sender: UIButton?) {
        let currentViewController = pageViewController?.viewControllers?[0] as? DataViewController
        let index = modelController?.indexOf(currentViewController) ?? 0
        modelController?.removeObject(at: index)

   
        
        let viewController = navigationController?.parent as? ViewController
        viewController?.photoData?.remove(at: index)
        viewController?.storeData()
//        if (index + 1) < (modelController?.getData()?.count ?? 0) {
//            if let viewController = modelController?.photoViewControllers[index + 1] {
//                pageViewController?.setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
//                navigationItem.title = modelController?.getTitle(viewController)
//            }
//        }
        if modelController?.isEmpty() == true {
            backButtonTapped(nil)
            return
        }
        let nextIndex = index == modelController?.getData()?.count ? index - 1 : index
        let nextViewController = modelController?.viewController(at: nextIndex, storyboard: storyboard)
        let viewControllers = [nextViewController]
        pageViewController?.setViewControllers(viewControllers.compactMap { $0 }, direction: .forward, animated: false)

        // Set navigation item
        navigationItem.title = modelController?.getTitle(nextViewController)
    }

    @objc func shareAction(_ sender: Any?) {
        // Umeng SDK
        if AppDelegate.isiPhone() {
            Umeng.event("SharePhoto_iPhone", value: "iPhone")
        }
        if AppDelegate.isIpad() {
            Umeng.event("SharePhoto_iPad", value: "iPad")
        }
        // Add image
        let currentViewController = pageViewController?.viewControllers?[0] as? DataViewController
        let image = currentViewController?.imageView.image
        var sharingItems: [AnyHashable] = []
        if let image = image {
            sharingItems.append(image)
        }
        // Put in a seperate thread
        DispatchQueue.main.async(execute: {
            let activityController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
            // Exclude AirDrop, since it will cause the controller show up quite slowly
            if floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1 {
                activityController.excludedActivityTypes = [.airDrop]
            }
            //if iPhone
            if UI_USER_INTERFACE_IDIOM() == .phone {
                self.present(activityController, animated: true)
            } else {
                let popup = UIPopoverController(contentViewController: activityController)
                if let sender = sender as? UIBarButtonItem {
                    popup.present(from: sender, permittedArrowDirections: .any, animated: true)
                }
            }
        })
    }

// MARK: - UIPageViewController delegate methods
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            // title
            let currentViewController = self.pageViewController?.viewControllers?[0] as? DataViewController
            navigationItem.title = modelController?.getTitle(currentViewController)
            // reset zoom scale
            let previousViewController = previousViewControllers[0] as? DataViewController
            previousViewController?.resetZoomScale()
        }
    }

    deinit {
    }
}
