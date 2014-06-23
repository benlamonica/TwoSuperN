//
//  BLGameDAO.m
//  TwoSuperN
//
//  Created by Ben La Monica on 6/23/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import "BLGameDAO.h"
#import "BLBoard.h"

@implementation BLGameDAO

-(NSURL *) getStateFile {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *dir = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
    [fm createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSURL *file = [NSURL URLWithString:@"TwoSuperN-GameState.json" relativeToURL:dir];
    return file;
}

-(BLBoard *) loadGame {
    BLBoard *board = [BLBoard new];
    NSURL *file = [self getStateFile];
    NSString *data = [NSString stringWithContentsOfURL:file encoding:NSUTF8StringEncoding error:nil];
    
    if (data != nil) {
        NSError *error;
        id hydrated = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        if ([[hydrated class] isSubclassOfClass:[NSDictionary class]]) {
            board.score = [hydrated[@"score"] intValue];
            [board setArray:hydrated[@"board"]];
        }
    }
    
    return board;
}

-(void) saveGame:(BLBoard *)board {
    NSURL *file = [self getStateFile];
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"board":[board asArray],@"score":@(board.score)} options:0 error:nil];
    [data writeToURL:file atomically:YES];
}

-(void) deleteGame {
    NSURL *file = [self getStateFile];
    [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
}

@end
