//
//  BLMultiDirectionalSwipeRecognizer.h
//  TwoSuperN
//
//  Created by Ben La Monica on 6/21/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    NONE = 0,
    LEFT = 1,
    RIGHT = 2,
    UP = 4,
    DOWN = 8
} BLDirection;


@interface BLMultiDirectionalSwipeRecognizer : UIPanGestureRecognizer
{
    NSMutableDictionary *actions;
}

-(id) init;
-(void)addTarget:(void (^)())action direction:(BLDirection)dir;

@end
