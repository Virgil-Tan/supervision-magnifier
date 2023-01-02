//  Converted to Swift 5.1 by Swiftify v5.1.33873 - https://objectivec2swift.com/
//
//  MyScrollView.swift
//  EyeSee
//
//  Created by Zewen Li on 7/4/13.
//  Copyright (c) 2013 Zewen Li. All rights reserved.
//

import UIKit

let ScreenWidth = UIScreen.main.bounds.width
let ScreenHeight = UIScreen.main.bounds.height
let IS_IPHONE_5 = UIScreen.main.bounds.size.height == 568


protocol MyScrollViewDelegate: class {
    func touchesBegan(touches: Set<UITouch>?, with event: UIEvent?)
    func touchesEnded(touches: Set<UITouch>?, with event: UIEvent?)
    func scrollViewDidZoom(scrollView: UIScrollView)
    func handleDoubleTap(gesture: UIGestureRecognizer?)
    //- (void)handleSingleTap:(UIGestureRecognizer *)gesture;
}

extension MyScrollViewDelegate {
    func scrollViewDidZoom(_ scrollView: UIScrollView) {}
}

@objcMembers
class MyScrollView: UIScrollView, UIScrollViewDelegate {
    //  ImageView is used as render for image
    var imageView: UIImageView?
    //  delegate to the view controller
    weak var touchDelegate: MyScrollViewDelegate?

    //  zoom image
    func zoomRect(forScale scale: Float, withCenter center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = frame.size.height / CGFloat(scale)
        zoomRect.size.width = frame.size.width / CGFloat(scale)
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }

    //  set the image in imageview
    func setImage(_ image: UIImage?) {
        DispatchQueue.main.async {
            self.imageView?.image = image
        }
    }
    
    func getImage() -> UIImage? {
        return imageView?.image
    }
    

    func adjustImageViewCenter() {
        let offsetX = (bounds.size.width > contentSize.width) ? (bounds.size.width - contentSize.width) * 0.5 : 0.0
        let offsetY = (bounds.size.height > contentSize.height) ? (bounds.size.height - contentSize.height) * 0.5 : 0.0
        imageView?.center = CGPoint(x: contentSize.width * 0.5 + offsetX, y: contentSize.height * 0.5 + offsetY)
    }

    func changeImageViewFrame(_ frame: CGRect) {
        DispatchQueue.main.async {
            self.contentSize = frame.size

            self.imageView?.frame = frame
            self.adjustImageViewCenter()
        }
    }

    func debugOutput() {
        print("imageview width:\(imageView?.frame.size.width ?? 0.0), height:\(imageView?.frame.size.height ?? 0.0), origin:\(imageView?.frame.origin.x ?? 0.0),\(imageView?.frame.origin.y ?? 0.0), center:\(imageView?.center.x ?? 0.0), \(imageView?.center.y ?? 0.0), scrollview width:\(frame.size.width), height\(frame.size.height), center:\(center.x), \(center.y), origin:\(frame.origin.x),\(frame.origin.y), content size:\(contentSize.width),\(contentSize.height), current scale:\(zoomScale)\n")
    }

//#pragma - Initialize
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        //[self.pinchGestureRecognizer setEnabled:NO];
    }
    
    private func commonInit() {
        delegate = self
        self.frame = CGRect(x: 0, y: 0, width: CGFloat(ScreenWidth), height: CGFloat(ScreenHeight))
        initImageView()
        // set zoom scale from 0.5 to 8
        minimumZoomScale = 0.5
        maximumZoomScale = 8
        zoomScale = 1
        alwaysBounceHorizontal = false
        alwaysBounceVertical = false
        bounces = false
        backgroundColor = UIColor.black
        isMultipleTouchEnabled = true
        isUserInteractionEnabled = true
        bouncesZoom = false
        adjustImageViewCenter()
        contentOffset = CGPoint(x: contentSize.width / 2 - self.frame.size.width / 2, y: contentSize.height / 2 - self.frame.size.height / 2)
    }

    func initImageView() {
        imageView = UIImageView()
        // The imageView can be zoomed largest size
        imageView?.frame = frame
        imageView?.isUserInteractionEnabled = true
        
        if let imageView = imageView {
            addSubview(imageView)
        }
        imageView?.contentMode = .center

        //self.pagingEnabled = YES;

        //[self setScrollEnabled:NO]; // disable scroll
        //  Add single tap to imageview
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(singleTapGesture)

        // Add gesture,double tap zoom imageView.
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)

        // differentiate single and double tap and release
        singleTapGesture.require(toFail: doubleTapGesture)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        // Setting the swipe direction.
        swipeLeft.direction = .left
        swipeRight.direction = .right

        // Adding the swipe gesture on image view
        addGestureRecognizer(swipeLeft)
        addGestureRecognizer(swipeRight)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.frame = CGRect(x: 0, y: 0, width: CGFloat(ScreenWidth), height: CGFloat(ScreenHeight))
        commonInit()
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    - (void)drawRect:(CGRect)rect
    {
        // Drawing code
    }
    */
// MARK: - Zoom methods

// MARK: - Autorotate
    func shouldAutorotate(to interfaceOrientation: UIInterfaceOrientation) -> Bool {
        return interfaceOrientation != .portraitUpsideDown
    }

// MARK: - helper

// MARK: - UIScrollViewDelegate

    //- (void)handleSingleTap:(UIGestureRecognizer *)gesture {
    //    [self.touchDelegate handleSingleTap: gesture];
    //    return;
    //}
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    /*- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
    {
        [scrollView setZoomScale:scale animated:NO];
        [self touchesEnded:nil withEvent:nil];
    }*/
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        //[self scrollToCenter];
        adjustImageViewCenter()
        touchDelegate?.scrollViewDidZoom(scrollView)
    }

    func scrollToCenter() {
        let toCenter = CGPoint(x: contentSize.width / 2 - frame.size.width / 2, y: contentSize.height / 2 - frame.size.height / 2)
        print("toCenter:",toCenter)
        setContentOffset(toCenter, animated: false)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //    if (self.zoomScale <= self.minimumZoomScale) {
        //        self.scrollEnabled = false;
        //    }
        //    else
        //        self.scrollEnabled = true;
    }

    @objc func handleSwipe(_ swipe: UISwipeGestureRecognizer?) {
        if swipe?.direction == .left {
            print("Left Swipe")
        }
        if swipe?.direction == .right {
            print("Right Swipe")
        }
    }

    @objc func handleSingleTap(_ gesture: UIGestureRecognizer?) {
        if (gesture?.state == .ended) || (gesture?.state == .failed) {
            touchesEnded(Set.init(), with: nil)
        }
        
        return
    }

    @objc func handleDoubleTap(_ gesture: UIGestureRecognizer?) {
        if (gesture?.state == .ended) || (gesture?.state == .failed) {
            super.touchesEnded(Set.init(), with: nil)
        }
        touchDelegate?.handleDoubleTap(gesture: gesture)
        return
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        super.touchesEnded(Set.init(), with: nil)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        touchDelegate?.touchesEnded(touches: nil, with: nil)
        super.touchesEnded(Set.init(), with: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let event = event {
            touchDelegate?.touchesBegan(touches: touches, with: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.isEmpty {
            touchDelegate?.touchesEnded(touches: nil, with: event)
        } else {
            touchDelegate?.touchesEnded(touches: touches, with: event)
        }
    }
}

