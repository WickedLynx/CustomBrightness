//
//  LuxRange.m
//  TestBrightness
//
//  Created by Harshad Dange on 04/01/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "CUBBrightnessSetting.h"

@implementation CUBBrightnessSetting

- (instancetype)initWithLux:(int)lux screenBrightness:(float)screenBrightness {
    
    self = [super init];
    
    if (self != nil) {
        
        _lux = lux;
        _screenBrightness = screenBrightness;
        
    }
    
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)aDictionary {
    self = [super init];
    
    if (self != nil) {
        
        NSNumber *lux = aDictionary[@"lux"];
        if (![lux isKindOfClass:[NSNull class]]) {
            _lux = [lux intValue];
        }
        
        NSNumber *screenBrightness = aDictionary[@"screenBrightness"];
        if (![screenBrightness isKindOfClass:[NSNull class]]) {
            _screenBrightness = [screenBrightness floatValue];
        }
    }
    
    return self;
}

- (NSDictionary *)toDictionary {
    return @{@"lux" : @(_lux), @"screenBrightness" : @(_screenBrightness)};
}
@end
