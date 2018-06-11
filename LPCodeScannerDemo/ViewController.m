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
    
    LPCodeScanner *scanner = LPCodeScanner.codeScanner;
    scanner.completion = ^(NSString *value) {
        self.codeLB.text = value;
    };
    [self.navigationController pushViewController:scanner animated:YES];
    
}

@end
