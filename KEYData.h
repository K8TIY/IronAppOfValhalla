#import <Cocoa/Cocoa.h>

// Make it easy to look up the resource name, given
// The file path and the resource index.
typedef struct
{
  NSString* biff;  // BIFF filename
  uint32_t  index;
  uint16_t  type;
  NSString* name;
} KEYResource;

@interface KEYData : NSObject
{
  NSData*              _data;
  NSString*            _path;  // Path to this file
  NSMutableDictionary* _biffs; // File path -> NSDictionary of NSNumber -> Resname
}
-(id)initWithURL:(NSURL*)url;
-(void)enumerateUsingBlock:(void (^)(KEYResource* resource, BOOL* stop))block;
-(NSString*)resourceNameForPath:(NSString*)path index:(uint32_t)idx;
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
