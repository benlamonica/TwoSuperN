//
//  BLViewController.m
//  KO4096
//
//  Created by Ben La Monica on 3/31/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import "BLViewController.h"
#import "BLMultiDirectionalSwipeRecognizer.h"

@interface BLViewController ()
-(UILabel *) getTileAt:(int)pos Val:(int)val;
-(void) removeActiveTile:(UIView *)tile;
@end

@implementation BLViewController

@synthesize score=m_scoreLbl, highScore=m_highScoreLbl, gameOverLbl=m_gameOverLbl, hintLbl=m_hintLbl, logoBtn=m_logoBtn, boardView=m_boardView;


-(void) removeActiveTile:(UIView *)tile {
    [tile removeFromSuperview];
    [m_activeTiles removeObject:tile];
    [m_inactiveTiles addObject:tile];
}

-(void) animateMergeFrom:(CGPoint)source To:(CGPoint)target Final:(CGPoint)final Val:(int)val {
    __weak id weakView = self.boardView;
    __weak id weakSelf = self;
    [m_animationQueue addObject:^(void(^completion)(void)){
        int fromTag = source.y * 4 + source.x + 200;
        int toTag = target.y * 4 + target.x + 200;
        int finalTag = final.y * 4 + final.x + 100;
        UIView *fromTile = [weakView viewWithTag:fromTag];
        UIView *toTile = [weakView viewWithTag:toTag];
        UIView *newTile = [weakSelf getTileAt:finalTag Val:val];
        // change the tag to prevent the tile from being grabbed again
        fromTile.tag = -1;
        toTile.tag = -1;
        newTile.alpha = 0;
        [weakView addSubview:newTile];
        [UIView animateWithDuration:0.1 animations:^{
            fromTile.frame = newTile.frame;
            toTile.frame = newTile.frame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                fromTile.alpha = 0;
                toTile.alpha = 0;
                newTile.alpha = 1;
            } completion:^(BOOL finished) {
                [weakSelf removeActiveTile: fromTile];
                [weakSelf removeActiveTile: toTile];
                LDBUG(@"Merge (%.0f,%.0f) -> (%.0f,%.0f) = %d", source.x,source.y,target.x,target.y, val);
                if (completion != nil) {
                    completion();
                }
            }];
        }];
    }];
}

-(void) onMergeFrom:(CGPoint)source To:(CGPoint)target Final:(CGPoint)final Val:(int) val {
    [self animateMergeFrom:source To:target Final:final Val:val];
}

-(void) animatePieceFrom:(CGPoint)source To:(CGPoint)target {
    __weak id weakView = self.view;
    [m_animationQueue addObject:^(void(^completion)(void)) {
        int fromTag = source.y * 4 + source.x + 200;
        int toTag = target.y * 4 + target.x + 100;
        UIView *fromTile = [weakView viewWithTag:fromTag];
        UIView *toLoc = [weakView viewWithTag:toTag];
        fromTile.tag = toTag + 100;
        [UIView animateWithDuration:0.1 animations:^{
            fromTile.frame = CGRectMake(toLoc.frame.origin.x, toLoc.frame.origin.y, toLoc.frame.size.width, toLoc.frame.size.height);
        } completion:^(BOOL finished) {
            LDBUG(@"Move (%.0f,%.0f) -> (%.0f,%.0f)", source.x,source.y,target.x,target.y);
            if (completion != nil) {
                completion();
            }
        }];
    }];
}

-(void) onMoveFrom:(CGPoint)source To:(CGPoint)target {
    [self animatePieceFrom:source To:target];
}

-(void) onNumberAdded:(CGPoint)location Val:(int) val {
    __weak id weakView = self.boardView;
    __weak id weakSelf = self;
    [m_animationQueue addObject:^(void(^completion)(void)) {
        int loc = location.y * 4 + location.x + 100;
        UILabel *tile = [weakSelf getTileAt:loc Val:val];
        [weakView addSubview:tile];
        tile.alpha = 0.75;
        tile.transform = CGAffineTransformMakeScale(0.01, 0.01);
        [UIView animateWithDuration:0.1 delay:0.25 options:0 animations:^{
            tile.alpha = 1.0;
            tile.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            LDBUG(@"%d placed at (%.0f,%.0f)", val, location.x, location.y);
            if (completion != nil) {
                completion();
            }
        }];
    }];
}

-(void) onGameOver {
    CGRect pos = m_gameOverLbl.frame;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        m_gameOverLbl.frame = CGRectMake(pos.origin.x, 0 - pos.size.height, pos.size.width, pos.size.height);
    } else {
        m_gameOverLbl.frame = CGRectMake(pos.origin.x, 960, pos.size.width, pos.size.height);
    }

    [UIView animateWithDuration:0.5 animations:^{
        m_hintLbl.alpha = 0.0;
        m_gameOverLbl.alpha = 1;
        m_gameOverLbl.hidden = NO;
        m_gameOverLbl.frame = pos;
        [self.view bringSubviewToFront:m_gameOverLbl];
    }];
}



-(void) onScoreUpdate:(int) score {
    LDBUG(@"score is now %d", score);
    
    m_scoreLbl.text = [NSString stringWithFormat:@"%d", score];
    if (m_highScore < score && !m_isInDemoMode) {
        m_highScore = score;
        m_highScoreLbl.text = [NSString stringWithFormat:@"%d", score];
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        [def setInteger:score forKey:@"highscore"];
        [def synchronize];
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
    
    if (m_completion != nil) {
        m_completion();
    }
}

-(void) onMoveComplete {
    // turn off the gesture recognizers while we animate, otherwise it gets confused and doesn't display the board correctly if someone swipes during an animation
    [self stopListeningToTouchEvents];
    
    for (int j = 0; j < [m_animationQueue count]; j++) {
        void(^animation)(void(^completion)(void)) = m_animationQueue[j];
        if (j == [m_animationQueue count] - 1) {
            animation(^() {
                [self startListeningToTouchEvents];
            });
        } else {
            animation(nil);
        }
    }
    
    if ([m_animationQueue count] == 0) {
        [self startListeningToTouchEvents];
    }
    
    [m_animationQueue removeAllObjects];
    [self showHint];
}

-(UILabel *) getTileAt:(int)pos Val:(int)val {
    UILabel *impl;
    
    // using a cache of inactive tiles speeds up animation times
    if (m_inactiveTiles.count > 0) {
        impl = [m_inactiveTiles lastObject];
        [m_inactiveTiles removeLastObject];
    }
    
    UIView *loc = [self.view viewWithTag:pos];
    CGRect newFrame = CGRectMake(loc.frame.origin.x, loc.frame.origin.y, loc.frame.size.width, loc.frame.size.height);

    if (impl == nil) {
        impl = [[UILabel alloc] initWithFrame:newFrame];
    } else {
        impl.frame = newFrame;
    }

    UILabel *template = (UILabel *)[self.view viewWithTag:1];
    impl.text = [NSString stringWithFormat:@"%d",val];
    impl.font = template.font;
    impl.textAlignment = template.textAlignment;
    impl.backgroundColor = m_tileColors[@(val)];
    impl.hidden = NO;
    impl.alpha = 1.0;
    impl.tag = pos + 100;
    [m_activeTiles addObject:impl];
    return impl;
}

-(void) startGame {
    m_board = [BLBoard new];
    m_board.listener = self;
    m_completion = nil;
    m_suggestionNum = 0;

    // zero out the score on the screen
    [self onScoreUpdate:0];
    
    m_gameOverLbl.hidden = YES;
    m_gameOverLbl.alpha=0.25;
    m_isInDemoMode = NO;
    [self drawBoard];
    [self showHint];
}

UIColor* rgba(int r, int g, int b, int a) {
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a];
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.layer.contents = [UIImage imageNamed:@"carbon-fiber"];
    self.view.layer.bounds = self.view.bounds;
    m_animationQueue = [NSMutableArray new];
    
    m_tileColors = @{
        @(1):rgba(255,255,255,1),
        @(2):rgba(163,232,163,1),
        @(4):rgba( 75,190, 75,1),
        @(8):rgba( 0x36, 0x98, 0x00,1),
        @(16):rgba(147,209,209,1),
        @(32):rgba( 56,143,143,1),
        @(64):rgba( 16,103,103,1),
        @(128):rgba(255,214,179,1),
        @(256):rgba(238,159, 94,1),
        @(512):rgba(210,126, 57,1),
        @(1024):rgba(255,179,179,1),
        @(2048):rgba(238, 94, 94,1),
        @(4096):rgba(210, 57, 57,1)
    };
    
    m_activeTiles = [NSMutableArray new];
    m_inactiveTiles = [NSMutableArray new];
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    m_highScore = [def integerForKey:@"highscore"];
    m_highScoreLbl.text = [NSString stringWithFormat:@"%ld", m_highScore];
    
    BLMultiDirectionalSwipeRecognizer *swipeRecognizer = [BLMultiDirectionalSwipeRecognizer new];

    [swipeRecognizer addTarget:^() { [self swipeDown]; } direction:DOWN];
    [swipeRecognizer addTarget:^() { [self swipeUp]; } direction:UP];
    [swipeRecognizer addTarget:^() { [self swipeLeft]; } direction:LEFT];
    [swipeRecognizer addTarget:^() { [self swipeRight]; } direction:RIGHT];
    [swipeRecognizer addTarget:^() { [self swipeDiagonal:@[@(DOWN|LEFT), @(NONE)]]; } direction:DOWN|LEFT];
    [swipeRecognizer addTarget:^() { [self swipeDiagonal:@[@(DOWN|RIGHT), @(NONE)]]; } direction:DOWN|RIGHT];
    [swipeRecognizer addTarget:^() { [self swipeDiagonal:@[@(UP|LEFT), @(NONE)]]; } direction:UP|LEFT];
    [swipeRecognizer addTarget:^() { [self swipeDiagonal:@[@(UP|RIGHT),@(NONE)]]; } direction:UP|RIGHT];
    
    [self.view addGestureRecognizer:swipeRecognizer];
    
    [self applyMask:m_logoBtn];
    [self startGame];
}

-(void) swipeDiagonal:(NSArray *)directions {
    __weak BLViewController *wself = self;
    BLDirection dir = [directions[0] intValue];
    __block BLDirection lastDir = [directions[1] intValue];
    
    if (!m_board.isGameOver) {
        BLDirection currDir = dir & ~lastDir;
        __block BOOL peiceMoved = NO;
        m_completion = ^() {
            if (peiceMoved) {
                [wself performSelectorOnMainThread:@selector(swipeDiagonal:) withObject:@[@(dir),@(lastDir)] waitUntilDone:NO];
            }
        };

        while (!peiceMoved) {
            if (!peiceMoved && (currDir & LEFT) == LEFT) {
                peiceMoved |= [m_board shiftLeft];
                if (peiceMoved) {
                    lastDir = LEFT;
                }
            }
            
            if (!peiceMoved && (currDir & RIGHT) == RIGHT) {
                peiceMoved |= [m_board shiftRight];
                if (peiceMoved) {
                    lastDir = RIGHT;
                }
            }
            
            if (!peiceMoved && (currDir & UP) == UP) {
                peiceMoved |= [m_board shiftUp];
                if (peiceMoved) {
                    lastDir = UP;
                }
            }
            
            if (!peiceMoved && (currDir & DOWN) == DOWN) {
                peiceMoved |= [m_board shiftDown];
                if (peiceMoved) {
                    lastDir = DOWN;
                }
            }
            
            if (!peiceMoved && currDir == dir) {
                break;
            } else {
                currDir = dir;
            }
        }
    } else {
        m_completion = nil;
    }
}

-(void) applyMask:(UIView *)view {
    CALayer *mask = [CALayer layer];
    UIImage *maskImage = [UIImage imageNamed:@"mask"];
    mask.frame = view.bounds;
    [mask setContents:(id)[maskImage CGImage]];
    [view.layer setMask:mask];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void) drawBoard {
    // clear the board
    while (m_activeTiles.count > 0) {
        [self removeActiveTile:[m_activeTiles firstObject]];
    }
    
    // draw the board
    NSArray *rows = [m_board rows];
    int pos = 100;
    for (NSArray *row in rows) {
        for (NSNumber *elem in row) {
            int val = elem.intValue;
            if (val != 0) {
                UILabel *impl = [self getTileAt:pos Val:val];
                [self.boardView addSubview:impl];
            }
            pos++;
        }
    }
}

-(IBAction)undo:(id)sender {
    if (m_board.isGameOver) {
        return;
    }
    
    [m_board undo];
    [self drawBoard];
}

-(void)swipeUp {
    if (m_board.isGameOver) {
        return;
    }
    
    [m_board shiftUp];
}

-(void)swipeDown {
    if (m_board.isGameOver) {
        return;
    }
    
    [m_board shiftDown];
}

-(void)swipeLeft {
    if (m_board.isGameOver) {
        return;
    }
    
    [m_board shiftLeft];
}

-(void)swipeRight {
    if (m_board.isGameOver) {
        return;
    }
    
    [m_board shiftRight];
}

-(IBAction)restart:(id)sender {
    [self startGame];
}

-(void) showHint {
    NSArray *suggestions = @[@"Swipe left, right, up, or down to move peices.", @"Swipe to combine identical tiles to get points.", @"Swipe diagonally to have the computer repeatedly push tiles in those two directions", @"When all squares are filled, the game is over.", @"Tap the left arrow to undo a move.", @"Tap the circular arrow to restart the game.", @"Tap on the 2^N icon to see a demo of the game."];
    
    if (m_hintLbl.alpha > 0.0) {
        if (m_suggestionNum < [suggestions count]) {
            NSString *suggestion = suggestions[m_suggestionNum++];
            [UIView animateWithDuration:0.125 animations:^{
                m_hintLbl.alpha = 0.0;
            } completion:^(BOOL finished) {
                m_hintLbl.text = suggestion;
                [UIView animateWithDuration:0.125 animations:^{
                    m_hintLbl.alpha = 1.0;
                }];
            }];
        } else {
            m_hintLbl.alpha = 0.0;
        }
    }
}

-(IBAction)playForMe:(id)sender {
    m_isInDemoMode = YES;
    NSString *move = [m_board suggestMove];

    __weak BLViewController *wself = self;
    m_completion = ^() {
        [wself performSelectorOnMainThread:@selector(playForMe:) withObject:sender waitUntilDone:NO];
    };
    
    if (!m_board.isGameOver) {
        if ([move isEqualToString:@"up"]) {
            [self swipeUp];
        } else if ([move isEqualToString:@"down"]) {
            [self swipeDown];
        } else if ([move isEqualToString:@"left"]) {
            [self swipeLeft];
        } else if ([move isEqualToString:@"right"]) {
            [self swipeRight];
        }
    } else {
        m_completion = nil;
    }
}


@end
