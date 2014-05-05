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
    [board setColumn:2 withValues:@[@(0),@(4),@(2),@(2)]];
    [board shiftDown];
    NSArray *col = [board columns][2];
    XCTAssertEqualObjects(@(0), col[0]);
    XCTAssertEqualObjects(@(0), col[1]);
    XCTAssertEqualObjects(@(4), col[2]);
    XCTAssertEqualObjects(@(4), col[3]);
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

@end
