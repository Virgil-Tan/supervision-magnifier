//
//  ViewController.m
//  EyeSee
//
//  Created by Zewen Li on 7/4/13.
//  Copyright (c) 2013 Zewen Li. All rights reserved.
//

#import "ViewController.h"
using namespace cv;

#define INFOICONWIDTH 35
#define INFOBUTTONWIDTH 35
#define PLUSICONWIDTH 30
#define MINUSICONWIDTH 30
#define SLIDERWIDTH 44
#define SLIDERHEIGHT 250
#define degreeToRadians(x) (M_PI * x / 180.0)
#define OUTVBUTTONOFFSET 30
#define OUTHBUTTONOFFSET 15
#define BUTTONWIDTH 55
#define INBUTTONOFFSET 10

#define INFOBUTTONPORTRAITORIENTATIONY 30
#define INFOBUTTONLANDSCAPEORIENTATIONY  20
#define IADLANDSCAPEORIENTATIONY [ [ UIScreen mainScreen ] bounds ].size.width - IADLANDSCAPEHEIGHT
#define IADPORTRAITWIDTH  [ [ UIScreen mainScreen ] bounds ].size.width     // 768
#define IADLANDSCAPEWIDTH  [ [ UIScreen mainScreen ] bounds ].size.height   // 1024
#define IADPORTRAITHEIGHT   50
#define IADLANDSCAPEHEIGHT  32
#define IPADIADPORTRAITHEIGHT   66
#define IPADIADLANDSCAPEHEIGHT  66

#define ScreenWidth      CGRectGetWidth([[UIScreen mainScreen] bounds])
#define ScreenHeight     CGRectGetHeight([[UIScreen mainScreen] bounds])

#define IS_IPHONE_5 ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )
#define IS_IPHONE_4 ( [ [ UIScreen mainScreen ] bounds ].size.height == 480 )

#pragma mark - resolution settings
#define RESOLUTION1 AVCaptureSessionPreset1920x1080
#define RESOLUTION2 AVCaptureSessionPreset1280x720
#define RESOLUTION3 AVCaptureSessionPresetiFrame960x540
#define RESOLUTION4 AVCaptureSessionPreset640x480
#define IP5RESOLUTION RESOLUTION1
#define IPADRESOLUTION RESOLUTION1
#define IP4RESOLUTION RESOLUTION3

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

// ICON RESOURCES
#define ADDPNG "add.png"
#define MINUSPNG "minus.png"
#define CANCELPNG "cancel.png"
#define FLASHONPNG "flashon.png"
#define FLASHOFFPNG "flashoff.png"
#define LOCKPNG "lock.png"
#define UNLOCKPNG "unlock.png"
#define ONESTABLEPNG "onestable.png"
#define TWOSTABLEPNG "twostable.png"
#define SLIDERTHUMB "sliderthumb2.png"

// check focus change
#define FRAMES 50

// Get current orientation
#define ORIENTATION [[UIApplication sharedApplication] statusBarOrientation]

@interface ViewController ()
//  used for time analysis.
@property (nonatomic, assign) NSDate *lastDate;
@property (nonatomic, assign) float avgTimeForOneFrame;
@property (nonatomic, assign) float avgTimeForAck;
@property (nonatomic, assign) float avgTimeForConvert;
@property (nonatomic, assign) float avgTimeForDetect;
@property (nonatomic, assign) float avgTimeForTrack;
@property (nonatomic, assign) float avgTimeForPostProcess;
@property (nonatomic, assign) float avgFeaturePoints;
@property (nonatomic, assign) float maxFrameRate;
@property (nonatomic, assign) float minFrameRate;
@property (nonatomic, strong) IBOutlet UILabel* label;
@property (nonatomic, assign) NSDate* lockTimer;
@property (nonatomic, assign) NSDate* stableTimer;
// Accelerometer
@property (nonatomic) SuperVision::Accelerometer * accelerometer;

// tap to focus
@property (nonatomic) BOOL isTapped;
@property (nonatomic) BOOL isExposureAdjusted;
@property (nonatomic) CGPoint point;
@property (nonatomic) float tapZoomRate;
@property (nonatomic) float tapLensPosition;
@property (nonatomic) float ISO;
@property (nonatomic) CMTime duration;
@property (nonatomic) BOOL readyChangeBack;

@property (nonatomic) UIInterfaceOrientation lockInterfaceOrientation;
@property (nonatomic, assign) NSDate* startTimer;
@end

@implementation ViewController

@synthesize scrollView = _scrollView;
@synthesize captureSession = _captureSession;
@synthesize zoomRateLabel = _zoomRateLabel;
@synthesize zoomSlider = _zoomSlider;
@synthesize sliderMaxButton = _sliderMaxButton;
@synthesize sliderMinButton = _sliderMinButton;
@synthesize stableDirectionButton = _stableDirectionButton;
@synthesize flashLightButton = _flashLightButton;
@synthesize screenLockButton = _screenLockButton;
@synthesize currentZoomRate = _currentZoomRate;
@synthesize infoButton = _infoButton;
@synthesize isLocked = _isLocked;
@synthesize isStabilizationEnable = _isStabilizationEnable;
@synthesize imageNo = _imageNo;
@synthesize imageProcess = _imageProcess;
@synthesize isFlashOn = _isFlashOn;
@synthesize isHorizontalStable = _isHorizontalStable;
@synthesize motionX = _motionX;
@synthesize motionY = _motionY;
@synthesize imageOrientation = _imageOrientation;
@synthesize hideControls = _hideControls;
@synthesize currentResolution = _currentResolution;
@synthesize featureWindowHeight = _featureWindowHeight;
@synthesize featureWindowWidth = _featureWindowWidth;
@synthesize correctContentOffset = _correctContentOffset;
@synthesize resolutionHeight;
@synthesize resolutionWidth;

@synthesize varQueue;
@synthesize highVarImg;
@synthesize maxVariance;
@synthesize adjustingFocus;
@synthesize lockDelay;
@synthesize volumeListener;
@synthesize helpViewController;
@synthesize saveButton = _saveButton;
@synthesize imageModeButton = _imageModeButton;

#pragma mark -
#pragma mark Initial Functions


- (void)initialSettings {
    self.currentZoomRate = 1;
    self.avgFeaturePoints = 0;
    self.avgTimeForAck = 0;
    self.avgTimeForConvert = 0;
    self.avgTimeForDetect = 0;
    self.avgTimeForOneFrame = 0;
    self.avgTimeForPostProcess = 0;
    self.avgTimeForTrack = 0;
    self.minFrameRate = 20;
    self.maxFrameRate = 30;
    self.imageNo = 0;
    self.imageProcess = [[ImageProcess alloc] init];
    /*  set the flashLight by default off */
    self.isFlashOn = false;
    self.isStabilizationEnable = false;
    /*  set the horizontal stabilization true by default. */
    self.isHorizontalStable = false;
    self.motionX = 0;
    self.motionY = 0;
    self.isLocked = false;
    self.beforeLock = false;
    self.imageOrientation = UIImageOrientationRight;
    self.hideControls = false;
    self.correctContentOffset = CGPointZero;
    [self.scrollView setZoomScale:self.currentZoomRate];
    self.varQueue = [[NSMutableArray alloc]init];
    self.maxVariance = 0;
    self.adjustingFocus = YES;
    self.counter = 0;
    [self.message setHidden:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.isTapped = false;
    self.isExposureAdjusted = false;
    self.readyChangeBack = false;
    self.photoData = [[NSMutableArray alloc] init];
//    [self.scrollView setScrollEnabled:NO];
    if ([self isIpad]) {
        self.currentResolution = IPADRESOLUTION;
        [self.scrollView setZoomScale:1];
        [self.zoomSlider setValue:1];
        float viewScale = fmin(self.scrollView.imageView.frame.size.width/ScreenWidth,
                              self.scrollView.imageView.frame.size.height/ScreenHeight);
        [self setMinimalZoomScale:1/viewScale];
        self.featureWindowWidth = 192;
        self.featureWindowHeight = 108;
        self.resolutionWidth = 1080;
        self.resolutionHeight = 1920;
        [self.imageProcess setMaxFeatureNumber:20];
        self.lockDelay = 10;
        if ([self beforeIpad2]) {
            self.currentResolution = RESOLUTION2;
            self.scrollView.zoomScale = 1.2;
            [self setMinimalZoomScale:1.2];
        }
        // Show flash button for iPad pro
        if ([self isIpadPro]) {
            NSLog(@"ipad pro: %d", self.flashLightButton.hidden);
            self.flashLightButton.hidden = NO;
        }
        return;
    }
    if ([self isIphone5]) {
        self.currentResolution = IP5RESOLUTION;
        [self.scrollView setZoomScale:1];
        [self.zoomSlider setValue:1];
        self.featureWindowWidth = 256;
        self.featureWindowHeight = 256;
        [self.imageProcess setMaxFeatureNumber:20];
        [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080, 1920)];
        float viewScale = fmin(self.scrollView.imageView.frame.size.width/ScreenWidth,
                              self.scrollView.imageView.frame.size.height/ScreenHeight);
//        [self.scrollView setMinimumZoomScale:1/viewScale];
//        [self.zoomSlider setMinimumValue:1/viewScale];
        [self setMinimalZoomScale:1/viewScale];
        NSLog(@"%@%f", @"minimal zoom scale: ", 1/viewScale);
        NSLog(@"%@%f", @"frame width scale: ", ScreenWidth);
        NSLog(@"%@%f", @"frame height scale: ", ScreenHeight);
        self.resolutionWidth = 1080;
        self.resolutionHeight = 1920;
        self.lockDelay = 10;
        return;
    }
    if (([self isIphone4]) || ([self isIphone4S])) {
        self.currentResolution = IP4RESOLUTION;
        self.featureWindowWidth = 128;
        self.featureWindowHeight = 72;
        [self.imageProcess setMaxFeatureNumber:6];
        [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 540*self.currentZoomRate, 960*self.currentZoomRate)];
        float viewScale = fmin(self.scrollView.imageView.frame.size.width/ScreenWidth,
                              self.scrollView.imageView.frame.size.height/ScreenHeight);
        [self.scrollView setMinimumZoomScale:1/viewScale];
        [self.zoomSlider setMinimumValue:1/viewScale];
        self.resolutionWidth = 540*self.currentZoomRate;
        self.resolutionHeight = 960*self.currentZoomRate;
        [self.scrollView setZoomScale:1];
        self.lockDelay = [self isIphone4]? 4:8;
        NSLog(@"%d", self.lockDelay);
        return;
    }
    else {
        return;
    }
}

- (void) initialControls {
    //  Customizing the UISlider
    UIImage *maxImage = [UIImage imageNamed:@"empty.png"];
    UIImage *minImage = [UIImage imageNamed:@"empty.png"];
    UIImage *thumbImage = [UIImage imageWithCGImage:[[UIImage imageNamed:@SLIDERTHUMB] CGImage] scale:2 orientation:UIImageOrientationUp];
    [[UISlider appearance] setMaximumTrackImage:maxImage
                                       forState:UIControlStateNormal];
    [[UISlider appearance] setMinimumTrackImage:minImage
                                       forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage
                                forState:UIControlStateNormal];

    //  set the slider vertical on screen
    CGAffineTransform transformRotate = CGAffineTransformMakeRotation(degreeToRadians(-90));
    self.zoomSlider.transform = transformRotate;
    
    CGRect bounds = [[UIScreen mainScreen] bounds];

    [self.scrollView setFrame:bounds];
    [self.saveButton setHidden:YES];
    //[self.photoButton setHidden:YES];
    /*
    [self.infoButton.imageView setFrame:
     CGRectMake(0,
                0,
                INFOICONWIDTH,
                INFOICONWIDTH)];
    [self.infoButton setFrame:
     CGRectMake(bounds.size.width - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
                INFOBUTTONPORTRAITORIENTATIONY,
                INFOBUTTONWIDTH,
                INFOBUTTONWIDTH)];

    [self.sliderBackground setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH + 4,
                                               bounds.size.height/2 - SLIDERHEIGHT/2 + 14,
                                               SLIDERWIDTH - 10,
                                               SLIDERHEIGHT - 27)];
    
    [self.zoomSlider setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH,
                                         bounds.size.height/2 - SLIDERHEIGHT/2,
                                         SLIDERWIDTH,
                                         SLIDERHEIGHT)];

    
    [self.stableDirectionButton setFrame:
     CGRectMake(OUTHBUTTONOFFSET,
                bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                BUTTONWIDTH,
                BUTTONWIDTH)];
    [self.flashLightButton setFrame:
     CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET + BUTTONWIDTH,
                bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                BUTTONWIDTH,
                BUTTONWIDTH)];
    [self.screenLockButton setFrame:
     CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET*2 + 2*BUTTONWIDTH,
                bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                BUTTONWIDTH,
                BUTTONWIDTH)];
     */
    
    self.scrollView.touchDelegate = self;

}

- (void)initialNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(beforeEnterBackground)
        name:UIApplicationDidEnterBackgroundNotification
      object:nil];
}

//  initial capture settings from camerra flow
- (void) initialCapture {
    /*And we create a capture session*/
    self.captureSession = [[AVCaptureSession alloc] init];
	/*We setup the input*/
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice
                                                                               error:&error];
    if (!error) {
        if ([self.captureSession canAddInput:captureInput]) {
            [self.captureSession addInput:captureInput];
        } else {
            NSLog(@"Video input add-to-session failed");
        }
    } else {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"No permission to get access to camera."
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
        NSLog(@"Video input creation failed");
    }
	/*We setupt the output*/
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	/*While a frame is processes in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
	 If you don't want this behaviour set the property to NO */
	captureOutput.alwaysDiscardsLateVideoFrames = YES;
	/*We specify a minimum duration for each frame (play with this settings to avoid having too many frames waiting
	 in the queue because it can cause memory issues). It is similar to the inverse of the maximum framerate.
	 In this example we set a min frame duration of 1/10 seconds so a maximum framerate of 10fps. We say that
	 we are not able to process more than 10 frames per second.*/
	
	/*We create a serial queue to handle the processing of our frames*/
	dispatch_queue_t queue;
	queue = dispatch_queue_create("cameraQueue", NULL);
	[captureOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
	// Set the video output to store frame in BGRA (It is supposed to be faster)
	NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
	NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
	[captureOutput setVideoSettings:videoSettings];
    
    // for ios 5.0  However, it does not work
    AVCaptureConnection *conn = [captureOutput connectionWithMediaType:AVMediaTypeVideo];
    conn.videoMinFrameDuration = CMTimeMake(1, self.minFrameRate);
    conn.videoMaxFrameDuration = CMTimeMake(1, self.maxFrameRate);
    [conn release];
    
	/*We add input and output*/
	[self.captureSession addOutput:captureOutput];
    /*We use medium quality, ont the iPhone 4 this demo would be laging too much, the conversion in UIImage and CGImage demands too much ressources for a 720p resolution.*/
    [self.captureSession setSessionPreset:self.currentResolution];

    if ([self.captureDevice lockForConfiguration:nil] && !SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        self.captureDevice.videoZoomFactor = self.captureDevice.activeFormat.videoZoomFactorUpscaleThreshold;
        [self.captureDevice unlockForConfiguration];
        NSLog(@"%@, %f", @"max factor: ", self.captureDevice.videoZoomFactor);
    }
    
    /*We start the capture*/
	[self.captureSession startRunning];
    
    // initial date time.
    self.lastDate = [[NSDate date] retain];
    
    // initial focus timer
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        ;
    } else {
        self.focusTimer = [[NSDate date] retain];
        //float angle = [self getAngle];
        float offset = [self getOffset];
        self.lensPosition = [self getLevel:_accelerometer -> getCurrent() offset:offset];
        NSString *label = [NSString stringWithFormat:@"%ld", (long)self.lensPosition];
        if ([self isiPhone]) {
            [Umeng beginEvent:@"FocusLevel_iPhone" primarykey:@"FocusLevel_iPhone" value:label];
        }
        if ([self isIpad]) {
            [Umeng beginEvent:@"FocusLevel_iPad" primarykey: @"FocusLevel_iPad" value:label];
        }
    }
    
}

/* 
    Zewen Li hasn't finished yet. Tested work, and resolution reached beyond 1920*1080, that's great.
    However, it didn't get focused. Currently no more time could spent on that, stopped here, sorry.
    this link may be of help.http://www.musicalgeometry.com/?p=1297
- (void) switchToStillImageMode {

    [self.captureSession removeOutput:[self.captureSession.outputs objectAtIndex:0]];
    AVCaptureStillImageOutput *stillImageCaptureOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [stillImageCaptureOutput setOutputSettings:outputSettings];
    [self.captureSession addOutput:stillImageCaptureOutput];
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    [self lockAutoFocus];
        
    AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in stillImageCaptureOutput.connections) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {
            break;
        }
	}
    [stillImageCaptureOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                         completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                                                             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                                                             UIImage *image = [[UIImage alloc] initWithData:imageData];
                                                             [self.scrollView setImage:image];
                                                             [image release];
                                                             [self.scrollView setMinimumZoomScale:0];
                                                             self.scrollView.zoomScale = 0.2;
                                                         }];
}
*/

- (void) initialVloumeListener {
    volumeListener = [[VolumeListener alloc] init];
    [[self.view viewWithTag:54870149] removeFromSuperview];
    [self.view addSubview: [volumeListener dummyVolume]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

- (void)volumeChanged:(NSNotification *)notification
{
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    
    if (musicPlayer.volume == volumeListener.systemVolume) {
        return;
    }
    [musicPlayer setVolume:volumeListener.systemVolume];
    [self lockButtonTapped:nil];
}

- (void)initialMotion {
    //  Accelerometer
    self.accelerometer = new SuperVision::Accelerometer();
    _accelerometer->start();
}

- (void)showAlert:(NSString *)s {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Test"
                                                 message:s
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    av.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            NSLog(@"Username: %@", [[alertView textFieldAtIndex:0] text]);
            NSLog(@"Password: %@", [[alertView textFieldAtIndex:1] text]);
        } else if (buttonIndex == alertView.cancelButtonIndex) {
            NSLog(@"Cancelled.");
        }
    };
    
    av.shouldEnableFirstOtherButtonBlock = ^BOOL(UIAlertView *alertView){
        return ([[[alertView textFieldAtIndex:1] text] length] > 0);
    };
    
    [av show];
    [av release];
}

- (void)viewDidLoad
{
    [self lockAutoFocus];
    //[MobClick event:@"Test" label:@"Lock Auto Focus Successfully."];
    [self unlockAutoFocus];
    //[MobClick event:@"Test" label:@"Unlock Auto Focus Successfully."];
    [super viewDidLoad];
    
    [self initialControls];
    //[MobClick event:@"Test" label:@"Init Controls Successfully."];
    [self initialSettings];
    //[MobClick event:@"Test" label:@"Init Settings Successfully."];
    [self initialNotification];
    //[MobClick event:@"Test" label:@"Init Notification Successfully."];
    [self initialMotion];
    //[MobClick event:@"Test" label:@"Init Motion Successfully."];
    [self initialCapture];
    //[MobClick event:@"Test" label:@"Init Capture Successfully."];
    [self setupControlsPosition];
    //[MobClick event:@"Test" label:@"Setup Controls Position Successfully."];
    [self initialVloumeListener];
    //[MobClick event:@"Test" label:@"Init Volume Listener Successfully."];
    [self performSelectorOnMainThread:@selector(adjustCurrentOrientation) withObject:nil waitUntilDone:YES];
    //[MobClick event:@"Test" label:@"Adjust Orientation Successfully."];
    [self scrollToCenter];
    //[MobClick event:@"Test" label:@"Scroll To Center Successfully."];
    [self retrieveData];
    //[MobClick event:@"Test" label:@"Retrieve Data Successfully."];
    // Set the start time for CalTimeSum event in Umeng SDK
}

#pragma mark - touches delegate management

- (void)handleSingleTap:(UITapGestureRecognizer *)tapRecognizer  {
    NSLog(@"single tap");
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    double screenWidth = screenRect.size.width;
    double screenHeight = screenRect.size.height;
    //NSLog(@"width = %f, height = %f", screenWidth, screenHeight);
    if (screenWidth > screenHeight) {
        double temp = screenHeight;
        screenHeight = screenWidth;
        screenWidth = temp;
    }
    CGPoint oldPoint = [tapRecognizer locationInView:nil];
    // point of interest x is vertial axis y is horizental axis
    CGPoint point = CGPointMake(oldPoint.y / screenHeight, (screenWidth - oldPoint.x) / screenWidth);
    if (UIInterfaceOrientationIsLandscape(ORIENTATION)) {
        point = CGPointMake(oldPoint.y / screenHeight, (screenWidth - oldPoint.x) / screenWidth);
    }
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            NSError *error;
            [device lockForConfiguration:&error];
            CGPoint newPoint = CGPointMake((point.x - 0.5) / (self.currentZoomRate / self.scrollView.minimumZoomScale) + 0.5,
                                           (point.y - 0.5) / (self.currentZoomRate / self.scrollView.minimumZoomScale) + 0.5);
            if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [device isFocusPointOfInterestSupported] && ![self.lockFocusButton isSelected]) {
                [device setFocusPointOfInterest:newPoint];
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
            }
            [device setExposurePointOfInterest:newPoint];
            [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            [device unlockForConfiguration];
            self.isTapped = true;
            self.point = newPoint;
            self.tapZoomRate = self.currentZoomRate;
            [self saveExposureInformation];
            //self.tapLensPosition = self.captureDevice.lensPosition;
        }
    }
}

- (void)saveExposureInformation{
    double delayInSeconds = 1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // original arguments
        self.ISO = self.captureDevice.ISO;
        self.duration = self.captureDevice.exposureDuration;
        self.isExposureAdjusted = true;
    });
}

//  double tap to hide or show controls
- (void)handleDoubleTap:(UIGestureRecognizer *)gesture {
    if (self.hideControls) {
        self.hideControls = false;
        [self showAllcontrols];
    }
    else {
        if ([self isiPhone]) {
            [Umeng event:@"DoubleTouchHide" value:@"iPhone"];
        }
        if ([self isIpad]) {
            [Umeng event:@"DoubleTouchHide" value:@"iPad"];
        }
        self.hideControls = true;
        [self hideAllControls];
    }
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches count] == 1) {
        self.stableTimer = [[NSDate date] retain];
        // trace touch event.
        if (self.isHorizontalStable == false) {
//            [MobClick event:@"TouchCount" label:@"XYStabilization"];
            if ([self isiPhone]) {
                [Umeng beginEvent:@"Stabilization_iPhone" primarykey:@"Stabilization_iPhone" value:@"XYStabilization"];
            }
            if ([self isIpad]) {
                [Umeng beginEvent:@"Stabilization_iPad" primarykey:@"Stabilization_iPad" value:@"XYStabilization"];
            }
        }
        else {
//            [MobClick event:@"TouchCount" label:@"VerticalStabilization"];
            if ([self isiPhone]) {
                [Umeng beginEvent:@"Stabilization_iPhone" primarykey:@"Stabilization_iPhone" value:@"VerticalStabilization"];
            }
            if ([self isIpad]) {
                [Umeng beginEvent:@"Stabilization_iPad" primarykey:@"Stabilization_iPad" value:@"VerticalStabilization"];
            }
        }
        // For test
                //NSDictionary *dictionary = [[NSMutableDictionary alloc] init];;
                //[dictionary setValue:@"123" forKey:groupID];
                //[MobClick beginEvent: @"Stabilization_iPhone" primarykey:@"Stabilizationsp_iPhone" attributes:dictionary];
                //[MobClick beginEvent:@"Stabilization_iPhone" label:[NSString stringWithFormat:@"%@%@", @"Schepens", groupID]];
        [self reSet];
        self.isStabilizationEnable = true;
        //    [self lockAutoFocus];
    }
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // trace touch event
    float seconds = [[NSDate date] timeIntervalSinceDate:self.stableTimer];

    if (seconds >= 1) {
        if (self.isHorizontalStable == false) {
            if ([self isiPhone]) {
                [Umeng endEvent:@"Stabilization_iPhone" primarykey:@"Stabilization_iPhone" value:@"XYStabilization"];
            }
            if ([self isIpad]) {
                [Umeng endEvent:@"Stabilization_iPad" primarykey:@"Stabilization_iPad" value:@"XYStabilization"];
            }
        }
        else {
            if ([self isiPhone]) {
                [Umeng endEvent:@"Stabilization_iPhone" primarykey:@"Stabilization_iPhone" value:@"VerticalStabilization"];
            }
            if ([self isIpad]) {
                [Umeng endEvent:@"Stabilization_iPad" primarykey:@"Stabilization_iPad" value:@"VerticalStabilization"];
            }
        }
    }
    //    [self unlockAutoFocus];
    self.isStabilizationEnable = false;
    [self reSet];
}

-(void)umengEvent:(NSString *)eventId attributes:(NSDictionary *)attributes number:(NSNumber *)number{
    NSString *numberKey = @"__ct__";
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:attributes];
    [mutableDictionary setObject:[number stringValue] forKey:numberKey];
    [MobClick event:eventId attributes:mutableDictionary];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
//    NSString *value = [NSString stringWithFormat:@"%f", self.currentZoomRate];
    //[MobClick event:@"UserExit" attributes:@{@"ZoomLevel": value}];
//    [self umengEvent:@"UserExit" attributes:@{@"ZoomLevel": value} number:@(self.currentZoomRate)];
    self.currentZoomRate = scrollView.zoomScale;
//    if (self.currentZoomRate >= scrollView.maximumZoomScale) {
//        self.currentZoomRate = scrollView.maximumZoomScale;
//    }
//    else if (self.currentZoomRate <= scrollView.minimumZoomScale) {
//        self.currentZoomRate = scrollView.minimumZoomScale;
//    }
    [self.zoomSlider setValue:self.currentZoomRate animated:YES];
    NSLog(@"Zoom Slider value:%f", self.currentZoomRate);
    if (self.isTapped) {
        [self adjustExposurePoint];
    }
}

- (void)adjustExposurePoint {
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            CGPoint newPoint = CGPointMake((self.point.x - 0.5) / (self.currentZoomRate / self.tapZoomRate) + 0.5,
                                           (self.point.y - 0.5) / (self.currentZoomRate / self.tapZoomRate) + 0.5);
            NSLog(@"point x = %f, point y = %f", newPoint.x, newPoint.y);
            NSError *error;
            [device lockForConfiguration:&error];
            [device setExposurePointOfInterest:newPoint];
            [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            [device unlockForConfiguration];
        }
    }
}

#pragma mark - orientation rotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

/*
- (void) setupControlsPosition {
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    ///--- portrait
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        [self.stableDirectionButton setFrame:
         CGRectMake(OUTHBUTTONOFFSET,
                    bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
        [self.flashLightButton setFrame:
         CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET + BUTTONWIDTH,
                    bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
        [self.screenLockButton setFrame:
         CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET*2 + 2*BUTTONWIDTH,
                    bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
        [self.sliderBackground setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH + 4,
                                                   bounds.size.height/2 - SLIDERHEIGHT/2 + 14,
                                                   SLIDERWIDTH - 10,
                                                   SLIDERHEIGHT - 27)];
        [self.zoomSlider setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH,
                                             bounds.size.height/2 - SLIDERHEIGHT / 2,
                                             SLIDERWIDTH,
                                             SLIDERHEIGHT)];
        
        [self.infoButton setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
                                             INFOBUTTONPORTRAITORIENTATIONY+IPADIADPORTRAITHEIGHT,
                                             INFOBUTTONWIDTH,
                                             INFOBUTTONWIDTH)];
        
 
       // if ([self isIpad])
       //     [self.iadView setFrame:CGRectMake(0, 0, IADPORTRAITWIDTH, IPADIADPORTRAITHEIGHT)];
       // else
       //     [self.iadView setFrame:CGRectMake(0, 0, IADPORTRAITWIDTH, IADPORTRAITHEIGHT)];
    }
    ///-- landscape
    else {
        [self.stableDirectionButton setFrame:
         CGRectMake(OUTHBUTTONOFFSET,
                    bounds.size.width - BUTTONWIDTH - OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
        [self.flashLightButton setFrame:
         CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET + BUTTONWIDTH,
                    bounds.size.width - BUTTONWIDTH - OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
        [self.screenLockButton setFrame:
         CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET*2 + 2*BUTTONWIDTH,
                    bounds.size.width - BUTTONWIDTH - OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
        [self.sliderBackground setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH + 4,
                                                   bounds.size.width/2 - SLIDERHEIGHT/2 + 14,
                                                   SLIDERWIDTH - 10,
                                                   SLIDERHEIGHT - 27)];
        [self.zoomSlider setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH,
                                             bounds.size.width/2 - SLIDERHEIGHT / 2,
                                             SLIDERWIDTH,
                                             SLIDERHEIGHT)];
        
        [self.infoButton setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
                                             INFOBUTTONLANDSCAPEORIENTATIONY,
                                             INFOBUTTONWIDTH,
                                             INFOBUTTONWIDTH)];
        if ([self isIpad]) {
            [self.infoButton setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
                                                 INFOBUTTONPORTRAITORIENTATIONY+IPADIADPORTRAITHEIGHT,
                                                 INFOBUTTONWIDTH,
                                                 INFOBUTTONWIDTH)];
          //  [self.iadView setFrame:CGRectMake(0, 0, IADLANDSCAPEWIDTH, IPADIADPORTRAITHEIGHT)];
        }
        //if ([self isiPhone]) {
        //  [self.iadView setFrame:CGRectMake(0,
        //                                      IADLANDSCAPEORIENTATIONY,
        //                                      IADLANDSCAPEWIDTH,
        //                                      IPADIADLANDSCAPEHEIGHT)];
       //}
    }
}
*/

/////---- 10/07/2014 updated the layout: hide ad banner and move flash and screen lock buttons to right
- (void) setupControlsPosition {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    ///--- portrait
    if (UIInterfaceOrientationIsPortrait(ORIENTATION)) {
        [self.scrollView setFrame:bounds];
        [self.stableDirectionButton setFrame:
         CGRectMake(OUTHBUTTONOFFSET,
                    bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
        [self.flashLightButton setFrame:
         CGRectMake(bounds.size.width - (3*OUTHBUTTONOFFSET) - (2*INBUTTONOFFSET) - (2*BUTTONWIDTH),
                    bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
        [self.screenLockButton setFrame:
         CGRectMake(bounds.size.width - (3*OUTHBUTTONOFFSET) - INBUTTONOFFSET - BUTTONWIDTH,
                    bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
        [self.sliderBackground setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH + 4,
                                                   bounds.size.height/2 - SLIDERHEIGHT/2 + 14,
                                                   SLIDERWIDTH - 10,
                                                   SLIDERHEIGHT - 27)];
        [self.zoomSlider setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH,
                                             bounds.size.height/2 - SLIDERHEIGHT / 2,
                                             SLIDERWIDTH,
                                             SLIDERHEIGHT)];
        
        [self.infoButton setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
                                             INFOBUTTONPORTRAITORIENTATIONY+IPADIADPORTRAITHEIGHT,
                                             INFOBUTTONWIDTH,
                                             INFOBUTTONWIDTH)];
        // new save button
        [self.saveButton setFrame:
         CGRectMake(OUTHBUTTONOFFSET,
                    bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
        // new photo button
        [self.photoButton setFrame:
         CGRectMake(bounds.size.width - (3*OUTHBUTTONOFFSET) - INBUTTONOFFSET - BUTTONWIDTH,
                    OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
        // new image mode button
        [self.imageModeButton setFrame:
         CGRectMake(OUTHBUTTONOFFSET,
                    OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
        // new fix focus button
        [self.lockFocusButton setFrame:
         CGRectMake(bounds.size.width - (3*OUTHBUTTONOFFSET) - (2*INBUTTONOFFSET) - (2*BUTTONWIDTH),
                    OUTVBUTTONOFFSET,
                    BUTTONWIDTH,
                    BUTTONWIDTH)];
    }
    ///-- landscape
    else {
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            [self.stableDirectionButton setFrame:
             CGRectMake(OUTHBUTTONOFFSET,
                        bounds.size.width - BUTTONWIDTH - OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            [self.flashLightButton setFrame:
             CGRectMake(bounds.size.height - (4*OUTHBUTTONOFFSET) - (2*INBUTTONOFFSET) - (2*BUTTONWIDTH),
                        bounds.size.width - BUTTONWIDTH - OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            [self.screenLockButton setFrame:
             CGRectMake(bounds.size.height - (4*OUTHBUTTONOFFSET) - INBUTTONOFFSET - BUTTONWIDTH,
                        bounds.size.width - BUTTONWIDTH - OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            [self.sliderBackground setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH + 4,
                                                       bounds.size.width/2 - SLIDERHEIGHT/2 + 14,
                                                       SLIDERWIDTH - 10,
                                                       SLIDERHEIGHT - 27)];
            [self.zoomSlider setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH,
                                                 bounds.size.width/2 - SLIDERHEIGHT / 2,
                                                 SLIDERWIDTH,
                                                 SLIDERHEIGHT)];
            
            [self.infoButton setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
                                                 INFOBUTTONLANDSCAPEORIENTATIONY,
                                                 INFOBUTTONWIDTH,
                                                 INFOBUTTONWIDTH)];
            if ([self isIpad]) {
                [self.infoButton setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
                                                     INFOBUTTONPORTRAITORIENTATIONY+IPADIADPORTRAITHEIGHT,
                                                     INFOBUTTONWIDTH,
                                                     INFOBUTTONWIDTH)];
            }
            // new save button
            [self.saveButton setFrame:
             CGRectMake(OUTHBUTTONOFFSET,
                        bounds.size.width - BUTTONWIDTH - OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            // new photo button
            [self.photoButton setFrame:
             CGRectMake(bounds.size.height - (4*OUTHBUTTONOFFSET) - INBUTTONOFFSET - BUTTONWIDTH,
                        OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            // new image mode button
            [self.imageModeButton setFrame:
             CGRectMake(OUTHBUTTONOFFSET,
                        OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            // new fix focus button
            [self.lockFocusButton setFrame:
             CGRectMake(bounds.size.height - (4*OUTHBUTTONOFFSET) - (2*INBUTTONOFFSET) - (2*BUTTONWIDTH),
                        OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            
        } else { // update for iOS 8.0
            [self.scrollView setFrame:bounds];
            [self.stableDirectionButton setFrame:
             CGRectMake(OUTHBUTTONOFFSET,
                        bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            [self.flashLightButton setFrame:
             CGRectMake(bounds.size.width - (4*OUTHBUTTONOFFSET) - (2*INBUTTONOFFSET) - (2*BUTTONWIDTH),
                        bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            [self.screenLockButton setFrame:
             CGRectMake(bounds.size.width - (4*OUTHBUTTONOFFSET) - INBUTTONOFFSET - BUTTONWIDTH,
                        bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            
            [self.infoButton setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
                                                 INFOBUTTONLANDSCAPEORIENTATIONY,
                                                 INFOBUTTONWIDTH,
                                                 INFOBUTTONWIDTH)];
            [self.sliderBackground setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH + 4,
                                                       bounds.size.height/2 - SLIDERHEIGHT/2 + 24,
                                                       SLIDERWIDTH - 10,
                                                       SLIDERHEIGHT - 27)];
            [self.zoomSlider setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH,
                                                 bounds.size.height/2 - SLIDERHEIGHT / 2 + 10,
                                                 SLIDERWIDTH,
                                                 SLIDERHEIGHT)];
            if ([self isIpad]) {
                [self.infoButton setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
                                                     INFOBUTTONPORTRAITORIENTATIONY+IPADIADPORTRAITHEIGHT,
                                                     INFOBUTTONWIDTH,
                                                     INFOBUTTONWIDTH)];
            }
            // new save button
            [self.saveButton setFrame:
             CGRectMake(OUTHBUTTONOFFSET,
                        bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            // new photo button
            [self.photoButton setFrame:
             CGRectMake(bounds.size.width - (4*OUTHBUTTONOFFSET) - INBUTTONOFFSET - BUTTONWIDTH,
                        OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            // new image mode button
            [self.imageModeButton setFrame:
             CGRectMake(OUTHBUTTONOFFSET,
                        OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
            // new fix focus button
            [self.lockFocusButton setFrame:
             CGRectMake(bounds.size.width - (4*OUTHBUTTONOFFSET) - (2*INBUTTONOFFSET) - (2*BUTTONWIDTH),
                        OUTVBUTTONOFFSET,
                        BUTTONWIDTH,
                        BUTTONWIDTH)];
        }
    }
}


- (void) adjustCurrentOrientation {
    
    if ((ORIENTATION == UIInterfaceOrientationPortrait) /*|| (!self.isLocked)*/) {
        self.imageOrientation = UIImageOrientationRight;
        if ([self isIphone4] || [self isIphone4S]) {
            [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 540*self.currentZoomRate, 960*self.currentZoomRate)];
            //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
              //                                               [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
        }
        if ([self isIphone5]) {
            [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080*self.currentZoomRate, 1920*self.currentZoomRate)];
            //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
            //                                                 [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
            // width 768, height 1024
        }
        if ([self isIpad]) {
            //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080*self.currentZoomRate, 1920*self.currentZoomRate)];
            [self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
                                                                 [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
        }

    }
    else if (UIInterfaceOrientationIsLandscape(ORIENTATION) /*(!self.isLocked)*/) {
        
        if (ORIENTATION == UIInterfaceOrientationLandscapeRight) {
            self.imageOrientation = UIImageOrientationUp;
        }
        else {
            self.imageOrientation = UIImageOrientationDown;
        }
        
        //if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            if ([self isIphone4] || [self isIphone4S]) {
                [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 960*self.currentZoomRate, 540*self.currentZoomRate)];
                //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
                  //                                               [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
            }
            if ([self isIphone5]) {
                [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1920*self.currentZoomRate, 1080*self.currentZoomRate)];
                //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate,
                //                                                 [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate)];
            }
            if ([self isIpad]) {
                //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1920*self.currentZoomRate, 1080*self.currentZoomRate)];
                [self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
                                                                    [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
            }
        /*} else {
            if ([self isIphone4] || [self isIphone4S]) {
                [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 540*self.currentZoomRate, 960*self.currentZoomRate)];
                //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
                //                                               [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
            }
            if ([self isIphone5]) {
                [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080*self.currentZoomRate, 1920*self.currentZoomRate)];
                //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
                //                                                 [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
                // width 768, height 1024
            }
            if ([self isIpad]) {
                //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080*self.currentZoomRate, 1920*self.currentZoomRate)];
                [self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
                                                                 [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
            }
            
        }*/
    }
/*
    else if ((self.interfaceOrientation == UIInterfaceOrientationPortrait)&& (self.isLocked)) {
        self.imageOrientation = UIImageOrientationRight;
        if ([self isIphone4] || [self isIphone4S]) {
            [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 960*self.currentZoomRate, 540*self.currentZoomRate)];
            //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
            //                                               [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
        }
        if ([self isIphone5]) {
            [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1920*self.currentZoomRate, 1080*self.currentZoomRate)];
            //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
            //                                                 [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
            // width 768, height 1024
        }
        if ([self isIpad]) {
            //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080*self.currentZoomRate, 1920*self.currentZoomRate)];
            [self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
                                                             [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
        }
    }
    
    else if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)&& (self.isLocked)) {
        
        if ([self isIphone4] || [self isIphone4S]) {
            [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 540*self.currentZoomRate, 960*self.currentZoomRate)];
            //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate,
            //                                               [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate)];
        }
        if ([self isIphone5]) {
            [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080*self.currentZoomRate, 1920*self.currentZoomRate)];
            //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate,
            //                                                 [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate)];
        }
        if ([self isIpad]) {
            //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1920*self.currentZoomRate, 1080*self.currentZoomRate)];
            [self.scrollView changeImageViewFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.height*self.currentZoomRate,
                                                             [[UIScreen mainScreen] bounds].size.width*self.currentZoomRate)];
        }
        
        if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            self.imageOrientation = UIImageOrientationUp;
        }
        else {
            self.imageOrientation = UIImageOrientationDown;
        }
    }
*/
    
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self setupControlsPosition];
    [self adjustCurrentOrientation];
    [self.scrollView adjustImageViewCenter];
    [self scrollToCenter];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (void) saveImageFile:(NSString *)fileName saveImage:(UIImage *)saveImage {
    fileName = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fileName]) {
        [fileManager createFileAtPath:fileName contents:nil attributes:nil];
    }
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
    [UIImageJPEGRepresentation(saveImage, 1) writeToFile:fileName atomically:YES];
    [file closeFile];
    [fileManager release];
}

- (UIImage *) readImageFile:(NSString *)fileName {
    fileName = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fileName]) {
        NSLog(@"file %@ not exist!\n", fileName);
        return NULL;
    }
    UIImage *imageFile = [UIImage imageWithContentsOfFile:fileName];
    return imageFile;
}

#pragma mark -
#pragma mark Capture Management

- (float)getDistance:(float)g offset:(float)offset {
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return 360;
    }
    float lens = self.captureDevice.lensPosition - offset * g;
    float distance = 1 / (-0.3929 * lens + 0.2986);
    if ([AppDelegate isIpadAir]) {
        distance = 1 / (-0.4985 * lens + 0.3524);
    }
    if (distance < 0 || distance > 360) {
        distance = 360;
    }
    return distance;
}

// Map focus level
- (NSInteger)getLevel:(float)g offset:(float)offset
{
    float distance = [self getDistance:g offset:offset];
    NSInteger focusLevel = 400;
    if (distance < 39.4) {
        // Divide by 1 can downward round float number into int
        NSInteger temp = (39.4 / distance) / 1;
        focusLevel = (39.4 / temp) / 1;
    } else if (distance <= 394) {
        NSInteger temp = (394 / distance) / 1;
        focusLevel = (394 / temp) / 1;
    }
    //NSLog(@"%@%ld", @"Focus level: ", (long)focusLevel);
    return focusLevel;
}

- (float)getAngle {
    float g = _accelerometer -> getCurrent();
    /*if (g > 1) {
        g = 1;
    }
    if (g < -1) {
        g = -1;
    }*/
    float angle = acos(g)/ M_PI * 180;
    NSLog(@"g = %f, angle = %f", g, angle);
    return angle;
}

- (float)getOffset {
    /*if ([self isIphone5]) {
        return 0.14;
    }*/
    return 0.16;
}

- (void)checkFocusChange {
    if (self.counter == FRAMES) {
        self.counter = 0;
        //float angle = [self getAngle];
        float offset = [self getOffset];
        NSInteger level = [self getLevel:_accelerometer -> getCurrent() offset:offset];
        //NSLog(@"focus level = %ld", (long)level);
        //[self displayMessage:[NSString stringWithFormat:@"level = %ld, lens = %.04f", (long)[self getLevel:_accelerometer -> getCurrent() offset:offset], self.captureDevice.lensPosition]];
        if (level != self.lensPosition) {
            float seconds = [[NSDate date] timeIntervalSinceDate:self.focusTimer];
            if (seconds >= 3) {
                NSString *label = [NSString stringWithFormat:@"%ld", (long)self.lensPosition];
                if ([self isiPhone]) {
                    [Umeng endEvent:@"FocusLevel_iPhone" primarykey:@"FocusLevel_iPhone"
                              value:label];
                }
                if ([self isIpad]) {
                    [Umeng endEvent:@"FocusLevel_iPad" primarykey:@"FocusLevel_iPad" value:label];
                }
            }
            NSString *label = [NSString stringWithFormat:@"%ld", (long)level];
            if ([self isiPhone]) {
                [Umeng beginEvent:@"FocusLevel_iPhone" primarykey:@"FocusLevel_iPhone" value:label];
            }
            if ([self isIpad]) {
                [Umeng beginEvent:@"FocusLevel_iPad" primarykey:@"FocusLevel_iPad" value:label];
            }
            self.lensPosition = level;
            self.focusTimer = [[NSDate date] retain];
        }
    } else {
        self.counter++;
    }
}

- (BOOL)focusCanNotChange {
    if ([AppDelegate beforeIpad2]) {
        return true;
    }
    return false;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
    //NSLog(@"lens aperture = %f, ISO = %f, exposure time = %lld", self.captureDevice.lensAperture, self.captureDevice.ISO, self.captureDevice.exposureDuration.value);
    /*if (self.readyChangeBack && self.captureDevice.adjustingFocus) {
        //[self unlockAutoFocus];
        self.readyChangeBack = false;
        NSLog(@"mode = %ld, x = %f, y = %f", (long)self.captureDevice.focusMode, self.captureDevice.focusPointOfInterest.x, self.captureDevice.focusPointOfInterest.y);
    }
    if (self.captureDevice.focusMode == AVCaptureFocusModeLocked && self.isTapped) {
            //NSLog(@"auto");
        [self unlockFocus];
        self.readyChangeBack = true;
        self.isTapped = false;
        NSLog(@"mode = %ld, x = %f, y = %f", (long)self.captureDevice.focusMode, self.captureDevice.focusPointOfInterest.x, self.captureDevice.focusPointOfInterest.y);
    }*/
    //NSLog(@"focus mode = %ld", (long)self.captureDevice.focusMode);
    /*if (self.isTapped && self.captureDevice.adjustingFocus) {
        [self resetExposure];
        self.isTapped = false;
        NSLog(@"reset exposure");
    }*/
    [self checkResetExposure];
    //NSLog(@"origina = %f, current = %f", self.ISO * self.duration.value, self.captureDevice.ISO * self.captureDevice.exposureDuration.value);
    
    if (SYSTEM_VERSION_LESS_THAN(@"8.0") || [self focusCanNotChange]) {
        ;
    } else {
        if (![self.lockFocusButton isSelected]) {
            [self checkFocusChange];
        }
    }
    /*
     NSLog(@"imageview size: w:%f, h:%f, scrollview size:%f, %f\n", self.scrollView.imageView.frame.size.width, self.scrollView.imageView.frame.size.height, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    NSLog(@"window: w %f, h %f\n", [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    */
    if (self.isLocked) {
        return;
    }
    
    // zewen li
    //[self performSelectorOnMainThread:@selector(adjustCurrentOrientation) withObject:nil waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(setupControlsPosition) withObject:nil waitUntilDone:YES];
 
    
    /* time statics
    NSDate *captureOutputStartTime = [NSDate date];
    double intervalBetweenTwoFrames = [captureOutputStartTime timeIntervalSinceDate:self.lastDate];
    self.avgTimeForOneFrame += intervalBetweenTwoFrames;
    self.lastDate = [[NSDate date] retain];
    int currentFrameRate = 1 / intervalBetweenTwoFrames;
    NSString *frameRateString = [NSString stringWithFormat:@"%d",currentFrameRate];
    [self.frameRateLabel performSelectorOnMainThread:@selector(setText:) withObject:frameRateString waitUntilDone:YES];
    [self systemOutput:@"Total Time for one frame is:%f\n" variable:intervalBetweenTwoFrames];
    */
    
	/*We create an autorelease pool because as we are not in the main_queue our code is
	 not executed in the main thread. So we have to create an autorelease pool for the thread we are in*/
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // screen width is 320, image width is 640 / 1920 / 1280
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    // screen height is 480, image height is 480 / 1080 / 720
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    /*Create a CGImageRef from the CVImageBufferRef*/
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // create a cgimgRef from original source.
    CGImageRef originalCGImage = CGBitmapContextCreateImage(context);
    
    /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly).
     Same thing as for the CALayer we are not in the main thread so ...*/
    // just change orientation for image rendering, its width and height does not change!!
    UIImage *originalUIImage = [UIImage imageWithCGImage:originalCGImage scale:1 orientation:(UIImageOrientation)self.imageOrientation];
    // add filter
    if (self.isImageModeOn) {
        originalUIImage = [self addFilter:originalCGImage];
    }
    
    /*We release some components*/
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    
    if (self.beforeLock) {
        
        CGImageRef processCGImageRef = CGImageCreateWithImageInRect(originalCGImage, CGRectMake(width/2 - self.featureWindowWidth/2, height/2 - self.featureWindowHeight/2, self.featureWindowWidth, self.featureWindowHeight));
        // we crop a part of cgimage to uiimage to do feature detect and track.
        UIImage *processUIImage = [UIImage imageWithCGImage:processCGImageRef];
        [self.imageProcess setCurrentImageMat:processUIImage];
        
        double var = [self.imageProcess calVariance];
        
        if (self.imageNo >= self.lockDelay) {
            
            if ([self isIphone5] || ([self isIpad])) {
                self.isLocked = true;
                UIImage *finalImage;
                if (self.isImageModeOn) {
                    finalImage = [self addFilter:originalCGImage];
                } else {
                    finalImage = self.highVarImg;
                }
                [self.scrollView setImage:finalImage];
                self.maxVariance = 0;
            }
            
            if ((width != 960) && ([self isIphone4] || [self isIphone4S])) {
                // show to screen.
                [self adjustForHighResolution];
                [self.scrollView setImage:self.highVarImg];
                self.isLocked = true;
                [self.scrollView setContentOffset:self.correctContentOffset animated:NO];
                self.maxVariance = 0;
            }
        }
        // if not reaching lock delay.
        else {
            if ((self.maxVariance < var)||(self.maxVariance == 0)) {
                self.highVarImg = [UIImage imageWithCGImage:originalCGImage scale:1 orientation:(UIImageOrientation)self.imageOrientation];
                self.maxVariance = var;
            }
        }
        
        /* release original cgimage */
        CGImageRelease(processCGImageRef);
        
    }
    // normal state that not locked.
    else {
        //  for ip4 resolution may not get changed that fast
        if (false) {//(([self isIphone4]) && (width != 960)) {
            // do nothing
        }
        else {
            // cut a particle of a cgimage to process fast feature detect
            CGImageRef processCGImageRef = CGImageCreateWithImageInRect(originalCGImage, CGRectMake(width/2 - self.featureWindowWidth/2, height/2 - self.featureWindowHeight/2, self.featureWindowWidth, self.featureWindowHeight));
            // we crop a part of cgimage to uiimage to do feature detect and track.
            UIImage *processUIImage = [UIImage imageWithCGImage:processCGImageRef];
            NSLog(@"%@%f", @"image width: ", originalUIImage.size.width);
            NSLog(@"%@%f", @"image height: ", originalUIImage.size.height);
            NSLog(@"%@, %f", @"max factor: ", self.captureDevice.videoZoomFactor);
            
            //  if stabilization function is disabled
            if (!self.isStabilizationEnable) {
                [self.scrollView setImage:originalUIImage];
            }
            else {
                if (self.imageNo == 0) {
                    [self.imageProcess setLastImageMat:processUIImage];
                    [self.scrollView setImage:originalUIImage];
                }
                else {
                    /* set up images */
                    [self.imageProcess setCurrentImageMat:processUIImage];
                    /* calculate motion vector */
                    CGPoint motionVector = [self.imageProcess motionEstimation];
                    
                    self.motionX += motionVector.x;
                    self.motionY += motionVector.y;
                    //  there is no feature points or either no feature tracking points
                    if (self.isHorizontalStable) {
                        if (UIInterfaceOrientationIsPortrait(ORIENTATION)) {
                            self.motionY = 0;
                        }
                        else
                            self.motionX = 0;
                    }
                    CGRect windowBounds = [[UIScreen mainScreen] bounds];
                    CGRect resultRect;
                    resultRect = [self.imageProcess calculateMyCroppedImage:self.motionX ypos:self.motionY width:width height:height scale:self.currentZoomRate bounds:windowBounds];
                    
                    // to solve a bug only more than iOS 8.0
                    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
                        ;
                    } else {
                        if (UIInterfaceOrientationIsLandscape(ORIENTATION)) {
                            resultRect = [self.imageProcess calculateMyCroppedImage:self.motionX ypos:self.motionY width:width height:height scale:self.currentZoomRate bounds:CGRectMake(windowBounds.origin.x, windowBounds.origin.y, windowBounds.size.height, windowBounds.size.width)];
                        }
                    }
                    
                    //NSLog(@"result rect: origin:%f, %f: w:%f,h:%f\n", resultRect.origin.x, resultRect.origin.y, resultRect.size.width, resultRect.size.height);
                    //  cut from original to move the image
                    CGImageRef finalProcessImage = CGImageCreateWithImageInRect([originalUIImage CGImage], resultRect);
                    UIImage *finalUIImage = [UIImage imageWithCGImage:finalProcessImage scale:1 orientation:(UIImageOrientation)self.imageOrientation];
                    [self.scrollView setImage:finalUIImage];
                    CGImageRelease(finalProcessImage);
                    
                }
            }
            CGImageRelease(processCGImageRef);
        }
    }

    /*We relase the CGImageRef*/
	CGImageRelease(originalCGImage);
	/*We unlock the  image buffer*/
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    [pool drain];
    self.imageNo++;
    //[MobClick event:@"Test" label:@"Caputure runs successfully."];
    return;
}

- (UIImage *)addFilter:(CGImageRef) cgImageRef {
    // add filter
    CIImage *image = [CIImage imageWithCGImage:cgImageRef];
    
    // coler black and white
    CIFilter* photoEffectMono = [CIFilter filterWithName:@"CIPhotoEffectMono"];
    [photoEffectMono setDefaults];
    [photoEffectMono setValue:image forKey:@"inputImage"];
    image = [photoEffectMono valueForKey:@"outputImage"];
    
    // coler invert filter
    CIFilter* colorInvertFilter = [CIFilter filterWithName:@"CIColorInvert"];
    [colorInvertFilter setDefaults];
    [colorInvertFilter setValue:image forKey:@"inputImage"];
    image = [colorInvertFilter valueForKey:@"outputImage"];
    
    // color control filter
    CIFilter* colorControlsFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorControlsFilter setDefaults];
    [colorControlsFilter setValue:@5 forKey:@"inputContrast"];
    [colorControlsFilter setValue:image forKey:@"inputImage"];
    image = [colorControlsFilter valueForKey:@"outputImage"];
    return [self makeUIImageFromCIImage:image];
}

- (void)checkResetExposure {
    if (self.isExposureAdjusted) {
        if (self.ISO * self.duration.value / (self.captureDevice.ISO * self.captureDevice.exposureDuration.value) > 3 ||
            self.captureDevice.ISO * self.captureDevice.exposureDuration.value / (self.ISO * self.duration.value) > 3) {
            self.isTapped = false;
            self.isExposureAdjusted = false;
            [self resetExposure];
            //NSLog(@"tapLensPosition = %f, lensPosition = %f", self.tapLensPosition, self.captureDevice.lensPosition);
            //NSLog(@"origina = %f, current = %f", self.ISO * self.duration.value, self.captureDevice.ISO * self.captureDevice.exposureDuration.value);
            NSLog(@"reset exposure");
        }
    }
}

-(UIImage*)makeUIImageFromCIImage:(CIImage*)ciImage
{
    // create the CIContext instance, note that this must be done after _videoPreviewView is properly set up
    //EAGLContext *_eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    ////CIContext *cicontext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]}];
    //CIContext *cicontext = [CIContext contextWithEAGLContext:_eaglContext options:nil];
    //CIContext *cicontext = [CIContext contextWithOptions:nil];
    CIContext *cicontext = [CIContext contextWithOptions:@{kCIContextWorkingColorSpace : [NSNull null]}];
    // finally!
    UIImage * returnImage;
    CGImageRef processedCGImage = [cicontext createCGImage:ciImage fromRect:[ciImage extent]];
    returnImage = [UIImage imageWithCGImage:processedCGImage scale:1 orientation:(UIImageOrientation)self.imageOrientation];
    CGImageRelease(processedCGImage);
    return returnImage;
}

#pragma mark - controller activities

- (void) setMinimalZoomScale: (float)minScale {
    self.scrollView.minimumZoomScale = minScale;
    [self.zoomSlider setMinimumValue:minScale];
}

- (void)showHelpViewController
{
    CGRect screenBounds = self.view.bounds;
    CGRect fromFrame = CGRectMake(0.0f, screenBounds.size.height, screenBounds.size.width, screenBounds.size.height);
    CGRect toFrame = screenBounds;
    
    self.helpViewController = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    [self addChildViewController:self.helpViewController];
    self.helpViewController.view.frame = fromFrame;
    [self.view addSubview:self.helpViewController.view];
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.helpViewController.view.frame = toFrame;
                     }
                     completion:^(BOOL finished){
                         [self.helpViewController didMoveToParentViewController:self];
                     }];
}

- (IBAction)infoButtonTapped:(id)sender {
    if ([self isIpad]) {
        [Umeng event:@"InfoButtonTouched" value:@"iPad"];
    } else {
        [Umeng event:@"InfoButtonTouched" value:@"iPhone"];
    }
    [self showHelpViewController];
}

- (IBAction)imageModeTapped {
    if (self.isImageModeOn) {
        [self.imageModeButton setSelected:NO];
        if ([self isIpad]) {
            [Umeng endEvent:@"ImageMode_iPad" primarykey:@"ImageMode_iPad" value:@"Enh-Inv"];
        }
        if ([self isiPhone]) {
            [Umeng endEvent:@"ImageMode_iPhone" primarykey:@"ImageMode_iPhone" value:@"Enh-Inv"];
        }
    } else {
        if ([self isIpad]) {
            [Umeng beginEvent:@"ImageMode_iPad" primarykey:@"ImageMode_iPad" value:@"Enh-Inv"];
        }
        if ([self isiPhone]) {
            [Umeng beginEvent:@"ImageMode_iPhone" primarykey:@"ImageMode_iPhone" value:@"Enh-Inv"];
        }
        [self.imageModeButton setSelected:YES];
    }
    self.isImageModeOn = !_isImageModeOn;
}

- (void)savePhoto:(NSString *)name {
    UIImage *image = [self normalizedImage:self.highVarImg];
    NSArray *pathArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [[pathArr objectAtIndex:0] stringByAppendingPathComponent:name];
    NSData* data = UIImagePNGRepresentation(image);
    [data writeToFile:path atomically:YES];
}

- (UIImage *)normalizedImage:(UIImage *)image {
    if (UIInterfaceOrientationIsLandscape(self.lockInterfaceOrientation)) {
        return image;
    }
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

- (IBAction)saveButtonTapped:(id)sender {
    //NSString *name = [NSString stringWithFormat:@"img%ld.data", (unsigned long)self.photoData.count];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSDate *date = [NSDate date];
    NSString *name = [dateFormatter stringFromDate:date];
    
    [self.photoData addObject:name];
    [self savePhoto:name];

    [self.saveButton setHidden:YES];
    if ([AppDelegate isiPhone]) {
        [Umeng event:@"SavePicture" value:@"iPhone"];
    }
    if ([AppDelegate isIpad]) {
        [Umeng event:@"SavePicture" value:@"iPad"];
    }
}

- (void)showPhotoViewController {
    CGRect screenBounds = self.view.bounds;
    CGRect fromFrame = CGRectMake(0.0f, screenBounds.size.height, screenBounds.size.width, screenBounds.size.height);
    CGRect toFrame = screenBounds;
    
    UIStoryboard *photoStoryBoard = [UIStoryboard storyboardWithName:@"Photo" bundle:nil];
    UINavigationController *navigationController = [photoStoryBoard instantiateInitialViewController];
    [self addChildViewController:navigationController];
    navigationController.view.frame = fromFrame;
    [self.view addSubview:navigationController.view];
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         navigationController.view.frame = toFrame;
                     }
                     completion:^(BOOL finished){
                         [navigationController didMoveToParentViewController:self];
                     }];
}

- (void)showEmptyViewController {
    CGRect screenBounds = self.view.bounds;
    CGRect fromFrame = CGRectMake(0.0f, screenBounds.size.height, screenBounds.size.width, screenBounds.size.height);
    CGRect toFrame = screenBounds;
    
    UIStoryboard *emptyStoryBoard = [UIStoryboard storyboardWithName:@"Empty" bundle:nil];
    UINavigationController *navigationController = [emptyStoryBoard instantiateInitialViewController];
    [self addChildViewController:navigationController];
    navigationController.view.frame = fromFrame;
    [self.view addSubview:navigationController.view];
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         navigationController.view.frame = toFrame;
                     }
                     completion:^(BOOL finished){
                         [navigationController didMoveToParentViewController:self];
                     }];
}

- (IBAction)photoButtonTapped:(id)sender {
    if ([self.photoData count] == 0) {
        [self showEmptyViewController];
    } else {
        [self showPhotoViewController];
    }
    if ([AppDelegate isiPhone]) {
        [MobClick beginEvent:@"ShowPicutures" label:@"iPhone"];
    }
    if ([AppDelegate isIpad]) {
        [MobClick beginEvent:@"ShowPicutures" label:@"iPad"];
    }
}

- (IBAction)lockFocusButtonTapped:(id)sender {
    float offset = [self getOffset];
    NSInteger level = [self getLevel:_accelerometer -> getCurrent() offset:offset];
    
    if ([self.lockFocusButton isSelected]) {
        [self.lockFocusButton setSelected:NO];
        [self unlockAutoFocus];
        // lock focus event end
        if ([self isIpad]) {
            [Umeng endEvent:@"LockFocus_iPad" primarykey:@"LockFocus_iPad" value:self.lockLabel];
        } else {
            [Umeng endEvent:@"LockFocus_iPhone" primarykey:@"LockFocus_iPhone" value:self.lockLabel];
        }
        // focus level event start
        NSString *label = [NSString stringWithFormat:@"%ld", (long)level];
        if ([self isiPhone]) {
            [Umeng beginEvent:@"FocusLevel_iPhone" primarykey:@"FocusLevel_iPhone" value:label];
        }
        if ([self isIpad]) {
            [Umeng beginEvent:@"FocusLevel_iPad" primarykey: @"FocusLevel_iPad" value:label];
        }
        self.lensPosition = level;
        self.focusTimer = [[NSDate date] retain];
        
    } else {
        self.lockLabel = [NSString stringWithFormat:@"%ld", (long)level];
        
        // lock focus event start
        if ([self isIpad]) {
            [Umeng beginEvent:@"LockFocus_iPad" primarykey:@"LockFocus_iPad" value:self.lockLabel];
        } else {
            [Umeng beginEvent:@"LockFocus_iPhone" primarykey:@"LockFocus_iPhone" value:self.lockLabel];
        }
        
        // focus level event end
        float seconds = [[NSDate date] timeIntervalSinceDate:self.focusTimer];
        if (seconds >= 3) {
            NSString *label = [NSString stringWithFormat:@"%ld", (long)self.lensPosition];
            if ([self isiPhone]) {
                [Umeng endEvent:@"FocusLevel_iPhone" primarykey:@"FocusLevel_iPhone"
                          value:label];
            }
            if ([self isIpad]) {
                [Umeng endEvent:@"FocusLevel_iPad" primarykey:@"FocusLevel_iPad" value:label];
            }
        }
        [self.lockFocusButton setSelected:YES];
        [self lockFocus];
    }
}

- (void)resetExposure {
    NSArray *devices = [AVCaptureDevice devices];
    NSError *error;
    for (AVCaptureDevice *device in devices) {
        if (([device hasMediaType:AVMediaTypeVideo]) &&
            ([device position] == AVCaptureDevicePositionBack) ) {
            [device lockForConfiguration:&error];
            if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                CGPoint autoExposurePoint = CGPointMake(0.5f, 0.5f);
                [device setExposurePointOfInterest:autoExposurePoint];
                device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            }
            [device unlockForConfiguration];
        }
    }
    [self unlockAutoFocus];
}

- (void)lockFocus {
    NSArray *devices = [AVCaptureDevice devices];
    NSError *error;
    for (AVCaptureDevice *device in devices) {
        if (([device hasMediaType:AVMediaTypeVideo]) &&
            ([device position] == AVCaptureDevicePositionBack) ) {
            [device lockForConfiguration:&error];
            if ([device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                device.focusMode = AVCaptureFocusModeLocked;
                NSLog(@"Focus locked");
            }
            
            [device unlockForConfiguration];
        }
    }
}

- (void)unlockFocus {
    NSArray *devices = [AVCaptureDevice devices];
    NSError *error;
    for (AVCaptureDevice *device in devices) {
        if (([device hasMediaType:AVMediaTypeVideo]) &&
            ([device position] == AVCaptureDevicePositionBack) ) {
            [device lockForConfiguration:&error];
            if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
                NSLog(@"Focus unlocked");
            }
            [device unlockForConfiguration];
        }
    }
}

//  hide all interface controls
- (void)hideAllControls {
    [self.stableDirectionButton setHidden:YES];
    [self.flashLightButton setHidden:YES];
    [self.screenLockButton setHidden:YES];
    //[self.infoButton setHidden:YES];
    [self.zoomSlider setHidden:YES];
    [self.sliderBackground setHidden:YES];
    [self.imageModeButton setHidden:YES];
    [self.lockFocusButton setHidden:YES];
    [self.photoButton setHidden:YES];
}

//  show all interface controls
- (void)showAllcontrols {
    [self.stableDirectionButton setHidden:NO];
    [self.flashLightButton setHidden:NO];
    [self.screenLockButton setHidden:NO];
    //[self.infoButton setHidden:NO];
    [self.zoomSlider setHidden:NO];
    [self.sliderBackground setHidden:NO];
    if ([self isIpad] && ![self isIpadPro]) {
        [self.flashLightButton setHidden:YES];
    }
    [self.imageModeButton setHidden:NO];
    [self.lockFocusButton setHidden:NO];
    [self.photoButton setHidden:NO];
}

- (IBAction)zoomSliderChanged:(id)sender {
    float scale = self.zoomSlider.value;
    NSLog(@"scale for ScrollView is: %f", scale);
    [self.label setText: [NSString stringWithFormat:@"%f", scale]];
    if (UIInterfaceOrientationIsPortrait(ORIENTATION)) {
        self.imageOrientation = UIImageOrientationRight;
    }
    else if (ORIENTATION == UIInterfaceOrientationLandscapeLeft) {
        self.imageOrientation = UIImageOrientationDown;
    }
    else {
        self.imageOrientation = UIImageOrientationUp;
    }
    [self.scrollView setZoomScale:scale animated:NO];
    self.currentZoomRate = scale;
    [[NSUserDefaults standardUserDefaults] setFloat:self.currentZoomRate forKey:@"Zoom Scale"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)horizontalStableButtonTapped:(id)sender {
    if (self.isHorizontalStable) {
        self.isHorizontalStable = false;
        [self.stableDirectionButton setImage:[UIImage imageNamed:@TWOSTABLEPNG]
                             forState:UIControlStateNormal];
    }
    else {
        self.isHorizontalStable = true;
        [self.stableDirectionButton setImage:[UIImage imageNamed:@ONESTABLEPNG]
                             forState:UIControlStateNormal];
    }
}

//  lock auto focus
- (void)lockAutoFocus {
    NSArray *devices = [AVCaptureDevice devices];
    NSError *error;
    for (AVCaptureDevice *device in devices) {
        if (([device hasMediaType:AVMediaTypeVideo]) &&
            ([device position] == AVCaptureDevicePositionBack) ) {
            [device lockForConfiguration:&error];
            CGPoint location = CGPointMake(0.5, 0.5);
            if ([device isFocusPointOfInterestSupported]) {
                [device setFocusPointOfInterest:location];
            }
            if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                device.focusMode = AVCaptureFocusModeAutoFocus;
            }
            if ([device isExposurePointOfInterestSupported]) {
                [device setExposurePointOfInterest:location];
            }
            else
                NSLog(@"exposure point not support\n");
            if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            [device unlockForConfiguration];
        }
    }
}

- (void)addFocusObserver {
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if (([device hasMediaType:AVMediaTypeVideo]) &&
            ([device position] == AVCaptureDevicePositionBack) ) {
            int flags = NSKeyValueObservingOptionNew;
            [device addObserver:self forKeyPath:@"adjustingFocus" options:flags context:nil];
        }
    }
}

- (void)removeFocusObserver {
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if (([device hasMediaType:AVMediaTypeVideo]) &&
            ([device position] == AVCaptureDevicePositionBack) ) {
            [device removeObserver:self forKeyPath:@"adjustingFocus"];
        }
    }
}

// callback
-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if([keyPath isEqualToString:@"adjustingFocus"]){
        BOOL adjustFocus =[[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
        //NSLog(@"Is adjusting focus? %@", adjustFocus ?@"YES":@"NO");
        //NSLog(@"Change dictionary: %@", change);
        if ((self.adjustingFocus == YES) && (adjustFocus == NO)) {
            self.adjustingFocus = NO;
        }
        else {
            self.adjustingFocus = YES;
        }
    }
    if ([keyPath isEqualToString:@"currentZoomRate"]) {
        [self.zoomSlider setValue:self.currentZoomRate];
        self.scrollView.zoomScale = self.currentZoomRate;
        [self.scrollView adjustImageViewCenter];
        [self scrollToCenter];
    }
}

//  unlock auto focus
- (void) unlockAutoFocus {
    NSArray *devices = [AVCaptureDevice devices];
    NSError *error;
    for (AVCaptureDevice *device in devices) {
        if (([device hasMediaType:AVMediaTypeVideo]) &&
            ([device position] == AVCaptureDevicePositionBack) ) {
            [device lockForConfiguration:&error];
            if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                CGPoint autofocusPoint = CGPointMake(0.5f, 0.5f);
                [device setFocusPointOfInterest:autofocusPoint];
                [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
//            if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
//                [device setExposureMode:AVCaptureExposureModeLocked];
//            }
            [device unlockForConfiguration];
        }
    }
}

- (void) resetFlashButton{
    if (self.isFlashOn) {
        self.isFlashOn = false;
        [self turnFlashOff];
        /*UIImage *flashOffImage = [UIImage imageNamed:@FLASHONPNG];
        [self.flashLightButton setImage:flashOffImage forState:UIControlStateNormal];*/
    }
}

- (void) recoverFlash {
    if (self.isFlashOn)
        [self turnFlashOn];
    else
        [self turnFlashOff];
}

- (void)turnFlashOn {
    UIImage *flashOffImage = [UIImage imageNamed:@FLASHOFFPNG];
    [self.flashLightButton setImage:flashOffImage forState:UIControlStateNormal];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setTorchMode:AVCaptureTorchModeOn];
        if ([self isIpadPro]) {
            [Umeng beginEvent:@"Flashlight" primarykey:@"Flashlight" value:@"iPad"];
        } else {
            [Umeng beginEvent:@"Flashlight" primarykey:@"Flashlight" value:@"iPhone"];
        }
        //  use AVCaptureTorchModeOff to turn off
        [device unlockForConfiguration];
    }
}

- (void)turnFlashOff {
    UIImage *flashOffImage = [UIImage imageNamed:@FLASHONPNG];
    [self.flashLightButton setImage:flashOffImage forState:UIControlStateNormal];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        if ([self isIpadPro]) {
            [Umeng beginEvent:@"Flashlight" primarykey:@"Flashlight" value:@"iPad"];
        } else {
            [Umeng endEvent:@"Flashlight" primarykey:@"Flashlight" value:@"iPhone"];
        }
        [device setTorchMode:AVCaptureTorchModeOff];
        //  use AVCaptureTorchModeOff to turn off
        [device unlockForConfiguration];
    }
}

- (IBAction)flashButtonTapped:(id)sender {
    if (self.isFlashOn) {
        self.isFlashOn = false;
        [self turnFlashOff];
    }
    else {
        self.isFlashOn = true;
        [self turnFlashOn];
    }
}

- (void) adjustForHighResolution {
    /* needs rescaling sicne resolution changed! for
     iphone4 and 4s other than iPhone5. */
    float adjustScale = 540.0/self.resolutionWidth;
    //  iPhone4 needs further more zooming scale, no idea why!
    if ([self isIphone4]) {
        adjustScale = adjustScale * 1;
    }
    float newMax = self.scrollView.maximumZoomScale * adjustScale;
    float newMin = self.scrollView.minimumZoomScale * adjustScale;
    [self.scrollView setMaximumZoomScale:newMax];
    [self.scrollView setMinimumZoomScale:newMin];
    self.currentZoomRate = self.scrollView.zoomScale * adjustScale;
    self.scrollView.zoomScale = self.currentZoomRate;
    [self.zoomSlider setMaximumValue:newMax];
    [self.zoomSlider setMinimumValue:newMin];
    [self.zoomSlider setValue:self.currentZoomRate animated:NO];
//    self.correctContentOffset = CGPointMake(self.correctContentOffset.x*adjustScale, self.correctContentOffset.y*adjustScale);
    if (UIInterfaceOrientationIsPortrait(ORIENTATION)) {
        [self.scrollView changeImageViewFrame:CGRectMake(0, 0, self.resolutionWidth * self.currentZoomRate, self.resolutionHeight * self.currentZoomRate)];
    }
    else {
        [self.scrollView changeImageViewFrame:CGRectMake(0, 0, self.resolutionHeight*self.currentZoomRate, self.resolutionWidth*self.currentZoomRate)];
    }
}

- (void) adjustForLowResolution {
    /* needs rescaling sicne resolution changed! for
     iphone4 and 4s other than iPhone5. */
    float adjustScale = self.resolutionWidth/540.0;
    //  iPhone 4 needs more zooming scale, no idea why!
    if ([self isIphone4]) {
        adjustScale = adjustScale/1;
    }
    float newMax = self.scrollView.maximumZoomScale * adjustScale;
    float newMin = self.scrollView.minimumZoomScale * adjustScale;
    [self.scrollView setMaximumZoomScale:newMax];
    [self.scrollView setMinimumZoomScale:newMin];
    self.currentZoomRate = self.scrollView.zoomScale * adjustScale;
    self.scrollView.zoomScale = self.currentZoomRate;
    [self.zoomSlider setMaximumValue:newMax];
    [self.zoomSlider setMinimumValue:newMin];
    [self.zoomSlider setValue:self.currentZoomRate animated:NO];
//    self.correctContentOffset = CGPointMake(self.correctContentOffset.x*adjustScale, self.correctContentOffset.y*adjustScale);
    if (UIInterfaceOrientationIsPortrait(ORIENTATION)) {
        [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 540*self.currentZoomRate, 960*self.currentZoomRate)];
    }
    else {
        [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 960*self.currentZoomRate, 540*self.currentZoomRate)];
    }
}

- (void) scrollToCenter {
    CGPoint toCenter = CGPointMake(self.scrollView.contentSize.width/2 - self.scrollView.frame.size.width/2, self.scrollView.contentSize.height/2 - self.scrollView.frame.size.height/2);
    [self.scrollView setContentOffset:toCenter animated:NO];
}

// enter background, end clock for locking.
- (void) beforeEnterBackground {
    if (self.isFlashOn) {
        [self flashButtonTapped:nil];
    }
    if (self.isLocked) {
        // trace touch event
        float seconds = [[NSDate date] timeIntervalSinceDate:self.lockTimer];
        if (seconds >= 1) {
            if ([self isiPhone]) {
                [Umeng event:@"Snapshot" value:@"iPhone" durations:seconds*1000];
            }
            if ([self isIpad]) {
                [Umeng event:@"Snapshot" value:@"iPad" durations:seconds*1000];
            }
        }
    }
    NSLog(@"Current Zoom rate:%f", self.currentZoomRate);
    [self storeData];
    // Send time interval
    float seconds = [[NSDate date] timeIntervalSinceDate:self.startTimer];
    if (seconds >= 1) {
        if ([self isiPhone]) {
            NSLog(@"%f", seconds);
            [Umeng event:@"TimePeriod_iPhone" value:@"iPhone" durations:seconds*1000];
            // Use counter means this is a computing event
            [Umeng event:@"TimePeriod_iPhone" attributes:@{@"TimePeriod_iPhone": @"iPhone"} counter:ceil(seconds)];
            //[self umengEvent:@"CalTimeSum" attributes:@{@"Device": @"iPhone"} number:@(seconds)];
        }
        if ([self isIpad]) {
            [Umeng event:@"TimePeriod_iPad" value:@"iPad" durations:seconds*1000];
            [Umeng event:@"TimePeriod_iPad" attributes:@{@"TimePeriod_iPad": @"iPad"} counter:ceil(seconds)];
            //[self umengEvent:@"CalTimeSum" attributes:@{@"Device": @"iPad"} number:@(seconds)];
        }
    }
    // Remove volume listener
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
// recover from background, start clock for locking.
- (void)applicationDidBecomeActive {
    if (self.isLocked) {
        self.lockTimer = [[NSDate date] retain];
        //[MobClick beginEvent:@"Snapshot"];
    }
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        ;
    } else {
        self.focusTimer = [[NSDate date] retain];
        //float angle = [self getAngle];
        float offset = [self getOffset];
        self.lensPosition = [self getLevel:_accelerometer -> getCurrent() offset:offset];
        NSString *label = [NSString stringWithFormat:@"%ld", (long)self.lensPosition];
        if ([self isiPhone]) {
            [Umeng beginEvent:@"FocusLevel_iPhone" primarykey:@"FocusLevel_iPhone" value:label];
        }
        if ([self isIpad]) {
            [Umeng beginEvent:@"FocusLevel_iPad" primarykey: @"FocusLevel_iPad" value:label];
        }
    }
    // start image mode event
    if ([AppDelegate isIpad]) {
        [Umeng beginEvent:@"ImageMode_iPad" primarykey:@"ImageMode_iPad" value:@"Enh-Inv"];
    }
    if ([AppDelegate isiPhone]) {
        [Umeng beginEvent:@"ImageMode_iPhone" primarykey:@"ImageMode_iPhone" value:@"Enh-Inv"];
    }
    // Set start timer
    self.startTimer = [[NSDate date] retain];
    // Start volume listener
    [self initialVloumeListener];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSObject *object = [userDefaults objectForKey:@"Zoom Scale"];
    if(object != nil){
    [self setZoomScale:(float)[userDefaults floatForKey:@"Zoom Scale"]];
    }
    
}

- (IBAction)lockButtonTapped:(id)sender {
    /*     if touch to unlock screen */
    if (self.isLocked) {
        // change ui to unlocked
        [self unlockedUserInterface];
        // trace lock tapped.
        float seconds = [[NSDate date] timeIntervalSinceDate:self.lockTimer];
        if (seconds >= 1) {
            if ([self isiPhone]) {
                [Umeng event:@"Snapshot" value:@"iPhone" durations:seconds*1000];
            }
            if ([self isIpad]) {
                [Umeng event:@"Snapshot" value:@"iPad" durations:seconds*1000];
            }
        }
//        [self.scrollView.pinchGestureRecognizer setEnabled:NO];
//        [self.scrollView setScrollEnabled:NO];
        
        if ([self isIphone5] || [self isIpad]) {
            self.beforeLock = false;
            self.isLocked = false;
            [self scrollToCenter];
            [self reSet];
        }
        if ([self isIphone4] || [self isIphone4S]) {
            self.currentResolution = IP4RESOLUTION;
            [self.captureSession beginConfiguration];
            [self.captureSession setSessionPreset:self.currentResolution];
            [self.captureSession commitConfiguration];
            [self recoverFlash];
            self.isLocked = false;
            self.beforeLock = false;
            [self adjustForLowResolution];
            [self scrollToCenter];
            self.resolutionWidth = 540;
            self.resolutionHeight = 960;
            [self reSet];
        }
        [self.screenLockButton setImage:[UIImage imageNamed:@UNLOCKPNG] forState:UIControlStateNormal];

    }
    /* touch to lock screen */
    else {
        self.lockInterfaceOrientation = ORIENTATION;
        // change ui to locked
        [self lockedUserInterface];
        // trace lock tapped count
        self.lockTimer = [[NSDate date] retain];

        
//        [self.scrollView.pinchGestureRecognizer setEnabled:YES];
//        [self.scrollView setScrollEnabled:YES];
        
        if ([self isIphone5] || [self isIpad]) {
            self.isLocked = false;
            self.beforeLock = true;
            [self reSet];
        }
        else {
            self.beforeLock = true;
            self.isLocked = false;
            //  1080p
            self.currentResolution = IP5RESOLUTION;
            self.resolutionWidth = 1080;
            self.resolutionHeight= 1920;
            //  if 1080p not available set 720p
            if (![self.captureSession canSetSessionPreset:self.currentResolution]) {
                self.currentResolution = RESOLUTION2;
                self.resolutionWidth = 720;
                self.resolutionHeight = 1280;
            }
            [self.captureSession beginConfiguration];
            [self.captureSession setSessionPreset:self.currentResolution];
            [self.captureSession commitConfiguration];
            [self recoverFlash];
            self.correctContentOffset = self.scrollView.contentOffset;
            [self reSet];
        }
        [self.screenLockButton setImage:[UIImage imageNamed:@LOCKPNG] forState:UIControlStateNormal];
    }
    [self adjustCurrentOrientation];
    [self setupControlsPosition];
}

- (void)lockedUserInterface {
    [self.stableDirectionButton setHidden:YES];
    [self.flashLightButton setHidden:YES];
    [self.saveButton setHidden:NO];
}

- (void)unlockedUserInterface {
    [self.stableDirectionButton setHidden:NO];
    if ([self isIpad] && ![self isIpadPro]) {
        [self.flashLightButton setHidden:YES];
    } else {
        [self.flashLightButton setHidden:NO];
    }
    [self.saveButton setHidden:YES];
    //[self.photoButton setHidden:YES];
}

#pragma mark -
#pragma mark Helper Functions

- (void)displayMessage:(NSString *)s {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.message.text = s;
        [self.message setHidden:NO];
    });
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.message setHidden:YES];
    });
}

- (BOOL)isIphone4 {
    return [AppDelegate isIphone4];
}

// for ip5 or higher device return true
- (BOOL)isIphone5 {
    return [AppDelegate isIphone5];
}

- (BOOL)isIphone4S {
    return [AppDelegate isIphone4S];
}

- (BOOL) isiPhone {
    return [AppDelegate isiPhone];
}

- (BOOL) isIpad {
    return [AppDelegate isIpad];
}

- (BOOL) beforeIpad2 {
    return [AppDelegate beforeIpad2];
}

- (BOOL) isIpadPro {
    return [AppDelegate isIpadPro];
}

- (NSString*)deviceString
{
    return [AppDelegate deviceString];
}

- (void) ViewDidDismiss {
    [self adjustCurrentOrientation];
}

//  reSet all settings
- (void) reSet {
    self.motionX = 0;
    self.motionY = 0;
    self.imageNo = 0;
    self.adjustingFocus = NO;
}

//  return true if stabilization is enabled, else false
- (BOOL) checkStableEnableDisable {
    if (self.isStabilizationEnable) {
        return true;
    }
    else
        return false;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

/*- (ALAssetsLibrary *)library {
    if (!_library) {
        return [[ALAssetsLibrary alloc] init];
    }
    return _library;
}*/

#pragma mark - Debug functions
- (void) systemOutput:(NSString *)content variable:(float)value {
    return;
    NSLog(content, value);
}

#pragma mark - Memory management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) stopPlaying {
    _accelerometer -> stop();
    AudioSessionSetActive(false);
    [self.captureSession stopRunning];
}

- (void) resumePlaying {
    [self scrollToCenter];
    [self.captureSession startRunning];
    AudioSessionSetActive(true);
    _accelerometer -> start();
}

- (void) dealloc {
    [self.imageProcess dealloc];
    [self.scrollView dealloc];
    [self stopPlaying];
    [self.captureSession dealloc];
    [_message release];
    [_saveButton release];
    [_imageModeButton release];
    [_lockFocusButton release];
    [_photoButton release];
    [super dealloc];
}

- (void)setZoomScale:(float)ZoomScale{
    self.currentZoomRate = ZoomScale;
    [self.zoomSlider setValue:self.currentZoomRate];
    self.scrollView.zoomScale = self.currentZoomRate;
    [self.scrollView adjustImageViewCenter];
    [self scrollToCenter];
}

#pragma mark - System Data Storage

- (void)storeData {
    NSMutableDictionary *svMagnifier = [[NSMutableDictionary alloc] init];
    [svMagnifier setObject:self.photoData forKey:@"Photo Data"];
    [[NSUserDefaults standardUserDefaults] setObject:svMagnifier forKey:@"SVMagnifier"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)retrieveData {
    NSDictionary *svMagnifier = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"SVMagnifier"];
    if (svMagnifier) {
        self.photoData = [[NSMutableArray alloc] initWithArray:[svMagnifier objectForKey:@"Photo Data"]];
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [self setZoomScale:(float)[userDefaults floatForKey:@"Zoom Scale"]];
}

@end
