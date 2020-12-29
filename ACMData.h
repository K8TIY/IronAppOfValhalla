#import <Cocoa/Cocoa.h>
#include "libacm.h"
#include </usr/local/include/sndfile.h>

typedef enum
{
  ACMDataFormatACM,
  ACMDataFormatOGG,
  ACMDataFormatWAV
} ACMDataFormat;

@interface ACMData : NSObject
{
  union
  {
    ACMStream*  acm;
    SNDFILE*    sf;
  }             _acm;
  NSData*       _data;
  off_t         _dataOffset;
  unsigned      _channels;
  unsigned      _rate;
  uint64_t      _pcmTotal;
  double        _timeTotal;
  ACMDataFormat _format;
}
@property(readonly) uint64_t PCMTotal;
@property(readonly) double timeTotal;
@property(readonly) unsigned channels;
@property(readonly) unsigned rate;
@property(readonly) NSData* data;
@property(readonly) ACMDataFormat format;
@property(assign) off_t dataOffset;
-(id)initWithURL:(NSURL*)url;
-(id)initWithData:(NSData*)data;
-(uint64_t)PCMTell;
-(void)PCMSeek:(uint64_t)off;
-(long)bufferSamples:(char*)buffer count:(unsigned)bytes
       bigEndian:(BOOL)big;
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
