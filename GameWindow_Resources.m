#import "GameWindow_Resources.h"

@implementation GameWindow (Resources)

#pragma mark Action
-(void)doResourceSearch
{
  NSString* s = _search.stringValue;
  BOOL reload = NO;
  if (_indices)
  {
    [_indices release];
    _indices = nil;
    reload = YES;
  }
  if (_currentResources && _currentBIFF && s && s.length)
  {
    _indices = [[NSMutableIndexSet alloc] init];
    NSUInteger n = [_currentResources count];
    NSUInteger i;
    for (i = 0; i < n; i++)
    {
      GameResource* resource = [_currentResources objectAtIndex:i];
      NSString* name = [_game.chitin resourceNameForPath:[_currentBIFF.url path] index:resource.loc & 0x3FFF];
      if (name)
      {
        NSRange range = [name rangeOfString:s options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
        if (range.length)
        {
          [_indices addIndex:i];
          reload = YES;
        }
        NSNumber* idx = [_game.tlk indexOfResName:name];
        if (idx)
        {
          NSString* val = [_game.tlk stringAtIndex:[idx unsignedIntValue]];
          if (val)
          {
            range = [val rangeOfString:s options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
            if (range.length)
            {
              [_indices addIndex:i];
              reload = YES;
            }
          }
        }
      }
    }
  }
  if (reload)
  {
    [_resourceTable reloadData];
  }
}

-(IBAction)resourceRevealInFinder:(id)sender
{
  #pragma unused (sender)
  NSInteger row = [_resourceFileTable selectedRow];
  if (row != -1)
  {
    GameResourceCount* grc = [_biffs objectAtIndex:row];
    [[NSWorkspace sharedWorkspace] selectFile:[grc.biff.url.path stringByResolvingSymlinksInPath]
                                   inFileViewerRootedAtPath:@""];
  }
}

#pragma mark Resource File Table
-(id)resourceFileObjectValueForTableColumn:(NSTableColumn*)col
     row:(NSInteger)row
{
  GameResourceCount* grc = [_biffs objectAtIndex:row];
  if ([col.identifier isEqualToString:@"file"])
  {
    NSString* gamePath = [[NSString alloc] initWithFormat:@"%@/", _game.main.path];
    NSString* path = grc.biff.url.path;
    path = [path stringByReplacingOccurrencesOfString:gamePath withString:@""];
    [gamePath release];
    return path;
  }
  else if ([col.identifier isEqualToString:@"resources"])
  {
    return [NSString stringWithFormat:@"%@", grc.count];
  }
  return @"";
}

-(void)resourceFileSelectionDidChange
{
  if (_currentBIFF)
  {
    [_currentBIFF release];
    _currentBIFF = nil;
  }
  if (_currentResources)
  {
    [_currentResources release];
    _currentResources = nil;
  }
  [self _setupCurrentFile];
  [self tableView:_resourceTable sortDescriptorsDidChange:_resourceTable.sortDescriptors];
  [_resourceTable reloadData];
  [_resourceTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

#pragma mark Private
-(void)_setupCurrentFile
{
  NSInteger row = _resourceFileTable.selectedRow;
  if (row != -1)
  {
    if (nil == _currentResources || nil == _currentBIFF)
    {
      if (_currentResources) [_currentResources release];
      if (_currentBIFF) [_currentBIFF release];
      GameResourceCount* grc = [_biffs objectAtIndex:row];
      _currentBIFF = [grc.biff retain];
      _currentResources = [[_game resourcesForBIFF:_currentBIFF.url ofType:4] retain];
      [self doSearch:self];
    }
  }
}

#pragma mark Resource Table
-(NSInteger)numberOfRowsInResourceTable
{
  [self _setupCurrentFile];
  if (_indices) return _indices.count;
  return (_currentResources)? _currentResources.count : 0;
}

-(id)resourcObjectValueForTableColumn:(NSTableColumn*)col
     row:(NSInteger)row
{
  id val = @"";
  [self _setupCurrentFile];
  id identifier = [col identifier];
  if (_indices) row = [_indices indexAtIndex:row];
  GameResource* res = [_currentResources objectAtIndex:row];
  if ([identifier isEqual:@"locator"])
  {
    val = [NSString stringWithFormat:@"%d", res.loc & 0x3FFF];
  }
  else if ([identifier isEqual:@"size"])
  {
    val = [NSByteCountFormatter stringFromByteCount:res.len
                                countStyle:NSByteCountFormatterCountStyleFile];
  }
  else if ([identifier isEqual:@"format"])
  {
    val = res.format;
  }
  else if ([identifier isEqual:@"resource"])
  {
    val = [_game.chitin resourceNameForPath:_currentBIFF.url.path index:res.loc & 0x3FFF];
  }
  else if ([identifier isEqual:@"text"])
  {
    NSString* name = [_game.chitin resourceNameForPath:_currentBIFF.url.path index:res.loc & 0x3FFF];
    NSNumber* idx = [_game.tlk indexOfResName:name];
    if (idx) val = [_game.tlk stringAtIndex:[idx unsignedIntValue]];
  }
  return val;
}

-(void)resourceSelectionDidChange
{
  NSString* val = @"";
  NSInteger row = [_resourceTable selectedRow];
  if (row != -1)
  {
    [self _setupCurrentFile];
    if (_indices) row = [_indices indexAtIndex:row];
    GameResource* res = [_currentResources objectAtIndex:row];
    NSString* name = [_game.chitin resourceNameForPath:_currentBIFF.url.path index:res.loc & 0x3FFF];
    NSNumber* idx = [_game.tlk indexOfResName:name];
    if (idx) val = [_game.tlk stringAtIndex:[idx unsignedIntValue]];
  }
  _text.string = val;
}


-(void)resourceTableReturn:(id)sender
{
  #pragma unused (sender)
  NSInteger row = [_resourceTable selectedRow];
  if (row != -1)
  {
    if (_indices) row = [_indices indexAtIndex:row];
    GameResource* resource = [_currentResources objectAtIndex:row];
    NSData* data = [_currentBIFF dataAtOffset:resource.off length:resource.len];
    NSString* title = [_game.chitin resourceNameForPath:_currentBIFF.url.path index:resource.loc & 0x3FFF];
    [_progress setTitle:title];
    [self loadMusicData:data playing:YES];
  }
}

#pragma mark AIFF Export
-(NSString*)resourceExportFileName
{
  NSString* base = [[[_currentBIFF.url path] lastPathComponent]
                     stringByDeletingPathExtension];
  NSInteger row = [_resourceTable selectedRow];
  if (_indices) row = [_indices indexAtIndex:row];
  GameResource* resource = [_currentResources objectAtIndex:row];
  NSString* val = nil;
  if (row != -1)
  {
    val = [_game.chitin resourceNameForPath:[_currentBIFF.url path] index:resource.loc & 0x3FFF];
    if (!val) val = [NSString stringWithFormat:@"%d", resource.loc & 0x3FFF];
  }
  if (val) base = [base stringByAppendingFormat:@"-%@", val];
  return base;
}

-(ACMRenderer* _Nullable)resourceRendererForExport
{
  ACMRenderer* renderer = nil;
  NSInteger row = [_resourceTable selectedRow];
  if (row != -1)
  {
    if (_indices) row = [_indices indexAtIndex:row];
    GameResource* resource = [_currentResources objectAtIndex:row];
    NSData* data = [_currentBIFF dataAtOffset:resource.off length:resource.len];
    renderer = [[ACMRenderer alloc] initWithData:data];
    [renderer setDelegate:self];
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
