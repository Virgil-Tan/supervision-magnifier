//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  DataViewController.swift
//  Photo Example
//
//  Created by Pengfei Tan on 10/27/15.
//  Copyright © 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

import UIKit

class DataViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet var imageView: UIImageView!
    var dataObject: String?
    var toolbar: UIToolbar?

    func resetZoomScale() {
        scrollView.zoomScale = 1
    }

    @IBOutlet private var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if navigationController?.isNavigationBarHidden ?? false {
            parent?.view.backgroundColor = UIColor.black
        } else {
            parent?.view.backgroundColor = UIColor.white
        }
        retrievePhoto(dataObject)
        //NSString *name = (NSString *)self.dataObject;
        //self.imageView.image = [UIImage imageWithData:self.dataObject];
        scrollView.delegate = self
        scrollView.maximumZoomScale = 8
        imageView.contentMode = .scaleAspectFill
    }

    func retrievePhoto(_ name: String?) {
        let pathArr = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let path = URL(fileURLWithPath: pathArr[0]).appendingPathComponent(name ?? "").absoluteString
        guard let url = URL.init(string: path  ?? "") else { return }
        let retrievedData = try? Data.init(contentsOf: url)//NSData(contentsOfFile: path) as Data?

        if let retrievedData = retrievedData {
            imageView.image = UIImage.init(data: retrievedData)
        }
        /*if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
                image = [[UIImage alloc] initWithCGImage: image.CGImage
                                                   scale: 1.0
                                             orientation: UIImageOrientationRight];
            }*/
       
    }

    @IBAction func handleSingleTap(_ sender: UITapGestureRecognizer) {

        let statusBarhidden = UIApplication.shared.isStatusBarHidden
        UIApplication.shared.setStatusBarHidden(!statusBarhidden, with: .none)

        //BOOL navigationBarHidden = [self.navigationController isNavigationBarHidden];
        //[self.navigationController setNavigationBarHidden:!navigationBarHidden animated:YES];

        //BOOL isToolBarHidden = [self.navigationController isToolbarHidden];
        //[self.navigationController setToolbarHidden:!isToolBarHidden animated:YES];

        //UIColor *currentColor = self.parentViewController.view.backgroundColor;
        //if (currentColor == [UIColor blackColor]) {
        //self.parentViewController.view.backgroundColor = [UIColor whiteColor];
        //} else {
        //self.parentViewController.view.backgroundColor = [UIColor blackColor];
        //}
    }

// MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
