//
//  CDVGaodeAction.h
//
//  Modified by 许灵 on 2019/1/15.
//
#import <Cordova/CDV.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>

@interface CDVGaodeLocation : CDVPlugin <AMapLocationManagerDelegate>

@property (nonatomic) BOOL isWatch;
@property (nonatomic, strong) NSString *currentCallbackId;
@property (nonatomic, strong) AMapLocationManager *locationManager;
@property (nonatomic, strong) NSMutableDictionary *locationInfo;
@property (nonatomic, strong) NSMutableArray *watchActions;
@property (nonatomic, copy) AMapLocatingCompletionBlock completionBlock;

@property (nonatomic, assign) CGFloat minSpeed;     //最小速度
@property (nonatomic, assign) CGFloat minFilter;    //最小范围
@property (nonatomic, assign) CGFloat minInteval;   //更新间隔
@property (nonatomic, assign) CGFloat distanceFilter;    //最小范围

- (void)getLocation:(CDVInvokedUrlCommand *)command;
- (void)configLocationManager:(CDVInvokedUrlCommand *)command;
- (void)watchLocation:(CDVInvokedUrlCommand *)command;
- (void)stopWatch:(CDVInvokedUrlCommand *)command;

@end
