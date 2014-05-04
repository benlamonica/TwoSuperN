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

@interface BLViewController : UIViewController <BLBoardEventListener,UIAlertViewDelegate>
{
    BLBoard *m_board;
    NSDictionary *m_tiles;
    NSMutableArray *m_activeTiles;
    BLMove m_lastMove;
    NSMutableArray *m_animationTempQueue;
    NSMutableArray *m_animationQueue;
    UILabel *m_scoreLbl;
    UILabel *m_highScoreLbl;
    long m_highScore;
    UIButton *m_restartBtn;
    UILabel *m_gameOverLbl;
    UIImageView *m_arrow;
    void (^m_completion)();
}

-(IBAction)swipeUp:(id)sender;
-(IBAction)swipeDown:(id)sender;
-(IBAction)swipeLeft:(id)sender;
-(IBAction)swipeRight:(id)sender;
-(IBAction)restart:(id)sender;
-(IBAction)suggestAMove:(id)sender;
-(IBAction)playForMe:(id)sender;

@property IBOutlet UILabel *score;
@property IBOutlet UILabel *highScore;
@property IBOutlet UILabel *gameOverLbl;
@property IBOutlet UIImageView *arrow;

@end
