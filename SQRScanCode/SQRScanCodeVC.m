//
//  ResultViewController.h
//  QMCode
//
//  Created by 主用户 on 16/2/26.
//  Copyright © 2016年 江萧. All rights reserved.
//

#import "SQRScanCodeVC.h"
#import <SQRBaseDefineWithFunction/SQRDataSave.h>
#import <SQRBaseDefineWithFunction/SQRBaseDefine.h>
#import <AVFoundation/AVFoundation.h>

#define ScreenW [UIScreen mainScreen].bounds.size.width
#define ScreenH [UIScreen mainScreen].bounds.size.height
#define Color(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]
#define Qmyalpha 0.2

@interface SQRScanCodeVC ()<AVCaptureMetadataOutputObjectsDelegate,UIAlertViewDelegate>//用于处理采集信息的代理
{
    AVCaptureSession * session;//输入输出的中间桥梁
    AVCaptureMetadataOutput * output;
    UIImageView * _QimageView ;
    UIImageView *_QrCodeline ;
    NSTimer *_timer;
    UIImage *_linimg;
    UILabel *lab;
    int index;
    
    NSString *deviceid;
    NSString *passw;
}

@end

@implementation SQRScanCodeVC
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    index = 0;
    [session startRunning];
    [self createTimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    NSNumber *num = [SQRDataSave takeOutDataFromDataEnum:SaveDataEnum_MasterColor customKey:nil];
    self.navigationController.navigationBar.barTintColor = num ? DEF_HEXColor(num.intValue) : [UIColor lightGrayColor];
    
    [self scanCode];
    
    UILabel *titleLb = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 44)];
    if (self.scanCodeType == SQRScanCodeTypeQRCode) {
        titleLb.text = @"扫描二维码";
    }else if (self.scanCodeType == SQRScanCodeTypeBarCode) {
        titleLb.text = @"扫描条形码";
    }else{
        titleLb.text = @"扫码";
    }
    
    titleLb.textColor = [UIColor whiteColor];
    titleLb.font = [UIFont systemFontOfSize:18];
    titleLb.textAlignment = YES;
    self.navigationItem.titleView = titleLb;
    
    UIButton* leftBtn= [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setImage:[UIImage imageNamed:@"icon_back"] forState:UIControlStateNormal];
    [leftBtn setImageEdgeInsets:UIEdgeInsetsMake(0, -40, 0, 0)];
    leftBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [leftBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    leftBtn.frame = CGRectMake(0, 0, 50, 30);
    
    UIBarButtonItem* leftBtnItem = [[UIBarButtonItem alloc]initWithCustomView:leftBtn];
    [leftBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = leftBtnItem;
}

- (void)rightAction {
    index = 0;
    [session startRunning];
}


- (void)back{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)scanCode{
    
    // iOS 8 后，全部都要授权
    AVAuthorizationStatus status =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                
                if (granted) {
                
                    dispatch_sync(dispatch_get_main_queue(),^{
                        SQRScanCodeVC *qm = [[SQRScanCodeVC alloc] init];
                        [self.navigationController pushViewController:qm animated:NO];
                    });
                   
                }else{
                    //用户拒绝
                    NSLog(@"用户明确地拒绝授权,请打开权限");
                    [self alertViewAction];
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            [self _initview];
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            // 用户明确地拒绝授权，或者相机设备无法访问
            NSLog(@"用户明确地拒绝授权，或者相机设备无法访问,请打开权限");
            [self alertViewAction];
        
            break;
        default:
            break;
    }
}

- (void)alertViewAction{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"请先在手机设置-隐私-相机-里面打开该应用权限" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
}


- (void)_initview{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) {
        //获取摄像设备
        AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        //创建输入流
        AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        //创建输出流
        output = [[AVCaptureMetadataOutput alloc]init];
        //设置代理 在主线程里刷新
        [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
        //初始化链接对象
        session = [[AVCaptureSession alloc]init];
        //高质量采集率
        [session setSessionPreset:AVCaptureSessionPresetHigh];
        
        [session addInput:input];
        [session addOutput:output];
        //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
        
        if (self.scanCodeType == SQRScanCodeTypeQRCode) {
            
            output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode];
            
        }else if (self.scanCodeType == SQRScanCodeTypeBarCode){
            
            output.metadataObjectTypes=@[AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code,AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode39Mod43Code,AVMetadataObjectTypeCode93Code,AVMetadataObjectTypePDF417Code,AVMetadataObjectTypeAztecCode,AVMetadataObjectTypeITF14Code,AVMetadataObjectTypeDataMatrixCode];
            
        }else{
            
            output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code,AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode39Mod43Code,AVMetadataObjectTypeCode93Code,AVMetadataObjectTypePDF417Code,AVMetadataObjectTypeAztecCode,AVMetadataObjectTypeITF14Code,AVMetadataObjectTypeDataMatrixCode];
            
        }
        
        AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:session];
        layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
        layer.frame=self.view.layer.bounds;
        [self.view.layer insertSublayer:layer atIndex:0];
        
        [self setScanImageView];
        [self setScanLine];
        [self setScanBackView];
    }else{
        NSLog(@"该设备无法使用相机功能");
    }
}

#pragma mark-method

//设置扫描这该区域
-(void) setScanBackView {
    
    CGFloat MaxY = CGRectGetMaxY(_QimageView.frame);
    [output setRectOfInterest:CGRectMake(_QimageView.frame.origin.y/self.view.frame.size.height, _QimageView.frame.origin.x/self.view.frame.size.width, _QimageView.frame.size.height/ScreenH, _QimageView.frame.size.width/ScreenW)];

    //上方遮盖层
    UIView * upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,self.view.frame.size.width,_QimageView.frame.origin.y  )];
    upView.backgroundColor = [UIColor blackColor];
    upView.alpha = Qmyalpha;
    [self.view addSubview:upView];
    
    UILabel *TX_lab = [[UILabel alloc] initWithFrame:CGRectMake(50, upView.frame.origin.y + 32 + 64, self.view.frame.size.width - 50 * 2, 40)];
    TX_lab.text = @"请将下方矩形框对准包装或设备上的二维码或条形码进行识别扫描";
    TX_lab.textColor = [UIColor whiteColor];
    TX_lab.font = [UIFont systemFontOfSize:16];
    TX_lab.textAlignment = NSTextAlignmentCenter;
    TX_lab.numberOfLines = 0;
    TX_lab.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:TX_lab];
    
    //左侧遮盖层
    UIView * leftView = [[UIView alloc] initWithFrame:CGRectMake(0, _QimageView.frame.origin.y, _QimageView.frame.origin.x, _QimageView.frame.size.height)];
    leftView.backgroundColor = [UIColor blackColor];
    leftView.alpha = Qmyalpha;
    [self.view addSubview:leftView];
    //右侧遮盖层
    UIView * rightView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame) + _QimageView.frame.size.width, leftView.frame.origin.y, leftView.frame.size.width, leftView.frame.size.height)];
    rightView.backgroundColor = [UIColor blackColor];
    rightView.alpha = Qmyalpha;
    [self.view addSubview:rightView];
    //下方遮盖曾
    UIView * downView = [[UIView alloc] initWithFrame:CGRectMake(0, MaxY, self.view.frame.size.width, ScreenH-MaxY)];
    downView.backgroundColor = [UIColor blackColor];
    downView.alpha = Qmyalpha;
    [self.view addSubview:downView];
    
    UIButton *kaideng = [[UIButton alloc]initWithFrame:CGRectMake((ScreenW-38)/2.0, downView.frame.origin.y+40,38, 38)];
    [kaideng setImage:[UIImage imageNamed:@"scan-open2"] forState:UIControlStateNormal];
    [self.view addSubview:kaideng];
    [kaideng addTarget:self action:@selector(torchOnOrOff:) forControlEvents:UIControlEventTouchUpInside];
    
//    UIButton *shuru = [[UIButton alloc] initWithFrame:CGRectMake((ScreenW-250)/2.0,kaideng.bottom+40, 250, 64)];
//    [shuru setTitle:@"无法识别？切换到手动输入" forState:UIControlStateNormal];
//    [shuru setTitleColor:Color(136,136,136) forState:UIControlStateNormal];
//    shuru.titleLabel.font = [UIFont systemFontOfSize:16];
//    shuru.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
//    [self.view addSubview:shuru];
//    shuru.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
//    [shuru addTarget:self action:@selector(shuruAction) forControlEvents:UIControlEventTouchUpInside];
//    shuru.layer.cornerRadius = shuru.height/2.0;
//    shuru.layer.masksToBounds = YES;
}

//小数转换
-(CGFloat)conversionFloat:(CGFloat)ofloat {
    
    NSString * str =[NSString stringWithFormat:@"%.1f",ofloat ];
    CGFloat a  = str.floatValue;
    return a;
}

//根据传入图片设置扫描框
-(void) setScanImageView {
    CGFloat new = [self conversionFloat:1.1];
    UIImage * img = [UIImage imageNamed:@"扫描框"];
    CGFloat x = (self.view.frame.size.width- img.size.width*new)/2;
    
    CGFloat y = self.view.frame.size.height/2-img.size.height*new+100;
   
    UIImageView * imgView = [[UIImageView alloc] initWithImage:img];
    imgView.frame = CGRectMake(x, y, img.size.width*new, img.size.height*new);
    _QimageView = imgView;
    [self.view addSubview:imgView];
}

//根据传入图片设置扫码线
-(void)setScanLine {
    
    _linimg = [UIImage imageNamed:@"扫描线"];
    _QrCodeline = [[ UIImageView alloc ] initWithImage:_linimg];
    _QrCodeline.frame = CGRectMake(_QimageView.frame.origin.x , _QimageView.frame.origin.y, _QimageView.frame.size.width, _linimg.size.height * 1.1);
    
    [ self.view addSubview : _QrCodeline ];
}

- (void)moveUpAndDownLine {
    CGFloat QY = _QimageView.frame.origin.y;
    CGFloat QMY = CGRectGetMaxY(_QimageView.frame);
    CGFloat Y= _QrCodeline . frame . origin . y ;
    if (Y == QY ){
        
        [UIView beginAnimations: @"asa" context: nil ];
        [UIView setAnimationDuration: 1.5 ];
        _QrCodeline.transform = CGAffineTransformMakeTranslation(0,_QimageView.frame.size.height-4);
        [UIView commitAnimations];

    } else if (Y == QMY-4){
        
        [UIView beginAnimations: @"asa" context: nil ];
        [UIView setAnimationDuration: 1.5 ];
        _QrCodeline.transform = CGAffineTransformMakeTranslation(0, 0);
        [UIView commitAnimations];
    }
}

- (void)createTimer {
    //创建一个时间计数
    _timer=[NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector: @selector (moveUpAndDownLine) userInfo: nil repeats: YES ];
}

- (void)stopTimer {
    
    if ([_timer isValid] == YES ) {
        [_timer invalidate];
        _timer = nil ;
    }
}


#pragma mark AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    //避免多次回调
    if (index == 0) {
        if ([metadataObjects count] > 0) {
            
            AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
            
            if (metadataObject.stringValue) {
                NSLog(@"%@",metadataObject.stringValue);
                [session stopRunning];
                
                if (self.block) {
                    self.block(metadataObject.stringValue);
                }
                [self dismissViewControllerAnimated:YES completion:nil];
            }else{
                
            }
        }
        index = 1;
    }else{
    
    }
    
}

- (void)scanCodeReturnBlock:(scanCodeReturnBlock)block {
    self.block = block;
}


-(void)shuruAction{
    NSLog(@"点击");
}


//调用系统的开灯关灯功能
- (void)torchOnOrOff:(UIButton*)bu {
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    if (device.torchMode == AVCaptureTorchModeOff) {
        [device setTorchMode: AVCaptureTorchModeOn];
        [bu setImage:[UIImage imageNamed:@"scan-open"] forState:UIControlStateNormal];
    }else{
        [device setTorchMode: AVCaptureTorchModeOff];
        
        [bu setImage:[UIImage imageNamed:@"scan-open2"] forState:UIControlStateNormal];
    }
    [device unlockForConfiguration];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [session startRunning];
    [self stopTimer];
}


@end
