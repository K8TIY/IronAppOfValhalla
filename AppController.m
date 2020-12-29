#import "AppController.h"
#import "IAoVGameManager.h"

/*void exceptionHandler(NSException *anException)
{
    NSLog(@"%@", [anException reason]);
    NSLog(@"%@", [anException userInfo]);

    [NSApp terminate:nil];  // you can call exit() instead if desired
}*/

@implementation AppController
#pragma mark IBAction
-(IBAction)orderFrontPrefsWindow:(id)sender
{
  #pragma unused (sender)
  [_prefsWindow makeKeyAndOrderFront:sender];
}

#pragma mark NSApplicationDelegate protocol
-(void)applicationWillFinishLaunching:(NSNotification*)note
{
  #pragma unused (note)
  NSString* where = [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"];
  NSMutableDictionary* d = [NSMutableDictionary dictionaryWithContentsOfFile:where];
  [[NSUserDefaults standardUserDefaults] registerDefaults:d];
  //NSSetUncaughtExceptionHandler(&exceptionHandler);
}

-(void)applicationWillTerminate:(NSNotification*)note
{
  #pragma unused (note)
  NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
  NSMutableArray* bookmarks = [[NSMutableArray alloc] init];
  for (IAoVGame* game in [IAoVGameManager sharedIAoVGameManager].games)
  {
    NSData* data = [game.url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope |
                                                     NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
                             includingResourceValuesForKeys:@[]
                             relativeToURL:nil error:nil];
    [bookmarks addObject:data];
  }
  [defs setValue:bookmarks forKey:@"games"];
  [bookmarks release];
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
