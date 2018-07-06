//
//  ResultViewController.h
//  QMCode
//
//  Created by 主用户 on 16/2/26.
//  Copyright © 2016年 江萧. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SQRScanCodeType) {
    //二维码
    SQRScanCodeTypeQRCode = 0,
    //条形码
    SQRScanCodeTypeBarCode,
    //二维码加条形码
    SQRScanCodeTypeQRCodeAndBarCode
};

//用block返回扫描结果
typedef void(^scanCodeReturnBlock)(NSString *code);


@interface SQRScanCodeVC :UIViewController

/**
 *  扫码 类型(枚举类型)
 */
@property (nonatomic,assign) SQRScanCodeType scanCodeType;

@property (nonatomic,strong) UIColor *navColor;         //导航颜色

@property (nonatomic,strong) scanCodeReturnBlock block;

- (void)scanCodeReturnBlock:(scanCodeReturnBlock)block;

@end
