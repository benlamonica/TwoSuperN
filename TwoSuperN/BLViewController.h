//
//  BLViewController.h
//  KO4096
//
//  Created by Ben La Monica on 3/31/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLBoard.h"

typedef enum {
    NONE = 0,
    LEFT = 1,
    RIGHT = 2,
    UP = 4,
    DOWN = 8
} BLDirection;

@interface BLViewController : UIViewController <BLBoardEventListener,UIAlertViewDelegate>
{
    BLBoard *m_board;
    NSDictionary *m_tileColors;
    NSMutableArray *m_activeTiles;
    NSMutableArray *m_inactiveTiles;
    NSMutableArray *m_animationQueue;
    UIView *m_boardView;
    UILabel *m_scoreLbl;
    UILabel *m_highScoreLbl;
    long m_highScore;
    UIButton *m_logoBtn;
    UILabel *m_gameOverLbl;
    UILabel *m_hintLbl;
    void (^m_completion)();
    BOOL m_isInDemoMode;
    int m_suggestionNum;
}

-(IBAction)moveDiagonal:(id)sender;
-(IBAction)swipeRight:(id)sender;
-(IBAction)swipeLeft:(id)sender;
-(IBAction)swipeUp:(id)sender;
-(IBAction)swipeDown:(id)sender;
-(IBAction)playForMe:(id)sender;
-(IBAction)restart:(id)sender;
-(IBAction)undo:(id)sender;

@property IBOutlet UILabel *score;
@property IBOutlet UILabel *highScore;
@property IBOutlet UILabel *gameOverLbl;
@property IBOutlet UILabel *hintLbl;
@property IBOutlet UIButton *logoBtn;
@property IBOutlet UIView *boardView;

@end
