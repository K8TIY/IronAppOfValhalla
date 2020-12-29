#import "GameWindow_Voices.h"

@interface GameWindow (Voices_Private)
-(void)_setupVoices;
-(NSArray*)_searchResultsForVoices:(NSArray<NSURL*>*)voices;
@end

@implementation GameWindow (Voices)
#pragma mark Action
-(IBAction)voiceRevealInFinder:(id)sender
{
  #pragma unused (sender)
  NSInteger row = [_voiceTable selectedRow];
  if (row != -1)
  {
    id item = [_voiceTable itemAtRow:row];
    if ([item class] == GameLocalization.class)
    {
      // Reveal the lang/<loc>/ directory.
      GameLocalization* loc = item;
      [[NSWorkspace sharedWorkspace] selectFile:[loc.url.path stringByResolvingSymlinksInPath]
                       inFileViewerRootedAtPath:@""];
    }
    else
    {
      NSURL* url = item;
      [[NSWorkspace sharedWorkspace] selectFile:[url.path stringByResolvingSymlinksInPath]
                                     inFileViewerRootedAtPath:@""];
    }
  }
}

-(void)doVoiceSearch
{
  [_voiceTable reloadData];
}

#pragma mark Outline View Data Source
-(NSInteger)outlineView:(NSOutlineView*)ov numberOfChildrenOfItem:(id)item
{
  #pragma unused (ov)
  if (nil == _voiceLocalizations)
    [self _setupVoices];
  if (nil == item) return _voiceLocalizations.count;
  GameLocalization* loc = item;
  NSArray* sounds = [self _searchResultsForVoices:loc.voices];
  return sounds.count;
}

-(id)outlineView:(NSOutlineView*)ov
     objectValueForTableColumn:(NSTableColumn*)col
     byItem:(id)item
{
  #pragma unused (ov)
  NSString* val = @"";
  if ([item class] == NSURL.class)
  {
    NSURL* url = item;
    if ([col.identifier isEqualToString:@"description"])
    {
      val = [IAoVGame descriptionForVoiceAtURL:url];
    }
    else if ([col.identifier isEqualToString:@"text"])
    {
      NSString* base = [[url lastPathComponent] stringByDeletingPathExtension];
      NSNumber* idx = [_game.tlk indexOfResName:base];
      if (!idx) idx = [_game.tlk indexOfResName:[base uppercaseString]];
      if (!idx) idx = [_game.tlk indexOfResName:[base lowercaseString]];
      if (idx) val = [_game.tlk stringAtIndex:[idx unsignedIntValue]];
    }
    else
    {
      NSMutableAttributedString* val2 = [[NSMutableAttributedString alloc] initWithString:url.lastPathComponent];
      [val2 addAttribute:NSFontAttributeName
                   value:[NSFont fontWithName:@"Menlo" size:12]
                   range:NSMakeRange(0, val2.length)];
      val = (NSString*)[val2 autorelease];
    }
  }
  else
  {
    if ([col.identifier isEqualToString:@"file"])
    {
      NSLocale* locale = [NSLocale currentLocale];
      GameLocalization* loc = item;
      val = [locale localizedStringForLanguageCode:loc.language];
    }
  }
  return val;
}

-(BOOL)outlineView:(NSOutlineView*)ov isItemExpandable:(id)item
{
  #pragma unused (ov)
  if (item && [item class] == GameLocalization.class) return YES;
  return NO;
}

-(id)outlineView:(NSOutlineView*)ov child:(NSInteger)index ofItem:(id)item
{
  #pragma unused (ov)
  if (nil == _voiceLocalizations)
    [self _setupVoices];
  if (nil == item)
  {
    return [_voiceLocalizations objectAtIndex:index];
  }
  else
  {
    GameLocalization* loc = item;
    NSArray* sounds = [self _searchResultsForVoices:loc.voices];
    return [sounds objectAtIndex:index];
  }
}

-(void)_setupVoices
{
  NSMutableArray* tmp = [[NSMutableArray alloc] init];
  for (GameLocalization* loc in _game.localizations)
  {
    if (loc.voices.count) [tmp addObject:loc];
  }
  _voiceLocalizations = [[NSArray alloc] initWithArray:tmp];
  [tmp release];
}

-(void)outlineView:(IAoVOutlineView*)ov didReceiveReturn:(NSEvent*)evt
{
  #pragma unused (ov, evt)
  [self voiceTableReturn:self];
}

-(void)voiceTableReturn:(id)sender
{
  #pragma unused (sender)
  NSInteger row = [_voiceTable selectedRow];
  id item = [_voiceTable itemAtRow:row];
  if ([item class] == NSURL.class)
  {
    NSURL* url = item;
    ACMData* md = [[ACMData alloc] initWithURL:url];
    NSData* data = [[NSData alloc] initWithContentsOfURL:url];
    [self loadMusicData:data playing:YES];
    [_progress setTitle:url.lastPathComponent];
    [md release];
    [data release];
  }
}

-(BOOL)voiceSelectionHasSound
{
  NSInteger row = [_voiceTable selectedRow];
  if (row != -1)
  {
    id item = [_voiceTable itemAtRow:row];
    return ([item class] == NSURL.class);
  }
  return NO;
}

-(NSString*)voiceExportFileName
{
  NSString* str = @"";
  NSInteger row = [_voiceTable selectedRow];
  if (row != -1)
  {
    id item = [_voiceTable itemAtRow:row];
    //NSLog(@"%@", [item class]);
    if ([item class] == NSURL.class)
    {
      NSURL* url = (NSURL*)item;
      return [[url.path lastPathComponent] stringByDeletingPathExtension];
    }
  }
  return str;
}

-(ACMRenderer* _Nullable)voiceRendererForExport
{
  ACMRenderer* renderer = nil;
  NSInteger row = [_voiceTable selectedRow];
  id item = [_voiceTable itemAtRow:row];
  //NSLog(@"%@", [item class]);
  if ([item class] == NSURL.class)
  {
    NSURL* url = item;
    NSData* data = [[NSData alloc] initWithContentsOfURL:url];
    renderer = [[ACMRenderer alloc] initWithData:data];
    [renderer setDelegate:self];
    [data release];
  }
  return [renderer autorelease];
}

// Character sounds filtered by search string
-(NSArray*)_searchResultsForVoices:(NSArray<NSURL*>*)voices
{
  if (_search.stringValue.length)
  {
    NSMutableArray* tmp = [[NSMutableArray alloc] init];
    for (NSURL* url in voices)
    {
      NSString* val = nil;
      NSString* base = [[url lastPathComponent] stringByDeletingPathExtension];
      NSNumber* idx = [_game.tlk indexOfResName:base];
      if (!idx) idx = [_game.tlk indexOfResName:[base uppercaseString]];
      if (!idx) idx = [_game.tlk indexOfResName:[base lowercaseString]];
      if (idx) val = [_game.tlk stringAtIndex:[idx unsignedIntValue]];
      if (val)
      {
        NSRange range = [val rangeOfString:_search.stringValue
                             options:NSCaseInsensitiveSearch |
                                     NSDiacriticInsensitiveSearch];
        if (range.length)
        {
          [tmp addObject:url];
        }
      }
    }
    voices = [NSArray arrayWithArray:tmp];
    [tmp release];
  }
  return voices;
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
