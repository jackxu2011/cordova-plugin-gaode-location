//
//  CDVGaodeAction.m
//  行在岱山
//
//  Created by 许灵 on 2019/1/15.
//

#import "CDVGaodeAction.h"

@implementation CDVGaodeAction

- (id)init {
    self = [super init];
    
    if (self) {
        self.requestCode = [self genRequestCode];
    }
    return self;
}

- (id)initWithCommand:(CDVInvokedUrlCommand *)command {
    self = [super init];
    if (self) {
        self.command = command;
        self.requestCode = [self genRequestCode];
    }
    return self;
}

- (NSUInteger)genRequestCode {
    NSString* stringUUID = [[NSUUID UUID] UUIDString];
    return [stringUUID hash];
}

@end

