//
//  BLViewController.h
//  KO4096
//
//  Created by Ben La Monica on 3/31/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLBoard.h"

typedef struct {
    CGPoint source;
    CGPoint target;
    BOOL isInitialized;
} BLMove;

@interface BLViewController : UIViewController <BLBoardEventListener>
{
    BLBoard *m_board;
    NSDictionary *m_tiles;
    NSMutableArray *m_activeTiles;
    BLMove m_lastMove;
    NSMutableArray *m_animationTempQueue;
    NSMutableArray *m_animationQueue;
}

-(IBAction)swipeUp:(id)sender;
-(IBAction)swipeDown:(id)sender;
-(IBAction)swipeLeft:(id)sender;
-(IBAction)swipeRight:(id)sender;

@end
