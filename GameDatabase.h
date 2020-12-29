#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "IAoVGame.h"

typedef struct
{
  NSUInteger filesLoaded;
  NSUInteger files;
} GameDatabaseProgress;

@protocol GameDatabaseProgress <NSObject>
-(void)gameDatabaseProgress:(id)sender;
-(void)gameDatabaseFinished:(id)sender;
@end

// Handles creating and populating the game database,
// and communicating progress to the main app
@interface GameDatabase : NSObject
{
  IAoVGame*                _game;
  NSURL*                   _url;
  id<GameDatabaseProgress> _delegate;
  sqlite3*                 _db;
  BOOL                     _loaded;
  GameDatabaseProgress     _progress;
}
@property(readonly) IAoVGame* game;
@property(readonly) sqlite3* db;
@property(readonly) BOOL loaded;
@property(readonly) GameDatabaseProgress progress;
+(NSString*)databaseNameForGame:(IAoVGame*)game;
-(id)initWithGame:(IAoVGame*)game delegate:(id<GameDatabaseProgress>)delegate;
-(void)delete;
@end

/*
Copyright © 2010-2019, BLUGS.COM LLC

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
