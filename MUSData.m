#import "MUSData.h"

@interface MUSData (Private)
-(NSString*)_runScript:(NSString*)script onString:(NSString*)string;
@end

@implementation MUSData
@synthesize url = _url;
@synthesize acms = _acms;
@synthesize epilogue = _epilogue;
@synthesize loopIndex = _loopIndex;
-(id)initWithURL:(NSURL*)url
{
  self = [super init];
  _url = [url retain];
  //NSDate* methodStart = [NSDate date];
  NSString* parsed = [self _runScript:@"mus.py" onString:url.path];
  //NSDate* methodFinish = [NSDate date];
  //NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
  //NSLog(@"executionTime = %f", executionTime);
  NSDictionary* pl = [parsed propertyList];
  NSMutableArray* tmp = [[NSMutableArray alloc] init];
  for (NSString* path in [pl objectForKey:@"files"])
  {
    NSURL* acmurl = [[NSURL alloc] initFileURLWithPath:path];
    [tmp addObject:acmurl];
    [acmurl release];
  }
  _acms = [[NSArray alloc] initWithArray:tmp];
  [tmp release];
  NSArray* eps = [pl objectForKey:@"epilogues"];
  if (eps && eps.count) _epilogue = [[NSURL alloc] initFileURLWithPath:[eps lastObject]];
  _loopIndex = [[pl objectForKey:@"loop"] intValue];
  // FIXME: mus.py uses a 1-based loop index which is unnecessary (default is always 0)
  if (_loopIndex > 0) _loopIndex--;
  return self;
}

-(void)dealloc
{
  if (_url) [_url release];
  if (_acms) [_acms release];
  if (_epilogue) [_epilogue release];
  [super dealloc];
}

#pragma mark Internal
// script is full or partial path to script file, including extension.
-(NSString*)_runScript:(NSString*)script onString:(NSString*)string
{
  NSBundle* bundle = [NSBundle mainBundle];
  NSString* path = [bundle pathForResource:script ofType:nil];
  NSTask* task = [[NSTask alloc] init];
  [task setLaunchPath:path];
  NSPipe* readPipe = [NSPipe pipe];
  NSFileHandle* readHandle = [readPipe fileHandleForReading];
  NSPipe* writePipe = [NSPipe pipe];
  NSFileHandle* writeHandle = [writePipe fileHandleForWriting];
  [task setStandardInput: writePipe];
  [task setStandardOutput: readPipe];
  [task launch];
  [writeHandle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
  [writeHandle closeFile];
  NSMutableData* data = [[NSMutableData alloc] init];
  NSData* readData;
  while ((readData = [readHandle availableData]) && [readData length])
    [data appendData:readData];
  [task release];
  NSString* outString = [[NSString alloc] initWithData:data
                                          encoding:NSUTF8StringEncoding];
  [data release];
  return [outString autorelease];
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
