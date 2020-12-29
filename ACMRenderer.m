#import "ACMRenderer.h"
#import <AudioToolbox/AudioToolbox.h>
#include <Accelerate/Accelerate.h>

@interface ACMRenderer (Private)
-(OSStatus)_initAUGraph:(double)rate;
-(int16_t*)_bufferSamples:(UInt32)count;
-(ACMData*)_advACM;
-(ACMData*)_epilogueAtIndex:(NSUInteger)idx;
-(void)_progress;
-(void)_setEpilogueState:(int)state;
-(ACMData*)_gotoACMAtIndex:(NSUInteger)index;
-(double)_pctForPCM:(uint64_t)pcm;
@end

static OSStatus	RenderCB(void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags, 
                         const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber, 
                         UInt32 inNumberFrames, AudioBufferList* ioData);

static OSStatus RenderCB(void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags, 
                         const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber, 
                         UInt32 inNumberFrames, AudioBufferList* ioData)
{
  #pragma unused (ioActionFlags,inTimeStamp,inBusNumber)
  ACMRenderer* myself = inRefCon;
  NSUInteger i;
  short* acmBufferRead = NULL;
  float* lBuffer = ioData->mBuffers[0].mData;
  float* rBuffer = ioData->mBuffers[1].mData;
  UInt32 samples = inNumberFrames;
  unsigned channels = myself.channels;
  if (channels > 1) samples *= 2;
  int16_t* acmBuffer = [myself _bufferSamples:samples];
  if (acmBuffer) acmBufferRead = acmBuffer;
  float amp = [myself amp];
  for (i = 0; i < inNumberFrames; i++)
  {
    float waveL = 0.0f, waveR = 0.0f;
    if (acmBuffer)
    {
      int16_t lSample = *acmBufferRead;
      acmBufferRead++;
      int16_t rSample = lSample;
      if (channels > 1)
      {
        rSample = *acmBufferRead;
        acmBufferRead++;
      }
      // Scale short int values to {-1,1}
      waveL = (float)lSample/32767.0f;
      if (rSample != lSample) waveR = (float)rSample/32767.0f;
      else waveR = waveL;
      // Only multiply by amp if we have to.
      if (amp != 1.0)
      {
        waveL *= amp;
        waveR *= amp;
      }
    }
    *lBuffer++ = waveL;
    *rBuffer++ = waveR;
  }
  [myself _progress];
  if (acmBuffer) free(acmBuffer);
  return noErr;
}


@implementation ACMRenderer
@synthesize currentURL = _currentURL;
@synthesize amp = _amp;
@synthesize channels = _channels;
@synthesize playing = _nowPlaying;
@synthesize loops = _loops;
@synthesize epilogueState = _epilogue;
@synthesize format = _format;

-(ACMRenderer*)initWithMUSData:(MUSData*)data
{
  self = [super init];
  _data = [data retain];
  _acmURLs = [data.acms retain];
  _epilogueURL = [data.epilogue retain];
  _amp = 0.5f;
  _totalSeconds = 0.0;
  _epilogueSeconds = 0.0;
  _loops = NO;
  double rate = 0.0;
  _acms = [[NSMutableArray alloc] init];
  ACMData* acm;
  unsigned i = 0;
  for (NSURL* url in _acmURLs)
  {
    //NSLog(@"Creating ACM from %@ (%d)", file, i);
    i++;
    acm = [[ACMData alloc] initWithURL:url];
    if (acm)
    {
      [_acms addObject:acm];
      _format = acm.format;
      _totalPCM += [acm PCMTotal];
      _totalSeconds += acm.timeTotal;
      _channels = [acm channels];
      rate = acm.rate;
      [acm release];
    }
    else NSLog(@"WARNING: can't find acm file at %@", url);
	}
  if (_epilogueURL)
  {
    acm = [[ACMData alloc] initWithURL:_epilogueURL];
    if (acm)
    {
      [_acms addObject:acm];
      _epilogueIndex = _acms.count - 1;
      _totalPCM += [acm PCMTotal];
      _totalSeconds += acm.timeTotal;
      _epiloguePCM = [acm PCMTotal];
      _epilogueSeconds = acm.timeTotal;
      [acm release];
    }
    else NSLog(@"WARNING: can't find epilogue at %@", _epilogueURL);
  }
  _loopIndex = data.loopIndex;
  _currentURL = [_acmURLs objectAtIndex:0];
  OSStatus err = [self _initAUGraph:rate];
  if (err)
  {
    NSLog(@"_initAUGraph: %f failed: '%.4s'", rate, (char*)&err);
    [self release];
    self = nil;
  }
  return self;
}

// FIXME: this needs a better way to report errors
-(ACMRenderer*)initWithData:(NSData*)data
{
  self = [super init];
  _data = [data retain];
  _amp = 0.5f;
  _totalSeconds = 0.0;
  _epilogueSeconds = 0.0;
  _loops = NO;
  OSStatus err = noErr;
  _acms = [[NSMutableArray alloc] init];
  ACMData* acm = [[ACMData alloc] initWithData:data];
  if (acm)
  {
    [_acms addObject:acm];
    _format = acm.format;
    _totalPCM = [acm PCMTotal];
    _totalSeconds = acm.timeTotal;
    _channels = [acm channels];
    [acm release];
    err = [self _initAUGraph:acm.rate];
    [self setDoesLoop:NO];
  }
  else NSLog(@"WARNING: can't load ACM data");
  if (err)
  {
    NSLog(@"_initAUGraph: %d failed: '%.4s'", acm.rate, (char*)&err);
  }
  if (err || !acm)
  {
    [self release];
    self = nil;
  }
  return self;
}

-(void)dealloc
{
  if (_ag) DisposeAUGraph(_ag);
  if (_acms) [_acms release];
  if (_acmURLs) [_acmURLs release];
  if (_epilogueURL) [_epilogueURL release];
  if (_data) [_data release];
  [super dealloc];
}

-(id)copyWithZone:(NSZone*)zone
{
  #pragma unused (zone)
  if ([_data isKindOfClass:[NSData class]]) return [[ACMRenderer alloc] initWithData:_data];
  return [[ACMRenderer alloc] initWithMUSData:_data];
}

-(void)setDelegate:(id)del {_delegate = del;}

-(void)setDoesLoop:(BOOL)loop
{
  _loops = loop;
}

-(void)start
{
  if (!_nowPlaying)
  {
    OSStatus err = AUGraphStart(_ag);
    if (!err) _nowPlaying = YES;
  }
}

-(void)stop
{
  if (_nowPlaying)
  {
    OSStatus err = AUGraphStop(_ag);
    if (err) NSLog(@"ERROR '%.4s' from AudioOutputUnitStop", (char*)&err);
    else _nowPlaying = NO;
  }
}

-(double)pct
{
  return [self _pctForPCM:_totalPCMPlayed];
}

// Includes epilogue only if not looping.
-(double)seconds
{
  double secs = _totalSeconds;
  if (_loops) secs -= _epilogueSeconds;
  return secs;
}

-(void)gotoPct:(double)pct
{
  if (pct < 0.0) pct = 0.0;
  if (pct > 1.0) pct = 1.0;
  uint64_t pcm = _totalPCM;
  if (_loops) pcm -= _epiloguePCM;
  uint64_t posPCM = pcm * pct;
  _totalPCMPlayed = 0;
  NSUInteger i, count = _acms.count;
  if (_epilogueIndex) count--;
  for (i = 0; i < count; i++)
  {
    ACMData* acm = [_acms objectAtIndex:i];
    pcm = acm.PCMTotal;
    if (_totalPCMPlayed + pcm >= posPCM)
    {
      uint64_t offset = posPCM - _totalPCMPlayed;
      [acm PCMSeek:offset];
      _totalPCMPlayed += offset;
      _currentACM = i;
      break;
    }
    else
    {
      _totalPCMPlayed += pcm;
    }
  }
}

// Returns number between 0.0 and 1.0 inclusive that represents the loop point.
-(double)loopPct
{
  uint64_t pcm = 0;
  NSUInteger i;
  for (i = 0; i < _loopIndex; i++)
  {
    ACMData* acm = [_acms objectAtIndex:i];
    pcm += acm.PCMTotal;
  }
  return [self _pctForPCM:pcm];
}

-(void)setAmp:(double)val
{
  if (val < 0.0) val = 0.0;
  if (val > 1.0) val = 1.0;
  _amp = val;
}

// Returns number between 0.0 and 1.0 inclusive that represents the epilogue point.
-(double)epiloguePct
{
  if (_loops || _epilogueIndex == 0) return 0.0;
  uint64_t pcm = 0;
  NSUInteger i;
  for (i = 0; i < _epilogueIndex; i++)
  {
    ACMData* acm = [_acms objectAtIndex:i];
    pcm += acm.PCMTotal;
  }
  return [self _pctForPCM:pcm];
}

#pragma mark Internal
-(OSStatus)_initAUGraph:(double)rate
{
  OSStatus result = NewAUGraph(&_ag);
  if (result) return result;
  AUNode outputNode;
  AudioUnit outputUnit;
  //  output component
  AudioComponentDescription output_desc;
  output_desc.componentType = kAudioUnitType_Output;
  output_desc.componentSubType = kAudioUnitSubType_DefaultOutput;
  output_desc.componentFlags = 0;
  output_desc.componentFlagsMask = 0;
  output_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
  result = AUGraphAddNode(_ag, &output_desc, &outputNode);
  if (result) return result;
  result = AUGraphOpen(_ag);
  if (result) return result;
  result = AUGraphNodeInfo(_ag, outputNode, NULL, &outputUnit);
  if (result) return result;
  AudioStreamBasicDescription desc;
  desc.mSampleRate = rate;
  desc.mFormatID = kAudioFormatLinearPCM;
  desc.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked |
                      kAudioFormatFlagIsNonInterleaved;
#if TARGET_RT_BIG_ENDIAN
  desc.mFormatFlags |= kAudioFormatFlagIsBigEndian;
#endif
  desc.mBytesPerPacket = 4;
  desc.mFramesPerPacket = 1;
  desc.mBytesPerFrame = 4;
  desc.mChannelsPerFrame = 2;
  desc.mBitsPerChannel = 32;
  // Setup render callback struct
  // This struct describes the function that will be called
  // to provide a buffer of audio samples for the mixer unit.
  AURenderCallbackStruct rcbs;
  rcbs.inputProc = RenderCB;
  rcbs.inputProcRefCon = self;
  // Set a callback for the specified node's specified input
  result = AudioUnitSetProperty(outputUnit, kAudioUnitProperty_SetRenderCallback,
                                kAudioUnitScope_Input, 0, &rcbs,
                                sizeof(AURenderCallbackStruct)); 
  //result = AUGraphSetNodeInputCallback(_ag, mixerNode, i, &rcbs);
  if (result) return result;
  // Apply the Description to the mixer output bus
  result = AudioUnitSetProperty(outputUnit, kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input, 0,
                                &desc, sizeof(desc));
  if (result) return result;
  // Once everything is set up call initialize to validate connections
  return AUGraphInitialize(_ag);
}

-(int16_t*)_bufferSamples:(UInt32)count
{
  int16_t* acmBuffer = NULL;
  unsigned long bytesNeeded = count * sizeof(int16_t);
  unsigned long bytesBuffered = 0;
  while (bytesBuffered < bytesNeeded)
  {
    ACMData* acm = nil;
    if (_currentACM < [_acms count])
      acm = [_acms objectAtIndex:_currentACM];
    if (!acm) NSLog(@"No acm at index %u of %lu??", (unsigned)_currentACM,
                    (unsigned long)[_acms count]);
    int returned = 0;
    unsigned long needed = bytesNeeded - bytesBuffered;
    if (!acmBuffer) acmBuffer = calloc(bytesNeeded, 1L);
    int before = [acm PCMTell];
    returned = [acm bufferSamples:((char*)acmBuffer) + bytesBuffered
                   count:needed bigEndian:TARGET_RT_BIG_ENDIAN];
    int after = [acm PCMTell];
    bytesBuffered += returned;
    _totalPCMPlayed += (after - before);
    if (returned < needed)
    {
      acm = [self _advACM];
      if (!acm && _delegate)
      {
        [_delegate performSelectorOnMainThread:@selector(acmDidFinishPlaying:)
                   withObject:self waitUntilDone:NO];
        break;
      }
    }
  }
  return acmBuffer;
}

// Go to the next ACM and prepare to play.
// If nil, we are done playing.
-(ACMData*)_advACM
{
  ACMData* acm = nil;
  // Go ahead and advance to the next one.
  _currentACM++;
  //printf("(now %d)\n", _currentACM);
  BOOL fini = NO;
  if (_epilogueIndex > 0 && _currentACM >= _epilogueIndex && _loops)
  {
    _currentACM = _loopIndex;
  }
  else if (_currentACM >= _acms.count)
  {
    if (_loops) _currentACM = _loopIndex;
    else
    {
      _currentACM = 0;
      fini = YES;
    }
  }
  acm = [self _gotoACMAtIndex:_currentACM];
  if (fini) acm = nil;
  if (_epilogueIndex && _currentACM == _epilogueIndex)
  {
    _currentURL = _epilogueURL;
  }
  else
  {
    _currentURL = [_acmURLs objectAtIndex:_currentACM];
  }
  return acm;
}

-(void)_progress
{
  if (_delegate && [_delegate respondsToSelector:@selector(acmProgress:)])
  {
    [_delegate performSelectorOnMainThread:@selector(acmProgress:)
               withObject:self waitUntilDone:NO];
  }
}

-(ACMData*)_gotoACMAtIndex:(NSUInteger)idx
{
  if (idx >= [_acms count]) idx = [_acms count]-1;
  _totalPCMPlayed = 0;
  _currentACM = idx;
  ACMData* acm;
  for (NSUInteger i = 0; i < idx; i++)
  {
    acm = [_acms objectAtIndex:i];
    int acmPCM = acm.PCMTotal;
    _totalPCMPlayed += acmPCM;
  }
  acm = [_acms objectAtIndex:idx];
  [acm PCMSeek:0];
  return acm;
}

-(double)_pctForPCM:(uint64_t)pcm
{
  double tpcm = (double)_totalPCM;
  if (_loops) tpcm -= (double)_epiloguePCM;
  double pct = (double)pcm / tpcm;
  return pct;
}

#define BUFF_SIZE 0x40000L
-(void)exportToURL:(NSURL*)url ofType:(AudioFileTypeID)type
{
  BOOL bigEndian = (type == kAudioFileAIFFType);
  if (type != kAudioFileAIFFType && type != kAudioFileWAVEType)
  {
    NSLog(@"ERROR: unknown export type %d", type);
    return;
  }
  char* buff = malloc(BUFF_SIZE);
  if (buff)
  {
    ACMData* acm;
    AudioStreamBasicDescription streamFormat;
    acm = [_acms objectAtIndex:0L];
    streamFormat.mSampleRate = acm.rate;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags = ((bigEndian)? kAudioFormatFlagIsBigEndian : 0) |
                                kAudioFormatFlagIsSignedInteger |
                                kAudioFormatFlagIsPacked;
    streamFormat.mChannelsPerFrame = acm.channels;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mBitsPerChannel = 16;
    streamFormat.mBytesPerFrame = 4;
    streamFormat.mBytesPerPacket = 4;
    SInt64 packetidx = 0;
    AudioFileID fileID;
    OSStatus err = AudioFileCreateWithURL((CFURLRef)url, type, &streamFormat,
                                          kAudioFileFlags_EraseFile, &fileID);
    if (err)
      NSLog(@"AudioFileCreateWithURL: error '%.4s' URL %@ rate %f file %d",
            (char*)&err, url, streamFormat.mSampleRate, (int)fileID);
    for (_currentACM = 0; _currentACM < [_acms count]; _currentACM++)
    {
      unsigned bytesDone = 0;
      acm = [_acms objectAtIndex:_currentACM];
      [acm PCMSeek:0];
      unsigned totalBytes = acm.PCMTotal * acm.channels * sizeof(int16_t);
	    while (bytesDone < totalBytes)
      {
        unsigned res = [acm bufferSamples:buff count:BUFF_SIZE bigEndian:bigEndian];
        #if ACM_RENDERER_DEBUG
        hexdump(buff,res);
        #endif
        if (!res)
        {
          //NSLog(@"WTF? Couldn't get acm reader to cough up any bits for the epilogue??\n%@", epiacm);
          break;
        }
        bytesDone += res;
        UInt32 ioNumPackets = res/streamFormat.mBytesPerPacket;
        err = AudioFileWritePackets(fileID, false, res, NULL, packetidx, &ioNumPackets, buff);
        if (err) NSLog(@"AudioFileWritePackets: error '%.4s'", (char*)&err);
        packetidx += ioNumPackets;
      }
    }
    AudioFileClose(fileID);
    free(buff);
  }
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
