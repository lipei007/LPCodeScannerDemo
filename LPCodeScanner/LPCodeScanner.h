//
//  RAQRCodeScannerViewController.h
//  Apex And Drivers
//
//  Created by Jack on 2018/6/5.
//  Copyright © 2018年 USAI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LPCodeScanner : UIViewController

+ (instancetype)codeScannerWithCompletionHandler:(void(^)(LPCodeScanner *scanner, BOOL cancel, NSString *value))completion;

@end
