//
//  RAQRCodeScannerViewController.m
//  Apex And Drivers
//
//  Created by Jack on 2018/6/5.
//  Copyright © 2018年 USAI. All rights reserved.
//

#import "LPCodeScanner.h"
#import <AVKit/AVKit.h>

@interface LPCodeScanner () <AVCaptureMetadataOutputObjectsDelegate>

@property (strong, nonatomic) IBOutlet UIView *scanerView;
@property (nonatomic,strong) IBOutlet UIView *previewContainer;
@property (strong, nonatomic) IBOutlet UIView *maskView;

@property (nonatomic,strong) AVCaptureDevice *device;
@property (nonatomic,strong) AVCaptureDeviceInput *input;
@property (nonatomic,strong) AVCaptureMetadataOutput *output;
@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic,assign) BOOL scannerInitial;

@property (nonatomic,strong) CAGradientLayer *scanLineLayer;
@property (nonatomic,strong) CAShapeLayer *maskLayer;
@property (nonatomic,strong) CAShapeLayer *rectLayer;

@end

@implementation LPCodeScanner

+ (NSString *)storyboardID {
    return NSStringFromClass([self class]);
}

+ (instancetype)codeScanner {
    LPCodeScanner *scannerVC = [[UIStoryboard storyboardWithName:@"CodeScanner" bundle:nil] instantiateViewControllerWithIdentifier:[self storyboardID]];
    return scannerVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.scanerView.layer.borderColor = [UIColor blackColor].CGColor;
    self.scanerView.layer.borderWidth = 0.5f;
    
    [self initCapture];
}

//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//    return UIInterfaceOrientationPortrait;
//}

- (AVCaptureVideoOrientation)captureVideoOrientation {
    AVCaptureVideoOrientation result;
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            result = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            //如果这里设置成AVCaptureVideoOrientationPortraitUpsideDown，则视频方向和拍摄时的方向是相反的。
            result = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            result = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            result = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            result = AVCaptureVideoOrientationPortrait;
            break;
    }
    
    return result;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.previewLayer.frame = self.previewContainer.bounds;
    AVCaptureVideoOrientation orientation = [self captureVideoOrientation];
    if (self.previewLayer.connection.isVideoOrientationSupported) {
        self.previewLayer.connection.videoOrientation = orientation;
    }
    
    CGFloat w = CGRectGetWidth(self.previewContainer.bounds);
    CGFloat h = CGRectGetHeight(self.previewContainer.bounds);
    
    /**
     rectOfInterest
     竖屏 x轴和y轴要交换一下
     Left、Right：Home键反方向X为0
     */
    CGRect rect = CGRectMake(CGRectGetMinY(self.scanerView.frame) / h, CGRectGetMinX(self.scanerView.frame) / w, CGRectGetHeight(self.scanerView.frame) / h, CGRectGetWidth(self.scanerView.frame) / w);
    if (orientation == AVCaptureVideoOrientationLandscapeRight) {
        
        rect = CGRectMake(CGRectGetMinX(self.scanerView.frame) / w, CGRectGetMinY(self.scanerView.frame) / h, CGRectGetWidth(self.scanerView.frame) / w,CGRectGetHeight(self.scanerView.frame) / h);
        
    } else if (orientation == AVCaptureVideoOrientationLandscapeLeft){
        
        rect = CGRectMake(1 - CGRectGetMaxX(self.scanerView.frame) / w, 1 - CGRectGetMaxY(self.scanerView.frame) / h, CGRectGetWidth(self.scanerView.frame) / w,CGRectGetHeight(self.scanerView.frame) / h);
        
    } else {
        
        rect = CGRectMake(CGRectGetMinY(self.scanerView.frame) / h, CGRectGetMinX(self.scanerView.frame) / w, CGRectGetHeight(self.scanerView.frame) / h, CGRectGetWidth(self.scanerView.frame) / w);
    }
    
    [self.output setRectOfInterest:rect];
    
    [self.view bringSubviewToFront:self.scanerView];
    
    CGRect scanlineFrame = CGRectMake(0, CGRectGetMidY(self.scanerView.bounds) - 0.5, CGRectGetWidth(self.scanerView.bounds), 1);
    self.scanLineLayer.frame = scanlineFrame;
    [self.scanerView.layer insertSublayer:self.scanLineLayer atIndex:0];
    
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.maskView.bounds];
    UIBezierPath *subPath = [UIBezierPath bezierPathWithRect:self.scanerView.frame];
    [path appendPath:subPath];

    if (!self.maskLayer) {
        self.maskLayer = [CAShapeLayer layer];
        self.maskLayer.fillColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.5].CGColor;
        self.maskLayer.fillRule = kCAFillRuleEvenOdd;
    }
    self.maskLayer.path = path.CGPath;

    if (!self.rectLayer) {
        self.rectLayer = [CAShapeLayer layer];
        self.rectLayer.fillColor = [UIColor clearColor].CGColor;
        self.rectLayer.strokeColor = [UIColor whiteColor].CGColor;
        self.rectLayer.lineWidth = 0.5f;
    }
    self.rectLayer.path = subPath.CGPath;
    
    [self.maskLayer addSublayer:self.rectLayer];
    [self.maskView.layer addSublayer:self.maskLayer];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
//    NSLog(@"device orientation: %ld & statusbar orientaion: %ld",[UIDevice currentDevice].orientation,[UIApplication sharedApplication].statusBarOrientation);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.scannerInitial) {
        [self.session startRunning];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CAGradientLayer *)scanLineLayer {
    if (!_scanLineLayer) {
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        //set gradient colors
        // 数组成员接受 CGColorRef 类型的值
        gradientLayer.colors = @[(__bridge id)[UIColor colorWithRed:1 green:0 blue:0 alpha:0.2].CGColor,(__bridge id)[UIColor redColor].CGColor,(__bridge id)[UIColor colorWithRed:1 green:0 blue:0 alpha:0.2].CGColor];
        
        gradientLayer.locations = @[@2.5,@0.5,@0.75];

        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1, 0);
        _scanLineLayer = gradientLayer;
    }
    return _scanLineLayer;
}

#pragma mark - Init

- (void)initCapture {
    
    self.scannerInitial = NO;
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *inputError;
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&inputError];
    
    if (inputError) {
        NSLog(@"init scanner input error: %@",inputError);
        return;
    }
    
    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    } else {
        NSLog(@"init scanner can't add input");
        return;
    }
    
    self.output = [[AVCaptureMetadataOutput alloc] init];
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    if ([self.session canAddOutput:self.output]) {
        [self.session addOutput:self.output];
    } else {
        NSLog(@"init scanner can't add output");
        return;
    }
    self.output.metadataObjectTypes = @[
                                        AVMetadataObjectTypeQRCode,
                                        AVMetadataObjectTypeEAN13Code,
                                        AVMetadataObjectTypeEAN8Code,
                                        AVMetadataObjectTypeUPCECode,
                                        AVMetadataObjectTypeCode39Code,
                                        AVMetadataObjectTypeCode39Mod43Code,
                                        AVMetadataObjectTypeCode93Code,
                                        AVMetadataObjectTypeCode128Code,
                                        AVMetadataObjectTypePDF417Code
                                        ];
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.previewContainer.layer addSublayer:self.previewLayer];
    
    self.scannerInitial = YES;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    if ([metadataObjects count] > 0) {
        [self.session stopRunning];
        
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        NSString *codeValue = metadataObject.stringValue;
        if (self.completion) {
            self.completion(codeValue);
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

@end
