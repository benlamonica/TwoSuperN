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

- (void)testExample
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

@end
