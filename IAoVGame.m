#import <Foundation/Foundation.h>
#import "IAoVGame.h"
#import "GameDatabase.h"
#import "ACMData.h"

@implementation GameResource
@synthesize loc = _loc;
@synthesize off = _off;
@synthesize len = _len;
@synthesize type = _type;
@synthesize subtype = _subtype;
@synthesize name = _name;
@synthesize string = _string;

-(id)initWithLocator:(uint32_t)loc offset:(uint32_t)off length:(uint32_t)len
     type:(uint16_t)type subtype:(uint16_t)subtype
{
  self = [super init];
  _loc = loc;
  _off = off;
  _len = len;
  _type = type;
  _subtype = subtype;
  return self;
}

-(NSString*)format
{
  NSString* fmt = @"";
  if (_type == 4)
  {
    char* fmtstr = (_subtype == ACMDataFormatOGG)? "OGG Vorbis" :
                    ((_subtype == ACMDataFormatWAV)? "WAV" : "ACM");
    fmt = [NSString stringWithCString:fmtstr encoding:NSUTF8StringEncoding];
  }
  return fmt;
}

-(void)setName:(NSString*)name
{
  [name retain];
  if (_name) [_name release];
  _name = name;
}

-(void)setString:(NSString*)string
{
  [string retain];
  if (_string) [_string release];
  _string = string;
}

@end

@implementation GameResourceCount
@synthesize biff = _biff;
@synthesize count = _count;
-(id)initWithBIFF:(BIFFData*)biff count:(NSNumber*)count
{
  self = [super init];
  if (!biff) NSLog(@"GameResourceCount initWithBIFF nil!");
  _biff = [biff retain];
  _count = [count retain];
  return self;
}

-(void)dealloc
{
  if (_biff) [_biff release];
  if (_count) [_count release];
  [super dealloc];
}
@end

@implementation GameLocalization
@synthesize url = _url;
@synthesize male = _maleTLK;
@synthesize female = _femaleTLK;
@synthesize language = _language;
@synthesize voices = _voices;
-(id)initWithURL:(NSURL*)url language:(NSString*)language
{
  NSError* err;
  NSFileManager* fm = [NSFileManager defaultManager];
  self = [super init];
  _url = [url retain];
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^dialog\\.tlk$"
                                                    options:NSRegularExpressionCaseInsensitive
                                                    error:&err];
  NSRegularExpression* fregex = [NSRegularExpression regularExpressionWithPattern:@"^dialogf\\.tlk$"
                                                     options:NSRegularExpressionCaseInsensitive
                                                     error:&err];
  _language = [language retain];
  NSArray<NSURL*>* tlks = [fm contentsOfDirectoryAtURL:_url
                              includingPropertiesForKeys:@[]
                              options:NSDirectoryEnumerationSkipsHiddenFiles |
                                      NSDirectoryEnumerationSkipsSubdirectoryDescendants |
                                      NSDirectoryEnumerationSkipsPackageDescendants
                              error:&err];
  for (NSURL* tlk in tlks)
  {
    NSString* filename = [tlk lastPathComponent];
    NSUInteger matches = [regex numberOfMatchesInString:filename options:0
                                range:NSMakeRange(0, filename.length)];
    if (matches > 0)
    {
      [tlk retain];
      if (_maleTLK) [_maleTLK release];
      _maleTLK = tlk;
      continue;
    }
    matches = [fregex numberOfMatchesInString:filename options:0
                      range:NSMakeRange(0, filename.length)];
    if (matches > 0)
    {
      [tlk retain];
      if (_femaleTLK) [_femaleTLK release];
      _femaleTLK = tlk;
    }
  }
  NSMutableArray* sounds = [[NSMutableArray alloc] init];
  NSURL* dir = [url URLByAppendingPathComponent:@"sounds"];
  NSArray<NSURL*>* files = [fm contentsOfDirectoryAtURL:dir
                               includingPropertiesForKeys:@[]
                               options:NSDirectoryEnumerationSkipsHiddenFiles
                               error:&err];
  for (NSURL* file in files)
  {
    if ([[file pathExtension] compare:@"wav"] == NSOrderedSame)
      [sounds addObject:file];
  }
  NSArray* sorted = [sounds sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
    NSString* first = [(NSURL*)a lastPathComponent];
    NSString* second = [(NSURL*)b lastPathComponent];
    return [first compare:second options:NSCaseInsensitiveSearch];}];
  _voices = [[NSArray alloc] initWithArray:sorted];
  [sounds release];
  return self;
}

-(void)dealloc
{
  if (_url) [_url release];
  if (_maleTLK) [_maleTLK release];
  if (_femaleTLK) [_femaleTLK release];
  if (_language) [_language release];
  if (_voices) [_voices release];
  [super dealloc];
}
@end


NSArray* gGameRegexes = nil;

@interface IAoVGame (Private)
-(BOOL)_findResourcesWithError:(NSError**)outError;
-(void)_findBIFFs;
-(void)_findMUSs;
-(void)_findLocalizations;
-(void)_setInitialLocalization;
-(BIFFData*)_BIFFNamed:(NSString*)name;
@end

@implementation IAoVGame
@synthesize url = _root;
@synthesize main = _main;
@synthesize app = _app;
@synthesize name = _name;
@synthesize icon = _icon;
@synthesize muss = _MUSs;
@synthesize biffs = _BIFFs;
@synthesize localizations = _localizations;
@synthesize localization = _localization;
@synthesize chitin = _chitin;
@synthesize tlk = _tlk;
@synthesize identifier = _identifier;
@synthesize db = _db;
+(void)initialize
{
  NSError* err = nil;
  NSMutableArray* regexes = [[NSMutableArray alloc] init];
  NSRegularExpression* regex;
  regex = [NSRegularExpression regularExpressionWithPattern:@"Baldur"
                               options:NSRegularExpressionCaseInsensitive
                               error:&err];
  [regexes addObject:regex];
  regex = [NSRegularExpression regularExpressionWithPattern:@"Baldur.*II"
                                options:NSRegularExpressionCaseInsensitive
                                error:&err];
  [regexes addObject:regex];
  regex = [NSRegularExpression regularExpressionWithPattern:@"Icewind"
                               options:NSRegularExpressionCaseInsensitive
                               error:&err];
  [regexes addObject:regex];
  regex = [NSRegularExpression regularExpressionWithPattern:@"Planescape"
                               options:NSRegularExpressionCaseInsensitive
                               error:&err];
  [regexes addObject:regex];
  gGameRegexes = [[NSArray alloc] initWithArray:regexes];
  [regexes release];
}

+(NSString*)descriptionForVoiceAtURL:(NSURL*)url
{
  NSString* desc = @"";
  NSString* file = [url lastPathComponent];
  NSRegularExpression* regex;
  NSError* err;
  regex = [NSRegularExpression regularExpressionWithPattern:@"\\d(.+?)\\.wav$"
                               options:NSRegularExpressionCaseInsensitive
                               error:&err];
  NSArray<NSTextCheckingResult*>* matches = [regex matchesInString:file
                                                   options:0
                                                   range:NSMakeRange(0, file.length)];
  if (matches.count)
  {
    NSTextCheckingResult* match = [matches objectAtIndex:0];
    if (match.numberOfRanges > 1)
    {
      NSString* m = [file substringWithRange:[match rangeAtIndex:1]];
      m = [m lowercaseString];
      desc = [[NSBundle mainBundle] localizedStringForKey:m value:@""
                                    table:@"voices"];
    }
  }
  return desc;
}

-(id)initWithURL:(NSURL*)url delegate:(id)delegate error:(NSError**)outError;
{
  self = [super init];
  _root = [url retain];
  _BIFFs = [[NSMutableArray alloc] init];
  BOOL ok = [self _findResourcesWithError:outError];
  if (!ok && outError && *outError)
  {
    [_root release];
    return nil;
  }
  [self _setInitialLocalization];
  GameDatabase* gdb = [[GameDatabase alloc] initWithGame:self delegate:delegate];
  _gdb = gdb;
  _db = gdb.db;
  for (NSInteger i = kLastGameIdentifier; i > kUnknownGameIdentifier; i--)
  {
    if ([[gGameRegexes objectAtIndex:i - 1] numberOfMatchesInString:_name options:0
                                        range:NSMakeRange(0, _name.length)])
    {
      _identifier = i;
      break;
    }
  }
  return self;
}

-(void)dealloc
{
  if (_root) [_root release];
  if (_MUSs) [_MUSs release];
  if (_BIFFs) [_BIFFs release];
  if (_trackTitles) [_trackTitles release];
  if (_properties) [_properties release];
  if (_gdb) [_gdb release];
  [super dealloc];
}

-(id)propertyForKey:(id)key
{
  return [_properties objectForKey:key];
}

-(void)setProperty:(id)property forKey:(id)key
{
  if (!_properties) _properties = [[NSMutableDictionary alloc] init];
  [_properties setObject:property forKey:key];
}

-(void)deleteDatabase
{
  if (_gdb)
  {
    [_gdb delete];
    [_gdb release];
    _gdb = nil;
  }
}

-(BOOL)isLoaded
{
  return _gdb.loaded;
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<Game> %@, %@", _name, _root];
}

// If url is an app:
//   Success if Contents/Resources/chitin.key exists
// Otherwise:
//  Success if chitin.key exists
-(BOOL)_findResourcesWithError:(NSError**)outError
{
  NSError* err = nil;
  NSURL* chitin = nil;
  NSURL* app = nil;
  if ([[_root pathExtension] compare:@"app"] == NSOrderedSame)
  {
    app = _root;
    chitin = [_root URLByAppendingPathComponent:@"Contents/Resources/chitin.key"];
    _isBeamdog = YES;
  }
  else
  {
    NSArray<NSURL*>* files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:_root
                                                             includingPropertiesForKeys:@[]
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    for (NSURL* file in files)
    {
      if ([[file pathExtension] compare:@"app"] == NSOrderedSame)
      {
        app = file;
        break;
      }
    }
    chitin = [_root URLByAppendingPathComponent:@"chitin.key"];
  }
  NSFileManager* fm = [NSFileManager defaultManager];
  if (![fm fileExistsAtPath:[chitin path]])
  {
    NSDictionary* userInfo = @{
      NSLocalizedDescriptionKey: NSLocalizedString(@"Not an Infinity Engine game.", nil),
      NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No chitin.key file found.", nil),
      NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"__LOCATION_HINT__", nil)
      };
    err = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                   code:-57 userInfo:userInfo]; // FIXME: revisit the error codes.
    if (outError) *outError = err;
  }
  if (app)
  {
    _app = [app retain];
    NSURL* plistURL = [app URLByAppendingPathComponent:@"Contents/Info.plist"];
    NSDictionary* plist = [[NSDictionary alloc] initWithContentsOfURL:plistURL];
    _name = [[NSString alloc] initWithString:[plist objectForKey:@"CFBundleName"]];
    if (_isBeamdog)
    {
      _main = [[_root URLByAppendingPathComponent:@"Contents/Resources"] retain];
    }
    else
    {
      _main = [_root copy];
    }
    NSString* icns = [plist objectForKey:@"CFBundleIconFile"];
    [plist release];
    if ([[icns pathExtension] caseInsensitiveCompare:@"icns"] != NSOrderedSame) icns = [NSString stringWithFormat:@"%@.icns", icns];
    NSString* icnsPath = [[NSString alloc] initWithFormat:@"Contents/Resources/%@", icns];
    NSURL* icnsURL = [app URLByAppendingPathComponent:icnsPath];
    [icnsPath release];
    _icon = [[NSImage alloc] initByReferencingURL:icnsURL];
    [self _findBIFFs];
    [self _findMUSs];
    [self _findLocalizations];
    [self _findTrackTitles];
    _chitin = [[KEYData alloc] initWithURL:chitin];
  }
  else
  {
    NSDictionary* userInfo = @{
      NSLocalizedDescriptionKey: NSLocalizedString(@"Not an Infinity Engine game.", nil),
      NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No game app found.", nil),
      NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"__LOCATION_HINT__", nil)
      };
    err = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                   code:-57 userInfo:userInfo]; // FIXME: revisit the error codes.
  }
  if (err && outError) *outError = err;
  return (nil == err);
}

-(void)_findBIFFs
{
  NSURL* data = [_main URLByAppendingPathComponent:@"data"];
  NSArray<NSURL*>* files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:data
                                                           includingPropertiesForKeys:@[]
                                                           options:NSDirectoryEnumerationSkipsHiddenFiles
                                                           error:nil];
  NSArray* sorted = [files sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
    NSString* first = [(NSURL*)a lastPathComponent];
    NSString* second = [(NSURL*)b lastPathComponent];
    return [first compare:second options:NSCaseInsensitiveSearch];}];
  NSMutableArray* tmp = [[NSMutableArray alloc] init];
  for (NSURL* url in sorted)
  {
    BIFFData* biff = [[BIFFData alloc] initWithURL:url];
    [tmp addObject:biff];
    [biff release];
  }
  [_BIFFs setArray:tmp];
  [tmp release];
}

-(void)_findMUSs
{
  NSURL* music = [_main URLByAppendingPathComponent:@"music"];
  NSArray<NSURL*>* files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:music
                                                           includingPropertiesForKeys:@[]
                                                           options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants
                                                           error:nil];
  NSMutableArray* tmp = [[NSMutableArray alloc] init];
  for (NSURL* file in files)
  {
    if (NSOrderedSame == [[file pathExtension] compare:@"mus" options:NSCaseInsensitiveSearch])
    {
      [tmp addObject:file];
    }
    else if (NSOrderedSame == [[file lastPathComponent] compare:@"songlist.txt"
                                                        options:NSCaseInsensitiveSearch])
    {
      _songlist = file;
    }
  }
  NSArray* sorted = [tmp sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
    NSString* first = [(NSURL*)a lastPathComponent];
    NSString* second = [(NSURL*)b lastPathComponent];
    return [first compare:second options:NSCaseInsensitiveSearch];}];
  [tmp release];
  _MUSs = [[NSArray alloc] initWithArray:sorted];
}

-(void)_findLocalizations
{
  NSError* err;
  NSFileManager* fm = [NSFileManager defaultManager];
  NSURL* langdir = [_main URLByAppendingPathComponent:@"lang"];
  NSArray<NSURL*>* dirs = [fm contentsOfDirectoryAtURL:langdir
                              includingPropertiesForKeys:@[]
                              options:NSDirectoryEnumerationSkipsHiddenFiles |
                                      NSDirectoryEnumerationSkipsSubdirectoryDescendants |
                                      NSDirectoryEnumerationSkipsPackageDescendants
                              error:nil];
  NSRegularExpression* bregex = [NSRegularExpression regularExpressionWithPattern:@"\\.bif$"
                                 options:NSRegularExpressionCaseInsensitive
                                 error:&err];
  NSMutableArray<GameLocalization*>* tmp = [[NSMutableArray alloc] init];
  for (NSURL* dir in dirs)
  {
    NSString* lang = [dir lastPathComponent];
    GameLocalization* loc = [[GameLocalization alloc] initWithURL:dir language:lang];
    [tmp addObject:loc];
    [loc release];
    // Add auxiliary BIFFs from locdir/data
    NSURL* datadir = [dir URLByAppendingPathComponent:@"data"];
    if ([fm fileExistsAtPath:[datadir path]])
    {
      NSArray<NSURL*>* biffs = [fm contentsOfDirectoryAtURL:datadir
                                   includingPropertiesForKeys:@[]
                                   options:NSDirectoryEnumerationSkipsHiddenFiles |
                                           NSDirectoryEnumerationSkipsSubdirectoryDescendants |
                                           NSDirectoryEnumerationSkipsPackageDescendants
                                   error:nil];
      for (NSURL* biff in biffs)
      {
        NSString* biffname = [biff lastPathComponent];
        NSUInteger matches = [bregex numberOfMatchesInString:biffname options:0
                                     range:NSMakeRange(0, biffname.length)];
        if (matches)
        {
          BIFFData* bd = [[BIFFData alloc] initWithURL:biff];
          [_BIFFs addObject:bd];
          [bd release];
        }
      }
    }
  }
  NSArray* sorted = [tmp sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
    NSString* first = [((GameLocalization*)a).url lastPathComponent];
    NSString* second = [((GameLocalization*)b).url lastPathComponent];
    return [first compare:second options:NSCaseInsensitiveSearch];}];
  _localizations = [[NSArray alloc] initWithArray:sorted];
  [tmp release];
}

// PST:EE has a file music/songlist.txt with track titles in the following format:
// XXX.mus // NN Title
-(void)_findTrackTitles
{
  if (_songlist)
  {
    NSStringEncoding enc = NSUTF8StringEncoding;
    NSString* songlist = [[NSString alloc] initWithContentsOfURL:_songlist
                                           usedEncoding:&enc error:nil];
    NSString* pattern = @"[\r\n]+";
    NSMutableArray<NSString*>* lines = [[NSMutableArray alloc] init];
    NSError* err;
    NSRegularExpression* re = [NSRegularExpression regularExpressionWithPattern:pattern
                                                   options:0 error:&err];
    __block NSUInteger start = 0;
    NSMutableArray<NSString*>* keys = [[NSMutableArray alloc] init];
    NSMutableArray<NSString*>* vals = [[NSMutableArray alloc] init];
    [re enumerateMatchesInString:songlist options:0
        range:NSMakeRange(0, songlist.length)
        usingBlock:^(NSTextCheckingResult* _Nullable result, NSMatchingFlags flags, BOOL* _Nonnull stop)
        {
          NSRange separatorRange = result.range;
          NSRange componentRange = NSMakeRange(start, separatorRange.location - start);
          [lines addObject:[songlist substringWithRange:componentRange]];
          start = NSMaxRange(separatorRange);
        }];
    [lines addObject:[songlist substringFromIndex:start]];
    NSCharacterSet* wscs = [NSCharacterSet whitespaceCharacterSet];
    NSCharacterSet* ddcs = [NSCharacterSet decimalDigitCharacterSet];
    for (NSString* line in lines)
    {
      NSArray<NSString*>* components = [line componentsSeparatedByString:@"//"];
      NSString* title = [components[1].lowercaseString stringByTrimmingCharactersInSet:wscs];
      title = [title stringByTrimmingCharactersInSet:ddcs];
      title = [title stringByTrimmingCharactersInSet:wscs];
      [keys addObject:[components[0].lowercaseString stringByTrimmingCharactersInSet:wscs]];
      [vals addObject:[title capitalizedString]];
    }
    _trackTitles = [[NSDictionary alloc] initWithObjects:vals forKeys:keys];
    [lines release];
    [keys release];
    [vals release];
  }
}

-(void)_setInitialLocalization
{
  GameLocalization* localization = nil;
  for (NSString* code in [NSLocale preferredLanguages])
  {
    NSDictionary* languageDic = [NSLocale componentsFromLocaleIdentifier:code];
    //NSString* countryCode = [languageDic objectForKey:@"kCFLocaleCountryCodeKey"]; //==>countryCode = "US"
    NSString* languageCode = [languageDic objectForKey:@"kCFLocaleLanguageCodeKey"]; //==> languageCode = "en"
    //NSString* scriptCode = [languageDic objectForKey:@"kCFLocaleScriptCodeKey"]; //==> scriptCode = "en"
    //NSLog(@"Language: %@ (%@, %@, %@)", code, languageCode, countryCode, scriptCode);
    for (GameLocalization* loc in _localizations)
    {
      NSArray* comps = [loc.language componentsSeparatedByString:@"_"];
      if ([[comps objectAtIndex:0] compare:languageCode options:NSCaseInsensitiveSearch] == NSOrderedSame)
      {
        localization = loc;
        break;
      }
    }
    if (localization) break;
  }
  if (!localization) localization = _localizations.firstObject;
  [self setLocalization:localization female:NO];
}

-(BIFFData*)_BIFFNamed:(NSString*)name
{
  BIFFData* ret = nil;
  for (BIFFData* biff in _BIFFs)
  {
    if (NSOrderedSame == [biff.url.path compare:name options:0])
    {
      ret = biff;
      break;
    }
  }
  return ret;
}

-(void)setLocalization:(GameLocalization*)localization female:(BOOL)female
{
  [localization retain];
  [_localization release];
  _localization = localization;
  [_tlk release];
  NSURL* url = (female)? localization.female : localization.male;
  // Try to fall back on something that sort of makes sense.
  if (!url) url = localization.male;
  if (!url) url = localization.female;
  _tlk = [[TLKData alloc] initWithURL:url];
}

// Get the localized MUS title from the URL -> title property list.
-(NSString*)trackTitleForURL:(NSURL*)url
{
  NSString* trackTitle = @"";
  if (!_trackTitles)
  {
    if (_identifier != kUnknownGameIdentifier)
    {
      NSString* name = (_identifier == kBaldursGateGameIdentifier)? @"bg":
        ((_identifier == kBaldursGate2GameIdentifier)? @"bg2":@"iwd");
      NSString* path = [[NSBundle mainBundle] pathForResource:name
                                              ofType:@"strings"];
      _trackTitles = [[NSDictionary alloc] initWithContentsOfFile:path];
    }
  }
  if (_trackTitles)
  {
    trackTitle = [_trackTitles objectForKey:[[url lastPathComponent] lowercaseString]];
  }
  return trackTitle;
}

-(NSUInteger)countBIFFsWithResourceType:(int)type
{
  int count = 0;
  sqlite3_stmt* dbs;
  NSString* sqlString = [[NSString alloc] initWithFormat:@"SELECT COUNT(DISTINCT path) FROM resources WHERE type=%d", type];
  const char* sql = [sqlString UTF8String];
  int res = sqlite3_prepare_v2(_db, sql, strlen(sql) + 1, &dbs, NULL);
  if (res != SQLITE_OK) NSLog(@"Step failure at %d: %s", __LINE__, sqlite3_errmsg(_db));
  while ((res = sqlite3_step(dbs)) == SQLITE_ROW)
  {
    count = sqlite3_column_int(dbs, 0);
    //res = sqlite3_errcode(_db);
  }
  if (res != SQLITE_DONE)
  {
    NSLog(@"Step failure at %d: %s", __LINE__, sqlite3_errmsg(_db));
    count = 0;
  }
  sqlite3_finalize(dbs);
  [sqlString release];
  return count;
}

-(NSArray*)getBIFFsAndResourceCountsForType:(int)type
{
  NSMutableArray* array = [[NSMutableArray alloc] init];
  int count = 0;
  sqlite3_stmt* dbs;
  NSString* sqlString = [[NSString alloc] initWithFormat:@"SELECT path,COUNT(*) FROM resources WHERE type=%d GROUP BY path ORDER BY path", type];
  const char* sql = [sqlString UTF8String];
  int res = sqlite3_prepare_v2(_db, sql, strlen(sql) + 1, &dbs, NULL);
  if (res != SQLITE_OK) NSLog(@"Step failure at %d: %s", __LINE__, sqlite3_errmsg(_db));
  while ((res = sqlite3_step(dbs)) == SQLITE_ROW)
  {
    //int bytes = sqlite3_column_bytes(dbs);
    const unsigned char* file = sqlite3_column_text(dbs, 0);
    NSString* fileString = [[NSString alloc] initWithUTF8String:(const char*)file];
    count = sqlite3_column_int(dbs, 1);
    NSNumber* countNumber = [[NSNumber alloc] initWithUnsignedInt:count];
    BIFFData* biff = [self _BIFFNamed:fileString];
    [fileString release];
    GameResourceCount* grc = [[GameResourceCount alloc] initWithBIFF:biff count:countNumber];
    [array addObject:grc];
    [grc release];
  }
  if (res != SQLITE_DONE)
  {
    NSLog(@"Step failure at %d: %s", __LINE__, sqlite3_errmsg(_db));
  }
  sqlite3_finalize(dbs);
  [sqlString release];
  NSArray* ret = [NSArray arrayWithArray:array];
  [array release];
  return ret;
}

-(NSArray*)resourcesForBIFF:(NSURL*)url ofType:(int)type
{
  NSMutableArray* array = [[NSMutableArray alloc] init];
  sqlite3_stmt* dbs;
  NSString* sqlString = [[NSString alloc] initWithFormat:@"SELECT locator,offset,length,subtype FROM resources WHERE path='%@' AND type=%d ORDER BY locator", url.path, type];
  const char* sql = [sqlString UTF8String];
  int res = sqlite3_prepare_v2(_db, sql, strlen(sql) + 1, &dbs, NULL);
  if (res != SQLITE_OK) NSLog(@"Step failure at %d: %s", __LINE__, sqlite3_errmsg(_db));
  while ((res = sqlite3_step(dbs)) == SQLITE_ROW)
  {
    int loc = sqlite3_column_int(dbs, 0);
    int off = sqlite3_column_int(dbs, 1);
    int len = sqlite3_column_int(dbs, 2);
    int subtype = sqlite3_column_int(dbs, 3);
    GameResource* resource = [[GameResource alloc] initWithLocator:loc offset:off length:len type:type subtype:subtype];
    NSString* resName = [_chitin resourceNameForPath:url.path index:loc & 0x3FFF];
    [resource setName:resName];
    NSString* str = @"";
    NSNumber* idx = [_tlk indexOfResName:resName];
    if (idx)
    {
      str = [_tlk stringAtIndex:[idx unsignedIntValue]];
    }
    [resource setString:str];
    [array addObject:resource];
    [resource release];
  }
  if (res != SQLITE_DONE)
  {
    NSLog(@"Step failure at %d: %s", __LINE__, sqlite3_errmsg(_db));
  }
  sqlite3_finalize(dbs);
  [sqlString release];
  NSArray* ret = [NSArray arrayWithArray:array];
  [array release];
  return ret;
}
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
