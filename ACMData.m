#import "ACMData.h"
#include <stdio.h>

static int read_func(void* ptr, int size, int n, void* datasrc);
static int seek_func(void* datasrc, int offset, int whence);
static int close_func(void* datasrc);
static int get_length_func(void* datasrc);
//static long tell_func(void* datasrc);

static sf_count_t _sf_vio_get_filelen(void* user_data);
static sf_count_t _sf_vio_seek(sf_count_t offset, int whence, void *user_data);
static sf_count_t _sf_vio_read(void* ptr, sf_count_t count, void* user_data);
static sf_count_t _sf_vio_write(const void *ptr, sf_count_t count, void *user_data);
static sf_count_t _sf_vio_tell(void* user_data);



@interface ACMData (Private)
-(void)_coreInit;
@end

@interface ACMVorbisData : ACMData
{}
@end


@implementation ACMData
@synthesize PCMTotal = _pcmTotal;
@synthesize timeTotal = _timeTotal;
@synthesize channels = _channels;
@synthesize rate = _rate;
@synthesize data = _data;
@synthesize dataOffset = _dataOffset;
@synthesize format = _format;
-(id)initWithURL:(NSURL*)url
{
  self = [super init];
  int err = acm_open_file(&_acm.acm, [url.path UTF8String], 0);
  if (!err)
  {
    [self _coreInit];
  }
  else
  {
    [self dealloc];
    self = [[ACMVorbisData alloc] initWithURL:url];
    if (!self)
    {
      NSLog(@"WARNING: can't find acm file named %@; %s", url.path, acm_strerror(err));
    }
  }
  // FIXME: this happens for BGII last entry in BM2.mus
  // Could try to repair???
  return self;
}

-(id)initWithData:(NSData*)data
{
  self = [super init];
  _data = [data copy];
  //const char* bytes = [_data bytes];
  acm_io_callbacks io = {read_func, seek_func, close_func, get_length_func};
  int err = acm_open_decoder(&_acm.acm, self, io, 0);
  if (!err)
  {
    _format = ACMDataFormatACM;
    [self _coreInit];
  }
  else
  {
    [self dealloc];
    self = [[ACMVorbisData alloc] initWithData:data];
    if (!self)
    {
      NSLog(@"WARNING: can't open acm data; %s", acm_strerror(err));
    }
  }
  return self;
}

-(void)_coreInit
{
  _rate = acm_rate(_acm.acm);
  _channels = acm_channels(_acm.acm);
  _pcmTotal = acm_pcm_total(_acm.acm);
  _timeTotal = acm_time_total(_acm.acm)/ 1000.0;
  acm_seek_pcm(_acm.acm, _pcmTotal-4);
  acm_seek_pcm(_acm.acm, 0);
}

-(void)dealloc
{
  if (_acm.acm) acm_close(_acm.acm);
  if (_data) [_data release];
  [super dealloc];
}

-(uint64_t)PCMTell
{
  return acm_pcm_tell(_acm.acm);
}

-(void)PCMSeek:(uint64_t)off
{
  acm_seek_pcm(_acm.acm, off);
}
#include "hexdump.h"
-(long)bufferSamples:(char*)buffer count:(unsigned)bytes bigEndian:(BOOL)big
{
  //printf("START\n");
  long n = acm_read_loop(_acm.acm, buffer, bytes, big, 2, 1);
  // Partially fix Enhanced Edition NFB.mus which has dropouts
  /*unsigned trailing = local_countTrailingZeroBytes(buffer, n);
  if (trailing > 1)
  {
    long trl = trailing /= 4;
    trl *= 4;
    //hexdump(buffer, n);
    long oldn = n;
    n = n - trl;
    //printf("Returning %d, %d trailing %d from %d\n", n, oldn, trl, trailing);
  }*/
  return n;
}

/*static int local_countTrailingZeroBytes(char* buffer, size_t length)
{
  char* p = buffer + (length - 1);
  unsigned n = 0;
  while (length)
  {
    if (*p == 0) n++;
    else break;
    length--;
    p--;
  }
  return n;
}*/
@end

@implementation ACMVorbisData
-(id)initWithURL:(NSURL*)url
{
  self = [super init];
  SF_INFO sfinfo = {0, 0, 0, 0, 0};
  SNDFILE* sf = sf_open([url.path UTF8String], SFM_READ, &sfinfo);
  if (sf_error(sf))
  {
    NSLog(@"Input does not appear to be a libsndfile file (err %d).", sf_error(sf));
    [self release];
    self = nil;
  }
  else
  {
    _acm.sf = sf;
    [self _coreInit:&sfinfo];
  }
  return self;
}

-(id)initWithData:(NSData*)data
{
  self = [super init];
  _data = [data copy];
  SF_INFO sfinfo = {0, 0, 0, 0, 0};
  SF_VIRTUAL_IO io = {_sf_vio_get_filelen, _sf_vio_seek, _sf_vio_read, _sf_vio_write, _sf_vio_tell};
  SNDFILE* sf = sf_open_virtual(&io, SFM_READ, &sfinfo, self);
  if (sf_error(sf))
  {
    NSLog(@"Input does not appear to be a libsndfile file (err %d).", sf_error(sf));
    [self release];
    self = nil;
  }
  else
  {
    _acm.sf = sf;
    [self _coreInit:&sfinfo];
  }
  return self;
}
/*
struct SF_INFO
{  sf_count_t  frames ;    // Used to be called samples.  Changed to avoid confusion.
  int      samplerate ;
  int      channels ;
  int      format ;
  int      sections ;
  int      seekable ;
} ;
*/
-(void)_coreInit:(SF_INFO*)info
{
  //SNDFILE* sf = _acm.sf;
  //NSLog(@"Bitstream is %d channel, %ldHz",vi->channels,vi->rate);
  //NSLog(@"Decoded length: %ld samples",
  //        (long)ov_pcm_total(vf,-1));
  //fprintf(stderr,"Encoded by: %s\n\n",ov_comment(vf,-1)->vendor);
  //fprintf(stderr,"Seekable? %s\n", ov_seekable(vf)? "yes":"no");
  //fprintf(stderr,"Raw total? %lu\n", ov_raw_total(vf, 0));
  //fprintf(stderr,"PCM total? %lu\n", ov_pcm_total(vf, 0));
  //fprintf(stderr,"Time total? %f\n", ov_time_total(vf, 0));
  _rate = info->samplerate;
  _channels = info->channels;
  _pcmTotal = info->frames;
  _timeTotal = (double)info->frames / (double)info->samplerate;
  //ov_pcm_seek(vf, _pcmTotal-4);
  //ov_pcm_seek(vf, 0);
  if ((info->format & SF_FORMAT_TYPEMASK) == SF_FORMAT_OGG) _format = ACMDataFormatOGG;
  else _format = ACMDataFormatWAV;
}

-(void)dealloc
{
  //ov_clear(_acm.ogg);
  sf_close(_acm.sf);
  //free(_acm.ogg);
  bzero(&_acm.sf, sizeof(void*));
  [super dealloc];
}

-(uint64_t)PCMTell
{
  return sf_seek(_acm.sf, 0, SEEK_CUR);
}

-(void)PCMSeek:(uint64_t)off
{
  (void)sf_seek(_acm.sf, off, SEEK_SET);
}

-(long)bufferSamples:(char*)buffer count:(unsigned)bytes bigEndian:(BOOL)big
{
  unsigned items = bytes / sizeof(short);
  long n = 0;
  do
  {
    long wanted = items - n;
    sf_count_t res = sf_read_short(_acm.sf, (short*)(buffer + n), wanted);
    if (big)
    {
      if (sizeof(short) != 2) NSLog(@"ERROR: short is not two bytes -- this will fail.");
      short* p = (short*)(buffer + n);
      for (int i = 0; i < res; i++)
      {
        *p = EndianU16_NtoB(*p);
        p++;
      }
    }
    n += res;
    if (res < wanted) break;
    if (0 == res) break;
  } while (n < items);
  return n * sizeof(short);
}
@end

#pragma mark Callbacks for libacm
static int read_func(void* ptr, int size, int n, void* datasrc)
{
  ACMData* myself = datasrc;
  size_t bytes = n * size;
  size_t avail = [myself.data length] - myself.dataOffset;
  if (avail < bytes) bytes = avail;
  [myself.data getBytes:ptr range:NSMakeRange(myself.dataOffset, bytes)];
  myself.dataOffset += bytes;
  return bytes;
}

static int seek_func(void* datasrc, int offset, int whence)
{
  ACMData* myself = datasrc;
  if (whence == SEEK_SET) myself.dataOffset = offset;
  else if (whence == SEEK_CUR) myself.dataOffset += offset;
  else if (whence == SEEK_END) myself.dataOffset = [myself.data length] + offset;
  return 0;
}

static int close_func(void* datasrc)
{
  #pragma unused (datasrc)
  return 0;
}

static int get_length_func(void* datasrc)
{
  ACMData* myself = datasrc;
  return [myself.data length];
}

/*static long tell_func(void* datasrc)
{
  ACMData* myself = datasrc;
  return myself.dataOffset;
}*/

#pragma mark Callbacks for Libsndfile
static sf_count_t _sf_vio_get_filelen(void* user_data)
{
  ACMData* myself = user_data;
  //NSLog(@"_sf_vio_get_filelen returning %d", [myself.data length]);
  return [myself.data length];
}

static sf_count_t _sf_vio_seek(sf_count_t offset, int whence, void *user_data)
{
  ACMData* myself = user_data;
  if (whence == SEEK_SET) myself.dataOffset = offset;
  else if (whence == SEEK_CUR) myself.dataOffset += offset;
  else if (whence == SEEK_END) myself.dataOffset = [myself.data length] + offset;
  //NSLog(@"_sf_vio_seek returning %d", myself.dataOffset);
  return myself.dataOffset;
}

static sf_count_t _sf_vio_read(void* ptr, sf_count_t count, void* user_data)
{
  sf_count_t actual = count;
  ACMData* myself = user_data;
  size_t avail = [myself.data length] - myself.dataOffset;
  if (avail < actual) actual = avail;
  [myself.data getBytes:ptr range:NSMakeRange(myself.dataOffset, actual)];
  myself.dataOffset += actual;
  //NSLog(@"_sf_vio_read(%d) = %d", count, actual);
  return actual;
}

static sf_count_t _sf_vio_write(const void *ptr, sf_count_t count, void *user_data)
{
  #pragma unused (ptr, user_data)
  return count;
}

static sf_count_t _sf_vio_tell(void* user_data)
{
  ACMData* myself = user_data;
  return myself.dataOffset;
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
