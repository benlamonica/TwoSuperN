//
//  BLBoard.m
//  KO4096
//
//  Created by Ben La Monica on 3/31/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import "BLBoard.h"

typedef enum {
    NOTHING = 0,
    MOVED = 1,
    MERGED = 2
} Result;

// Private Methods
@interface BLBoard ()
+(BOOL) move:(int[BOARD_WIDTH][BOARD_WIDTH])board x:(int)x y:(int)y x1:(int)x1 y1:(int)y1 listener:(id<BLBoardEventListener>)listener;
+(BOOL) merge:(int[BOARD_WIDTH][BOARD_WIDTH])board x:(int)x y:(int)y x1:(int)x1 y1:(int)y1 score:(int *)score listener:(id<BLBoardEventListener>)listener;

@end

@implementation BLBoard

@synthesize score = m_score, listener = m_listener, isGameOver = m_isGameOver, isInDemoMode = m_isInDemoMode;

int getInc(int x, int x1) {
    int xInc = (x1-x);
    if (xInc < 0) {
        xInc = -1;
    } else if (xInc > 0) {
        xInc = 1;
    }
    
    return xInc;
}

// -=-=-=-=-=-=-= Helper Functions -=-=-=-=-=-=-=-=-=-
+(BOOL) merge:(int[BOARD_WIDTH][BOARD_WIDTH])board x:(int)x y:(int)y x1:(int)x1 y1:(int)y1 score:(int *)score listener:(id<BLBoardEventListener>)listener {
    
    // range check
    if (x < 0 || x1 < 0 || y1 < 0 || y < 0 || x >= BOARD_WIDTH || x1 >= BOARD_WIDTH || y1 >= BOARD_WIDTH || y >= BOARD_WIDTH) {
        return NO;
    }
    
    int slide = 0;
    // if the peices match, merge them
    if (board[x][y] != 0 && board[x1][y1] == board[x][y] && board[x1][y1] < 4096) {
        board[x][y] = 0;

        // keep going in the same direction, if it needs to slide;
        int xInc = getInc(x,x1); int yInc = getInc(y,y1);
        int x2 = x1 + xInc; int y2 = y1 + yInc;
        
        if (x2 >= BOARD_WIDTH || x2 < 0 || y2 >= BOARD_WIDTH || y2 < 0) {
            // we have already exceeded the bounds, just use the x1,y1 values
            x2 = x1;
            y2 = y1;
        } else {
            // otherwise, find if we need to slide somewhere
            while (x2+xInc >= 0 && x2+xInc < BOARD_WIDTH-1 && y2+yInc >= 0 && y2+yInc < BOARD_WIDTH-1 && board[x2][y2] == 0 && board[x2+xInc][y2+yInc] == 0) {
                x2 += xInc;
                y2 += yInc;
            }
            
            // to handle the case where the tile you just hit begins to slide, count the number of 0's, and increment the destination by that amount
            int slideX = x2+xInc;
            int slideY = y2+yInc;
            while (slideX >= 0 && slideX < BOARD_WIDTH && slideY >= 0 && slideY < BOARD_WIDTH) {
                if (board[slideX][slideY] == 0) {
                    slide++;
                }
                slideX += xInc;
                slideY += yInc;
            }
            
        }
        
        if (x2 < 0 || x2 > BOARD_WIDTH-1 || board[x2][y2] != 0) {
            x2 = x1;
            y2 = y1;
        }

        if (y2 < 0 || y2 > BOARD_WIDTH-1 || board[x2][y2] != 0 ) {
            y2 = y1;
            x2 = x1;
        }

        board[x2][y2] = board[x1][y1]*2;
        if (x1 != x2 || y1 != y2) {
            board[x1][y1] = 0;
        }
        
        int val = board[x2][y2];
        *score += board[x2][y2];
        [listener onScoreUpdate:*score];

        if ((slide*xInc) != 0) {
            x2 += (slide*xInc);
        } else {
            y2 += (slide*yInc);
        }
        
        [listener onMergeFrom:CGPointMake(x,y) To:CGPointMake(x1,y1) Final:CGPointMake(x2,y2) Val:val];
        return YES;
    }
    
    return NO;
}

+(BOOL) move:(int[BOARD_WIDTH][BOARD_WIDTH])board x:(int)x y:(int)y x1:(int)x1 y1:(int)y1 listener:(id<BLBoardEventListener>)listener {
    
    // range check
    if (x < 0 || x1 < 0 || y1 < 0 || y < 0 || x >= BOARD_WIDTH || x1 >= BOARD_WIDTH || y1 >= BOARD_WIDTH || y >= BOARD_WIDTH) {
        return NO;
    }
    
    if (board[x][y] != 0) {
        board[x1][y1] = board[x][y];
        board[x][y] = 0;
        [listener onMoveFrom:CGPointMake(x,y) To:CGPointMake(x1,y1)];
        return YES;
    }
    
    return NO;
    
}

+(int) shiftDown:(int[BOARD_WIDTH][BOARD_WIDTH])board score:(int *)score listener:(id<BLBoardEventListener>)listener {
    int merged = 0;
    BOOL somethingHappened = NO;
    for (int x = 0; x < BOARD_WIDTH; x++) {
        // merge
        for (int y = (BOARD_WIDTH-1); y > 0; y--) {
            // find the first non-empty spot
            while (board[x][y] == 0 && y > 0) y--;

            // no non-empty spots, this column is empty, skip it
            if (y <= 0) continue;
            
            int y1 = y-1;
            // advance to find the next peice we are going to act on
            while (board[x][y1] == 0 && y1 >= 0) y1--;
            
            // if the peices match, merge them
            if ([BLBoard merge:board x:x y:y1 x1:x y1:y score:score listener:listener]) {
                somethingHappened = YES;
                merged++;
                // skip over the merged peice
                y = y1;
            }
        }
        
        // move
        for (int y = (BOARD_WIDTH-1); y > 0; y--) {
            // find the first empty spot
            while (board[x][y] != 0 && y > 0) y--;
            
            // no empty spots, this row/column is full
            if (y <= 0) break;
            
            // advance to find the next peice we are going to move
            int y1 = y-1;
            while (board[x][y1] == 0 && y1 > 0) y1--;
            
            if ([BLBoard move:board x:x y:y1 x1:x y1:y listener:listener]) {
                somethingHappened = YES;
            }
        }
    }
    
    if (somethingHappened) {
        return merged;
    } else {
        return -1;
    }
}

+(int) shiftUp:(int[BOARD_WIDTH][BOARD_WIDTH])board score:(int *)score listener:(id<BLBoardEventListener>)listener {
    int merged = 0;
    BOOL somethingHappened = NO;
    for (int x = 0; x < BOARD_WIDTH; x++) {
        // merge
        for (int y = 0; y < (BOARD_WIDTH-1); y++) {
            int y1 = y+1;
            // advance to find the next peice we are going to act on
            while (board[x][y1] == 0 && y1 < (BOARD_WIDTH-1)) y1++;
            
            // if the peices match, merge them
            if ([BLBoard merge:board x:x y:y1 x1:x y1:y score:score listener:listener]) {
                somethingHappened = YES;
                merged++;
                // skip over the merged peice
                y = y1;
            }
        }
        
        // move
        for (int y = 0; y < (BOARD_WIDTH-1); y++) {
            // find the first empty spot
            while (board[x][y] != 0 && y < BOARD_WIDTH) y++;
            
            // no empty spots, this row/column is full
            if (y == BOARD_WIDTH) break;
            
            // advance to find the next peice we are going to move
            int y1 = y+1;
            while (board[x][y1] == 0 && y1 < (BOARD_WIDTH-1)) y1++;
            
            if ([BLBoard move:board x:x y:y1 x1:x y1:y listener:listener]) {
                somethingHappened = YES;
            }
        }
    }
    
    if (somethingHappened) {
        return merged;
    } else {
        return -1;
    }
}

+(int) shiftRight:(int[BOARD_WIDTH][BOARD_WIDTH])board score:(int *)score listener:(id<BLBoardEventListener>)listener {
    int merged = 0;
    BOOL somethingHappened = NO;
    for (int y = 0; y < BOARD_WIDTH; y++) {
        // merge
        for (int x = (BOARD_WIDTH-1); x > 0; x--) {
            // find the first non-empty spot
            while (board[x][y] == 0 && x > 0) x--;
            
            // no non-empty spots, this column is empty, skip it
            if (x <= 0) continue;
            
            int x1 = x-1;
            // advance to find the next peice we are going to act on
            while (board[x1][y] == 0 && x1 > 0) x1--;
            
            // if the peices match, merge them
            if ([BLBoard merge:board x:x1 y:y x1:x y1:y score:score listener:listener]) {
                somethingHappened = YES;
                merged++;
                // skip over the merged peice
                x = x1;
            }
        }
        
        // move
        for (int x = (BOARD_WIDTH-1); x > 0; x--) {
            // find the first empty spot
            while (board[x][y] != 0 && x > 0) x--;
            
            // no empty spots, this row/column is full
            if (x <= 0) break;
            
            // advance to find the next peice we are going to move
            int x1 = x-1;
            while (board[x1][y] == 0 && x1 > 0) x1--;
            
            if ([BLBoard move:board x:x1 y:y x1:x y1:y listener:listener]) {
                somethingHappened = YES;
            }
        }
    }
    
    if (somethingHappened) {
        return merged;
    } else {
        return -1;
    }
}

+(int) shiftLeft:(int[BOARD_WIDTH][BOARD_WIDTH])board score:(int *)score listener:(id<BLBoardEventListener>)listener {
    int merged = 0;
    BOOL somethingHappened = NO;
    for (int y = 0; y < BOARD_WIDTH; y++) {
        // merge
        for (int x = 0; x < (BOARD_WIDTH-1); x++) {
            // find the first non-empty spot
            while (board[x][y] == 0 && x < (BOARD_WIDTH-1)) x++;

            // no non-empty spots, this column is empty, skip it
            if (x >= (BOARD_WIDTH-1)) continue;

            int x1 = x+1;
            // advance to find the next peice we are going to act on
            while (board[x1][y] == 0 && x1 < (BOARD_WIDTH-1)) x1++;
            
            // if the peices match, merge them
            if ([BLBoard merge:board x:x1 y:y x1:x y1:y score:score listener:listener]) {
                somethingHappened = YES;
                merged++;
                // skip over the merged peice
                x = x1-1;
            }
        }
        
        // move
        for (int x = 0; x < (BOARD_WIDTH-1); x++) {
            // find the first empty spot
            while (board[x][y] != 0 && x < BOARD_WIDTH) x++;
            
            // no empty spots, this row/column is full
            if (x == BOARD_WIDTH) break;
            
            // advance to find the next peice we are going to move
            int x1 = x+1;
            while (board[x1][y] == 0 && x1 < (BOARD_WIDTH-1)) x1++;
            
            if ([BLBoard move:board x:x1 y:y x1:x y1:y listener:listener]) {
                somethingHappened = YES;
            }
        }
    }
    
    if (somethingHappened) {
        return merged;
    } else {
        return -1;
    }
}

//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

-(id) init {
    self = [super init];
    if (self) {
        m_score = 0;
        m_undoIdx = 0;
        [self startOver];
        [self addDigit];
        [self addDigit];
    }
    
    return self;
}

-(BOOL) processTurn:(int)numMerged {
    BOOL boardChanged = NO;
    if (numMerged > -1) {
        boardChanged = YES;
        LDBUG(@"Num merged: %d", numMerged);
        m_spacesFree += numMerged;
        LDBUG(@"Spaces free: %d", m_spacesFree);
        [self addDigit];
    }
    [m_listener onMoveComplete];
    return boardChanged;
}

-(void) undo {
    LINFO(@"undoIdx %d undoBufferStart %d", m_undoIdx, m_undoBufferStart);
    if ((m_undoIdx - 1) >= m_undoBufferStart) {
        m_undoIdx--;
        memcpy(m_board, m_undoBuffer[m_undoIdx % MAX_UNDO].board, sizeof(m_board));
        m_score = m_undoBuffer[m_undoIdx % MAX_UNDO].score;
        [m_listener onScoreUpdate:m_score];
        m_spacesFree = 16;
        for(int i = 0; i < BOARD_WIDTH; i++) {
            for (int j = 0; j < BOARD_WIDTH; j++) {
                if (m_board[i][j] != 0) {
                    m_spacesFree--;
                }
            }
        }
    }
}

-(void) saveUndoPoint {
    // if the board we're saving is identical to the last one, don't bother saving.
    if (m_undoIdx > 0 && memcmp(m_undoBuffer[(m_undoIdx - 1) % MAX_UNDO].board, m_board, sizeof(m_board)) == 0) {
        return;
    }
    
    // if we are about to overwrite the current start of the undo buffer, then increment so that we don't end up going in circles
    if (m_undoIdx >= MAX_UNDO && m_undoIdx != m_undoBufferStart && m_undoIdx % MAX_UNDO == m_undoBufferStart % MAX_UNDO) {
        m_undoBufferStart++;
    }

    // copy the current board
    memcpy(m_undoBuffer[m_undoIdx % MAX_UNDO].board, m_board, sizeof(m_board));
    // and score
    m_undoBuffer[m_undoIdx % MAX_UNDO].score = m_score;
    
    m_undoIdx++;
}

-(BOOL) shiftUp {
    [self saveUndoPoint];
    return [self processTurn:[BLBoard shiftUp:m_board score:&m_score listener:m_listener]];
}

-(BOOL) shiftDown {
    [self saveUndoPoint];
    return [self processTurn:[BLBoard shiftDown:m_board score:&m_score listener:m_listener]];
}

-(BOOL) shiftRight {
    [self saveUndoPoint];
    return [self processTurn:[BLBoard shiftRight:m_board score:&m_score listener:m_listener]];
}

-(BOOL) shiftLeft {
    [self saveUndoPoint];
    return [self processTurn:[BLBoard shiftLeft:m_board score:&m_score listener:m_listener]];
}

-(BOOL) checkIfGameIsOver {
    int tempBoard[BOARD_WIDTH][BOARD_WIDTH];
    int score = 0;
    memcpy(tempBoard, m_board, sizeof(tempBoard));
    BOOL shifted = NO;
    // check to see if any of them would move should we try to go in any of these directions
    shifted |= [BLBoard shiftUp:tempBoard score:&score listener:nil] > -1;
    shifted |= [BLBoard shiftDown:tempBoard score:&score listener:nil] > -1;
    shifted |= [BLBoard shiftLeft:tempBoard score:&score listener:nil] > -1;
    shifted |= [BLBoard shiftRight:tempBoard score:&score listener:nil] > -1;

    m_isGameOver = !shifted;
    
    LINFO(@"Game is %@over", m_isGameOver ? @"" : @"NOT ");
    return !shifted;
}

CGPoint addDigit(int board[BOARD_WIDTH][BOARD_WIDTH]) {
    NSMutableArray *spaces = [NSMutableArray new];
    
    for (int x = 0; x < BOARD_WIDTH; x++) {
        for (int y = 0; y < BOARD_WIDTH; y++) {
            if (board[x][y] == 0) {
                [spaces addObject:@(x*BOARD_WIDTH+y)];
            }
        }
    }

    if (spaces.count > 0) {
        int pos = [spaces[arc4random_uniform((int) spaces.count)] intValue];
        int num = arc4random_uniform(100);
        
        int x = pos / BOARD_WIDTH;
        int y = pos % BOARD_WIDTH;
        if (num <= 75) {
            board[x][y] = 2048;
        } else {
            board[x][y] = 4096;
        }

        return CGPointMake(x,y);
    } else {
        return CGPointMake(-1,-1);
    }
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

-(void) setListener:(id<BLBoardEventListener>)listener {
    m_listener = listener;
    
    if (listener != nil) {
        // listener has changed, so notify them that the game is over if it is over
        if (m_isGameOver) {
            [listener onGameOver];
        }
    }
}

-(void) setColumn:(int)x withValues:(NSArray *)vals {
    for (int y = 0; y < [vals count]; y++) {
        int val = [vals[y] intValue];
        m_board[x][y] = val;
        if (val != 0) {
            m_spacesFree--;
        }
    }
}

-(void) setRow:(int)y withValues:(NSArray *)vals {
    for (int x = 0; x < [vals count]; x++) {
        int val = [vals[x] intValue];
        m_board[x][y] = val;
        if (val != 0) {
            m_spacesFree--;
        }
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

-(NSArray *) asArray {
    NSMutableArray *a = [NSMutableArray new];
    for (int i = 0; i < BOARD_WIDTH; i++) {
        for (int j = 0; j < BOARD_WIDTH; j++) {
            [a addObject:@(m_board[i][j])];
        }
    }
    
    return a;
}

-(void) setArray:(NSArray *)array {
    int arrCounter = 0;
    m_spacesFree = 16;
    for (int i = 0; i < BOARD_WIDTH; i++) {
        for (int j = 0; j < BOARD_WIDTH; j++) {
            m_board[i][j] = [array[arrCounter++] intValue];
            if (m_board[i][j] != 0) {
                m_spacesFree--;
            }
        }
    }
    
    m_isGameOver = [self checkIfGameIsOver];
}


-(NSString *) suggestMove {
    NSArray *currentHighScoreMove;
    int currentHighScore = -1;
    static NSString* MOVES[4] = {@"up",@"down",@"left",@"right"};

    @autoreleasepool {
        int lookahead = 4;
        int *counters = malloc(sizeof(int)*lookahead);
        for (int i = 0; i < lookahead; i++) {
            counters[i] = 0;
        }
        
        while (counters[lookahead - 1] < 4) {
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

            LDBUG(@"Trying: %@", moves);
            int score = 0;
            int numMerged = [self scoreMove:moves score:&score];
            if ((numMerged*5) + score > currentHighScore) {
                currentHighScore = score;
                currentHighScoreMove = moves;
            }
            
            if (!incremented) {
                counters[0]++;
                if (counters[0] > 3) break;
            }
        }
        free(counters);
        counters = NULL;
    }
    
    return currentHighScoreMove[0];
}

-(int) scoreMove:(NSArray *)directions score:(int *)score {
    int tempBoard[BOARD_WIDTH][BOARD_WIDTH];
    BOOL shifted = NO;
    int merged = 0;
    int counter = -1;
    
    memcpy(tempBoard, m_board, sizeof(tempBoard));
    for (NSString *dir in directions) {
        if ([dir isEqualToString:@"up"]) {
            merged = [BLBoard shiftUp:tempBoard score:score listener:nil];
        } else if ([dir isEqualToString:@"down"]) {
            merged = [BLBoard shiftDown:tempBoard score:score listener:nil];
        } else if ([dir isEqualToString:@"left"]) {
            merged = [BLBoard shiftLeft:tempBoard score:score listener:nil];
        } else if ([dir isEqualToString:@"right"]) {
            merged = [BLBoard shiftRight:tempBoard score:score listener:nil];
        }
        
        if (merged > -1) {
            shifted |= YES;
            CGPoint p = addDigit(tempBoard);
            tempBoard[(int)p.x][(int)p.y] = counter--; // this will cause this to be a place holder instead of a tile that can be merged, allowing us to shift to cause a merge later on
        } else if (!shifted) {
            return -1;
        }
    }
    
    return MAX(0,merged);
}


@end
