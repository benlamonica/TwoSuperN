//
//  BLViewController.m
//  KO4096
//
//  Created by Ben La Monica on 3/31/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import "BLViewController.h"

@interface BLViewController ()
-(UILabel *) getTileAt:(int)pos Val:(int)val;
-(void) removeActiveTile:(UIView *)tile;
@end

@implementation BLViewController

@synthesize score=m_scoreLbl, highScore=m_highScoreLbl, arrow=m_arrow, gameOverLbl=m_gameOverLbl, suggestLbl=m_suggestLbl, suggestBtn=m_suggestBtn, demoBtn=m_demoBtn;


-(void) removeActiveTile:(UIView *)tile {
    [m_activeTiles removeObject:tile];
}

-(void) animateMergeFrom:(CGPoint)source To:(CGPoint)target Final:(CGPoint)final Val:(int)val {
    __weak id weakView = self.view;
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
                [fromTile removeFromSuperview];
                [toTile removeFromSuperview];
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
    __weak id weakView = self.view;
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
    [UIView animateWithDuration:0.5 animations:^{
        m_demoBtn.alpha = 0.0;
        m_gameOverLbl.alpha = 1.0;
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
}

-(UILabel *) getTileAt:(int)pos Val:(int)val {
    UIView *loc = [self.view viewWithTag:pos];
    CGRect newFrame = CGRectMake(loc.frame.origin.x, loc.frame.origin.y, loc.frame.size.width, loc.frame.size.height);
    UILabel *template = (UILabel *)[self.view viewWithTag:1];
    UILabel *impl = [[UILabel alloc] initWithFrame:newFrame];
    impl.text = [NSString stringWithFormat:@"%d",val];
    impl.font = template.font;
    impl.textAlignment = template.textAlignment;
    impl.backgroundColor = m_tileColors[@(val)];
    CALayer *mask = [CALayer layer];
    UIImage *maskImage = [UIImage imageNamed:@"mask"];
    mask.frame = impl.bounds;
    [mask setContents:(id)[maskImage CGImage]];
    [impl.layer setMask:mask];
    impl.hidden = NO;
    impl.tag = pos + 100;
    [m_activeTiles addObject:impl];
    return impl;
}

-(void) startGame {
    m_board = [BLBoard new];
    m_board.listener = self;
    m_completion = nil;

    // zero out the score on the screen
    [self onScoreUpdate:0];
    
    m_gameOverLbl.alpha = 0;
    m_demoBtn.alpha = 1.0;
    m_isInDemoMode = NO;
    [self drawBoard];
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
        @(8):rgba( 45,168, 45,1),
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
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    m_highScore = [def integerForKey:@"highscore"];
    m_highScoreLbl.text = [NSString stringWithFormat:@"%ld", m_highScore];
    
    [self startGame];
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

-(IBAction)undo:(id)sender {
    if (m_board.isGameOver) {
        return;
    }
    
    [m_board undo];
    [self drawBoard];
}

-(IBAction)swipeUp:(id)sender {
    if (m_board.isGameOver) {
        return;
    }
    
    [m_board shiftUp];
}

-(IBAction)swipeDown:(id)sender {
    if (m_board.isGameOver) {
        return;
    }
    
    [m_board shiftDown];
}

-(IBAction)swipeLeft:(id)sender {
    if (m_board.isGameOver) {
        return;
    }
    
    [m_board shiftLeft];
}

-(void)swipeRight:(id)sender {
    if (m_board.isGameOver) {
        return;
    }
    
    [m_board shiftRight];
}

-(IBAction)restart:(id)sender {
    [self startGame];
}

-(void) showSuggestion {
    static int suggestionNum = 0;
    NSArray *suggestions = @[@"Play again", @"Go do something else for a while", @"Floss", @"Never pet a stray dog", @"Get out of debt", @"Save for a rainy day", @"Take a walk", @"Read more", @"Buy flowers for your better half", @"Hug your kids", @"Never stand on a swivel chair", @"Never put a thumbtack where you might sit on it", @"Call your Mom", @"Read a book to a child"];
    
    if (suggestionNum >= [suggestions count]) {
        suggestionNum = 0;
    }
    
    NSString *suggestion = suggestions[suggestionNum++];
    m_suggestLbl.text = suggestion;
    m_suggestLbl.hidden = NO;
    m_suggestBtn.enabled = NO;
    
    [self.view bringSubviewToFront:m_suggestLbl];
    [UIView animateWithDuration:0.25 animations:^{
        m_suggestLbl.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 delay:2 options:0 animations:^{
            m_suggestLbl.alpha = 0;
        } completion:^(BOOL finished) {
            m_suggestBtn.enabled = YES;
        }];
    }];
}

-(IBAction)suggestMove:(id)sender {
    if (m_board.isGameOver) {
        [self showSuggestion];
        return;
    }
    NSString *move = [m_board suggestMove];
    UIImage *arrow = [UIImage imageNamed:move];
    [self.view bringSubviewToFront:m_arrow];
    
    [m_arrow setImage:arrow];
    m_arrow.alpha = 0.25;
    m_arrow.transform = CGAffineTransformMakeScale(0.75, 0.75);
    
    [UIView animateWithDuration:0.5 delay:0 options:0 animations:^{
        m_arrow.transform = CGAffineTransformIdentity;
        m_arrow.alpha = 0.75;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            m_arrow.alpha = 0;
        } completion:^(BOOL finished) {
        }];
    }];
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
            [self swipeUp:sender];
        } else if ([move isEqualToString:@"down"]) {
            [self swipeDown:sender];
        } else if ([move isEqualToString:@"left"]) {
            [self swipeLeft:sender];
        } else if ([move isEqualToString:@"right"]) {
            [self swipeRight:sender];
        }
    } else {
        m_completion = nil;
    }
}


@end
