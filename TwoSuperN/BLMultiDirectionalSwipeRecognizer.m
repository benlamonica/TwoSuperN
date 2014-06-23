//
//  BLMultiDirectionalSwipeRecognizer.m
//  TwoSuperN
//
//  Created by Ben La Monica on 6/21/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import "BLMultiDirectionalSwipeRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation BLMultiDirectionalSwipeRecognizer

-(id) init {
    self = [super initWithTarget:self action:@selector(detectDirection:)];
    
    if (self) {
        self->actions = [NSMutableDictionary new];
        self.delaysTouchesEnded = NO;
    }
    
    return self;
}

-(void)addTarget:(void (^)())action direction:(BLDirection)dir {
    NSMutableArray *arr = actions[@(dir)];
    if (arr == nil) {
        arr = [NSMutableArray new];
        actions[@(dir)] = arr;
    }
    
    [arr addObject:action];
}

-(void)detectDirection:(UIPanGestureRecognizer*)pan {
    if (pan.state == UIGestureRecognizerStateEnded) {
        CGPoint stopPan = [pan translationInView:self.view];
        CGPoint velocity = [pan velocityInView:self.view];
        
        int direction = NONE;
        
        // first determine the directions
        if (velocity.x < 0) {
            direction |= LEFT;
        } else if (velocity.x > 0) {
            direction |= RIGHT;
        }
        
        if (velocity.y < 0) {
            direction |= UP;
        } else if (velocity.y > 0) {
            direction |= DOWN;
        }
        
        double x2 = stopPan.x;
        double x1 = 0;
        double y2 = abs(stopPan.y);
        double y1 = 0;
        
        
        double angle = atan((y2 - y1 + 1) / (x2 - x1 + 1)) * 57.29577951308233;
        
        // mask out the vertical directions if they aren't sufficiently strong
        if ((angle < 0 && angle < -55) || (angle > 0 && angle > 55)) {
            direction &= (UP | DOWN);
        }
        
        // mask out the horizontal directions if they aren't sufficiently strong
        if ((angle < 0 && angle > -35) || (angle > 0 && angle < 35)) {
            direction &= (LEFT | RIGHT);
        }

        NSLog(@"Direction is %s%s%s%s", ((direction & UP) == UP) ? "UP" : "",
              ((direction & DOWN) == DOWN) ? "DOWN" : "",
              ((direction & LEFT) == LEFT) ? "LEFT" : "",
              ((direction & RIGHT) == RIGHT) ? "RIGHT" : "");
        
        NSArray *targets = actions[@(direction)];
        if (targets != nil) {
            for (void(^notify)() in targets) {
                notify();
            }
        }
    }
}

@end
