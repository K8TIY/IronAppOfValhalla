#import "KEYData.h"

@interface KEYData (Private)
-(void)_setData;
@end

@implementation KEYData
-(id)initWithURL:(NSURL*)url
{
  self = [super init];
  _path = [[url path] copy];
  _biffs = [[NSMutableDictionary alloc] init];
  _data = [[NSData alloc] initWithContentsOfURL:url];
  [self _setData];
  return self;
}

-(void)dealloc
{
  if (_path) [_path release];
  if (_biffs) [_biffs release];
  if (_data) [_data release];
  [super dealloc];
}

/*
0x0000	4 (char array)	Signature ('KEY ')
0x0004	4 (char array)	Version ('V1 ')
0x0008	4 (dword)	Count of BIF entries
0x000c	4 (dword)	Count of resource entries
0x0010	4 (dword)	Offset (from start of file) to BIF entries
0x0014	4 (dword)	Offset (from start of file) to resource entries
*/

/*
0x0000	4 (dword)	Length of BIF file
0x0004	4 (dword)	Offset from start of file to ASCIIZ BIF filename
0x0008	2 (word)	Length, including terminating NUL, of ASCIIZ BIF filename
0x000a	2 (word)	The 16 bits of this field are used individually to mark the location of the relevant file.

(MSB) xxxx xxxx ABCD EFGH (LSB)
Bits marked A to F determine on which CD the file is stored (A = CD6, F = CD1)
Bit G determines if the file is in the \cache directory
Bit H determines if the file is in the \data directory
*/

/*
0x0000	8 (resref)	Resource name
0x0008	2 (word)	Resource type
0x000a	4 (dword)	Resource locator. The IE resource manager uses 32-bit values as a 'resource index', which codifies the source of the resource as well as which source it refers to. The layout of this value is below.

bits 31-20: source index (the ordinal value giving the index of the corresponding BIF entry)
bits 19-14: tileset index
bits 13- 0: non-tileset file index (any 12 bit value, so long as it matches the value used in the BIF file)
*/
-(void)_setData
{
  if (_data)
  {
    NSMutableArray* biffs = [[NSMutableArray alloc] init];
    NSString* here = [_path stringByDeletingLastPathComponent];
    char* buff = calloc(1, 12);
    const char* bytes = [_data bytes];
    memcpy(buff, bytes, 4);
    //NSLog(@"Signature: '%s'", buff);
    uint32_t nBIF = EndianU32_LtoN(*(uint32_t*)(bytes + 0x0008));
    uint32_t nRes = EndianU32_LtoN(*(uint32_t*)(bytes + 0x000C));
    uint32_t offBIF = EndianU16_LtoN(*(uint32_t*)(bytes + 0x0010));
    uint16_t offRes = EndianU16_LtoN(*(uint32_t*)(bytes + 0x0014));
    //NSLog(@"%d BIF, %d Res", nBIF, nRes);
    const char* p = bytes + offBIF;
    NSMutableString* loc = [[NSMutableString alloc] init];
    for (uint32_t i = 0; i < nBIF; i++)
    {
      [loc setString:@""];
      //uint32_t len = EndianU32_LtoN(*(uint32_t*)p);
      p += 4;
      uint32_t offName = EndianU32_LtoN(*(uint32_t*)p);
      p += 4;
      uint16_t lenName = EndianU16_LtoN(*(uint16_t*)p);
      p += 2;
      uint16_t bits = EndianU16_LtoN(*(uint16_t*)p);
      p += 2;
      NSString* fileName = [[NSString alloc] initWithBytes:bytes + offName length:lenName - 1 encoding:NSUTF8StringEncoding];
      if ((bits & 0x01) == 0x01)
      {
        [loc setString:[here stringByAppendingPathComponent:fileName]];
      }
      if ((bits & 0x02) == 0x02)
      {
        [loc setString:[here stringByAppendingPathComponent:@"cache"]];
        [loc setString:[loc stringByAppendingPathComponent:fileName]];
      }
      if (bits & 0x04)
      {
        [loc setString:[here stringByAppendingPathComponent:@"cd1"]];
        [loc setString:[loc stringByAppendingPathComponent:fileName]];
      }
      if (bits & 0x08)
      {
        [loc setString:[here stringByAppendingPathComponent:@"cd2"]];
        [loc setString:[loc stringByAppendingPathComponent:fileName]];
      }
      if (bits & 0x10)
      {
        [loc setString:[here stringByAppendingPathComponent:@"cd3"]];
        [loc setString:[loc stringByAppendingPathComponent:fileName]];
      }
      if (bits & 0x20)
      {
        [loc setString:[here stringByAppendingPathComponent:@"cd4"]];
        [loc setString:[loc stringByAppendingPathComponent:fileName]];
      }
      if (bits & 0x40)
      {
        [loc setString:[here stringByAppendingPathComponent:@"cd5"]];
        [loc setString:[loc stringByAppendingPathComponent:fileName]];
      }
      if (bits & 0x80)
      {
        [loc setString:[here stringByAppendingPathComponent:@"cd6"]];
        [loc setString:[loc stringByAppendingPathComponent:fileName]];
      }
      if (loc.length)
      {
        [biffs addObject:[loc lastPathComponent]];
      }
      [fileName release];
    }
    p = bytes + offRes;
    for (uint32_t i = 0; i < nRes; i++)
    {
      bzero(buff, 12);
      memcpy(buff, p, 8);
      p += 8;
      //uint16_t type = EndianU16_LtoN(*(uint16_t*)p);
      p += 2;
      uint32_t locator = EndianU32_LtoN(*(uint32_t*)p);
      p += 4;
      uint32_t idxBIF = (locator & 0xFFF00000) >> 20;
      //uint32_t idxTS = (locator & 0x000FC000) >> 13;
      uint32_t idxNonTS = locator & 0x3FFF;
      if (1)//(type == 4)
      {
        // Lowercase for DESound.bif vs DeSound.bif
        NSString* biff = [[biffs objectAtIndex:idxBIF] lowercaseString];
        NSNumber* n2 = [[NSNumber alloc] initWithInt:idxNonTS];
        NSString* s2 = [[NSString alloc] initWithCString:buff
                                         encoding:NSUTF8StringEncoding];
        NSMutableDictionary* d = [_biffs objectForKey:biff];
        if (!d)
        {
          d = [[NSMutableDictionary alloc] init];
          [_biffs setObject:d forKey:biff];
          [d release];
        }
        //printf("%s (%d) %d %s\n", [biff UTF8String], idxBIF, idxNonTS, [s2 UTF8String]);
        [d setObject:s2 forKey:n2];
        [n2 release];
        [s2 release];
      }
    }
    [biffs release];
    [loc release];
    free(buff);
  }
}

-(void)enumerateUsingBlock:(void (^)(KEYResource* resource, BOOL* stop))block
{
  NSMutableArray* biffs = [[NSMutableArray alloc] init];
  NSString* here = [_path stringByDeletingLastPathComponent];
  char* buff = calloc(1, 12);
  const char* bytes = [_data bytes];
  memcpy(buff, bytes, 4);
  //NSLog(@"Signature: '%s'", buff);
  uint32_t nBIF = EndianU32_LtoN(*(uint32_t*)(bytes + 0x0008));
  uint32_t nRes = EndianU32_LtoN(*(uint32_t*)(bytes + 0x000C));
  uint32_t offBIF = EndianU16_LtoN(*(uint32_t*)(bytes + 0x0010));
  uint16_t offRes = EndianU16_LtoN(*(uint32_t*)(bytes + 0x0014));
  //NSLog(@"%d BIF, %d Res", nBIF, nRes);
  const char* p = bytes + offBIF;
  NSMutableString* loc = [[NSMutableString alloc] init];
  for (uint32_t i = 0; i < nBIF; i++)
  {
    [loc setString:@""];
    //uint32_t len = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    uint32_t offName = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    uint16_t lenName = EndianU16_LtoN(*(uint16_t*)p);
    p += 2;
    uint16_t bits = EndianU16_LtoN(*(uint16_t*)p);
    p += 2;
    NSString* fileName = [[NSString alloc] initWithBytes:bytes + offName length:lenName - 1 encoding:NSUTF8StringEncoding];
    //NSLog(@"Filename %@ bits %d", fileName, bits);
    if ((bits & 0x01) == 0x01)
    {
      [loc setString:[here stringByAppendingPathComponent:fileName]];
    }
    if ((bits & 0x02) == 0x02)
    {
      [loc setString:[here stringByAppendingPathComponent:@"cache"]];
      [loc setString:[loc stringByAppendingPathComponent:fileName]];
    }
    if (bits & 0x04)
    {
      [loc setString:[here stringByAppendingPathComponent:@"cd1"]];
      [loc setString:[loc stringByAppendingPathComponent:fileName]];
    }
    if (bits & 0x08)
    {
      [loc setString:[here stringByAppendingPathComponent:@"cd2"]];
      [loc setString:[loc stringByAppendingPathComponent:fileName]];
    }
    if (bits & 0x10)
    {
      [loc setString:[here stringByAppendingPathComponent:@"cd3"]];
      [loc setString:[loc stringByAppendingPathComponent:fileName]];
    }
    if (bits & 0x20)
    {
      [loc setString:[here stringByAppendingPathComponent:@"cd4"]];
      [loc setString:[loc stringByAppendingPathComponent:fileName]];
    }
    if (bits & 0x40)
    {
      [loc setString:[here stringByAppendingPathComponent:@"cd5"]];
      [loc setString:[loc stringByAppendingPathComponent:fileName]];
    }
    if (bits & 0x80)
    {
      [loc setString:[here stringByAppendingPathComponent:@"cd6"]];
      [loc setString:[loc stringByAppendingPathComponent:fileName]];
    }
    if (loc.length)
    {
      [biffs addObject:[loc lastPathComponent]];
    }
    [fileName release];
  }
  p = bytes + offRes;
  for (uint32_t i = 0; i < nRes; i++)
  {
    bzero(buff, 12);
    memcpy(buff, p, 8);
    KEYResource res;
    bzero(&res, sizeof(KEYResource));
    p += 8;
    uint16_t type = EndianU16_LtoN(*(uint16_t*)p);
    p += 2;
    uint32_t locator = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    uint32_t idxBIF = (locator & 0xFFF00000) >> 20;
    //uint32_t idxTS = (locator & 0x000FC000) >> 13;
    uint32_t idxNonTS = locator & 0x3FFF;
    NSString* biff = [biffs objectAtIndex:idxBIF];
    NSString* s2 = [[NSString alloc] initWithCString:buff
                                     encoding:NSUTF8StringEncoding];
    res.biff = biff;
    res.index = idxNonTS;
    res.type = type;
    res.name = s2;
    BOOL stop = NO;
    block(&res, &stop);
    [s2 release];
    if (stop) break;
  }
  [biffs release];
  [loc release];
  free(buff);
}

-(NSString*)resourceNameForPath:(NSString*)path index:(uint32_t)idx
{
  NSString* s = nil;
  NSString* file = [[path lastPathComponent] lowercaseString];
  NSDictionary* d = [_biffs objectForKey:file];
  if (d)
  {
    s = [d objectForKey:[NSNumber numberWithInt:idx]];
  }
  return s;
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
