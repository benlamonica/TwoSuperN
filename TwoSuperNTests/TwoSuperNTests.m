//
//  KO4096Tests.m
//  KO4096Tests
//
//  Created by Ben La Monica on 3/31/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BLBoard.h"

@interface KO4096Tests : XCTestCase

@end

@implementation KO4096Tests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testShouldMergeDown
{
    BLBoard *board = [BLBoard new];
    [board startOver];
    [board setColumn:2 withValues:@[@(0),@(4),@(2),@(2)]];
    [board shiftDown];
    NSArray *col = [board columns][2];
    XCTAssertEqualObjects(@(4), col[2]);
    XCTAssertEqualObjects(@(4), col[3]);
}

- (void)testShouldMergeUp
{
    BLBoard *board = [BLBoard new];
    [board startOver];
    [board setColumn:2 withValues:@[@(0),@(4),@(2),@(2)]];
    [board shiftUp];
    NSArray *col = [board columns][2];
    XCTAssertEqualObjects(@(4), col[0]);
    XCTAssertEqualObjects(@(4), col[1]);
}

- (void)testShouldMergeLeft
{
    BLBoard *board = [BLBoard new];
    [board startOver];
    [board setRow:2 withValues:@[@(0),@(4),@(2),@(2)]];
    [board shiftLeft];
    NSArray *col = [board rows][2];
    XCTAssertEqualObjects(@(4), col[0]);
    XCTAssertEqualObjects(@(4), col[1]);
}

- (void)testShouldMergeRight
{
    BLBoard *board = [BLBoard new];
    [board startOver];
    [board setRow:2 withValues:@[@(0),@(4),@(2),@(2)]];
    [board shiftRight];
    NSArray *col = [board rows][2];
    XCTAssertEqualObjects(@(4), col[2]);
    XCTAssertEqualObjects(@(4), col[3]);
}

- (void)testShouldShiftRight
{
    BLBoard *board = [BLBoard new];
    [board startOver];
    [board setRow:0 withValues:@[@(8),@(2),@(0),@(0)]];
    [board setRow:1 withValues:@[@(2),@(0),@(0),@(0)]];
    [board shiftRight];
    NSArray *col = [board columns][3];
    XCTAssertEqualObjects(@(2), col[0]);
    XCTAssertEqualObjects(@(2), col[1]);
    
    col = [board columns][2];
    XCTAssertEqualObjects(@(8), col[0]);

}

- (void)testShouldMoveAndMergeUp
{
    BLBoard *board = [BLBoard new];
    [board startOver];
    [board setColumn:3 withValues:@[@(0),@(8),@(8),@(2)]];
    [board shiftUp];
    NSArray *col = [board columns][3];
    XCTAssertEqualObjects(@(16), col[0]);
    XCTAssertEqualObjects(@(2), col[1]);
    
}

- (void)testShouldPreferTheFurthestNumberToMergeInTheDirectionOfTheSwipe
{
    BLBoard *board = [BLBoard new];
    [board setColumn:0 withValues:@[@(4),@(4),@(4),@(2)]];
    [board shiftUp];
    NSArray *col = [board columns][0];
    XCTAssertEqualObjects(@(8), col[0]);
    XCTAssertEqualObjects(@(4), col[1]);
    XCTAssertEqualObjects(@(2), col[2]);
    
    board = [BLBoard new];
    [board setColumn:0 withValues:@[@(4),@(4),@(4),@(2)]];
    [board shiftDown];
    col = [board columns][0];
    XCTAssertEqualObjects(@(4), col[1]);
    XCTAssertEqualObjects(@(8), col[2]);
    XCTAssertEqualObjects(@(2), col[3]);
    
    board = [BLBoard new];
    [board setRow:0 withValues:@[@(4),@(4),@(4),@(2)]];
    [board shiftLeft];
    col = [board rows][0];
    XCTAssertEqualObjects(@(8), col[0]);
    XCTAssertEqualObjects(@(4), col[1]);
    XCTAssertEqualObjects(@(2), col[2]);

    board = [BLBoard new];
    [board setRow:0 withValues:@[@(4),@(4),@(4),@(2)]];
    [board shiftRight];
    col = [board rows][0];
    XCTAssertEqualObjects(@(4), col[1]);
    XCTAssertEqualObjects(@(8), col[2]);
    XCTAssertEqualObjects(@(2), col[3]);


}

- (void)testSuggestMoveShouldNotGetStuckIfAllButTheLastColumnAreFilled
{
    BLBoard *board = [BLBoard new];
    [board setColumn:0 withValues:@[@(4),@(256),@(128),@(16)]];
    [board setColumn:1 withValues:@[@(32),@(16),@(64),@(8)]];
    [board setColumn:2 withValues:@[@(2),@(8),@(16),@(2)]];
    [board setColumn:3 withValues:@[@(0),@(0),@(0),@(0)]];
    NSString *move = [board suggestAMove];
    XCTAssertEqualObjects(move, @"right", @"should have been something.");
}

- (void)testSuggestMoveShouldNotGetStuckIfAllButTheLastSpotAreFilled
{
    BLBoard *board = [BLBoard new];
    [board startOver];
    [board setColumn:0 withValues:@[@(4),@(32),@(2),@(0)]];
    [board setColumn:1 withValues:@[@(32),@(128),@(64),@(16)]];
    [board setColumn:2 withValues:@[@(2),@(32),@(16),@(8)]];
    [board setColumn:3 withValues:@[@(8),@(2),@(4),@(2)]];
    NSString *move = [board suggestAMove];
    XCTAssertEqualObjects(move, @"down", @"should have been something.");
}

- (void)testSuggestMoveShouldOptimizeToGroupLargerValues
{
    BLBoard *board = [BLBoard new];
    [board startOver];
    [board setColumn:0 withValues:@[@(4),@(32),@(2),@(0)]];
    [board setColumn:1 withValues:@[@(32),@(128),@(64),@(16)]];
    [board setColumn:2 withValues:@[@(2),@(32),@(16),@(8)]];
    [board setColumn:3 withValues:@[@(8),@(2),@(4),@(2)]];
    NSString *move = [board suggestAMove];
    XCTAssertEqualObjects(move, @"down", @"should have been something.");
}

- (void)testShouldCombineMultipleTilesPerRow
{
    BLBoard *board = [BLBoard new];
    [board startOver];
    [board setColumn:0 withValues:@[@(4),@(4),@(4),@(4)]];
    [board shiftDown];
    NSArray *col = [board columns][0];
    XCTAssertEqualObjects(@(8), col[2]);
    XCTAssertEqualObjects(@(8), col[3]);
}

- (void)testShouldCombineMultipleTilesPerRowButOnlyIfTheyAreTheSameValue
{
    BLBoard *board = [BLBoard new];
    [board setColumn:0 withValues:@[@(4),@(4),@(4),@(8)]];
    [board shiftDown];
    NSArray *col = [board columns][0];
    XCTAssertEqualObjects(@(4), col[1]);
    XCTAssertEqualObjects(@(8), col[2]);
    XCTAssertEqualObjects(@(8), col[3]);
}

@end
