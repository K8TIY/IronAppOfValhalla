#import <Cocoa/Cocoa.h>
#import "BIFFData.h"
#import "KEYData.h"
#import "TLKData.h"
#import <sqlite3.h>

typedef enum : NSUInteger
{
  kUnknownGameIdentifier,
  kBaldursGateGameIdentifier,
  kBaldursGate2GameIdentifier,
  kIcewindDaleGameIdentifier,
  kPlanescapeTormentGameIdentifier,
  kLastGameIdentifier = kPlanescapeTormentGameIdentifier
} IAoVGameIdentifier;

@interface GameResourceCount : NSObject
{
  BIFFData* _biff;
  NSNumber* _count;
}
-(id)initWithBIFF:(BIFFData*)biff count:(NSNumber*)count;
@property(readonly) BIFFData* biff;
@property(readonly) NSNumber* count;
@end

@interface GameResource : NSObject
{
  uint32_t  _loc; // locator
  uint32_t  _off; // From BIFFData [_data bytes]
  uint32_t  _len;
  uint16_t  _type;
  uint16_t  _subtype; // Semantics depends on type. Currently used for ACM/OGG/WAV formats.
  NSString* _name; // Resource name
  NSString* _string;
}
@property (readonly) uint32_t loc;
@property (readonly) uint32_t off;
@property (readonly) uint32_t len;
@property (readonly) uint16_t type;
@property (readonly) uint16_t subtype;
@property (readonly) NSString* name;
@property (readonly) NSString* string;
-(id)initWithLocator:(uint32_t)loc offset:(uint32_t)off length:(uint32_t)len
     type:(uint16_t)type subtype:(uint16_t)subtype;
-(void)setName:(NSString*)name;
-(void)setString:(NSString*)string;
-(NSString*)format;
@end


@interface GameLocalization : NSObject
{
  NSURL*                   _url;
  NSURL*                   _maleTLK;
  NSURL*                   _femaleTLK;
  NSString*                _lang; // Language code
  NSArray<NSURL*>*         _voices; // lang/en_US/sounds/XXX.wav
}
-(id)initWithURL:(NSURL*)url language:(NSString*)language;
@property (readonly) NSURL* url;
@property (readonly) NSURL* male;
@property (readonly) NSURL* female;
@property (readonly) NSString* language;
@property (readonly) NSArray<NSURL*>* voices;
@end

@class GameDatabase;

@interface IAoVGame : NSObject
{
  NSURL*                      _root; // This is the game directory we need to bookmark.
  NSURL*                      _main; // The directory that contains data/ and music/
  NSURL*                      _app;
  NSArray<NSURL*>*            _MUSs;
  NSURL*                      _songlist; // Helpful .txt file found in PST
  NSMutableArray<BIFFData*>*  _BIFFs;
  NSArray<GameLocalization*>* _localizations;
  GameLocalization*           _localization;
  NSDictionary*               _trackTitles;
  KEYData*                    _chitin;
  TLKData*                    _tlk;
  NSString*                   _name; // from plist CFBundleName
  NSImage*                    _icon; // from plist CFBundleIconFile
  BOOL                        _isBeamdog; // the app and chitin.key are in e.g. Beamdog Library/00782
  IAoVGameIdentifier          _identifier;
  GameDatabase*               _gdb;
  sqlite3*                    _db;
}
@property(readonly) NSURL* url;
@property(readonly) NSURL* main;
@property(readonly) NSURL* app;
@property(readonly) NSString* name;
@property(readonly) NSImage* icon;
@property(readonly) NSArray<NSURL*>* muss;
@property(readonly) NSArray<BIFFData*>* biffs;
@property(readonly) NSArray<GameLocalization*>* localizations;
@property(readonly) GameLocalization* localization;
@property(readonly) KEYData* chitin;
@property(readonly) TLKData* tlk;
@property(readonly) IAoVGameIdentifier identifier;
@property(readonly) sqlite3* db;

+(NSString*)descriptionForVoiceAtURL:(NSURL*)url;
-(id)initWithURL:(NSURL*)url delegate:(id)delegate error:(NSError**)outError;
-(void)deleteDatabase;
-(BOOL)isLoaded;
-(void)setLocalization:(GameLocalization*)localization female:(BOOL)female;
-(NSString*)trackTitleForURL:(NSURL*)url;
-(NSUInteger)countBIFFsWithResourceType:(int)type;
-(NSArray*)getBIFFsAndResourceCountsForType:(int)type;
-(NSArray*)resourcesForBIFF:(NSURL*)url ofType:(int)type;
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
