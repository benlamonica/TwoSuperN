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
typedef BOOL (^Action)(int[BOARD_WIDTH][BOARD_WIDTH], CGPoint, CGPoint, int *, id<BLBoardEventListener>);
typedef int(^ShiftAction)(int[BOARD_WIDTH][BOARD_WIDTH], BOOL, Action, int *score, id<BLBoardEventListener>);
-(void) shift:(ShiftAction)shiftAction;
@end

@implementation BLBoard

@synthesize score = m_score, listener = m_listener, isGameOver = m_isGameOver;

// -=-=-=-=-=-=-= Helper Functions -=-=-=-=-=-=-=-=-=-

Action consolidatePiece =
^(int board[BOARD_WIDTH][BOARD_WIDTH], CGPoint from, CGPoint to, int *score, id<BLBoardEventListener>listener) {
    int *source = &board[(int)from.x][(int)from.y];
    int *target = &board[(int)to.x][(int)to.y];
    if (*target != 0 && *target == *source && *target < 4096) { // don't merge peices larger than 2048
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

Action movePiece =
^(int board[BOARD_WIDTH][BOARD_WIDTH], CGPoint from, CGPoint to, int *score, id<BLBoardEventListener>listener) {
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

ShiftAction shiftUp =
^(int board[BOARD_WIDTH][BOARD_WIDTH], BOOL onlyOnce, Action action, int *score, id<BLBoardEventListener> listener) {
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

ShiftAction shiftDown =
^(int board[BOARD_WIDTH][BOARD_WIDTH], BOOL onlyOnce, Action action, int *score, id<BLBoardEventListener> listener) {
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

ShiftAction shiftRight =
^(int board[BOARD_WIDTH][BOARD_WIDTH], BOOL onlyOnce, Action action, int *score, id<BLBoardEventListener> listener) {
    int changed = 0;
    for (int y = 0; y < BOARD_WIDTH; y++) {
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

ShiftAction shiftLeft =
^(int board[BOARD_WIDTH][BOARD_WIDTH], BOOL onlyOnce, Action action, int *score, id<BLBoardEventListener> listener) {
    int changed = 0;
    for (int y = 0; y < BOARD_WIDTH; y++) {
        for (int x = 1; x < BOARD_WIDTH; x++) {
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

+(int) performMove:(ShiftAction)action board:(int[BOARD_WIDTH][BOARD_WIDTH])board score:(int *)score listener:(id<BLBoardEventListener>)listener {
    BOOL shifted = NO;
    int numMerged = 0;
    shifted |= action(board, NO, movePiece, score, listener) != 0;
    [listener onChangesComplete];
    shifted |= (numMerged = action(board, YES, consolidatePiece, score, listener)) != 0;
    [listener onChangesComplete];
    shifted |= action(board, NO, movePiece, score, listener) != 0;
    [listener onChangesComplete];

    if (!shifted) {
        return -1;
    } else {
        return numMerged;
    }
}

-(void) shift:(ShiftAction)shiftAction {
    int numMerged = 0;
    NSString *before = nil;

    if (DBUG_ENABLED) {
        before = [self description];
    }

    numMerged = [BLBoard performMove:shiftAction board:m_board score:&m_score listener:m_listener];
    if (numMerged > -1) {
        LDBUG(@"Num merged: %d", numMerged);
        m_spacesFree += numMerged;
        LDBUG(@"Spaces free: %d", m_spacesFree);
        [self addDigit];
    }
    
    LDBUG(@"\nBefore: \n%@\nAfter: \n%@\n", before, [self description]);
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

-(BOOL) checkIfGameIsOver {
    int tempBoard[BOARD_WIDTH][BOARD_WIDTH];
    int score = 0;
    memcpy(tempBoard, m_board, sizeof(tempBoard));
    BOOL shifted = NO;
    // check to see if any of them would move should we try to go in any of these directions
    shifted |= shiftUp(tempBoard, NO, movePiece, &score, nil) != 0;
    shifted |= shiftUp(tempBoard, YES, consolidatePiece, &score, nil) != 0;
    shifted |= shiftDown(tempBoard, NO, movePiece, &score, nil) != 0;
    shifted |= shiftDown(tempBoard, YES, consolidatePiece, &score, nil) != 0;
    shifted |= shiftLeft(tempBoard, NO, movePiece, &score, nil) != 0;
    shifted |= shiftLeft(tempBoard, YES, consolidatePiece, &score, nil) != 0;
    shifted |= shiftRight(tempBoard, NO, movePiece, &score, nil) != 0;
    shifted |= shiftRight(tempBoard, YES, consolidatePiece, &score, nil) != 0;

    m_isGameOver = !shifted;
    
    return !shifted;
}

CGPoint addDigit(int board[BOARD_WIDTH][BOARD_WIDTH]) {
    int pos = arc4random_uniform(16);
    int num = arc4random_uniform(2);
    int timesAround = 0;
    while (timesAround < 2) {
        int x = pos / BOARD_WIDTH;
        int y = pos % BOARD_WIDTH;
        if (board[x][y] == 0) {
            if (num == 0) {
                board[x][y] = 2;
            } else {
                board[x][y] = 4;
            }
            
            return CGPointMake(x,y);
        } else {
            pos++;
            if (pos > 15) {
                pos = 0;
                timesAround++;
            }
        }
    }
    
    return CGPointMake(-1,-1);
}

-(void) addDigit {
    CGPoint addedAt = addDigit(m_board);
    [m_listener onNumberAdded:addedAt Val:m_board[(int)addedAt.x][(int)addedAt.y]];
    m_spacesFree--;
    LDBUG(@"spacesFree: %d", m_spacesFree);

    if (m_spacesFree == 0 && [self checkIfGameIsOver]) {
        [m_listener onGameOver];
    }
}

-(NSString *) description {
    return [NSString stringWithFormat:@"%4d %4d %4d %4d\n%4d %4d %4d %4d\n%4d %4d %4d %4d\n%4d %4d %4d %4d\n",
            m_board[0][0],m_board[1][0],m_board[2][0],m_board[3][0],
            m_board[0][1],m_board[1][1],m_board[2][1],m_board[3][1],
            m_board[0][2],m_board[1][2],m_board[2][2],m_board[3][2],
            m_board[0][3],m_board[1][3],m_board[2][3],m_board[3][3]];
}

-(void) startOver {
    m_isGameOver = NO;
    for (int x = 0; x < BOARD_WIDTH; x++) {
        for (int y = 0; y < BOARD_WIDTH; y++) {
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
    for (int i = 0; i < BOARD_WIDTH; i++) {
        [a addObject:@[@(m_board[0][i]), @(m_board[1][i]), @(m_board[2][i]), @(m_board[3][i])]];
    }
    
    return a;
}

-(NSArray *) columns {
    NSMutableArray *a = [NSMutableArray new];
    for (int i = 0; i < BOARD_WIDTH; i++) {
        [a addObject:@[@(m_board[i][0]), @(m_board[i][1]), @(m_board[i][2]), @(m_board[i][3])]];
    }
    
    return a;
}

-(NSString *) suggestAMove {
    NSArray *currentHighScoreMove;
    int currentHighScore = -1;
    static NSString* MOVES[4] = {@"up",@"down",@"left",@"right"};

    @autoreleasepool {
        int lookahead = 2;
        int *counters = malloc(sizeof(int)*lookahead);
        for (int i = 0; i < lookahead; i++) {
            counters[i] = 0;
        }
        
        while (counters[lookahead - 1] < 3) {
            NSMutableArray *moves = [NSMutableArray new];
            for (int i = 0; i < lookahead; i++) {
                [moves addObject:MOVES[counters[i]]];
            }
            
            BOOL incremented = NO;
            for (int i = 0; i < (lookahead - 1); i++) {
                if (counters[i] > counters[i+1]) {
                    counters[i+1]++;
                    incremented = YES;
                    break;
                }
            }
            if (!incremented) {
                counters[0]++;
            }
            
            int score = [self scoreAMove:moves];
            if (score > currentHighScore) {
                currentHighScore = score;
                currentHighScoreMove = moves;
            }
        }
        free(counters);
        counters = NULL;
    }
    
    return currentHighScoreMove[0];
}

-(int) scoreAMove:(NSArray *)directions {
    int tempBoard[BOARD_WIDTH][BOARD_WIDTH];
    int score = 0;
    ShiftAction direction;
    BOOL shifted = NO;
    
    
    memcpy(tempBoard, m_board, sizeof(tempBoard));
    for (NSString *dir in directions) {
        if ([dir isEqualToString:@"up"]) {
            direction = shiftUp;
        } else if ([dir isEqualToString:@"down"]) {
            direction = shiftDown;
        } else if ([dir isEqualToString:@"left"]) {
            direction = shiftLeft;
        } else if ([dir isEqualToString:@"right"]) {
            direction = shiftRight;
        }
        
        if ([BLBoard performMove:direction board:tempBoard score:&score listener:nil] > -1) {
            shifted |= YES;
            addDigit(tempBoard);
        }
    }
    
    if (!shifted) {
        return -1;
    } else {
        return score;
    }
}

@end
