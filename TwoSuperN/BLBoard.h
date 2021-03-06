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
-(void) onMergeFrom:(CGPoint)source To:(CGPoint)target Final:(CGPoint)final Val:(int) val;
-(void) onMoveFrom:(CGPoint)source To:(CGPoint)target;
-(void) onMoveComplete;
-(void) onNumberAdded:(CGPoint)location Val:(int) val;
-(void) onScoreUpdate:(int) score;
-(void) onGameOver;
@end

#define BOARD_WIDTH 4
#define MAX_UNDO 255

typedef struct {
    int board[BOARD_WIDTH][BOARD_WIDTH];
    int score;
} UndoInfo;

@interface BLBoard : NSObject
{
    int m_board[BOARD_WIDTH][BOARD_WIDTH];
    int m_spacesFree;
    int m_score;
    BOOL m_isGameOver;
    BOOL m_isInDemoMode;
    UndoInfo m_undoBuffer[MAX_UNDO];
    int m_undoIdx;
    int m_undoBufferStart;
    id<BLBoardEventListener> m_listener;
}

-(NSArray *) columns;
-(NSArray *) rows;
-(NSArray *) asArray;
-(void) setColumn:(int)col withValues:(NSArray *)vals;
-(void) setRow:(int)y withValues:(NSArray *)vals;
-(void) setArray:(NSArray *)array;
-(BOOL) shiftUp;
-(BOOL) shiftDown;
-(BOOL) shiftRight;
-(BOOL) shiftLeft;

-(void) addDigit;
-(void) startOver;
-(void) undo;
-(NSString *) suggestMove;

@property (readwrite) int score;
@property (readonly) BOOL isGameOver;
@property BOOL isInDemoMode;
@property (nonatomic, readwrite) id<BLBoardEventListener> listener;
@end
