//
//  CDVGaodeAction.h
//
//  Modified by 许灵 on 2019/1/15.
//
#import "CDVGaodeLocation.h"
#import "CDVGaodeAction.h"

#define DefaultLocationTimeout 10
#define DefaultReGeocodeTimeout 5

@implementation CDVGaodeLocation

#pragma mark "API"

- (void)pluginInitialize {
    // 初始化Key
    NSString *key = [[self.commandDelegate settings] objectForKey:@"gaodekey"];
    key = [key substringFromIndex:5];
    [AMapServices sharedServices].apiKey = key;
    
    self.isWatch = NO;
    self.minSpeed   = 2;
    self.minFilter  = 50;
    self.minInteval = 10;
    self.distanceFilter = self.minFilter;
    
    [self initCompleteBlock];
    [self initLocationManager];
}

- (void)configLocationManager:(CDVInvokedUrlCommand *)command {
    NSDictionary *iosPara;
    NSDictionary *param = [command.arguments objectAtIndex:0];

    if ((NSNull *)param == [NSNull null]) {
        param = nil;
    } else {
        iosPara = [param objectForKey:@"ios"];
    }
    
    // 设置期望的定位精度
    CLLocationAccuracy accuracy = kCLLocationAccuracyNearestTenMeters;
    NSString *accuracyCode = [[iosPara objectForKey:@"accuracy"] stringValue];
    
    if ([accuracyCode isEqualToString:@"1"]) {
        accuracy = kCLLocationAccuracyBestForNavigation;
    } else if ([accuracyCode isEqualToString:@"2"]) {
        accuracy = kCLLocationAccuracyBest;
    } else if ([accuracyCode isEqualToString:@"3"]) {
        accuracy = kCLLocationAccuracyNearestTenMeters;
    } else if ([accuracyCode isEqualToString:@"4"]) {
        accuracy = kCLLocationAccuracyHundredMeters;
    } else if ([accuracyCode isEqualToString:@"5"]) {
        accuracy = kCLLocationAccuracyKilometer;
    } else if ([accuracyCode isEqualToString:@"6"]) {
        accuracy = kCLLocationAccuracyThreeKilometers;
    }
    [self.locationManager setDesiredAccuracy:accuracy];
    
    // 设置定位超时时间
    NSInteger locationTimeout;
    if ([iosPara objectForKey:@"locationTimeout"]) {
        locationTimeout = [[iosPara objectForKey:@"locationTimeout"] integerValue];
    } else {
        locationTimeout = DefaultLocationTimeout;
    }
    [self.locationManager setLocationTimeout:locationTimeout];
    
    //设置逆地址超时时间
    NSInteger reGeoCodeTimeout;
    if ([iosPara objectForKey:@"reGeoCodeTimeout"]) {
        reGeoCodeTimeout = [[iosPara objectForKey:@"reGeoCodeTimeout"] integerValue];
    } else {
        reGeoCodeTimeout = DefaultReGeocodeTimeout;
    }
    
    [self.locationManager setReGeocodeTimeout:reGeoCodeTimeout];
    
    [self successWithCallbackID:command.callbackId];
}

- (void)getLocation:(CDVInvokedUrlCommand *)command {
    if([self hasPermission:command]) {
        if( self.isWatch && self.locationInfo != nil) {
            [self successWithCallbackID:command.callbackId withDictionary:self.locationInfo];
        } else {
            [self.commandDelegate runInBackground:^{
                self.currentCallbackId = command.callbackId;
                [self reGeocodeAction];
            }];
        }
    }
}

- (void)watchLocation:(CDVInvokedUrlCommand *) command {
    if([self hasPermission:command]) {
        CDVGaodeAction *action = [[CDVGaodeAction alloc] initWithCommand:command];
        if(self.watchActions == nil) {
            self.watchActions = [[NSMutableArray alloc] initWithObjects:action, nil];
        } else {
            [self.watchActions addObject:action];
        }
        if(!self.isWatch) {
            [self.locationManager startUpdatingLocation];
            self.isWatch = YES;
        }
        NSDictionary *success =
            @{
              @"requestCode": [NSString stringWithFormat:@"%lu", [action requestCode]],
            };
        [self successKeepWithCallbackID:command.callbackId withDictionary:success];
    }
}

- (void)stopWatch:(CDVInvokedUrlCommand *)command {
    NSString *param = [command.arguments objectAtIndex:0];
    if((NSNull *)param == [NSNull null]) {
        NSDictionary *err =
            @{
              @"errorCode": [NSString stringWithFormat:@"%ld", 101L],
              @"errorInfo": @"参数错误，请检查参数格式"
            };
        [self failWithCallbackID:command.callbackId withDictionary:err];
    } else {
        NSUInteger requestCode = [param longLongValue];
        
        CDVGaodeAction *shouldRemove = [self findActionByRequestCode: requestCode];
        
        [self.watchActions removeObject:shouldRemove];
        [self successWithCallbackID:command.callbackId];
        if ([self.watchActions count] == 0) {
            [self.locationManager stopUpdatingLocation];
            self.isWatch = NO;
        }
    }
}

#pragma mark "AMapLocationManagerDelegate"

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location  reGeocode:(AMapLocationReGeocode *)reGeocode
{
    [self adjustDistanceFilter:location];
    if(location.horizontalAccuracy < 0) {
        return;
    }
    NSMutableDictionary *locationInfo = [self genLocation:location withReGeocode:reGeocode];
    self.locationInfo = locationInfo;
    [self sendLocation];
}

#pragma mark "Private methods"

- (CDVGaodeAction *) findActionByRequestCode: (NSUInteger) requestCode {
    NSEnumerator *enumerator = [self.watchActions objectEnumerator];
    CDVGaodeAction *anObject;
    while (anObject = [enumerator nextObject]) {
        if([anObject requestCode] == requestCode) {
            return anObject;
        }
    }
    return nil;
}

- (void) sendLocation {
    NSEnumerator *enumerator = [self.watchActions objectEnumerator];
    CDVGaodeAction *anObject;
    
    while (anObject = [enumerator nextObject]) {
        [self successKeepWithCallbackID:[[anObject command] callbackId] withDictionary:self.locationInfo];
    }
}

/**
 *  规则: 如果速度小于minSpeed m/s 则把触发范围设定为minFilter m
 *  否则将触发范围设定为minSpeed*minInteval
 *  此时若速度变化超过10% 则更新当前的触发范围(这里限制是因为不能不停的设置distanceFilter,
 *  否则uploadLocation会不停被触发)
 */
- (void)adjustDistanceFilter:(CLLocation*)location
{
    if ( location.speed < self.minSpeed )
    {
        if ( fabs(self.distanceFilter-self.minFilter) > 0.1f )
        {
            self.distanceFilter = self.minFilter;
            self.locationManager.distanceFilter = self.distanceFilter;
        }
    }
    else
    {
        CGFloat lastSpeed = self.distanceFilter/self.minInteval;
        
        if ( (fabs(lastSpeed-location.speed)/lastSpeed > 0.1f) || (lastSpeed < 0) )
        {
            CGFloat newSpeed  = (int)(location.speed+0.5f);
            CGFloat newFilter = newSpeed*self.minInteval;
            
            self.distanceFilter = newFilter;
            self.locationManager.distanceFilter = self.distanceFilter;
        }
    }
    
}

- (BOOL)hasPermission:(CDVInvokedUrlCommand *)command {
    // 判断当前 app 是否打开了定位权限
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        NSDictionary *err = @{
                              @"errorCode": [NSString stringWithFormat:@"%ld", 12L],
                              @"errorInfo": @"定位权限没有打开"
                              };
        //定位不能用
        [self failWithCallbackID: command.callbackId withDictionary: err];
        return @NO;
    }
    return @YES;
}

- (void)reGeocodeAction
{
    //进行单次带逆地理定位请求
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:self.completionBlock];
}



- (void)initCompleteBlock {
    __weak CDVGaodeLocation *weakSelf = self;
    self.completionBlock = ^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error)
    {
        if (error != nil && error.code == AMapLocationErrorLocateFailed)
        {
            //定位错误：此时location和regeocode没有返回值，不进行annotation的添加
            NSString *errorMsg = [NSString stringWithFormat:@"定位错误:{%ld - %@};", (long)error.code, error.localizedDescription];
            NSDictionary *err = @{ @"errorCode": [NSString stringWithFormat:@"%ld", (long)error.code],
                                   @"errorInfo": errorMsg
                                   };
            [weakSelf failWithCallbackID:weakSelf.currentCallbackId withDictionary:err];
            NSLog(@"定位错误:{%ld - %@};", (long)error.code, error.localizedDescription);
            return;
        }
        else if (error != nil
                 && (error.code == AMapLocationErrorReGeocodeFailed
                     || error.code == AMapLocationErrorTimeOut
                     || error.code == AMapLocationErrorCannotFindHost
                     || error.code == AMapLocationErrorBadURL
                     || error.code == AMapLocationErrorNotConnectedToInternet
                     || error.code == AMapLocationErrorCannotConnectToHost))
        {
            //逆地理错误：在带逆地理的单次定位中，逆地理过程可能发生错误，此时location有返回值，regeocode无返回值，进行annotation的添加
            NSString *errorMsg = [NSString stringWithFormat:@"逆地理错误:{%ld - %@};", (long)error.code, error.localizedDescription];
            NSDictionary *err = @{ @"errorCode": [NSString stringWithFormat:@"%ld", (long)error.code],
                                   @"errorInfo": errorMsg
                                   };
            [weakSelf failWithCallbackID:weakSelf.currentCallbackId withDictionary:err];
            NSLog(@"%@", errorMsg);
        } else if (error != nil && error.code == AMapLocationErrorRiskOfFakeLocation) {
            NSString *errorMsg = [NSString stringWithFormat:@"存在虚拟定位的风险:{%ld - %@};", (long)error.code, error.localizedDescription];
            [weakSelf failWithCallbackID:weakSelf.currentCallbackId withMessage:errorMsg];
            //存在虚拟定位的风险：此时location和regeocode没有返回值，不进行annotation的添加
            NSLog(@"%@", errorMsg);
            return;
        }
        NSMutableDictionary *locationInfo = [weakSelf genLocation:location withReGeocode:regeocode];
        
        [weakSelf successWithCallbackID:weakSelf.currentCallbackId withDictionary: locationInfo];
    };
}

- (NSMutableDictionary *) genLocation: (CLLocation *) location withReGeocode: (AMapLocationReGeocode *) regeocode {
    NSNumber *latitude = [[NSNumber alloc] initWithDouble:location.coordinate.latitude];
    NSNumber *longitude = [[NSNumber alloc] initWithDouble:location.coordinate.longitude];
    NSMutableDictionary *locationInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[latitude stringValue], @"latitude", [longitude stringValue], @"longitude", nil];
    
    //修改label显示内容
    if (regeocode) {
        [locationInfo setValue:regeocode.formattedAddress forKey:@"address"];
        [locationInfo setValue:regeocode.country forKey:@"country"];
        [locationInfo setValue:regeocode.province forKey:@"province"];
        [locationInfo setValue:regeocode.city forKey:@"city"];
        [locationInfo setValue:regeocode.district forKey:@"district"];
        [locationInfo setValue:regeocode.citycode forKey:@"cityCode"];
        [locationInfo setValue:regeocode.adcode forKey:@"adCode"];
        
        NSLog(@"地址信息：%@", [NSString stringWithFormat:@"%@ \n %@-%@-%.2fm", regeocode.formattedAddress,regeocode.citycode, regeocode.adcode, location.horizontalAccuracy]);
    } else {
        [locationInfo setValue:[NSString stringWithFormat:@"%.2fm", location.horizontalAccuracy] forKey:@"accuracy"];
        
        NSLog(@"经纬度：%@", [NSString stringWithFormat:@"lat:%f;lon:%f \n accuracy:%.2fm", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy]);
    }
    return locationInfo;
}

- (void) initLocationManager {
    self.locationManager = [[AMapLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    // 设置是否允许系统暂停定位
    [self.locationManager setPausesLocationUpdatesAutomatically:NO];
    // 设置是否允许后台定位/ios9及以上，本插件只支付ios9或以上
    [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    
    [self.locationManager setLocatingWithReGeocode:YES];
}

- (void)successWithCallbackID:(NSString *)callbackID {
    [self successWithCallbackID:callbackID withMessage:@"success"];
}

- (void)successWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message {
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)successWithCallbackID:(NSString *)callbackID withDictionary:(NSDictionary *)dictionary {
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)successKeepWithCallbackID:(NSString *)callbackID withDictionary:(NSDictionary *)dictionary {
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    [commandResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)failWithCallbackID:(NSString *)callbackID withError:(NSError *)error {
    [self failWithCallbackID:callbackID withMessage:[error localizedDescription]];
}

- (void)failWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message {
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)failWithCallbackID:(NSString *)callbackID withDictionary:(NSDictionary *)dictionary {
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)failKeepWithCallbackID:(NSString *)callbackID withDictionary:(NSDictionary *)dictionary {
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    [commandResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

@end
