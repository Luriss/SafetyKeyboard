//
//  ViewController.m
//  LRSafetyKeyboard
//
//  Created by luris on 2018/6/20.
//  Copyright © 2018年 luris. All rights reserved.
//

#import "ViewController.h"
#import "LRSafetyKeyboard.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor yellowColor];
        
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(30, 80, 300, 50)];
    textField.backgroundColor = [UIColor whiteColor];
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:textField];
    
    LRSafetyKeyboard *view = [[LRSafetyKeyboard alloc] initWithInputSource:textField keyboardType:LRSafetyKeyboardTypeSafetyNumber];
    textField.inputView = view;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 230, 300, 250)];
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:20.0f];
    label.backgroundColor = [UIColor redColor];
    label.numberOfLines = 0;
    [self.view addSubview:label];
    
    UITextField *textField1 = [[UITextField alloc] initWithFrame:CGRectMake(30, 150, 300, 50)];
    textField1.backgroundColor = [UIColor whiteColor];
    textField1.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField1.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:textField1];
    
    LRSafetyKeyboard *view1 = [[LRSafetyKeyboard alloc] initWithInputSource:textField1 keyboardType:LRSafetyKeyboardTypeSafetyQWERTY];
    textField1.inputView = view1;
    [view1 secureTextDidEndEditing:^(NSString *text) {
        NSLog(@"text = %@",text);
    }];
    
    [view1 secureTextDidChange:^(NSString *text) {
        label.text = text;
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [textField resignFirstResponder];
    });
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self setEditing:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
