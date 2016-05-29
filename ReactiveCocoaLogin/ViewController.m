//
//  ViewController.m
//  ReactiveCocoaLogin
//
//  Created by Spectator on 16/5/28.
//  Copyright © 2016年 Spectator. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa.h>
#import "LoginService.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *userTF;
@property (weak, nonatomic) IBOutlet UITextField *passTF;
@property (weak, nonatomic) IBOutlet UIButton *loginBTN;
@property (nonatomic, strong) LoginService *service;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.service = [LoginService new];
    
    // Do any additional setup after loading the view, typically from a nib

//    新加的map操作通过block改变了事件的数据。map从上一个next事件接收数据，通过执行block把返回值传给下一个next事件。在上面的代码中，map以NSString为输入，取字符串的长度，返回一个NSNumber。

    RACSignal *validUsernameSignal = [self.userTF.rac_textSignal map:^id(NSString *text) {
        return @([self isValidUsername:text]);
    }];
    RACSignal *validPasswordSignal =
    [self.passTF.rac_textSignal
     map:^id(NSString *text) {
         return @([self isValidPassword:text]);
     }];
    
    
//    RAC宏允许直接把信号的输出应用到对象的属性上。RAC宏有两个参数，第一个是需要设置属性值的对象，第二个是属性名。每次信号产生一个next事件，传递过来的值都会应用到该属性上
    
    RAC(self.userTF, backgroundColor) = [validUsernameSignal map:^id(NSNumber *userValid) {
        return [userValid boolValue] ? [UIColor clearColor] : [UIColor purpleColor];
    }];

    
    RAC(self.passTF, backgroundColor) = [validPasswordSignal map:^id(NSNumber *passValid) {
        return [passValid boolValue] ? [UIColor clearColor] : [UIColor purpleColor];
    }];
    
    
//    combineLatest:reduce:方法把validUsernameSignal和validPasswordSignal产生的最新的值聚合在一起，并生成一个新的信号。每次这两个源信号的任何一个产生新值时，reduce block都会执行，block的返回值会发给下一个信号。
    RACSignal *loginSignal = [RACSignal combineLatest:@[validPasswordSignal,validUsernameSignal] reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid){
        return @([usernameValid boolValue] && [passwordValid boolValue]);
    }];
    
    [loginSignal subscribeNext:^(NSNumber *login) {
        self.loginBTN.enabled = [login boolValue];
    }];
    
    
    [[[[self.loginBTN rac_signalForControlEvents:UIControlEventTouchUpInside] doNext:^(id x) {
        self.loginBTN.enabled = NO;
    }] flattenMap:^RACStream *(id value) {
        return [self loginInSignal];
    }] subscribeNext:^(NSNumber *loginIn) {
        NSLog(@"登录结果：%@",loginIn);
                    BOOL success = [loginIn boolValue];
                    if (success) {
                        [self performSegueWithIdentifier:@"Kitten" sender:self];
                    }

    }];
    
}


- (RACSignal *)loginInSignal {
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.service signInWithUsername:self.userTF.text password:self.passTF.text complete:^(BOOL success) {
            [subscriber sendNext:@(success)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}




- (BOOL)isValidUsername:(NSString *)username {
    return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
    return password.length > 3;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
