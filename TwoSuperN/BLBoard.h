//
//  BLBoard.h
//  KO4096
//
//  Created by Ben La Monica on 3/31/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLLogging.h"

@protocol BLBoardEventListener
-(void) onMergeFrom:(CGPoint)source To:(CGPoint)target Val:(int) val;
-(void) onMoveFrom:(CGPoint)source To:(CGPoint)target;
-(void) onChangesComplete;
-(void) onMoveComplete;
-(void) onNumberAdded:(CGPoint)location Val:(int) val;
-(void) onScoreUpdate:(int) score;
-(void) onGameOver;
@end

#define BOARD_WIDTH 4

@interface BLBoard : NSObject
{
    int m_board[BOARD_WIDTH][BOARD_WIDTH];
    int m_spacesFree;
    int m_score;
    BOOL m_isGameOver;
    id<BLBoardEventListener> m_listener;
}

typedef enum {
    MOVE_UP,
    MOVE_DOWN,
    MOVE_LEFT,
    MOVE_RIGHT
} MOVE;

-(NSArray *) columns;
-(NSArray *) rows;
-(void) setColumn:(int)col withValues:(NSArray *)vals;
-(void) shiftUp;
-(void) shiftDown;
-(void) shiftRight;
-(void) shiftLeft;
-(void) addDigit;
-(void) startOver;
-(NSString *) suggestAMove;

@property int score;
@property BOOL isGameOver;
@property id<BLBoardEventListener> listener;
@end
