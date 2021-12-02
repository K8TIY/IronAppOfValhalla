#import "IAoVGameManager.h"

#define kGameButtonWidth 330
#define kGameButtonHeight 100

// IAoVGame property keys for UI elements
NSString* kGameWindowKey = @"GameWindow";
NSString* kGameButtonKey = @"GameButton";

@interface IAoVGameManager (Private)
-(void)_addGame:(IAoVGame*)game;
-(void)_recalculateButtonFrames;
-(void)_resizeMainWindow;
-(IAoVGame*)_gameForButton:(GameButton*)button;
@end

@implementation IAoVGameManager
@synthesize games = _games;
CWL_SYNTHESIZE_SINGLETON_FOR_CLASS(IAoVGameManager);

-(id)init
{
  self = [super init];
  _games = [[NSMutableArray alloc] init];
  return self;
}

-(void)awakeFromNib
{
  NSError* err = nil;
  NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
  NSArray* bookmarks = [defs objectForKey:@"games"];
  if (bookmarks.count)
  {
    for (NSData* bookmark in bookmarks)
    {
      BOOL stale;
      NSURL* url = [NSURL URLByResolvingBookmarkData:bookmark
                          options:NSURLBookmarkResolutionWithSecurityScope | NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
                          relativeToURL:nil
                          bookmarkDataIsStale:&stale
                          error:&err];
      BOOL ok = [url startAccessingSecurityScopedResource];
      if (!ok) NSLog(@"Problem with startAccessingSecurityScopedResource");
      [self addGameAtURL:url];
    }
  }
  else
  {
    BOOL initialHelp = [defs boolForKey:@"initialHelpShown"];
    if (!initialHelp) [self _showInitialHelp:self];
    else [self openGameDirectory:self];
  }
}

-(void)addGameAtURL:(NSURL*)url
{
  NSError* err = nil;
  IAoVGame* game = [[IAoVGame alloc] initWithURL:url delegate:self error:&err];
  if (!game)
  {
    NSAlert* alert = [NSAlert alertWithError:err];
    [alert runModal];
    return;
  }
  else
  {
    if ([game isLoaded]) [self _addGame:game];
  }
}

-(NSArray<GameWindow*>*)gameWindows
{
  NSMutableArray* windows = [[NSMutableArray alloc] init];
  for (IAoVGame* game in _games)
  {
    id w = [game propertyForKey:kGameWindowKey];
    if (w) [windows addObject:w];
  }
  NSArray* ret = [NSArray arrayWithArray:windows];
  [windows release];
  return ret;
}

#pragma mark Private
-(void)_addGame:(IAoVGame*)game
{
  NSRect frame = NSMakeRect(0, 0, kGameButtonWidth, kGameButtonHeight);
  GameButton* button = [[GameButton alloc] initWithFrame:frame];
  [button setTarget:self];
  [button setDelegate:self];
  [button setAction:@selector(gameButtonAction:)];
  [button setTitle:game.name];
  [button setImage:game.icon];
  button.toolTip = [game.app relativePath];
  [[_mainWindow contentView] addSubview:button];
  [game setProperty:button forKey:kGameButtonKey];
  [_games addObject:game];
  [button release];
  [game release];
  [self _recalculateButtonFrames];
  [self _resizeMainWindow];
}

-(void)_recalculateButtonFrames
{
  NSUInteger n = 0;
  for (IAoVGame* game in [[_games reverseObjectEnumerator] allObjects])
  {
    NSButton* button = [game propertyForKey:kGameButtonKey];
    NSRect frame = NSMakeRect(0, n * kGameButtonHeight,
                              kGameButtonWidth, kGameButtonHeight);
    [button setFrame:frame];
    n++;
  }
}

-(void)_resizeMainWindow
{
  NSUInteger n = [_games count];
  if (n == 0) return;
  [_mainWindow contentView].autoresizingMask = NSViewMaxYMargin;
  NSRect viewScreenFrame = NSMakeRect(0, 0, kGameButtonWidth, kGameButtonHeight * n);
  viewScreenFrame.origin = _mainWindow.frame.origin;
  [_mainWindow setContentSize:viewScreenFrame.size];
  CGFloat titleBarHeight = _mainWindow.frame.size.height - ((NSView*)_mainWindow.contentView).frame.size.height;
  CGSize windowSize = CGSizeMake(viewScreenFrame.size.width, viewScreenFrame.size.height + titleBarHeight);
  float originX = _mainWindow.frame.origin.x + (_mainWindow.frame.size.width - windowSize.width) / 2;
  float originY = _mainWindow.frame.origin.y + (_mainWindow.frame.size.height - windowSize.height) / 2;
  NSRect windowFrame = CGRectMake(originX, originY, windowSize.width, windowSize.height);
  [_mainWindow setFrame:windowFrame display:YES animate:YES];
  _mainWindow.minSize = windowFrame.size;
  _mainWindow.maxSize = windowFrame.size;
  [_mainWindow makeKeyAndOrderFront:self];
}

-(void)_showInitialHelp:(id)sender
{
  [_helpWindow makeKeyAndOrderFront:sender];
}

-(IAoVGame*)_gameForButton:(GameButton*)button
{
  for (IAoVGame* game in [[_games reverseObjectEnumerator] allObjects])
  {
    if ([game propertyForKey:kGameButtonKey] == button)
    {
      return game;
    }
  }
  return nil;
}

#pragma mark GameButtonDelegate protocol
-(void)gameButtonDidClose:(GameButton*)sender
{
  NSAlert* alert = [[NSAlert alloc] init];
  alert.alertStyle = NSAlertStyleWarning;
  alert.showsSuppressionButton = YES;
  alert.messageText = NSLocalizedString(@"Remove game?", nil);
  alert.informativeText = NSLocalizedString(@"You can restore the game by choosing File -> Open Game from the File menu.", nil);
  [alert addButtonWithTitle:NSLocalizedString(@"__ALERT_OK__", nil)];
  [alert addButtonWithTitle:NSLocalizedString(@"__ALERT_CANCEL__", nil)];
  [alert beginSheetModalForWindow:_mainWindow completionHandler:^(NSModalResponse returnCode)
  {
    if (returnCode == NSAlertFirstButtonReturn)
    {
      IAoVGame* game = [self _gameForButton:sender];
      if (game)
      {
        [sender removeFromSuperview];
        GameWindow* gw = [game propertyForKey:kGameWindowKey];
        if (gw) [[gw window] orderOut:self];
        [game deleteDatabase];
        [_games removeObject:game];
        if (!_games.count) [_mainWindow orderOut:self];
        [self _recalculateButtonFrames];
        [self _resizeMainWindow];
      }
      else
      {
        NSLog(@"Can't find game for button %@??", sender);
      }
    }
  }];
}

#pragma mark IBAction
-(IBAction)gameButtonAction:(GameButton*)sender
{
  IAoVGame* game = [self _gameForButton:sender];
  GameWindow* gw = [game propertyForKey:kGameWindowKey];
  if (!gw)
  {
    gw = [[GameWindow alloc] initWithGame:game];
    [game setProperty:gw forKey:kGameWindowKey];
    [gw release];
  }
  [gw showWindow:self];
}

-(IBAction)openGameDirectory:(id)sender
{
  #pragma unused (sender)
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.treatsFilePackagesAsDirectories = YES;
  panel.canCreateDirectories = NO;
  panel.allowsMultipleSelection = NO; // Doesn't seem to work with directories
  panel.resolvesAliases = YES;
  panel.message = NSLocalizedString(@"Locate an Infinity Engine game…", nil);
  [panel beginWithCompletionHandler:^(NSInteger result)
   {
     if (result == NSModalResponseOK)
     {
       [self addGameAtURL:panel.URL];
       [self _resizeMainWindow];
     }
   }];
}

-(IBAction)dismissInitialHelp:(id)sender
{
  [_helpWindow orderOut:sender];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"initialHelpShown"];
  [self openGameDirectory:self];
}

#pragma mark GameDatabaseProgress protocol
-(void)gameDatabaseProgress:(GameDatabase*)gdb
{
  //NSLog(@"PROGRESS: %d of %d total files, GAME %@", gdb.progress.filesLoaded, gdb.progress.files, gdb.game);
  if (gdb.progress.filesLoaded == 0)
  {
    dispatch_async(dispatch_get_main_queue(), ^{
       [_dbProgressPath setStringValue:@""];
       [_dbProgressImage setImage:gdb.game.icon];
       [_dbProgressProgress setDoubleValue:100.0 * ((double)(gdb.progress.filesLoaded)/(double)(gdb.progress.files))];
       [_dbProgressWindow makeKeyAndOrderFront:nil];
    });
  }
  NSUInteger n = gdb.progress.filesLoaded;
  NSUInteger of = gdb.game.biffs.count;
  if (n < of)
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      BIFFData* biff = [gdb.game.biffs objectAtIndex:n];
      if (!biff.url || !biff.url.path)
      {
        NSLog(@"Nil URL from %@, %lu, %lu", biff.url, (unsigned long)gdb.progress.filesLoaded, (unsigned long)gdb.progress.files);
      }
      NSString* path = (biff.url)? biff.url.path : @"";
      [_dbProgressPath setStringValue:path];
      [_dbProgressProgress setDoubleValue:100.0 * ((double)(gdb.progress.filesLoaded)/(double)(gdb.progress.files))];
    });
  }
}

-(void)gameDatabaseFinished:(GameDatabase*)gdb
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [_dbProgressWindow orderOut:self];
    [self _addGame:gdb.game];
  });
}
@end

/*
Copyright © 2010-2021, BLUGS.COM LLC

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
