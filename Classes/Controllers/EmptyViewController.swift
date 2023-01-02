//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  EmptyViewController.swift
//  SuperVision
//
//  Created by Pengfei Tan on 11/6/15.
//  Copyright © 2015 Zewen Li. All rights reserved.
//

import UIKit

class EmptyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func exitView() {
        backButtonTapped(nil)
    }

    @IBAction func backButtonTapped(_ sender: UIButton?) {
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
}
