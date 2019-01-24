//
//  ViewController.m
//  LPCodeScannerDemo
//
//  Created by Jack on 2018/6/11.
//  Copyright © 2018年 Jack. All rights reserved.
//

#import "ViewController.h"
#import "LPCodeScanner.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UILabel *codeLB;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)scannerClick:(id)sender {
    
    __weak typeof(self) weakSelf = self;
    LPCodeScanner *scanner = [LPCodeScanner codeScannerWithCompletionHandler:^(LPCodeScanner *scanner, BOOL cancel, NSString *value) {
        if (cancel) {
            
        } else {
            weakSelf.codeLB.text = value;
        }
        
        [scanner.navigationController popViewControllerAnimated:YES];
    }];
    [self.navigationController pushViewController:scanner animated:YES];
    
}

@end
