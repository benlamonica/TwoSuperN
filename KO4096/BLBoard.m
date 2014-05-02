//
//  BLBoard.m
//  KO4096
//
//  Created by Ben La Monica on 3/31/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import "BLBoard.h"

// Private Methods
@interface BLBoard ()
-(void) shift:(int(^)(int[4][4], BOOL, BOOL(^)(int[4][4], CGPoint, CGPoint, int *, id<BLBoardEventListener>), int *score, id<BLBoardEventListener>))shiftAction;
@end

@implementation BLBoard

@synthesize score = m_score, listener = m_listener;

// -=-=-=-=-=-=-= Helper Functions -=-=-=-=-=-=-=-=-=-

BOOL (^consolidatePiece)(int[4][4], CGPoint, CGPoint, int *, id<BLBoardEventListener>) =
^(int board[4][4], CGPoint from, CGPoint to, int *score, id<BLBoardEventListener>listener) {
    int *source = &board[(int)from.x][(int)from.y];
    int *target = &board[(int)to.x][(int)to.y];
    if (*target != 0 && *target == *source) {
        // multiply the source by 2, that way we don't combine all the way down the line
        *source *= 2;
        *target *= 0;
        [listener onMergeFrom:to To:from Val:*source];
        *score += *source;
        [listener onScoreUpdate:*score];
        return YES;
    }
    return NO;
};

BOOL (^movePiece)(int[4][4], CGPoint, CGPoint, int *, id<BLBoardEventListener>) =
^(int board[4][4], CGPoint from, CGPoint to, int *score, id<BLBoardEventListener>listener) {
    int *source = &board[(int)from.x][(int)from.y];
    int *target = &board[(int)to.x][(int)to.y];
    
    if (*target == 0 && *source != 0) {
        *target = *source;
        *source = 0;
        [listener onMoveFrom:from To:to];
        return YES;
    }
    return NO;
};

int (^shiftUp)(int[4][4], BOOL, BOOL(^)(int[4][4], CGPoint, CGPoint, int *, id<BLBoardEventListener>), int *, id<BLBoardEventListener>) =
^(int board[4][4], BOOL onlyOnce, BOOL(^action)(int[4][4], CGPoint, CGPoint, int *, id<BLBoardEventListener>), int *score, id<BLBoardEventListener> listener) {
    int changed = 0;
    for (int x = 0; x < 4; x++) {
        for (int y = 1; y < 4; y++) {
            BOOL actionChanged = action(board, CGPointMake(x,y), CGPointMake(x,y-1), score, listener);
            if (actionChanged) {
                changed++;

                if (onlyOnce) {
                    break;
                }
                
                for (int y2 = y-1; y2 > 0 ; y2--) {
                    if (!action(board, CGPointMake(x,y2), CGPointMake(x,y2-1), score, listener)) {
                        break;
                    }
                    
                    changed++;
                }
            }
        }
    }
    
    return changed;
};

int (^shiftDown)(int[4][4], BOOL, BOOL(^)(int[4][4], CGPoint, CGPoint, int *, id<BLBoardEventListener>), int *, id<BLBoardEventListener>) =
^(int board[4][4], BOOL onlyOnce, BOOL(^action)(int[4][4], CGPoint, CGPoint, int *, id<BLBoardEventListener>), int *score, id<BLBoardEventListener> listener) {
    int changed = 0;
    for (int x = 0; x < 4; x++) {
        for (int y = 2; y >= 0; y--) {
            BOOL actionChanged = action(board, CGPointMake(x,y), CGPointMake(x,y+1), score, listener);
            if (actionChanged) {
                changed++;

                if (onlyOnce) {
                    break;
                }
                
                for (int y2 = y+1; y2 < 3; y2++) {
                    if (!action(board, CGPointMake(x,y2), CGPointMake(x,y2+1), score, listener)) {
                        break;
                    }
                    
                    changed++;
                }
            }
        }
    }
    
    return changed;
};

int (^shiftRight)(int[4][4], BOOL, BOOL(^)(int[4][4], CGPoint, CGPoint, int *, id<BLBoardEventListener>), int *, id<BLBoardEventListener>) =
^(int board[4][4], BOOL onlyOnce, BOOL(^action)(int[4][4], CGPoint, CGPoint, int *, id<BLBoardEventListener>), int *score, id<BLBoardEventListener> listener) {
    int changed = 0;
    for (int y = 0; y < 4; y++) {
        for (int x = 2; x >= 0; x--) {
            BOOL actionChanged = action(board, CGPointMake(x,y), CGPointMake(x+1,y), score, listener);
            if (actionChanged) {
                changed++;

                if (onlyOnce) {
                    break;
                }
                
                for (int x2 = x+1; x2 < 3 ; x2++) {
                    if(!action(board, CGPointMake(x2,y), CGPointMake(x2+1,y), score, listener)) {
                        // if we didn't do anything, no point in doing anything more
                        break;
                    }

                    changed++;
                }
            }
        }
    }
    
    return changed;
};

int (^shiftLeft)(int[4][4], BOOL, BOOL(^)(int[4][4], CGPoint, CGPoint, int *, id<BLBoardEventListener>), int *score, id<BLBoardEventListener>) =
^(int board[4][4], BOOL onlyOnce, BOOL(^action)(int[4][4], CGPoint, CGPoint, int *score, id<BLBoardEventListener>), int *score, id<BLBoardEventListener> listener) {
    int changed = 0;
    for (int y = 0; y < 4; y++) {
        for (int x = 1; x < 4; x++) {
            BOOL actionChanged = action(board, CGPointMake(x,y), CGPointMake(x-1,y), score, listener);
            if (actionChanged) {
                changed++;

                if (onlyOnce) {
                    break;
                }
                
                for (int x2 = x-1; x2 > 0 ; x2--) {
                    if(!action(board, CGPointMake(x2,y), CGPointMake(x2-1,y), score, listener)) {
                        // if we didn't do anything, no point in doing anything more
                        break;
                    }
                    
                    changed++;

                }
            }
        }
    }
    
    return changed;
};

//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

-(id) init {
    self = [super init];
    if (self) {
        m_score = 0;
        [self startOver];
        [self addDigit];
        [self addDigit];
    }
    
    return self;
}

-(void) shift:(int(^)(int[4][4], BOOL, BOOL(^)(int[4][4], CGPoint, CGPoint, int *, id<BLBoardEventListener>), int *score, id<BLBoardEventListener>))shiftAction {
    BOOL shifted = NO;
    int numMerged = 0;
    NSString *before = [self description];
    shifted |= shiftAction(m_board, NO, movePiece, &m_score, m_listener) != 0;
    [m_listener onChangesComplete];
    shifted |= (numMerged = shiftAction(m_board, YES, consolidatePiece, &m_score, m_listener)) != 0;
    [m_listener onChangesComplete];
    shifted |= shiftAction(m_board, NO, movePiece, &m_score, m_listener) != 0;
    [m_listener onChangesComplete];
    
    NSLog(@"Num merged: %d", numMerged);
    m_spacesFree += numMerged;
    NSLog(@"Spaces free: %d", m_spacesFree);
    
    if (shifted) {
        [self addDigit];
    }
    
    NSLog(@"\nBefore: \n%@\nAfter: \n%@\n", before, [self description]);
    [m_listener onMoveComplete];
}

-(void) shiftUp {
    [self shift:shiftUp];
}

-(void) shiftDown {
    [self shift:shiftDown];
}

-(void) shiftRight {
    [self shift:shiftRight];
}

-(void) shiftLeft {
    [self shift:shiftLeft];
}

-(void) addDigit {
    BOOL digitPlaced = NO;
    int pos = arc4random_uniform(16);
    int num = arc4random_uniform(2);
    while (!digitPlaced && m_spacesFree > 0) {
        int x = pos / 4;
        int y = pos % 4;
        if (m_board[x][y] == 0) {
            if (num == 0) {
                m_board[x][y] = 2;
            } else {
                m_board[x][y] = 4;
            }

            [m_listener onNumberAdded:CGPointMake(x,y) Val:m_board[x][y]];
            digitPlaced = YES;
            m_spacesFree--;
        } else {
            pos++;
            if (pos > 15) {
                pos = 0;
            }
        }
    }
    
    NSLog(@"spacesFree: %d", m_spacesFree);

}

-(NSString *) description {
    return [NSString stringWithFormat:@"%4d %4d %4d %4d\n%4d %4d %4d %4d\n%4d %4d %4d %4d\n%4d %4d %4d %4d\n",
            m_board[0][0],m_board[1][0],m_board[2][0],m_board[3][0],
            m_board[0][1],m_board[1][1],m_board[2][1],m_board[3][1],
            m_board[0][2],m_board[1][2],m_board[2][2],m_board[3][2],
            m_board[0][3],m_board[1][3],m_board[2][3],m_board[3][3]];
}

-(void) startOver {
    for (int x = 0; x < 4; x++) {
        for (int y = 0; y < 4; y++) {
            m_board[x][y] = 0;
        }
    }
    
    m_spacesFree = 16;
}

-(void) setColumn:(int)x withValues:(NSArray *)vals {
    for (int y = 0; y < [vals count]; y++) {
        m_board[x][y] = [vals[y] intValue];
    }
}


-(NSArray *) rows {
    NSMutableArray *a = [NSMutableArray new];
    for (int i = 0; i < 4; i++) {
        [a addObject:@[@(m_board[0][i]), @(m_board[1][i]), @(m_board[2][i]), @(m_board[3][i])]];
    }
    
    return a;
}

-(NSArray *) columns {
    NSMutableArray *a = [NSMutableArray new];
    for (int i = 0; i < 4; i++) {
        [a addObject:@[@(m_board[i][0]), @(m_board[i][1]), @(m_board[i][2]), @(m_board[i][3])]];
    }
    
    return a;
}

@end
