//
//  BLGameDAO.h
//  TwoSuperN
//
//  Created by Ben La Monica on 6/23/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BLBoard;

@interface BLGameDAO : NSObject

-(BLBoard *) loadGame;
-(void) saveGame:(BLBoard *)board;
-(void) deleteGame;
-(void) saveHighScore;

@end
