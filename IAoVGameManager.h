#import <Foundation/Foundation.h>
#import "CWLSynthesizeSingleton.h"
#import "IAoVGame.h"
#import "GameButton.h"
#import "GameDatabase.h"
#import "GameWindow.h"

NS_ASSUME_NONNULL_BEGIN



@interface IAoVGameManager : NSResponder <GameButtonDelegate,
                                         GameDatabaseProgress>
{
  IBOutlet NSWindow*             _mainWindow;
  IBOutlet NSWindow*             _helpWindow;
  IBOutlet NSWindow*             _dbProgressWindow;
  IBOutlet NSImageView*          _dbProgressImage;
  IBOutlet NSTextField*          _dbProgressPath;
  IBOutlet NSProgressIndicator*  _dbProgressProgress;
  NSMutableArray<IAoVGame*>*     _games;
}
@property (readonly) NSArray<IAoVGame*>* games;
CWL_DECLARE_SINGLETON_FOR_CLASS(IAoVGameManager)
-(void)addGameAtURL:(NSURL*)url;
-(NSArray<GameWindow*>*)gameWindows;
-(IBAction)gameButtonAction:(id)sender;
-(IBAction)openGameDirectory:(id)sender;
-(IBAction)dismissInitialHelp:(id)sender;
@end

NS_ASSUME_NONNULL_END

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
