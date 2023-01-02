//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  SVHelpScrollView.swift
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/9/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

import UIKit

func SYSTEM_VERSION_LESS_THAN(version: String) -> Bool {
    return UIDevice.current.systemVersion.compare(version, options: .numeric) == .orderedAscending
}

let ENGLISH = "en"
let CHINESE = "zh"
let RUSSIAN = "ru"
let SPANISH = "es"
let JAPANISE = "ja"
let ITILIAN = "it"
let FRENCH = "fr"
let GERMAN = "de"

@objcMembers
class SVHelpScrollView: UIScrollView {
    //  ImageView is used as render for image
    var imageView: UIImageView?
    var textField: UITextField?

    func adjustImageViewCenter() {
        let offsetX = (bounds.size.width > contentSize.width) ? (bounds.size.width - contentSize.width) * 0.5 : 0.0
        let offsetY = (bounds.size.height > contentSize.height) ? (bounds.size.height - contentSize.height) * 0.5 : 0.0
        imageView?.center = CGPoint(x: contentSize.width * 0.5 + offsetX, y: contentSize.height * 0.5 + offsetY)
    }

    private var width: Float = 0.0
    private var height: Float = 0.0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialBound()
        initialImageView()
        initialTextField()
    }

    func initialBound() {
        let bounds = UIScreen.main.bounds
        if SYSTEM_VERSION_LESS_THAN(version: "8.0") {
            width = Float(bounds.size.height)
            height = Float(bounds.size.width)
        } else {
            width = Float(bounds.size.width)
            height = Float(bounds.size.height)
        }
    }

    func initialImageView() {
        imageView = UIImageView()
        let image = UIImage(named: getCorrectHelpImage() ?? "")
        imageView?.image = image
        imageView?.frame = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        //[self.imageView setContentMode:UIViewContentModeScaleAspectFit];
        if let imageView = imageView {
            addSubview(imageView)
        }
    }

    func initialTextField() {
        textField = UITextField()
        textField?.frame = CGRect(x: 0, y: imageView?.frame.size.height ?? 0.0, width: 200, height: 44)
        textField?.backgroundColor = UIColor.white
        textField?.attributedPlaceholder = NSAttributedString(string: "Enter group ID", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
        textField?.borderStyle = .roundedRect
        if let textField = textField {
            addSubview(textField)
        }
    }

    func getCorrectHelpImage() -> String? {
        let languages = NSLocale.preferredLanguages
        var currentLanguage = languages[0]
        // extract components
        let components = NSLocale.components(fromLocaleIdentifier: currentLanguage)
        // get language designator
        let currentLanguage1 = components[NSLocale.Key.languageCode.rawValue]
        currentLanguage = NSLocale.current.languageCode ?? ""
//        let errorAlert = UIAlertView(title: "Language", message: "The following language was detcted: \(currentLanguage) \(currentLanguage1 ?? "")", delegate: nil, cancelButtonTitle: "OK")
//        errorAlert.show()
        if (currentLanguage1 == ENGLISH) {
            return "help_en.png"
        }
        if (currentLanguage1 == CHINESE) {
            return "help_zh.png"
        }
        if (currentLanguage1 == RUSSIAN) {
            return "help_ru.png"
        }
        if (currentLanguage1 == SPANISH) {
            return "help_es.png"
        }
        if (currentLanguage1 == JAPANISE) {
            return "help_ja.png"
        }
        if (currentLanguage1 == ITILIAN) {
            return "help_it.png"
        }
        if (currentLanguage1 == FRENCH) {
            return "help_fr.png"
        }
        if (currentLanguage1 == GERMAN) {
            return "help_de.png"
        } else {
            return "help_en.png"
        }
    }
}

