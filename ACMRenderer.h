#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreAudio/CoreAudio.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreAudio/AudioHardware.h>
#import <CoreServices/CoreServices.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ACMData.h"
#import "MUSData.h"

#ifndef ACM_RENDERER_DEBUG
#define ACM_RENDERER_DEBUG 0
#endif

@protocol ACM <NSObject>
-(void)acmDidFinishPlaying:(id)renderer;
-(void)acmProgress:(id)renderer;
@end


@interface ACMRenderer : NSObject <NSCopying>
{
  double                    _amp;
  double                    _totalSeconds;
  double                    _epilogueSeconds;
  NSArray<NSURL*>*          _acmURLs; // For NSCopying
  NSURL*                    _epilogueURL; // For NSCopying
  id                        _data; // NSData or ACMData for NSCopying
  NSMutableArray<ACMData*>* _acms;
  NSURL*                    _currentURL;
  AUGraph                   _ag;
  id                        _delegate;
  unsigned                  _channels;
  uint64_t                  _totalPCM; // Includes epilogue
  uint64_t                  _totalPCMPlayed;
  uint64_t                  _epiloguePCM;
  NSUInteger                _currentACM; // 0-based
  //FIXME: _loopIndex should be a PCM number for efficiency
  NSUInteger                _loopIndex; // 0-based
  NSUInteger                _epilogueIndex; // index of the acm array that is the epilogue, if 0 then no epilogue
  BOOL                      _nowPlaying;
  BOOL                      _loops;
  ACMDataFormat             _format;
}

@property(readonly) NSURL* currentURL;
@property(readonly) double amp;
@property(readonly) double seconds;
@property(readonly) unsigned channels;
@property(readonly) BOOL playing;
@property(readonly) BOOL loops;
@property(readonly) int epilogueState;
@property(readonly) ACMDataFormat format;

-(ACMRenderer*)initWithMUSData:(MUSData*)data;
-(ACMRenderer*)initWithData:(NSData*)data;
-(void)setAmp:(double)val;
-(void)start;
-(void)stop;
-(double)pct;
-(void)gotoPct:(double)pct;
-(void)setDelegate:(id)delegate;
-(void)setDoesLoop:(BOOL)loop;
-(double)loopPct;
-(double)epiloguePct;
-(void)exportToURL:(NSURL*)url ofType:(AudioFileTypeID)type;
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
