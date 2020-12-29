#import "TLKData.h"

@implementation TLKString
@synthesize snd = _snd;
@synthesize offset = _offset;
@synthesize length = _length;
//@synthesize vol = _vol;
//@synthesize pitch = _pitch;

-(id)initWithSoundName:(NSString*)name offset:(uint32_t)off length:(uint32_t)len
{
  self = [super init];
  if (name) _snd = [name copy];
  _offset = off;
  _length = len;
  return self;
}

-(void)dealloc
{
  if (_snd) [_snd release];
  [super dealloc];
}
@end


@implementation TLKData
@synthesize strings = _strings;

-(id)initWithURL:(NSURL*)url
{
  self = [super init];
  _data = [[NSData alloc] initWithContentsOfURL:url];
  _strings = [[NSMutableArray alloc] init];
  _resNames = [[NSMutableDictionary alloc] init];
  unsigned char* buff = calloc(1, 12);
  const unsigned char* p = [_data bytes];
  memcpy(buff, p, 4);
  //NSLog(@"Signature: '%s'", buff);
  p += 4;
  memcpy(buff, p, 4);
  //NSLog(@"Version: '%s'", buff);
  p += 6;
  uint32_t n = EndianU32_LtoN(*(uint32_t*)p);
  p += 4;
  _offset = EndianU32_LtoN(*(uint32_t*)p);
  p += 4;
  //NSLog(@"There are %d strings at offset %d", n, _offset);
  uint32_t i;
  for (i = 0; i < n; i++)
  {
    //uint16_t flags = EndianU16_LtoN(*(uint16_t*)p);
    p += 2;
    bzero(buff, 12);
    (void)strncpy((char*)buff, (const char*)p, 8);
    p += 8;
    //uint32_t vol = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    //uint32_t pitch = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    uint32_t off = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    uint32_t len = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    NSString* str = nil;
    //if (strlen((char*)buff))
    {
      /*NSString* resName = [[NSString alloc] initWithCString:buff encoding:NSUTF8StringEncoding];
      NSString* resText = [[NSString alloc] initWithBytes:[_data bytes] + _offset + off length:len encoding:NSUTF8StringEncoding];
      printf("%d '%s' vol %d pitch %d flags 0x%X (%s)\n", i, [resName UTF8String], vol, pitch, flags, [resText UTF8String]);
      [resName release];
      [resText release];*/
      str = [[NSString alloc] initWithCString:(const char*)buff
                              encoding:NSUTF8StringEncoding];
      // FIXME: can use i instead of _strings.count?
      NSNumber* number = [NSNumber numberWithUnsignedInt:[_strings count]];
      TLKString* string = [[TLKString alloc] initWithSoundName:str
                                             offset:_offset + off
                                             length:len];
      @synchronized(self)
      {
        [_resNames setObject:number forKey:str];
        [_strings addObject:string];
      }
      if (str) [str release];
      [string release];
    }
  }
  free(buff);
  return self;
}

-(void)enumerateUsingBlock:(void (^)(TLKResource* resource, BOOL* stop))block
{
  unsigned char* buff = calloc(1, 12);
  const unsigned char* p = [_data bytes];
  p += 4;
  p += 6;
  uint32_t n = EndianU32_LtoN(*(uint32_t*)p);
  p += 4;
  _offset = EndianU32_LtoN(*(uint32_t*)p);
  p += 4;
  uint32_t i;
  TLKResource res;
  BOOL stop = NO;
  for (i = 0; i < n; i++)
  {
    res.id = i;
    res.flags = EndianU16_LtoN(*(uint16_t*)p);
    p += 2;
    bzero((void*)buff, 12);
    (void)strncpy((char*)buff, (const char*)p, 8);
    p += 8;
    res.vol = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    res.pitch = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    uint32_t off = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    uint32_t len = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    res.name = [[NSString alloc] initWithCString:(const char*)buff
                                 encoding:NSUTF8StringEncoding];
    res.text = [[NSString alloc] initWithBytes:[_data bytes] + _offset + off
                                 length:len encoding:NSUTF8StringEncoding];
    block(&res, &stop);
    [res.name release];
    [res.text release];
    if (stop) break;
  }
  free(buff);
}

-(void)dealloc
{
  if (_strings) [_strings release];
  if (_data) [_data release];
  if (_resNames) [_resNames release];
  [super dealloc];
}

-(NSString*)stringAtIndex:(uint32_t)i
{
  NSString* val = nil;
  @synchronized(self)
  {
    if (i >= [_strings count]) return nil;
    TLKString* str = [_strings objectAtIndex:i];
    val = [[NSString alloc] initWithBytes:[_data bytes] + str.offset
                            length:str.length
                            encoding:NSUTF8StringEncoding];
    [val autorelease];
  }
  return val;
}

-(NSNumber*)indexOfResName:(NSString*)name
{
  return [_resNames objectForKey:name];
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
