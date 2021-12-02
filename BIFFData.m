#import "BIFFData.h"
#import "ACMData.h"
#import <zlib.h>

@interface BIFFData (Private)
-(void)_load;
-(void)_setBIFFData;
-(void)_setBIFData;
-(void)_setBIFCData;
@end

@implementation BIFFData
@synthesize url = _url;

+(NSString*)fileFormat:(uint32_t)type
{
  static NSDictionary* fileTypes = nil;
  if (nil == fileTypes)
  {
    fileTypes = [[NSDictionary alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"FileTypes" withExtension:@"plist"]];
  }
  return [fileTypes objectForKey:[NSString stringWithFormat:@"0x%04X", type]];
}

-(id)initWithURL:(NSURL*)url
{
  self = [super init];
  _url = [url retain];
  //NSData* data = [[NSData alloc] initWithContentsOfURL:_url];
  //[self setData:data];
  return self;
}

-(void)dealloc
{
  if (_url) [_url release];
  if (_data) [_data release];
  [super dealloc];
}

-(void)unload
{
  if (_data) [_data release];
  _data = nil;
}

-(NSData*)dataAtOffset:(uint32_t)offset length:(uint32_t)length
{
  if (!_data)
  {
    _data = [[NSData alloc] initWithContentsOfURL:_url];
  }
  NSData* val = [[NSData alloc] initWithBytes:[_data bytes] + offset
                                length:length];
  return [val autorelease];
}

-(void)enumerateUsingBlock:(void (^)(BIFFResource* resource, BOOL* stop))block
{
  if (!_data)
  {
    _data = [[NSData alloc] initWithContentsOfURL:_url];
  }
  char* buff = calloc(1, 12);
  memcpy(buff, [_data bytes], 4);
  if (0 == strncmp(buff, "BIFF", 4)) [self _enumerateBIFFDataUsingBlock:block];
  else if (0 == strncmp(buff, "BIF ", 4)) [self _enumerateBIFDataUsingBlock:block];
  else if (0 == strncmp(buff, "BIFC", 4)) [self _enumerateBIFCDataUsingBlock:block];
  free(buff);
}

-(void)_enumerateBIFFDataUsingBlock:(void (^)(BIFFResource* resource, BOOL* stop))block
{
  const unsigned char* bytes = [_data bytes];
  _resourceCount = EndianU32_LtoN(*(uint32_t*)(bytes + 0x0008));
  _offset = EndianU32_LtoN(*(uint32_t*)(bytes + 0x0010));
  const unsigned char* p = bytes + _offset;
  BOOL stop = NO;
  for (uint32_t i = 0; i < _resourceCount; i++)
  {
    BIFFResource res;
    res.loc = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    res.off = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    res.len = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    res.type = EndianU16_LtoN(*(uint16_t*)p);
    p += 4;
    res.subtype = 0;
    if (res.type == 4)
    {
      res.subtype = ACMDataFormatACM;
      // ACM header is 0x97 28 03 01 but we'll call it the default even though it is becoming obsolete.
      char code[4] = {*(bytes + res.off), *(bytes + res.off + 1), *(bytes + res.off + 2), *(bytes + res.off + 3)};
      //printf("Music signature %c%c%c%c in %s at %d\n", code[0], code[1], code[2], code[3], _url.lastPathComponent.UTF8String, res.loc);
      if (code[0] == 'R' && code[1] == 'I' && code[2] == 'F' && code[3] == 'F')
      {
        //NSLog(@"RIFF file detected in %@ at loc %d", [_url lastPathComponent], res.loc);
        res.subtype = ACMDataFormatWAV;
      }
      if (code[0] == 'O' && code[1] == 'g' && code[2] == 'g' && code[3] == 'S')
      {
        //NSLog(@"RIFF file detected in %@ at loc %d", [_url lastPathComponent], res.loc);
        res.subtype = ACMDataFormatOGG;
      }
    }
    block(&res, &stop);
    if (stop) break;
  }
}
/*
0x0000  4 (char array)  Signature ('BIF ')
0x0004  4 (char array)  Version ('V1.0')
0x0008  4 (dword)  Length of filename
0x000c  (ASCIIZ char array)  Filename (length specified by previous field)
sizeof(filename)+0x0010  4 (dword)  Uncompressed data length
sizeof(filename)+0x0014  4 (dword)  Compressed data length
sizeof(filename)+0x0018  Variable (raw data)  Compressed data
*/
-(void)_enumerateBIFDataUsingBlock:(void (^)(BIFFResource* resource, BOOL* stop))block
{
  const unsigned char* bytes = [_data bytes];
  uint32_t fnlen = EndianU32_LtoN(*(uint32_t*)(bytes + 0x0008));
  uint32_t uncmplen = EndianU32_LtoN(*(uint32_t*)(bytes + fnlen + 0x0010));
  uint32_t cmplen = EndianU32_LtoN(*(uint32_t*)(bytes + fnlen + 0x0014));
  unsigned char* decomp = malloc(uncmplen);
  const unsigned char* p = bytes + fnlen + 0x0014;
  uLongf zuncmplen = uncmplen;
  if (uncmplen > 0 && cmplen > 0)
  {
    int status = uncompress(decomp, &zuncmplen, p, cmplen);
    if (status != Z_OK)
    {
      NSLog(@"Status: %d", status);
      goto Done;
    }
  }
  if (_data) [_data release];
  _data = [[NSData alloc] initWithBytes:decomp length:zuncmplen];
  [self _enumerateBIFFDataUsingBlock:block];
Done:
  if (decomp) free(decomp);
}

/*Header

Offset  Size (data type)  Description
0x0000  4 (char array)  Signature ('BIFC')
0x0004  4 (char array)  Version ('V1.0')
0x0008  4 (dword)  Uncompressed BIF size
Compressed Blocks

Offset  Size (data type)  Description
0x0000  4 (dword)  Decompressed size
0x0004  4 (dword)  Compressed size
0x0008  varies (bytes)  Compressed data*/
-(void)_enumerateBIFCDataUsingBlock:(void (^)(BIFFResource* resource, BOOL* stop))block
{
  const unsigned char* bytes = [_data bytes];
  uint32_t sz = EndianU32_LtoN(*(uint32_t*)(bytes + 0x0008));
  //NSLog(@"Size: %d", sz);
  unsigned char* decomp = malloc(sz);
  const unsigned char* p = bytes + 12;
  uint32_t amt = 0; // Amount decompressed
  while (amt < sz)
  {
    // read block header
    uint32_t uncmplen = EndianU32_LtoN(*(uint32_t*)p);
    uLongf zuncmplen = uncmplen;
    p += 4;
    uint32_t cmplen = EndianU32_LtoN(*(uint32_t*)p);
    p += 4;
    if (uncmplen > 0 && cmplen > 0)
    {
      int status = uncompress(decomp + amt, &zuncmplen, p, cmplen);
      if (status != Z_OK)
      {
        NSLog(@"Status: %d", status);
        goto Done;
      }
      p += cmplen;
      amt += uncmplen;
    }
  }
  if (_data) [_data release];
  _data = [[NSData alloc] initWithBytes:decomp length:amt];
  free(decomp);
  decomp = NULL;
  [self _enumerateBIFFDataUsingBlock:block];
Done:
  if (decomp) free(decomp);
}
@end

/*
Copyright © 2010-2021, BLUGS.COM LLC

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
