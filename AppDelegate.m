#import "AppDelegate.h"
#import "ACMGame.h"
#import "GameWindow.h"
#import "GameButton.h"

@implementation AppDelegate

#define kGameButtonWidth 90
#define kGameButtonHeight 110

// If the user has not set up a set of game locations, this prompts them for
// the first location.
-(void)applicationDidFinishLaunching:(NSNotification*)note
{
  //NSWindow.allowsAutomaticWindowTabbing = NO;
  NSError* err = nil;
  NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
  _games = [[NSMutableArray alloc] init];
  _buttons = [[NSMutableArray alloc] init];
  _gameWindows = [[NSMutableArray alloc] init];
  NSArray* bookmarks = [defs objectForKey:@"games"];
  for (NSData* bookmark in bookmarks)
  {
    BOOL stale;
    NSURL* url = [NSURL URLByResolvingBookmarkData:bookmark
                        options:NSURLBookmarkResolutionWithSecurityScope | NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
                        relativeToURL:nil
                        bookmarkDataIsStale:&stale
                        error:&err];
    BOOL ok = [url startAccessingSecurityScopedResource];
    //NSLog(@"BOOKMARK: %@, stale %s, success %s (err %@)", url, (stale)? "YES":"NO", (ok)? "YES":"NO", err);
    [self addGameAtURL:url];
    [self addGamesToMainWindow:_games];
  }
  if (0 == bookmarks.count) [self openGameDirectory:self];
  
}

-(IBAction)openGameDirectory:(id)sender
{
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.treatsFilePackagesAsDirectories = YES;
  panel.canCreateDirectories = NO;
  panel.allowsMultipleSelection = NO; // Doesn't seem to work with directories
  panel.resolvesAliases = YES;
  panel.message = NSLocalizedString(@"Locate an Infinity Engine game…", @"Locate an Infinity Engine game…");
  [panel beginWithCompletionHandler:^(NSInteger result)
   {
     if (result == NSModalResponseOK)
     {
       [self addGameAtURL:panel.URL];
       [self addGamesToMainWindow:_games];
     }
   }];
}

// Create new content view, add buttons, swap into main window and animate
-(void)addGamesToMainWindow:(NSArray*)games
{
  NSUInteger n = [games count];
  if (n == 0) return;
  //NSLog(@"%ul rows", rows);
  [_mainWindow contentView].autoresizingMask = NSViewMaxYMargin;
  NSRect viewScreenFrame = NSMakeRect(0, 0, kGameButtonWidth * n, kGameButtonHeight);
  viewScreenFrame.origin = _mainWindow.frame.origin;
  [_mainWindow setContentSize:viewScreenFrame.size];
  [self resizeWindowWithContentSize:viewScreenFrame.size animated:YES];
  [_mainWindow makeKeyAndOrderFront:self];
}

-(void)addGameAtURL:(NSURL*)url
{
  NSError* err = nil;
  ACMGame* game = [[ACMGame alloc] initWithURL:url error:&err];
  if (!game)
  {
    NSAlert* alert = [NSAlert alertWithError:err];
    [alert runModal];
    return;
  }
  [_games addObject:game];
  NSUInteger n = [_games count];
  NSRect frame = NSMakeRect((n - 1) * kGameButtonWidth, 0,
                            kGameButtonWidth, kGameButtonHeight);
  GameButton* myButton = [[GameButton alloc] initWithFrame:frame];
  [myButton setTarget:self];
  [myButton setAction:@selector(gameButtonAction:)];
  [myButton setTitle:game.name];
  [myButton setImage:game.icon];
  myButton.tag = n;
  myButton.toolTip = [game.app relativePath];
  [[_mainWindow contentView] addSubview:myButton];
  [_buttons addObject:myButton];
  [_gameWindows addObject:[NSNull null]];
  [myButton release];
}

-(void)gameButtonDismissed:(GameButton*)sender
{
  //NSLog(@"Need to remove game button with tag %d", [sender tag]);
  NSUInteger tag = sender.tag;
  [sender removeFromSuperview];
  [_games removeObjectAtIndex:tag - 1];
  [_buttons removeObjectAtIndex:tag - 1];
  NSRect viewScreenFrame = NSMakeRect(0, 0, kGameButtonWidth * _games.count, kGameButtonHeight);
  viewScreenFrame.origin = _mainWindow.frame.origin;
  [_mainWindow setContentSize:viewScreenFrame.size];
  [self resizeWindowWithContentSize:viewScreenFrame.size animated:YES];
}


-(void)resizeWindowWithContentSize:(NSSize)contentSize animated:(BOOL)animated
{
  CGFloat titleBarHeight = _mainWindow.frame.size.height - ((NSView*)_mainWindow.contentView).frame.size.height;
  CGSize windowSize = CGSizeMake(contentSize.width, contentSize.height + titleBarHeight);
  // Optional: keep it centered
  float originX = _mainWindow.frame.origin.x + (_mainWindow.frame.size.width - windowSize.width) / 2;
  float originY = _mainWindow.frame.origin.y + (_mainWindow.frame.size.height - windowSize.height) / 2;
  NSRect windowFrame = CGRectMake(originX, originY, windowSize.width, windowSize.height);
  //NSLog(@"Setting window frame to %@", NSStringFromRect(windowFrame));
  [_mainWindow setFrame:windowFrame display:YES animate:animated];
  _mainWindow.minSize = windowFrame.size;
  _mainWindow.maxSize = windowFrame.size;
}

-(void)applicationWillTerminate:(NSNotification*)note
{
  NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
  NSMutableArray* bookmarks = [[NSMutableArray alloc] init];
  for (ACMGame* game in _games)
  {
    NSData* data = [game.url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope | NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
                             includingResourceValuesForKeys:[NSArray array]
                              relativeToURL:nil error:nil];
    [bookmarks addObject:data];
  }
  [defs setValue:bookmarks forKey:@"games"];
  //[defs setValue:[NSArray array] forKey:@"games"];
  [bookmarks release];
}

-(IBAction)gameButtonAction:(NSButton*)sender
{
  NSUInteger tag = sender.tag;
  ACMGame* game = [_games objectAtIndex:tag - 1];
  GameWindow*  gw = [_gameWindows objectAtIndex:tag - 1];
  if ([gw isKindOfClass:[NSNull class]])
    gw = nil;
  if (!gw)
  {
    gw = [[GameWindow alloc] initWithGame:game];
    [_gameWindows replaceObjectAtIndex:tag - 1 withObject:gw];
    [gw release];
  }
  [gw showWindow:self];
}

@end
