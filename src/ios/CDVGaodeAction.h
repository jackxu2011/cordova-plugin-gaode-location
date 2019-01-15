//
//  CDVGaodeAction.h
//
//  Created by 许灵 on 2019/1/15.
//
#import <Cordova/CDV.h>

@interface CDVGaodeAction: NSObject

@property (nonatomic) CDVInvokedUrlCommand *command;
@property (nonatomic) NSUInteger requestCode;

- (id)initWithCommand:(CDVInvokedUrlCommand *)command;

@end
