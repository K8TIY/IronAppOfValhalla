/*
 * Copyright © 2010-2018, Brian "Moses" Hall
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
#import "BIFFDocument.h"
#import "Onizuka.h"

static CFStringRef gMaleSuff = CFSTR(" \u2642");
static CFStringRef gFemaleSuff = CFSTR(" \u2640");

@implementation NSIndexSet (IndexAtIndex)
-(NSUInteger)indexAtIndex:(NSUInteger)anIndex
{
  if (anIndex >= [self count]) return NSNotFound;
  NSUInteger idx = [self firstIndex];
  for (NSUInteger i = 0; i < anIndex; i++)
    idx = [self indexGreaterThanIndex:idx];
  return idx;
}
@end

@interface BIFFDocument (Private)
-(void)_tableReturn:(id)sender;
/*-(void)_endSheet:(NSPanel*)sheet returnCode:(int)code
       contextInfo:(void*)ctx;*/
@end


@implementation BIFFDocument
-(id)initWithGame:(ACMGame*)game biff:(BIFFData*)biff
{
  self = [super initWithWindowNibName:@"BIFFDocument"];
  _game = [game retain];
  _biff = [biff retain];
  _lastSelectedRow = -1;
  _resources = [_game resourcesForBIFF:biff.url ofType:4];
  [_resources retain];
  return self;
}

-(void)dealloc
{
  if (_indices) [_indices release];
  if (_game) [_game release];
  if (_biff) [_biff release];
  if (_resources) [_resources release];
  [super dealloc];
}

-(void)awakeFromNib
{
  //_mainWindow = _docWindow;
  [super awakeFromNib];
  [_table setTarget:self];
  [_table setDoubleAction:@selector(doubleClick:)];
  NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
  BOOL loop = [defs floatForKey:@"defaultLoopBIFF"];
  [_renderer setDoesLoop:loop];
  [_loopButton setState:(loop)? NSOnState:NSOffState];
  [_docWindow setTitle:[_biff.url lastPathComponent]];
  NSLocale* locale = [NSLocale currentLocale];
  for (GameLocalization* loc in _game.localizations)
  {
    NSDictionary* languageDic = [NSLocale componentsFromLocaleIdentifier:loc.language];
    NSString* countryCode = [languageDic objectForKey:@"kCFLocaleCountryCodeKey"]; //==>countryCode = "US"
    //NSString* languageCode = [languageDic objectForKey:@"kCFLocaleLanguageCodeKey"]; //==> languageCode = "en"
    //NSString* scriptCode = [languageDic objectForKey:@"kCFLocaleScriptCodeKey"]; //==> scriptCode = "en"
    int genderCount = (loc.male && loc.female)? 2 : 1;
    NSString* gender = (genderCount == 1)? @"" : (NSString*)gMaleSuff;
    NSString* title = [[NSString alloc] initWithFormat:@"%@%@", [locale localizedStringForLanguageCode:loc.language], gender];
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
    [title release];
    item.representedObject = loc;
    item.image = [NSImage imageNamed:countryCode];
    [_languageMenu.menu addItem:item];
    if (_game.localization == loc) [_languageMenu selectItem:item];
    [item release];
    if (genderCount > 1)
    {
      title = [[NSString alloc] initWithFormat:@"%@%@", [locale localizedStringForLanguageCode:loc.language], gFemaleSuff];
      item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
      [title release];
      item.representedObject = loc;
      item.image = [NSImage imageNamed:countryCode];
      [_languageMenu.menu addItem:item];
      if (_game.localization == loc) [_languageMenu selectItem:item];
      [item release];
    }
  }
}

-(IBAction)localizationChanged:(NSPopUpButton*)sender
{
  NSMenuItem* selection = sender.selectedItem;
  GameLocalization* localization = selection.representedObject;
  [_game setLocalization:localization];
  [_table reloadData];
  [self tableViewSelectionDidChange:nil];
}

-(void)windowWillClose:(NSNotification*)note
{
  #pragma unused (note)
  if (_renderer)
  {
    [_renderer setDelegate:nil];
    [_renderer stop];
    [_renderer release];
    _renderer = nil;
  }
  if (_biff) [_biff unload];
}

-(BOOL)validateMenuItem:(NSMenuItem*)item
{
  SEL action = [item action];
  if (action == @selector(exportAIFF:))
  {
    if (1 != [_table numberOfSelectedRows]) return NO;
  }
  return YES;
}

-(ACMRenderer*)copyRendererForAIFFExport
{
  ACMRenderer* r = nil;
  NSUInteger row = [_table selectedRow];
  if (row != -1)
  {
    if (_indices) row = [_indices indexAtIndex:row];
    GameResource* res = [_resources objectAtIndex:row];
    NSData* data = [_biff dataAtOffset:res.off length:res.len];
    r = [[ACMRenderer alloc] initWithData:data];
  }
  return r;
}

-(NSString*)AIFFFilename
{
  NSString* base = [[[_biff.url path] lastPathComponent]
                     stringByDeletingPathExtension];
  NSInteger row = [_table selectedRow];
  if (_indices) row = [_indices indexAtIndex:row];
  GameResource* resource = [_resources objectAtIndex:row];
  NSString* val = nil;
  if (row != -1)
  {
    val = [_game.chitin resourceNameForPath:[_biff.url path] index:resource.loc & 0x3FFF];
    if (!val) val = [NSString stringWithFormat:@"%d", resource.loc & 0x3FFF];
  }
  if (val) base = [base stringByAppendingFormat:@"-%@", val];
  return [base stringByAppendingPathExtension:@"aiff"];
}

#pragma mark Action
-(IBAction)doSearch:(id)sender
{
  NSString* s = [sender stringValue];
  BOOL reload = NO;
  if (_indices)
  {
    [_indices release];
    _indices = nil;
    reload = YES;
  }
  if (s && [s length])
  {
    _indices = [[NSMutableIndexSet alloc] init];
    NSUInteger n = [_resources count];
    NSUInteger i;
    for (i = 0; i < n; i++)
    {
      GameResource* resource = [_resources objectAtIndex:i];
      NSString* name = [_game.chitin resourceNameForPath:[_biff.url path] index:resource.loc & 0x3FFF];
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
    [_table reloadData];
    [self tableViewSelectionDidChange:nil];
  }
}

-(IBAction)startStop:(id)sender
{
  #pragma unused (sender)
  if (!_renderer)
  {
    NSInteger row = [_table selectedRow];
    if (row != -1)
    {
      if (_indices) row = [_indices indexAtIndex:row];
      GameResource* res = [_resources objectAtIndex:row];
      NSData* data = [_biff dataAtOffset:res.off length:res.len];
      _renderer = [[ACMRenderer alloc] initWithData:data];
      [_renderer setDelegate:self];
      [_renderer setAmp:[_ampSlider floatValue]];
      [_renderer setDoesLoop:([_loopButton state] == NSOnState)];
    }
  }
  if (_renderer) [super startStop:self];
}

#pragma mark Delegate
-(void)windowDidReceiveSpace:(id)sender
{
  NSInteger row = [_table selectedRow];
  if (row != -1)
  {
    if (_indices) row = [_indices indexAtIndex:row];
    if (row != _lastSelectedRow)
    {
      if (_renderer)
      {
        [_renderer stop];
        [_renderer release];
        _renderer = nil;
      }
      GameResource* resource = [_resources objectAtIndex:row];
      NSData* data = [_biff dataAtOffset:resource.off length:resource.len];
      _renderer = [[ACMRenderer alloc] initWithData:data];
      [_renderer setDelegate:self];
      [_renderer setAmp:[_ampSlider floatValue]];
      [_renderer setDoesLoop:([_loopButton state] == NSOnState)];
      _lastSelectedRow = row;
    }
  }
  [super startStop:sender];
}

#pragma mark Delegate
-(void)tableView:(ACMTableView*)tv didReceiveReturn:(NSEvent*)evt
{
  #pragma unused (evt)
  [self _tableReturn:tv];
}

#pragma mark Internal
-(void)_tableReturn:(id)sender
{
  #pragma unused (sender)
  // FIXME: remove duplication with windowDidReceiveSpace:
  NSInteger row = [_table selectedRow];
  if (row != -1)
  {
    /*if (_renderer)
    {
      [_renderer stop];
      [_renderer release];
      _renderer = nil;
    }*/
    if (_indices) row = [_indices indexAtIndex:row];
    GameResource* resource = [_resources objectAtIndex:row];
    NSData* data = [_biff dataAtOffset:resource.off length:resource.len];
    /*_renderer = [[ACMRenderer alloc] initWithData:data];
    [_renderer setDelegate:self];
    [_renderer setAmp:[_ampSlider floatValue]];
    [_renderer setDoesLoop:([_loopButton state] == NSOnState)];*/
    _lastSelectedRow = row;
    NSString* title = [_game.chitin resourceNameForPath:_biff.url.path index:resource.loc & 0x3FFF];
    [_oy setTitle:title];
    [self loadMusicData:data playing:YES];
    /*[super startStop:self];*/
  }
}

/*-(void)_endSheet:(NSPanel*)sheet returnCode:(int)code
       contextInfo:(void*)ctx
{
  #pragma unused (sheet,code)
  if ([(id)ctx isEqualToString:@"__NO_SOUNDS__"])
    [self close];
}*/

#pragma mark Table Data Source
-(NSInteger)numberOfRowsInTableView:(NSTableView*)tv
{
  #pragma unused (tv)
  NSInteger cnt = 0;
  if (_indices) cnt = [_indices count];
  else cnt = [_resources count];
  return cnt;
}

-(id)tableView:(NSTableView*)tv objectValueForTableColumn:(NSTableColumn*)col
     row:(NSInteger)row
{
  #pragma unused (tv)
  id identifier = [col identifier];
  id val = nil;
  if (_indices) row = [_indices indexAtIndex:row];
  GameResource* res = [_resources objectAtIndex:row];
  if ([identifier isEqual:@"locator"])
  {
    val = [NSString stringWithFormat:@"%d", res.loc & 0x3FFF];
  }
  else if ([identifier isEqual:@"length"])
  {
    //char buff[SIZE_BUFSZ];
    //format_size(buff, res.len);
    //val = [NSString stringWithCString:buff encoding:NSUTF8StringEncoding];
    val = [NSByteCountFormatter stringFromByteCount:res.len
                                countStyle:NSByteCountFormatterCountStyleFile];
  }
  else if ([identifier isEqual:@"format"])
  {
    val = res.format;
  }
  else if ([identifier isEqual:@"resource"])
  {
    val = [_game.chitin resourceNameForPath:_biff.url.path index:res.loc & 0x3FFF];
  }
  else if ([identifier isEqual:@"text"])
  {
    NSString* name = [_game.chitin resourceNameForPath:_biff.url.path index:res.loc & 0x3FFF];
    NSNumber* idx = [_game.tlk indexOfResName:name];
    if (idx) val = [_game.tlk stringAtIndex:[idx unsignedIntValue]];
  }
  return val;
}

-(BOOL)tableView:(NSTableView*)tv shouldEditTableColumn:(NSTableColumn*)col
       row:(NSInteger)row
{
  #pragma unused (tv,col,row)
  return NO;
}

-(void)doubleClick:(id)sender
{
  [self _tableReturn:sender];
}

-(void)tableViewSelectionDidChange:(NSNotification*)note
{
  #pragma unused (note)
  if ([_table numberOfSelectedRows] == 1)
  {
    NSInteger row = [_table selectedRow];
    if (_indices) row = [_indices indexAtIndex:row];
    GameResource* res = [_resources objectAtIndex:row];
    NSString* name = [_game.chitin resourceNameForPath:[_biff.url path] index:res.loc & 0x3FFF];
    NSString* val = @"";
    if ([name length])
    {
      NSNumber* idx = [_game.tlk indexOfResName:name];
      if (idx) val = [_game.tlk stringAtIndex:[idx unsignedIntValue]];
    }
    if (val) [_text setString:val];
  }
}
@end

