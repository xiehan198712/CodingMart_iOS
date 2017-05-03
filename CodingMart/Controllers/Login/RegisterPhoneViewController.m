//
//  RegisterPhoneViewController.m
//  CodingMart
//
//  Created by Ease on 15/12/14.
//  Copyright © 2015年 net.coding. All rights reserved.
//

#import "RegisterPhoneViewController.h"
#import "RegisterPasswordViewController.h"
#import "PhoneCodeButton.h"
#import "TableViewFooterButton.h"
#import "UITTTAttributedLabel.h"
#import "Coding_NetAPIManager.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "CountryCodeListViewController.h"
#import <BlocksKit/BlocksKit+UIKit.h>

@interface RegisterPhoneViewController ()
@property (weak, nonatomic) IBOutlet UITextField *mobileF;
@property (weak, nonatomic) IBOutlet UITextField *verify_codeF;
@property (weak, nonatomic) IBOutlet UITextField *global_keyF;
@property (weak, nonatomic) IBOutlet PhoneCodeButton *verify_codeBtn;

@property (weak, nonatomic) IBOutlet TableViewFooterButton *footerBtn;

@property (weak, nonatomic) IBOutlet UILabel *countryCodeL;
@property (strong, nonatomic) NSDictionary *countryCodeDict;

@property (strong, nonatomic) UILabel *loginL;

@end

@implementation RegisterPhoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.countryCodeDict = @{@"country": @"China",
                             @"country_code": @"86",
                             @"iso_code": @"cn"};
    _mobileF.text = _mobile;
    RAC(self, footerBtn.enabled) = [RACSignal combineLatest:@[self.mobileF.rac_textSignal, self.verify_codeF.rac_textSignal, self.global_keyF.rac_textSignal] reduce:^id(NSString *mobile, NSString *verify_code, NSString *global_key){
        return @(mobile.length > 0 && verify_code.length > 0 && global_key.length > 0);
    }];
    
    if (!_loginL) {
        _loginL = [UILabel new];
        _loginL.userInteractionEnabled = YES;
        _loginL.textColor = [UIColor colorWithHexString:@"0x999999"];
        _loginL.font = [UIFont systemFontOfSize:15];
        _loginL.textAlignment = NSTextAlignmentCenter;
        _loginL.frame = CGRectMake(0, kScreen_Height - self.navBottomY - 60, kScreen_Width, 30);
        [self.view addSubview:_loginL];
    }
    [_loginL setAttrStrWithStr:@"已有码市帐号，立即登录" diffColorStr:@"立即登录" diffColor:kColorBrandBlue];
    [_loginL bk_whenTapped:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)setCountryCodeDict:(NSDictionary *)countryCodeDict{
    _countryCodeDict = countryCodeDict;
    _countryCodeL.text = [NSString stringWithFormat:@"+%@", _countryCodeDict[@"country_code"]];
}

#pragma mark - Button
- (IBAction)countryCodeBtnClicked:(id)sender {
    CountryCodeListViewController *vc = [CountryCodeListViewController storyboardVC];
    WEAKSELF;
    vc.selectedBlock = ^(NSDictionary *countryCodeDict){
        weakSelf.countryCodeDict = countryCodeDict;
    };
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)verify_codeBtnClicked:(id)sender {
    if (_mobileF.text.length <= 0) {
        [NSObject showHudTipStr:@"请填写手机号码"];
        return;
    }
    _verify_codeBtn.enabled = NO;
    NSString *path = @"api/account/verification-code";
    
    NSDictionary *params = @{@"phone": _mobileF.text,
                             @"countryCode": [NSString stringWithFormat:@"+%@", _countryCodeDict[@"country_code"]],
                             @"isoCode": _countryCodeDict[@"iso_code"],
                             @"from": @"mart"};
    
    [[CodingNetAPIClient sharedJsonClient] requestJsonDataWithPath:path withParams:params withMethodType:Post andBlock:^(id data, NSError *error) {
        if (data) {
            [NSObject showHudTipStr:@"验证码发送成功"];
            [self.verify_codeBtn startUpTimer];
        }else{
            self.verify_codeBtn.enabled = YES;
        }
    }];
}
- (IBAction)footerBtnClicked:(id)sender {
    [NSObject showHUDQueryStr:@"请稍等..."];
    WEAKSELF;
    [[Coding_NetAPIManager sharedManager] get_CheckGK:_global_keyF.text block:^(NSNumber *isExist, NSError *error0) {
        if (isExist) {
            if (!isExist.boolValue) {
                [NSObject hideHUDQuery];
                [weakSelf performSegueWithIdentifier:NSStringFromClass([RegisterPasswordViewController class]) sender:self];
                
//    easeeeeeeeee todo

//                NSString *path = @"api/account/phone/code/check";
//                NSDictionary *params = @{@"phone": weakSelf.mobileF.text,
//                                         @"code": weakSelf.verify_codeF.text,
//                                         @"phoneCountryCode": [NSString stringWithFormat:@"+%@", weakSelf.countryCodeDict[@"country_code"]],
//                                         @"type": @"register"};
//                [[CodingNetAPIClient codingJsonClient] requestJsonDataWithPath:path withParams:params withMethodType:Post andBlock:^(id data, NSError *error) {
//                    [NSObject hideHUDQuery];
//                    if (data) {
//                        [weakSelf performSegueWithIdentifier:NSStringFromClass([RegisterPasswordViewController class]) sender:self];
//                    }
//                }];
            }else{
                [NSObject hideHUDQuery];
                [NSObject showHudTipStr:@"用户名已存在"];
            }
        }else{
            [NSObject hideHUDQuery];
        }
    }];
}

#pragma mark goTo
- (void)goToServiceTerms{
    NSString *pathForServiceterms = [[NSBundle mainBundle] pathForResource:@"service_terms" ofType:@"html"];
    [self goToWebVCWithUrlStr:pathForServiceterms title:@"码市用户服务协议"];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[RegisterPasswordViewController class]]) {
        RegisterPasswordViewController *vc = (RegisterPasswordViewController *)segue.destinationViewController;
        vc.countryCodeDict = _countryCodeDict;
        vc.phone = _mobileF.text;
        vc.code = _verify_codeF.text;
        vc.global_key = _global_keyF.text;
        vc.loginSucessBlock = _loginSucessBlock;
    }
}

@end
