//
//  CUBBorderedButton.m
//  CustomBrightness
//
//  Created by Harshad on 25/01/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "CUBBorderedButton.h"

@implementation CUBBorderedButton {
    UIColor *_highlightColor;
}

- (id)initWithFrame:(CGRect)frame highlightColor:(UIColor *)highlightColor
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        _highlightColor = highlightColor;
        
        [self.layer setBorderColor:[highlightColor CGColor]];
        [self.layer setBorderWidth:1.0f];
        [self.layer setCornerRadius:5.0f];
        
        [self setTitleColor:highlightColor forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        [self setBackgroundColor:_highlightColor];
    } else {
        [self setBackgroundColor:[UIColor clearColor]];
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (selected) {
        [self setBackgroundColor:_highlightColor];
    } else {
        [self setBackgroundColor:[UIColor clearColor]];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
