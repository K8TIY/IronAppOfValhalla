#import <Cocoa/Cocoa.h>
#import "KEYData.h"

@interface TLKString : NSObject
{
  NSString* _snd;    // May be nil
  uint32_t  _offset; // To string data
  uint32_t  _length;
  //uint32_t  _vol;    // Volume variance
  //uint32_t  _pitch;  // Pitch variance
}
@property (readonly) NSString* snd;
@property (readonly) uint32_t offset;
@property (readonly) uint32_t length;
//@property (assign) uint32_t vol;
//@property (assign) uint32_t pitch;
-(id)initWithSoundName:(NSString*)name offset:(uint32_t)off length:(uint32_t)len;
@end

// An entry in a TLK file suitable for DB
typedef struct
{
  uint32_t  id;
  NSString* name;
  uint32_t  vol;
  uint32_t  pitch;
  uint16_t  flags;
  NSString* text;
} TLKResource;


@interface TLKData : NSObject
{
  NSMutableArray*      _strings;
  NSMutableDictionary* _resNames;
  uint32_t             _offset;  // To string data
  NSData*              _data;    // Release when done
}
-(id)initWithURL:(NSURL*)url;
-(void)enumerateUsingBlock:(void (^)(TLKResource* resource, BOOL* stop))block;
-(NSString*)stringAtIndex:(uint32_t)i;
-(NSNumber*)indexOfResName:(NSString*)name;
@property (readonly) NSArray* strings;
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
