//
//  LuxRange.h
//  TestBrightness
//
//  Created by Harshad on 04/01/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CUBBrightnessSetting : NSObject

- (instancetype)initWithLux:(int)lux screenBrightness:(float)screenBrightness;
- (instancetype)initWithDictionary:(NSDictionary *)aDictionary;
- (NSDictionary *)toDictionary;

@property (nonatomic) float lux;
@property (nonatomic) float screenBrightness;

@end
