#import "GameWindow_Music.h"

@implementation GameWindow (Music)

#pragma mark Contextual Menu
-(IBAction)musicRevealInFinder:(id)sender
{
  #pragma unused (sender)
  NSInteger row = [_musicTable selectedRow];
  if (row != -1)
  {
    if (_musicIndices) row = [_musicIndices indexAtIndex:row];
    MUSFile* mf = [_musFiles objectAtIndex:row];
    [[NSWorkspace sharedWorkspace] selectFile:[mf.url.path stringByResolvingSymlinksInPath]
                                   inFileViewerRootedAtPath:@""];
  }
}

-(void)doMusicSearch
{
  NSString* s = _search.stringValue;
  BOOL reload = NO;
  if (_musicIndices)
  {
    [_musicIndices release];
    _musicIndices = nil;
    reload = YES;
  }
  if (_musFiles && s && s.length)
  {
    _musicIndices = [[NSMutableIndexSet alloc] init];
    NSUInteger n = [_musFiles count];
    NSUInteger i;
    for (i = 0; i < n; i++)
    {
      MUSFile* mf = [_musFiles objectAtIndex:i];
      if (mf.title)
      {
        NSRange range = [mf.title rangeOfString:s
                                  options:NSCaseInsensitiveSearch |
                                          NSDiacriticInsensitiveSearch];
        if (range.length)
        {
          [_musicIndices addIndex:i];
          reload = YES;
        }
      }
    }
  }
  if (reload)
  {
    [_musicTable reloadData];
  }
}

-(NSInteger)numberOfRowsInMusicTable
{
  if (_musicIndices) return _musicIndices.count;
  return _musFiles.count;
}

-(id)musicObjectValueForTableColumn:(NSTableColumn*)col row:(NSInteger)row
{
  if (_musicIndices) row = [_musicIndices indexAtIndex:row];
  if ([col.identifier isEqualToString:@"file"])
  {
    MUSFile* f = [_musFiles objectAtIndex:row];
    return [NSString stringWithFormat:@"%@", [f.url lastPathComponent]];
  }
  else if ([col.identifier isEqualToString:@"title"])
  {
    MUSFile* f = [_musFiles objectAtIndex:row];
    return f.title;
  }
  return @"";
}

-(void)musicTableReturn:(id)sender
{
  #pragma unused (sender)
  NSInteger row = [_musicTable selectedRow];
  if (row != -1)
  {
    MUSFile* mf = [_musFiles objectAtIndex:row];
    MUSData* md = [[MUSData alloc] initWithURL:mf.url];
    [self loadMUSData:md playing:YES];
    [md release];
  }
}

#pragma mark AIFF Export
-(NSString*)musicExportFileName
{
  NSString* str = @"";
  NSInteger row = [_musicTable selectedRow];
  if (row != -1)
  {
    MUSFile* mf = [_musFiles objectAtIndex:row];
    return [[mf.url.path lastPathComponent] stringByDeletingPathExtension];
    
  }
  return str;
}

-(ACMRenderer* _Nullable)musicRendererForExport
{
  ACMRenderer* renderer = nil;
  NSInteger row = [_musicTable selectedRow];
  if (row != -1)
  {
    MUSFile* mf = [_musFiles objectAtIndex:row];
    MUSData* md = [[MUSData alloc] initWithURL:mf.url];
    renderer = [[ACMRenderer alloc] initWithMUSData:md];
    [renderer setDelegate:self];
    [md release];
  }
  return [renderer autorelease];
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
