#import "GameDatabase.h"
#import "IAoVGame.h"

@interface GameDatabase (Private)
-(void)_addGame;
-(void)_loadTask;
@end

static dispatch_queue_t gGameDatabaseDispatchQueue = NULL;

@implementation GameDatabase
@synthesize db = _db;
@synthesize loaded = _loaded;
@synthesize game = _game;
@synthesize progress = _progress;

static NSURL* local_applicationDataDirectory(void);

// Game databases live in /Users/<user>/Library/Containers/com.blugs.IronAppOfValhalla/Data/Library/Application Support/com.blugs.IronAppOfValhalla/
// Database name is path to ACMGame main URL with spaces and slashes removed.
+(NSString*)databaseNameForGame:(IAoVGame*)game
{
  NSError* err = nil;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[\\s/':]" options:NSRegularExpressionCaseInsensitive error:&err];
  NSString* base = [regex stringByReplacingMatchesInString:game.url.path options:0
                          range:NSMakeRange(0, game.url.path.length) withTemplate:@""];
  return [NSString stringWithFormat:@"%@.db", base];
}

-(id)initWithGame:(IAoVGame*)game delegate:(id<GameDatabaseProgress>)delegate
{
  self = [super init];
  _game = [game retain];
  _delegate = [delegate retain];
  _loaded = NO;
  [self _addGame];
  return self;
}

-(void)dealloc
{
  if (_game) [_game release];
  if (_url) [_url release];
  if (_delegate) [_delegate release];
  if (_db)
  {
    sqlite3_close(_db);
    _db = NULL;
  }
  [super dealloc];
}

-(void)delete
{
  NSFileManager* fm = [NSFileManager defaultManager];
  if (_db)
  {
    sqlite3_close(_db);
    _db = NULL;
  }
  [fm removeItemAtURL:_url error:nil];
}

-(void)_addGame
{
  NSFileManager* fm = [NSFileManager defaultManager];
  NSURL* url = local_applicationDataDirectory();
  NSString* name = [GameDatabase databaseNameForGame:_game];
  _url = [[url URLByAppendingPathComponent:name] retain];
  BOOL exists = [fm fileExistsAtPath:[_url path]];
  int res = sqlite3_open([[_url path] UTF8String], &_db);
  if (res != SQLITE_OK)
  {
    NSLog(@"Database error (%d) for %s", res, [[_url path] UTF8String]);
    // FIXME: report fatal error here.
  }
  // FIXME: add sanity checks for incompletely loaded DB.
  if (exists) _loaded = YES;
  else
  {
    if (NULL == gGameDatabaseDispatchQueue)
    {
      gGameDatabaseDispatchQueue = dispatch_queue_create("com.blugs.GameDatabaseDispatchQueue", NULL);
    }
    dispatch_async(gGameDatabaseDispatchQueue, ^{
      [self _loadTask];
    });
  }
}

-(void)_loadTask
{
  _progress.filesLoaded = 0;
  _progress.files = _game.biffs.count;
  const char* sql = "CREATE TABLE IF NOT EXISTS resources (path VARCHAR(1024) NOT NULL, locator INT NOT NULL, offset INT NOT NULL, length INT NOT NULL, type INT NOT NULL, subtype INT, resref VARCHAR(8))";
  sqlite3_stmt* dbs;
  int res = sqlite3_prepare_v2(_db, sql, strlen(sql) + 1, &dbs, NULL);
  if (res != SQLITE_OK) NSLog(@"Prepare failure at %d: %s", __LINE__, sqlite3_errmsg(_db));
  do { res = sqlite3_step(dbs); } while (res != SQLITE_DONE);
  sqlite3_finalize(dbs);
  sql = "CREATE TABLE IF NOT EXISTS strings (id INT NOT NULL, lang VARCHAR(6), resref VARCHAR(8), flags INT, vol INT, pitch INT, text TEXT)";
  res = sqlite3_prepare_v2(_db, sql, strlen(sql) + 1, &dbs, NULL);
  if (res != SQLITE_OK) NSLog(@"Prepare failure at %d: %s", __LINE__, sqlite3_errmsg(_db));
  do { res = sqlite3_step(dbs); } while (res != SQLITE_DONE);
  sqlite3_finalize(dbs);
  for (BIFFData* biff in _game.biffs)
  {
    //NSLog(@"LOADING BIFF %@", biff.url);
    if (_delegate && [_delegate respondsToSelector:@selector(gameDatabaseProgress:)])
    {
      [_delegate gameDatabaseProgress:self];
    }
    NSString* sqlString = [[NSString alloc] initWithFormat:@"SELECT COUNT(*) FROM resources WHERE path='%@'", biff.url.path];
    sql = [sqlString UTF8String];
    int count = 0;
    res = sqlite3_prepare_v2(_db, sql, strlen(sql) + 1, &dbs, NULL);
    if (res != SQLITE_OK) NSLog(@"Prepare failure at %d: %s", __LINE__, sqlite3_errmsg(_db));
    while ((res = sqlite3_step(dbs)) == SQLITE_ROW)
    {
      count = sqlite3_column_int(dbs, 0);
      //res = sqlite3_errcode(_db);
    }
    if (res != SQLITE_DONE) NSLog(@"Step failure at %d: %s", __LINE__, sqlite3_errmsg(_db));
    sqlite3_finalize(dbs);
    [sqlString release];
    if (count == 0)
    {
      [biff enumerateUsingBlock:^(BIFFResource* resource, BOOL* stop)
      {
        #pragma unused (stop)
        NSString* block_sqlString = [[NSString alloc] initWithFormat:@"INSERT INTO resources (path,locator,offset,length,type,subtype) VALUES ('%@',%d,%d,%d,%d,%d)",
                 biff.url.path, resource->loc, resource->off, resource->len, resource->type, resource->subtype];
        const char* block_sql = [block_sqlString UTF8String];
        sqlite3_stmt* block_dbs;
        int block_res = sqlite3_prepare_v2(_db, block_sql, strlen(block_sql) + 1, &block_dbs, NULL);
        if (block_res != SQLITE_OK) NSLog(@"Prepare failure at %d: %s", __LINE__, sqlite3_errmsg(_db));
        block_res = sqlite3_step(block_dbs);
        if (block_res != SQLITE_DONE) NSLog(@"Step failure at %d: %s", __LINE__, sqlite3_errmsg(_db));
        sqlite3_finalize(block_dbs);
        [block_sqlString release];
      }];
    }
    [biff unload];
    _progress.filesLoaded++;
  }
  if (_delegate && [_delegate respondsToSelector:@selector(gameDatabaseFinished:)])
  {
    [_delegate gameDatabaseFinished:self];
  }
  _loaded = YES;
}
@end

static NSURL* local_applicationDataDirectory(void)
{
  NSFileManager* fm = [NSFileManager defaultManager];
  NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
  NSArray* urlPaths = [fm URLsForDirectory:NSApplicationSupportDirectory
                          inDomains:NSUserDomainMask];
  NSURL* appDirectory = [urlPaths[0] URLByAppendingPathComponent:bundleID isDirectory:YES];
  //TODO: handle the error
  if (![fm fileExistsAtPath:[appDirectory path]])
    [fm createDirectoryAtURL:appDirectory withIntermediateDirectories:NO attributes:nil error:nil];
  //NSLog(@"%@", appDirectory);
  return appDirectory;
}

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
