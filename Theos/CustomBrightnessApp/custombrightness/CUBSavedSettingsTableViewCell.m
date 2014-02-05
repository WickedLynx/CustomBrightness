//
//  CUBSavedSettingsTableViewCell.m
//  CustomBrightness
//
//  Created by Harshad Dange on 09/01/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "CUBSavedSettingsTableViewCell.h"

@implementation CUBSavedSettingsTableViewCell {
    __weak UILabel *_luxLabel;
    __weak UILabel *_brightnessLabel;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, 110, self.bounds.size.height)];
        [aLabel setFont:[UIFont systemFontOfSize:14.0f]];
        [self addSubview:aLabel];
        _luxLabel = aLabel;
        
        UILabel *anotherLabel = [[UILabel alloc] initWithFrame:CGRectMake(200, 0, 110, self.bounds.size.height)];
        [anotherLabel setFont:[UIFont systemFontOfSize:14.0f]];
        [self addSubview:anotherLabel];
        _brightnessLabel = anotherLabel;

    }
    return self;
}

- (void)setLux:(int)lux brightness:(float)brightness {
    [_luxLabel setText:[NSString stringWithFormat:@"%d", lux]];
    [_brightnessLabel setText:[NSString stringWithFormat:@"%.4f", brightness]];
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    [[UIColor colorWithWhite:0.3f alpha:1.0f] setStroke];
    
    CGContextSetLineWidth(currentContext, 1.0f);
    CGContextMoveToPoint(currentContext, 160.0f, 0);
    CGContextAddLineToPoint(currentContext, 160.0f, self.bounds.size.height);
    
    CGContextDrawPath(currentContext, kCGPathStroke);
}

@end
