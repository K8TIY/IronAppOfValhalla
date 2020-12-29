#import "GameWindow.h"
#import "IAoVGameManager.h"
#import "BIFFData.h"
#import "MUSData.h"
#import "GameWindow_Resources.h"
#import "GameWindow_Music.h"
#import "GameWindow_Voices.h"

@implementation MUSFile
@synthesize url = _url;
@synthesize title = _title;
-(id)initWithURL:(NSURL*)url title:(NSString*)title
{
  self = [super init];
  _url = [url retain];
  _title = [title retain];
  return self;
}

-(void)dealloc
{
  if (_url) [_url release];
  if (_title) [_title release];
  [super dealloc];
}
@end

// Subclass that can detect spacebar and send notification to its delegate.
@implementation IAoVWindow
-(void)sendEvent:(NSEvent*)event
{
  BOOL handled = NO;
  if (event.type == NSKeyUp)
  {
    if ([[event charactersIgnoringModifiers] isEqualToString:@" "])
    {
      id del = [self delegate];
      if (del && [del respondsToSelector:@selector(windowDidReceiveSpace:)])
        handled = [del windowDidReceiveSpace:self];
    }
  }
  if (!handled) [super sendEvent:event];
}
@end

NSImage* gPlayImage = nil;
NSImage* gPlayPressedImage = nil;
NSImage* gPauseImage = nil;
NSImage* gPausePressedImage = nil;


static CFStringRef gMaleSuff = CFSTR(" \u2642");
static CFStringRef gFemaleSuff = CFSTR(" \u2640");

@interface GameWindow (Private)
-(void)_updateTimeDisplay;
-(void)_suspendOthers;
-(void)_resumeOther;
@end

@implementation GameWindow
+(void)initialize
{
  NSBundle* mb = [NSBundle mainBundle];
  gPlayImage = [[NSImage alloc] initWithContentsOfFile:[mb pathForImageResource:@"play"]];
  gPlayPressedImage = [[NSImage alloc] initWithContentsOfFile:[mb pathForImageResource:@"play_blue"]];
  gPauseImage = [[NSImage alloc] initWithContentsOfFile:[mb pathForImageResource:@"pause"]];
  gPausePressedImage = [[NSImage alloc] initWithContentsOfFile:[mb pathForImageResource:@"pause_blue"]];
}

-(id)initWithGame:(IAoVGame*)game
{
  self = [super initWithWindowNibName:@"GameWindow"];
  _game = [game retain];
  _biffs = [_game getBIFFsAndResourceCountsForType:4];
  [_biffs retain];
  NSMutableArray* tmp = [[NSMutableArray alloc] init];
  for (NSURL* url in _game.muss)
  {
    MUSFile* f = [[MUSFile alloc] initWithURL:url title:[_game trackTitleForURL:url]];
    [tmp addObject:f];
    [f release];
  }
  NSArray* sorted = [tmp sortedArrayUsingComparator:^NSComparisonResult(MUSFile* a, MUSFile* b) {
    NSString* first = [a.url lastPathComponent];
    NSString* second = [b.url lastPathComponent];
    return [first localizedStandardCompare:second];}];
  _musFiles = [[NSArray alloc] initWithArray:sorted];
  [tmp release];
  return self;
}

-(void)dealloc
{
  if (_game) [_game release];
  if (_biffs) [_biffs release];
  if (_musFiles) [_musFiles release];
  if (_voiceLocalizations) [_voiceLocalizations release];
  [super dealloc];
}

-(void)awakeFromNib
{
  [_startStopButton setImage:gPlayImage];
  [_startStopButton setAlternateImage:gPlayPressedImage];
  NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
  float ampVal = [defs floatForKey:@"defaultVol"];
  BOOL loop = [defs boolForKey:@"defaultLoop"];
  [_loopButton setState:(loop)? NSOnState : NSOffState];
  [_renderer setDoesLoop:loop];
  [_ampSlider setDoubleValue:ampVal];
  [_resourceTable setDoubleAction:@selector(resourceTableReturn:)];
  [_musicTable setDoubleAction:@selector(musicTableReturn:)];
  [_voiceTable setDoubleAction:@selector(voiceTableReturn:)];
  [[self window] setTitle:_game.name];
  [[self window] setFrameAutosaveName:_game.url.absoluteString];
  [_progress setDelegate:self];
  for (NSTableColumn* col in _musicTable.tableColumns)
  {
    if ([col.identifier compare:@"file"] == NSOrderedSame)
    {
      id cell = [col dataCell];
      [cell setFont: [NSFont fontWithName:@"Menlo" size:12.0]];
    }
  }
  for (NSTableColumn* col in _resourceFileTable.tableColumns)
  {
    if ([col.identifier compare:@"file"] == NSOrderedSame)
    {
      id cell = [col dataCell];
      [cell setFont: [NSFont fontWithName:@"Menlo" size:12.0]];
    }
  }
  NSTableColumn* col = [_resourceTable.tableColumns objectAtIndex:0];
  NSSortDescriptor* desc = [NSSortDescriptor sortDescriptorWithKey:@"loc"
                                             ascending:YES selector:@selector(compare:)];
  [col setSortDescriptorPrototype:desc];
  col = [_resourceTable.tableColumns objectAtIndex:1];
  desc = [NSSortDescriptor sortDescriptorWithKey:@"format"
                           ascending:YES selector:@selector(compare:)];
  [col setSortDescriptorPrototype:desc];
  col = [_resourceTable.tableColumns objectAtIndex:2];
  desc = [NSSortDescriptor sortDescriptorWithKey:@"len"
                           ascending:YES selector:@selector(compare:)];
  [col setSortDescriptorPrototype:desc];
  col = [_resourceTable.tableColumns objectAtIndex:3];
  desc = [NSSortDescriptor sortDescriptorWithKey:@"name"
                           ascending:YES selector:@selector(compare:)];
  [col setSortDescriptorPrototype:desc];
  col = [_resourceTable.tableColumns objectAtIndex:4];
  desc = [NSSortDescriptor sortDescriptorWithKey:@"string"
                           ascending:YES selector:@selector(localizedStandardCompare:)];
  [col setSortDescriptorPrototype:desc];
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
  [_resourceTable sizeLastColumnToFit];
  [_resourceFileTable sizeLastColumnToFit];
  [_musicTable sizeLastColumnToFit];
  [_voiceTable sizeLastColumnToFit];
  NSString* autosave = [defs stringForKey:[NSString stringWithFormat:@"NSWindow Frame %@", _game.url.absoluteString]];
  if (!autosave)
  {
    NSRect screenSize = [[NSScreen mainScreen] frame];
    CGFloat percent = 0.6;
    CGFloat offset = (1.0 - percent) / 2.0;
    [[self window] setFrame:NSMakeRect(screenSize.size.width * offset,
                                       screenSize.size.height * offset,
                                       screenSize.size.width * percent,
                                       screenSize.size.height * percent)
                   display:YES];
  }
}

-(BOOL)playing
{
  return (_renderer && _renderer.playing);
}

-(void)suspend
{
  if (_renderer.playing)
  {
    [_renderer stop];
    _suspendedInBackground = YES;
  }
}

-(void)resume
{
  if (_suspendedInBackground)
  {
    [_renderer start];
    _suspendedInBackground = NO;
  }
}

-(BOOL)isSuspended
{
  return _suspendedInBackground;
}

-(void)loadMusicData:(NSData*)data playing:(BOOL)play
{
  if (_renderer)
  {
    [_renderer stop];
    [_renderer release];
    _renderer = nil;
  }
  _renderer = [[ACMRenderer alloc] initWithData:data];
  [_renderer setDelegate:self];
  [_renderer setAmp:[_ampSlider floatValue]];
  [_renderer setDoesLoop:([_loopButton state] == NSOnState)];
  if (play) [self startStop:self];
}

-(void)loadMUSData:(MUSData*)data playing:(BOOL)play
{
  if (_renderer)
  {
    [_renderer stop];
    [_renderer release];
    _renderer = nil;
  }
  _renderer = [[ACMRenderer alloc] initWithMUSData:data];
  [_renderer setDelegate:self];
  [_renderer setAmp:[_ampSlider floatValue]];
  [_renderer setDoesLoop:([_loopButton state] == NSOnState)];
  if (play) [self startStop:self];
}

-(void)windowDidBecomeMain:(NSNotification*)note
{
  #pragma unused (note)
  if (_renderer.playing || _suspendedInBackground)
    [self _suspendOthers];
  [self resume];
}

#pragma mark Action
-(IBAction)startStop:(id)sender
{
  #pragma unused (sender)
  if (_renderer && _renderer.playing)
  {
    [_renderer stop];
    [_startStopButton setImage:gPlayImage];
    [_startStopButton setAlternateImage:gPlayPressedImage];
    [self _resumeOther];
  }
  else
  {
    [self _suspendOthers];
    [_renderer start];
    [_startStopButton setImage:gPauseImage];
    [_startStopButton setAlternateImage:gPausePressedImage];
    [self _updateTimeDisplay];
  }
}

-(IBAction)rewind:(id)sender
{
  #pragma unused (sender)
  [_renderer gotoPct:0.0];
  [_progress setDoubleValue:0.0];
  [self _updateTimeDisplay];
}

-(IBAction)setAmp:(id)sender
{
  #pragma unused (sender)
  if (_renderer)
  {
    float ampVal = [_ampSlider floatValue];
    [_renderer setAmp:ampVal];
  }
}

-(IBAction)setAmpLo:(id)sender
{
  #pragma unused (sender)
  float ampVal = 0.0f;
  [_ampSlider setFloatValue:ampVal];
  [_renderer setAmp:ampVal];
}

-(IBAction)setAmpHi:(id)sender
{
  #pragma unused (sender)
  float ampVal = 1.0f;
  [_ampSlider setFloatValue:ampVal];
  [_renderer setAmp:ampVal];
}

-(IBAction)setProgress:(id)sender
{
  #pragma unused (sender)
  BOOL playing = _renderer.playing;
  [_renderer stop];
  [_renderer gotoPct:_progress.trackingValue];
  if (playing) [_renderer start];
}

-(IBAction)IAoVProgressViewValueChanged:(id)sender
{
  #pragma unused (sender)
  BOOL playing = _renderer.playing;
  [_renderer stop];
  [_renderer gotoPct:_progress.trackingValue];
  if (playing) [_renderer start];
}

-(IBAction)setLoop:(id)sender
{
  #pragma unused (sender)
  [_renderer setDoesLoop:([_loopButton state] == NSOnState)];
  [self _updateTimeDisplay];
}

/*-(ACMRenderer*)copyRendererForAIFFExport
{
  return [_renderer copy];
}*/

#pragma mark Delegate
-(void)windowWillClose:(NSNotification*)note
{
  #pragma unused (note)
  [_renderer setDelegate:nil];
  [_renderer stop];
  [self _resumeOther];
}

#pragma mark Notification
-(void)acmDidFinishPlaying:(id)sender
{
  #pragma unused (sender)
  [_renderer stop];
  [_renderer gotoPct:0.0];
  [_startStopButton setImage:gPlayImage];
  [_startStopButton setAlternateImage:gPlayPressedImage];
  [self _resumeOther];
}

-(void)acmProgress:(id)renderer
{
  #pragma unused (renderer)
  if (_renderer && _progress)
  {
    [_progress setDoubleValue:[_renderer pct]];
    [self _updateTimeDisplay];
  }
}

#pragma mark Internal
-(void)_updateTimeDisplay
{
  //printf("Update time display\n");
  [_progress setDoubleValue:_renderer.pct];
  [_progress setLoopPct:[_renderer loopPct]];
  [_progress setLength:_renderer.seconds];
  double ep = [_renderer epiloguePct];
  [_progress setEpiloguePct:ep];
  NSColor* cols[] = {IAoVProgressViewACMColor, IAoVProgressViewOGGColor,
                     IAoVProgressViewWAVColor};
  if (_renderer.format < 3)
  {
      [_progress setColor:cols[_renderer.format]];
  }
  if (_renderer.currentURL)
  {
    NSString* title = _renderer.currentURL.lastPathComponent;
    [_progress setTitle:title];
  }
}

-(void)_suspendOthers
{
  NSArray<GameWindow*>* docs = [[IAoVGameManager sharedIAoVGameManager] gameWindows];
  for (GameWindow* doc in docs)
  {
    if (doc != self)
    {
      if ([doc isMemberOfClass:[self class]] &&
          [doc respondsToSelector:@selector(suspend)])
      {
        [doc suspend];
      }
    }
  }
}

-(void)_resumeOther
{
  NSArray* docs = [[NSDocumentController sharedDocumentController] documents];
  for (GameWindow* doc in docs)
  {
    if (doc != self)
    {
      if ([doc isKindOfClass:[self class]] &&
          [doc respondsToSelector:@selector(resume)] &&
          [doc respondsToSelector:@selector(isSuspended)])
      {
        if ([doc isSuspended])
        {
          [doc resume];
          break;
        }
      }
    }
  }
}

#pragma mark Action
-(IBAction)doSearch:(id)sender
{
  #pragma unused (sender)
  [self doMusicSearch];
  [self doResourceSearch];
  [self doVoiceSearch];
}

-(IBAction)localizationChanged:(NSPopUpButton*)sender
{
  NSMenuItem* selection = sender.selectedItem;
  GameLocalization* localization = selection.representedObject;
  NSRange range = [sender.selectedItem.title rangeOfString:(NSString*)gFemaleSuff
                                             options:NSCaseInsensitiveSearch];
  [_game setLocalization:localization female:(range.length > 0)];
  [self doSearch:self];
  [_resourceTable reloadData];
  [self resourceSelectionDidChange];
  [_voiceTable reloadData];
}

#pragma mark Table View Data Sources
-(NSInteger)numberOfRowsInTableView:(NSTableView*)tv
{
  if (tv == _resourceFileTable)
  {
    return _biffs.count;
  }
  else if (tv == _resourceTable)
  {
    return [self numberOfRowsInResourceTable];
  }
  else if (tv == _musicTable)
  {
    return [self numberOfRowsInMusicTable];
  }
  return 0;
}

-(id)tableView:(NSTableView*)tv
     objectValueForTableColumn:(NSTableColumn*)col
     row:(NSInteger)row
{
  if (tv == _resourceFileTable)
  {
    return [self resourceFileObjectValueForTableColumn:col row:row];
  }
  if (tv == _resourceTable)
  {
    return [self resourcObjectValueForTableColumn:col row:row];
  }
  else if (tv == _musicTable)
  {
    return [self musicObjectValueForTableColumn:col row:row];
  }
  return @"";
}

-(void)tableView:(NSTableView*)tv sortDescriptorsDidChange:(NSArray<NSSortDescriptor*>*)oldDescriptors
{
  #pragma unused (oldDescriptors)
  if (tv == _resourceFileTable)
  {
    NSArray* sorted = [_biffs sortedArrayUsingDescriptors:tv.sortDescriptors];
    NSArray* toRelease = _biffs;
    _biffs = [[NSArray alloc] initWithArray:sorted];
    [toRelease release];
  }
  else if (tv == _resourceTable)
  {
    NSArray* sorted = [_currentResources sortedArrayUsingDescriptors:tv.sortDescriptors];
    NSArray* toRelease = _currentResources;
    _currentResources = [[NSArray alloc] initWithArray:sorted];
    [toRelease release];
    [self doSearch:self];
  }
  else if (tv == _musicTable)
  {
    NSArray* sorted = [_musFiles sortedArrayUsingDescriptors:tv.sortDescriptors];
    NSArray* toRelease = _musFiles;
    _musFiles = [[NSArray alloc] initWithArray:sorted];
    [toRelease release];
  }
  [tv reloadData];
}

#pragma mark Delegate
-(void)tableViewSelectionDidChange:(NSNotification*)note
{
  if (note.object == _resourceFileTable)
  {
    [self resourceFileSelectionDidChange];
  }
  else if (note.object == _resourceTable)
  {
    [self resourceSelectionDidChange];
  }
}

-(BOOL)tableView:(NSTableView*)tv shouldEditTableColumn:(NSTableColumn*)col
       row:(NSInteger)row
{
  #pragma unused (tv, col, row)
  return NO;
}

-(BOOL)windowDidReceiveSpace:(id)sender
{
  #pragma unused (sender)
  if (self.window.firstResponder == _search)
    return NO;
  if (_renderer)
  {
    [self startStop:self];
    return YES;
  }
  return NO;
}

-(void)tableView:(IAoVTableView*)tv didReceiveReturn:(NSEvent*)evt
{
  #pragma unused (evt)
  if (tv == _musicTable) [self musicTableReturn:tv];
  else if (tv == _resourceTable) [self resourceTableReturn:tv];
}

#pragma mark Delegate
-(BOOL)splitView:(NSSplitView*)sv shouldAdjustSizeOfSubview:(NSView*)view
{
  #pragma unused (sv)
  return (view != _resourceFileScrollView);
}

-(BOOL)validateMenuItem:(NSMenuItem*)item
{
  BOOL valid = YES;
  SEL action = [item action];
  if (action == @selector(exportAIFF:))
  {
    valid = NO;
    NSTabViewItem* tvi = [_tabs selectedTabViewItem];
    if ([[tvi identifier] isEqualToString:@"resources"])
    {
      valid = [_resourceTable numberOfSelectedRows] > 0;
    }
    if ([[tvi identifier] isEqualToString:@"music"])
    {
      valid = [_musicTable numberOfSelectedRows] > 0;
    }
    if ([[tvi identifier] isEqualToString:@"voices"])
    {
      valid = [self voiceSelectionHasSound];
    }
  }
  return valid;
}

#pragma mark Export
-(IBAction)exportAIFF:(id)sender
{
  #pragma unused (sender)
  _exportPanel = [NSSavePanel savePanel];
  _exportPanel.extensionHidden = NO;
  _exportPanel.canSelectHiddenExtension = YES;
  [_exportPanel setAllowedFileTypes:@[@"aiff"]];
  _exportPanel.nameFieldStringValue = [self exportFileName];
  [_exportPanel beginSheetModalForWindow:[self window]
                completionHandler:^(NSModalResponse returnCode)
  {
    if (NSModalResponseOK == returnCode)
    {
      NSURL* url = [_exportPanel URL];
      ACMRenderer* r = [[self rendererForExport] retain];
      [r exportToURL:url ofType:kAudioFileAIFFType];
      [r release];
    }
  }];
}

-(NSString*)exportFileName
{
  NSString* str = @"";
  NSTabViewItem* tvi = [_tabs selectedTabViewItem];
  if ([[tvi identifier] isEqualToString:@"resources"])
  {
    str = [self resourceExportFileName];
  }
  if ([[tvi identifier] isEqualToString:@"music"])
  {
    str = [self musicExportFileName];
  }
  if ([[tvi identifier] isEqualToString:@"voices"])
  {
    str = [self voiceExportFileName];
  }
  return str;
}

-(ACMRenderer* _Nullable)rendererForExport
{
  ACMRenderer* renderer = nil;
  NSTabViewItem* tvi = [_tabs selectedTabViewItem];
  if ([[tvi identifier] isEqualToString:@"music"])
  {
    renderer = [self musicRendererForExport];
  }
  if ([[tvi identifier] isEqualToString:@"resources"])
  {
    renderer = [self resourceRendererForExport];
  }
  if ([[tvi identifier] isEqualToString:@"voices"])
  {
    renderer = [self voiceRendererForExport];
  }
  return renderer;
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
