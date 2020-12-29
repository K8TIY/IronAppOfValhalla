#import <Cocoa/Cocoa.h>

// An entry in a BIFF file
typedef struct
{
  uint32_t  loc;
  uint32_t  off; // From _bytes
  uint32_t  len;
  uint16_t  type;
  uint16_t  subtype;
} BIFFResource;


@interface BIFFData : NSObject
{
  NSURL*   _url;
  uint32_t _resourceCount;
  uint32_t _offset;  // To string data
  NSData*  _data;    // Release when done
}
@property (readonly) NSURL* url;
-(id)initWithURL:(NSURL*)url;
-(void)unload;
-(void)enumerateUsingBlock:(void (^)(BIFFResource* resource, BOOL* stop))block;
-(NSData*)dataAtOffset:(uint32_t)offset length:(uint32_t)length;
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
