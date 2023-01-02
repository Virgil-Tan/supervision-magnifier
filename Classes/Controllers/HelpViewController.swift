//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  HelpViewController.swift
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/8/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
class HelpViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var backButton: UIButton!
    @IBOutlet var scrollView: SVHelpScrollView!

    @IBAction func backButtonTapped() {
        let screenBounds = view.bounds
        let toFrame = CGRect(x: 0.0, y: screenBounds.size.height, width: screenBounds.size.width, height: screenBounds.size.height)
        willMove(toParent: nil)
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            self.view.frame = toFrame
        }) { finished in
            self.view.removeFromSuperview()
        }
        removeFromParent()
    }

    func exitView() {
        backButtonTapped()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //[MobClick beginLogPageView:@"HelperPage"];
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //[MobClick endLogPageView:@"HelperPage"];
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.accessibilityViewIsModal = true
        // Register keyboard notifications
        registerForKeyboardNotifications()
        // Set the scrollView's content size, to include the textField
        let bounds = UIScreen.main.bounds
        let width = bounds.size.width
        let height = bounds.size.height
        scrollView.contentSize = CGSize(width: width, height: height + 60)

        // Set delegate of textField
        scrollView.textField?.delegate = self
        scrollView.textField?.textColor = UIColor.black

        // In iOS8, the screen width and height are orientation-dependant. So in order to
        // show the helper view image normally in landscape mode, we need to exchange order
        // height and width.
        if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
            scrollView.imageView?.frame = CGRect(x: 0, y: 0, width: height, height: width)
            scrollView.contentSize = CGSize(width: height, height: width + 60)
            scrollView.textField?.frame = CGRect(x: 0, y: scrollView.imageView?.frame.size.height ?? 0.0, width: 200, height: 44)
            print(String(format: "Currently landscape:width: %.2f, height: %.2f", UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height))
        }

        // Show textField group ID whenever we open the helper view
        if let groupId = AppDelegate.getGroupId(),
            let studyId = AppDelegate.getStudyId() {
            scrollView.textField?.text = "\("SVM")\(studyId)\("-")\(groupId)"
        } else {
            scrollView.textField?.text = ""
        }
    }

// MARK: - orientation rotation
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if AppDelegate.isIpad() {
            scrollView.contentSize = CGSize(width: 2500, height: scrollView.contentSize.height)
        }
        //[self.scrollView adjustImageViewCenter];
    }

// MARK: - keyboard
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWasShown(_ aNotification: Notification?) {
        let info = aNotification?.userInfo
        let kbSize = (info?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: (kbSize?.height ?? 0.0) + 60, right: 0.0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    @objc func keyboardWillBeHidden(_ aNotification: Notification?) {
        let contentInsets: UIEdgeInsets = .zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    // Capture return button keyboard event
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        // Use "SVM" as prefix, and pass the numerical values before dash as study ID, and the
        // string after dash as group ID
        // Ex. SVM123-ABC, where study ID is 123, and group ID is ABC
        // rangeofString returns {NSNotFound, 0} if the string is not found
        let r1 = (textField.text as NSString?)?.range(of: "SVM")
        let r2 = (textField.text as NSString?)?.range(of: "-")
        if r1?.location != NSNotFound && r2?.location != NSNotFound && (r1?.location ?? 0) < (r2?.location ?? 0) {
            // Get range only when r1 and r2 exist and r1 is before r2
            let studyIdRange = NSRange(location: (r1?.location ?? 0) + (r1?.length ?? 0), length: (r2?.location ?? 0) - (r1?.location ?? 0) - (r1?.length ?? 0))
            let groupIdRange = NSRange(location: (r2?.location ?? 0) + (r2?.length ?? 0), length: (textField.text?.count ?? 0) - 1 - (r2?.location ?? 0))
            let studyId = (textField.text as NSString?)?.substring(with: studyIdRange)
            let groupId = (textField.text as NSString?)?.substring(with: groupIdRange)
            // Continue only when studyId and groupId are not empty
            if (studyId?.count ?? 0) > 0 && (groupId?.count ?? 0) > 0 {
                let notDigits = CharacterSet.decimalDigits.inverted
                let validChars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
                let invalidChars = validChars.inverted
                // Check if studyId only contatns 0 to 9, and groupId only contains alphabet characters
                if (studyId as NSString?)?.rangeOfCharacter(from: notDigits).location == NSNotFound && (groupId as NSString?)?.rangeOfCharacter(from: invalidChars).location == NSNotFound {
                    // Save studyId and groupId
                    UserDefaults.standard.set(groupId, forKey: "groupId")
                    UserDefaults.standard.set(studyId, forKey: "studyId")
                    UserDefaults.standard.synchronize()
                }
            }
        } else {
            // Set empty string to delete the groupID
            UserDefaults.standard.removeObject(forKey: "groupId")
            UserDefaults.standard.removeObject(forKey: "studyId")
            UserDefaults.standard.synchronize()
        }
        return false
    }
}
