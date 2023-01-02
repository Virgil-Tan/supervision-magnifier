////  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
////
////  UIAlertView+Blocks.swift
////  UIAlertViewBlocks
////
////  Created by Ryan Maxwell on 29/08/13.
////
////  The MIT License (MIT)
////
////  Copyright (c) 2013 Ryan Maxwell
////
////  Permission is hereby granted, free of charge, to any person obtaining a copy of
////  this software and associated documentation files (the "Software"), to deal in
////  the Software without restriction, including without limitation the rights to
////  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
////  the Software, and to permit persons to whom the Software is furnished to do so,
////  subject to the following conditions:
////
////  The above copyright notice and this permission notice shall be included in all
////  copies or substantial portions of the Software.
////
////  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
////  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
////  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
////  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
////  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
////  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
////
//
//import ObjectiveC
//import UIKit
//
//typealias UIAlertViewBlock = (UIAlertView) -> Void
//typealias UIAlertViewCompletionBlock = (UIAlertView, Int) -> Void
//private let UIAlertViewOriginalDelegateKey = UIAlertViewOriginalDelegateKey
//private let UIAlertViewTapBlockKey = UIAlertViewTapBlockKey
//private let UIAlertViewWillPresentBlockKey = UIAlertViewWillPresentBlockKey
//private let UIAlertViewDidPresentBlockKey = UIAlertViewDidPresentBlockKey
//private let UIAlertViewWillDismissBlockKey = UIAlertViewWillDismissBlockKey
//private let UIAlertViewDidDismissBlockKey = UIAlertViewDidDismissBlockKey
//private let UIAlertViewCancelBlockKey = UIAlertViewCancelBlockKey
//private let UIAlertViewShouldEnableFirstOtherButtonBlockKey = UIAlertViewShouldEnableFirstOtherButtonBlockKey
//
//extension UIAlertView {
//    class func show(withTitle title: String?, message: String?, style: UIAlertViewStyle, cancelButtonTitle: String?, otherButtonTitles: [AnyHashable]?, tap tapBlock: UIAlertViewCompletionBlock) -> Self {
//
//        let firstObject = otherButtonTitles?.count != nil ? otherButtonTitles?[0] : nil as? String
//
//        let alertView = self.init(title: title, message: message, delegate: nil, cancelButtonTitle: cancelButtonTitle, otherButtonTitles: firstObject)
//
//        alertView.alertViewStyle = style
//
//        if (otherButtonTitles?.count ?? 0) > 1 {
//            for buttonTitle in (otherButtonTitles as NSArray?)?.subarray(with: NSRange(location: 1, length: (otherButtonTitles?.count ?? 0) - 1)) ?? [] {
//                guard let buttonTitle = buttonTitle as? String else {
//                    continue
//                }
//                alertView.addButton(withTitle: buttonTitle)
//            }
//        }
//
//        if tapBlock != nil {
//            alertView.tapBlock = tapBlock
//        }
//
//        alertView.show()
//
//#if !__has_feature(objc_arc)
//        return alertView
//#else
//        return alertView
//#endif
//    }
//
//    class func show(withTitle title: String?, message: String?, cancelButtonTitle: String?, otherButtonTitles: [AnyHashable]?, tap tapBlock: UIAlertViewCompletionBlock) -> Self {
//
//        return self.show(withTitle: title, message: message, style: .default, cancelButtonTitle: cancelButtonTitle, otherButtonTitles: otherButtonTitles, tap: tapBlock)
//    }
//
//
//    var tapBlock: UIAlertViewCompletionBlock? {
//        get {
//            return objc_getAssociatedObject(self, &UIAlertViewTapBlockKey) as! UIAlertViewCompletionBlock
//        }
//        set(tapBlock) {
//            _checkDelegate()
//            objc_setAssociatedObject(self, &UIAlertViewTapBlockKey, tapBlock, .OBJC_ASSOCIATION_COPY)
//        }
//    }
//
//    var willDismissBlock: UIAlertViewCompletionBlock? {
//        get {
//            return objc_getAssociatedObject(self, &UIAlertViewWillDismissBlockKey) as! UIAlertViewCompletionBlock
//        }
//        set(willDismissBlock) {
//            _checkDelegate()
//            objc_setAssociatedObject(self, &UIAlertViewWillDismissBlockKey, willDismissBlock, .OBJC_ASSOCIATION_COPY)
//        }
//    }
//
//    var didDismissBlock: UIAlertViewCompletionBlock? {
//        get {
//            return objc_getAssociatedObject(self, &UIAlertViewDidDismissBlockKey) as! UIAlertViewCompletionBlock
//        }
//        set(didDismissBlock) {
//            _checkDelegate()
//            objc_setAssociatedObject(self, &UIAlertViewDidDismissBlockKey, didDismissBlock, .OBJC_ASSOCIATION_COPY)
//        }
//    }
//
//    var willPresentBlock: UIAlertViewBlock? {
//        get {
//            return objc_getAssociatedObject(self, &UIAlertViewWillPresentBlockKey) as! UIAlertViewBlock
//        }
//        set(willPresentBlock) {
//            _checkDelegate()
//            objc_setAssociatedObject(self, &UIAlertViewWillPresentBlockKey, willPresentBlock, .OBJC_ASSOCIATION_COPY)
//        }
//    }
//
//    var didPresentBlock: UIAlertViewBlock? {
//        get {
//            return objc_getAssociatedObject(self, &UIAlertViewDidPresentBlockKey) as! UIAlertViewBlock
//        }
//        set(didPresentBlock) {
//            _checkDelegate()
//            objc_setAssociatedObject(self, &UIAlertViewDidPresentBlockKey, didPresentBlock, .OBJC_ASSOCIATION_COPY)
//        }
//    }
//
//    var cancelBlock: UIAlertViewBlock? {
//        get {
//            return objc_getAssociatedObject(self, &UIAlertViewCancelBlockKey) as! UIAlertViewBlock
//        }
//        set(cancelBlock) {
//            _checkDelegate()
//            objc_setAssociatedObject(self, &UIAlertViewCancelBlockKey, cancelBlock, .OBJC_ASSOCIATION_COPY)
//        }
//    }
//
//    var shouldEnableFirstOtherButtonBlock: ((_ alertView: UIAlertView) -> Bool)? {
//        get {
//            return objc_getAssociatedObject(self, &UIAlertViewShouldEnableFirstOtherButtonBlockKey) as? @escaping (_ alertView: UIAlertView?) -> Bool ?? { _ in return false }
//        }
//        set(shouldEnableFirstOtherButtonBlock) {
//            _checkDelegate()
//            objc_setAssociatedObject(self, &UIAlertViewShouldEnableFirstOtherButtonBlockKey, shouldEnableFirstOtherButtonBlock, .OBJC_ASSOCIATION_COPY)
//        }
//    }
//
//// MARK: -
//    func _checkDelegate() {
//        if delegate != self as? UIAlertViewDelegate {
//            objc_setAssociatedObject(self, &UIAlertViewOriginalDelegateKey, delegate, .OBJC_ASSOCIATION_ASSIGN)
//            delegate = self as? UIAlertViewDelegate
//        }
//    }
//
//// MARK: - UIAlertViewDelegate
//    @objc func willPresent(_ alertView: UIAlertView) {
//        let block = alertView.willPresentBlock
//
//        if block != nil {
//            block?(alertView)
//        }
//
//        let originalDelegate = objc_getAssociatedObject(self, &UIAlertViewOriginalDelegateKey)
//        if originalDelegate != nil && originalDelegate?.responds(to: #selector(UIAlertViewDelegate.willPresent(_:))) ?? false {
//            originalDelegate?.willPresent(alertView)
//        }
//    }
//
//    @objc func didPresent(_ alertView: UIAlertView) {
//        let block = alertView.didPresentBlock
//
//        if block != nil {
//            block?(alertView)
//        }
//
//        let originalDelegate = objc_getAssociatedObject(self, &UIAlertViewOriginalDelegateKey)
//        if originalDelegate != nil && originalDelegate?.responds(to: #selector(UIAlertViewDelegate.didPresent(_:))) ?? false {
//            originalDelegate?.didPresent(alertView)
//        }
//    }
//
//    @objc func alertViewCancel(_ alertView: UIAlertView) {
//        let block = alertView.cancelBlock
//
//        if block != nil {
//            block?(alertView)
//        }
//
//        let originalDelegate = objc_getAssociatedObject(self, &UIAlertViewOriginalDelegateKey)
//        if originalDelegate != nil && originalDelegate?.responds(to: #selector(UIAlertViewDelegate.alertViewCancel(_:))) ?? false {
//            originalDelegate?.alertViewCancel(alertView)
//        }
//    }
//
//    @objc func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
//        let completion = alertView.tapBlock
//
//        if completion != nil {
//            completion?(alertView, buttonIndex)
//        }
//
//        let originalDelegate = objc_getAssociatedObject(self, &UIAlertViewOriginalDelegateKey)
//        if originalDelegate != nil && originalDelegate?.responds(to: #selector(UIAlertViewDelegate.alertView(_:clickedButtonAt:))) ?? false {
//            originalDelegate?.alertView(alertView, clickedButtonAt: buttonIndex)
//        }
//    }
//
//    @objc func alertView(_ alertView: UIAlertView, willDismissWithButtonIndex buttonIndex: Int) {
//        let completion = alertView.willDismissBlock
//
//        if completion != nil {
//            completion?(alertView, buttonIndex)
//        }
//
//        let originalDelegate = objc_getAssociatedObject(self, &UIAlertViewOriginalDelegateKey)
//        if originalDelegate != nil && originalDelegate?.responds(to: #selector(UIAlertViewDelegate.alertView(_:willDismissWithButtonIndex:))) ?? false {
//            originalDelegate?.alertView(alertView, willDismissWithButtonIndex: buttonIndex)
//        }
//    }
//
//    @objc func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
//        let completion = alertView.didDismissBlock
//
//        if completion != nil {
//            completion?(alertView, buttonIndex)
//        }
//
//        let originalDelegate = objc_getAssociatedObject(self, &UIAlertViewOriginalDelegateKey)
//        if originalDelegate != nil && originalDelegate?.responds(to: #selector(UIAlertViewDelegate.alertView(_:didDismissWithButtonIndex:))) ?? false {
//            originalDelegate?.alertView(alertView, didDismissWithButtonIndex: buttonIndex)
//        }
//    }
//
//    @objc func alertViewShouldEnableFirstOtherButton(_ alertView: UIAlertView) -> Bool {
//        let shouldEnableFirstOtherButtonBlock: ((_ alertView: UIAlertView?) -> Bool)? = alertView.shouldEnableFirstOtherButtonBlock
//
//        if shouldEnableFirstOtherButtonBlock != nil {
//            return shouldEnableFirstOtherButtonBlock?(alertView)
//        }
//
//        let originalDelegate = objc_getAssociatedObject(self, &UIAlertViewOriginalDelegateKey)
//        if originalDelegate != nil && originalDelegate?.responds(to: #selector(UIAlertViewDelegate.alertViewShouldEnableFirstOtherButton(_:))) ?? false {
//            return originalDelegate?.alertViewShouldEnableFirstOtherButton(alertView) ?? false
//        }
//
//        return true
//    }
//}
