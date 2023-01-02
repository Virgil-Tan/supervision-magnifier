//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  ImagePickupViewController.swift
//  EyeSee
//
//  Created by Zewen Li on 7/23/13.
//  Copyright (c) 2013 Zewen Li. All rights reserved.
//

import UIKit

class ImagePickupViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var scrollView: MyScrollView!
    var imagePicker: UIImagePickerController?
    @IBOutlet var button: UIButton!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Custom initialization
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.imageView?.contentMode = .scaleAspectFit
        scrollView.contentSize = CGSize(width:1936, height: 2592)
//        scrollView.contentSize = CGSize(width: 3000, height: 2500)
        scrollView.minimumZoomScale = 0
        // Do any additional setup after loading the view from its nib.
        imagePicker = UIImagePickerController()
        imagePicker?.delegate = self
        imagePicker?.sourceType = .camera
        if let view = imagePicker?.view {
            view.addSubview(view)
        }
        //[self presentViewController:self.imagePicker animated:YES completion:^{[self.imagePicker dismissModalViewControllerAnimated:YES];}];
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let imageToShow = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerOriginalImage")] as? UIImage
        view.addSubview(scrollView)
        scrollView.setImage(imageToShow)
        imagePicker?.view.removeFromSuperview()
        view.addSubview(button)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    @IBAction func back(_ sender: Any) {
        dismiss(animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
