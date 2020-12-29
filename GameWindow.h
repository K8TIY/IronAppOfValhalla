#import <Cocoa/Cocoa.h>
#import "IAoVGame.h"
#import "ACMRenderer.h"
#import "IAoVTableView.h"
#import "IAoVProgressView.h"
#import "NSIndexSet_IndexAtIndex.h"

NS_ASSUME_NONNULL_BEGIN

@interface IAoVWindow : NSWindow
@end

@protocol IAoVWindowDelegate <NSObject>
-(BOOL)windowDidReceiveSpace:(id)sender;
@end

@interface MUSFile : NSObject
{
  NSURL*    _url;
  NSString* _title;
}
@property (readonly) NSURL* url;
@property (readonly) NSString* title;
-(id)initWithURL:(NSURL*)url title:(NSString*)title;
@end

@interface GameWindow : NSWindowController <NSTableViewDataSource,
                                            NSTableViewDelegate,
                                            ACM, IAoVTableViewDelegate,
                                            IAoVWindowDelegate,
                                            IAoVProgressViewValue>
{
  IAoVGame*                    _game;
  NSArray<GameResourceCount*>* _biffs; // BIF files with audio assets
  NSArray<MUSFile*>*           _musFiles;
  NSArray<GameLocalization*>*  _voiceLocalizations; // With empty directories pruned
  IBOutlet NSButton*           _startStopButton;
  IBOutlet NSButton*           _loopButton;
  IBOutlet NSSlider*           _ampSlider;
  IBOutlet NSButton*           _ampLoButton;
  IBOutlet NSButton*           _ampHiButton;
  IBOutlet IAoVProgressView*   _progress;
  ACMRenderer*                 _renderer;
  ACMRenderer*                 _exportRenderer;
  BOOL                         _suspendedInBackground;
  IBOutlet NSSearchField*      _search;
  IBOutlet NSPopUpButton*      _languageMenu;
  NSSavePanel*                 _exportPanel;
  IBOutlet NSTabView*          _tabs;
  IBOutlet IAoVTableView*      _musicTable;
  IBOutlet NSOutlineView*      _voiceTable;
  // BIFF Resources pane
  IBOutlet IAoVTableView*      _resourceFileTable; // Master
  IBOutlet NSScrollView*       _resourceFileScrollView; // For splitter delegate
  IBOutlet IAoVTableView*      _resourceTable; // Detail
  IBOutlet NSTextView*         _text;
  NSMutableIndexSet*           _indices; // The resource rows found by searching
  NSMutableIndexSet*           _musicIndices;
  NSArray<GameResource*>*      _currentResources; // The ones being viewed
  BIFFData*                    _currentBIFF;
}
-(id)initWithGame:(IAoVGame*)game;
-(IBAction)localizationChanged:(NSPopUpButton*)sender;
-(IBAction)doSearch:(id)sender;
-(void)loadMusicData:(NSData*)data playing:(BOOL)play;
-(void)loadMUSData:(MUSData*)data playing:(BOOL)play;
@end

NS_ASSUME_NONNULL_END

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
