//
//  BLViewController.m
//  KO4096
//
//  Created by Ben La Monica on 3/31/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import "BLViewController.h"
#import <dispatch/semaphore.h>

@interface BLViewController ()
-(UILabel *) getTileAt:(int)pos Val:(int)val;
-(void) removeActiveTile:(UIView *)tile;
@end

@implementation BLViewController

@synthesize score=m_score, highScore=m_highScore;

-(void) removeActiveTile:(UIView *)tile {
    [m_activeTiles removeObject:tile];
}

-(void) onMergeFrom:(CGPoint)source To:(CGPoint)target Val:(int) val {
    __weak id weakView = self.view;
    __weak id weakSelf = self;
    [m_animationTempQueue addObject:^(void(^completion)(void)){
        int fromTag = target.y * 4 + target.x + 200;
        int toTag = source.y * 4 + source.x + 200;
        UIView *fromTile = [weakView viewWithTag:fromTag];
        UIView *toTile = [weakView viewWithTag:toTag];
        UIView *newTile = [weakSelf getTileAt:toTag-100 Val:val];
        newTile.alpha = 0;
        [weakView addSubview:newTile];
        [UIView animateWithDuration:0.1 animations:^{
            fromTile.frame = toTile.frame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                fromTile.alpha = 0;
                toTile.alpha = 0;
                newTile.alpha = 1;
            } completion:^(BOOL finished) {
                [fromTile removeFromSuperview];
                [toTile removeFromSuperview];
                [weakSelf removeActiveTile: fromTile];
                [weakSelf removeActiveTile: toTile];
                NSLog(@"Merge (%.0f,%.0f) -> (%.0f,%.0f) = %d", source.x,source.y,target.x,target.y, val);
                if (completion != nil) {
                    completion();
                }
            }];
        }];
    }];
}

-(void) animatePieceFrom:(CGPoint)source To:(CGPoint)target {
    __weak id weakView = self.view;
    [m_animationTempQueue addObject:^(void(^completion)(void)) {
        int fromTag = source.y * 4 + source.x + 200;
        int toTag = target.y * 4 + target.x + 100;
        UIView *fromTile = [weakView viewWithTag:fromTag];
        UIView *toLoc = [weakView viewWithTag:toTag];
        fromTile.tag = toTag + 100;
        [UIView animateWithDuration:0.1 animations:^{
            fromTile.frame = CGRectMake(toLoc.frame.origin.x, toLoc.frame.origin.y, toLoc.frame.size.width, toLoc.frame.size.height);
        } completion:^(BOOL finished) {
            NSLog(@"Move (%.0f,%.0f) -> (%.0f,%.0f)", source.x,source.y,target.x,target.y);
            if (completion != nil) {
                completion();
            }
        }];
    }];
}

-(void) onMoveFrom:(CGPoint)source To:(CGPoint)target {
    if (m_lastMove.isInitialized) {
        if (m_lastMove.target.x == source.x && m_lastMove.target.y == source.y) {
            // same piece is being moved, consolidate.
            m_lastMove.target = target;
        } else {
            // new piece is being moved, so go ahead and animate this one.
            [self animatePieceFrom:m_lastMove.source To:m_lastMove.target];
            m_lastMove.source = source;
            m_lastMove.target = target;
            m_lastMove.isInitialized = YES; // clear out initialized flag, so that we will work on a new piece
        }
    } else {
        m_lastMove.source = source;
        m_lastMove.target = target;
        m_lastMove.isInitialized = YES;
    }
}

-(void) onNumberAdded:(CGPoint)location Val:(int) val {
    __weak id weakView = self.view;
    __weak id weakSelf = self;
    [m_animationQueue addObject:@[^(void(^completion)(void)) {
        int loc = location.y * 4 + location.x + 100;
        UILabel *tile = [weakSelf getTileAt:loc Val:val];
        [weakView addSubview:tile];
        tile.alpha = 0.75;
        tile.transform = CGAffineTransformMakeScale(0.01, 0.01);
        [UIView animateWithDuration:0.25 delay:0.5 options:0 animations:^{
            tile.alpha = 1.0;
            tile.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            NSLog(@"%d placed at (%.0f,%.0f)", val, location.x, location.y);
            if (completion != nil) {
                completion();
            }
        }];
    }]];
}

-(void) onScoreUpdate:(int) score {
    NSLog(@"score is now %d", score);
    m_score.text = [NSString stringWithFormat:@"%d", score];
    m_highScore.text = [NSString stringWithFormat:@"%d", score];
    
}

-(void) onChangesComplete {
    if (m_lastMove.isInitialized) {
        // new piece is being moved, so go ahead and animate this one.
        [self animatePieceFrom:m_lastMove.source To:m_lastMove.target];
        m_lastMove.isInitialized = NO;
    }
    
    if ([m_animationTempQueue count] > 0) {
        [m_animationQueue addObject:[NSArray arrayWithArray:m_animationTempQueue]];
        [m_animationTempQueue removeAllObjects];
    }
}

-(void) stopListeningToTouchEvents {
    for(UIGestureRecognizer *recognizer in self.view.gestureRecognizers) {
        recognizer.enabled = NO;
    }
}

-(void) startListeningToTouchEvents {
    for(UIGestureRecognizer *recognizer in self.view.gestureRecognizers) {
        recognizer.enabled = YES;
    }
}

-(void) onMoveComplete {
    // turn off the gesture recognizers while we animate, otherwise it gets confused and doesn't display the board correctly if someone swipes during an animation
    [self stopListeningToTouchEvents];
    
    for (int i = 0; i < [m_animationQueue count]; i++) {
        for (int j = 0; j < [m_animationQueue[i] count]; j++) {
            void(^animation)(void(^completion)(void)) = m_animationQueue[i][j];
            animation(nil);
        }
    }
    
    [m_animationQueue removeAllObjects];
    [self startListeningToTouchEvents];
}

-(UILabel *) getTileAt:(int)pos Val:(int)val {
    UILabel *template = m_tiles[[NSString stringWithFormat:@"%d", val]];
    UIView *loc = [self.view viewWithTag:pos];
    CGRect newFrame = CGRectMake(loc.frame.origin.x, loc.frame.origin.y, loc.frame.size.width, loc.frame.size.height);
    UILabel *impl = [[UILabel alloc] initWithFrame:newFrame];
    impl.text = template.text;
    impl.font = template.font;
    impl.textAlignment = template.textAlignment;
    impl.backgroundColor = template.backgroundColor;
    impl.hidden = NO;
    impl.tag = pos + 100;
    [m_activeTiles addObject:impl];
    return impl;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    m_board = [BLBoard new];
    m_board.listener = self;
    m_animationQueue = [NSMutableArray new];
    m_animationTempQueue = [NSMutableArray new];
    m_tiles = @{
        @"2":[self.view viewWithTag:2],
        @"4":[self.view viewWithTag:4],
        @"8":[self.view viewWithTag:8],
        @"16":[self.view viewWithTag:16],
        @"32":[self.view viewWithTag:32],
        @"64":[self.view viewWithTag:64],
        @"128":[self.view viewWithTag:128],
        @"256":[self.view viewWithTag:256],
        @"512":[self.view viewWithTag:512],
        @"1024":[self.view viewWithTag:1024],
        @"2048":[self.view viewWithTag:2048],
        @"4096":[self.view viewWithTag:4096]
    };
    
    for (UIView *tile in [m_tiles allValues]) {
        tile.hidden = YES;
    }
    
    m_activeTiles = [NSMutableArray new];
    m_lastMove.isInitialized = NO;
    
    [self drawBoard];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void) drawBoard {
    // clear the board
    for (UIView *v in m_activeTiles) {
        [v removeFromSuperview];
    }
    
    // draw the board
    NSArray *rows = [m_board rows];
    int pos = 100;
    for (NSArray *row in rows) {
        for (NSNumber *elem in row) {
            int val = elem.intValue;
            if (val != 0) {
                UILabel *impl = [self getTileAt:pos Val:val];
                [self.view addSubview:impl];
            }
            pos++;
        }
    }
}

-(IBAction)swipeUp:(id)sender {
    NSLog(@"swipe up");
    [m_board shiftUp];
}
-(IBAction)swipeDown:(id)sender {
    NSLog(@"swipe down");
    [m_board shiftDown];
}
-(IBAction)swipeLeft:(id)sender {
    NSLog(@"swipe left");
    [m_board shiftLeft];
}
-(IBAction)swipeRight:(id)sender {
    NSLog(@"swipe right");
    [m_board shiftRight];
}


@end
