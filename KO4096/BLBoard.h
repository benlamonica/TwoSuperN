//
//  BLBoard.h
//  KO4096
//
//  Created by Ben La Monica on 3/31/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BLBoardEventListener
-(void) onMergeFrom:(CGPoint)source To:(CGPoint)target Val:(int) val;
-(void) onMoveFrom:(CGPoint)source To:(CGPoint)target;
-(void) onChangesComplete;
-(void) onMoveComplete;
-(void) onNumberAdded:(CGPoint)location Val:(int) val;
-(void) onScoreUpdate:(int) score;
@end

@interface BLBoard : NSObject
{
    int m_board[4][4];
    int m_spacesFree;
    int m_score;
    id<BLBoardEventListener> m_listener;
}

-(NSArray *) columns;
-(NSArray *) rows;
-(void) setColumn:(int)col withValues:(NSArray *)vals;
-(void) shiftUp;
-(void) shiftDown;
-(void) shiftRight;
-(void) shiftLeft;
-(void) addDigit;
-(void) startOver;

@property int score;
@property id<BLBoardEventListener> listener;
@end
