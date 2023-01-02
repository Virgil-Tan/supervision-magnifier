//
//  ImageProcess.h
//  EyeSee
//
//  Created by Zewen Li on 7/5/13.
//  Copyright (c) 2013 Zewen Li. All rights reserved.
//

#ifdef __cplusplus

#include "../Frameworks/opencv2.framework/Headers/opencv.hpp"

#endif

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#include "OpenCV.framework/Headers/opencv2/opencv.hpp"

@interface ImageProcess : NSObject

//  threshold for fast detection
@property (nonatomic, assign) int threshold;
//  max feature number for fast detection;
@property (nonatomic, assign) int maxFeatureNumber;

@property (nonatomic, assign) int reducedSize;
@property (nonatomic, assign) int sizeMultiplier;

- (void) setLastImageMat: (UIImage *)processUIImage;
- (void) setCurrentImageMat: (UIImage *)processUIImage;
- (CGPoint) motionEstimation;
- (CGRect) calculateMyCroppedImage: (float)x ypos:(float)y width:(float)width height:(float)height scale:(float)currentScale bounds:(CGRect)bounds;
- (int) fastFeatureDetection;
- (double) calVariance;
@end
