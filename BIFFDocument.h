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
#import <Cocoa/Cocoa.h>
#import "ACMGame.h"
#import "BIFFData.h"
//#import "KEYData.h"
//#import "TLKData.h"
#import "ACMDocumentCommon.h"
#import "ACMTableView.h"

@interface NSIndexSet (IndexAtIndex)
-(NSUInteger)indexAtIndex:(NSUInteger)anIndex;
@end

@interface BIFFTableView : NSTableView
@end

@interface BIFFDocument : ACMDocumentCommon <ACMTableViewDelegate>
{
  ACMGame*                     _game;
  BIFFData*                    _biff;
  NSArray<GameResource*>*      _resources;
  //NSTimer*                      _timer;
  //KEYData*                      _key;
  //TLKData*                      _tlk;
  NSMutableIndexSet*            _indices;
  IBOutlet NSWindow*            _docWindow;
  IBOutlet NSTableView*         _table;
  IBOutlet NSTextView*          _text;
  IBOutlet NSSearchField*       _search;
  //IBOutlet NSProgressIndicator* _loadProgress;
  IBOutlet NSPopUpButton*       _languageMenu;
  NSInteger                     _lastSelectedRow;
  BOOL                          _didSelect;
}
-(id)initWithGame:(ACMGame*)game biff:(BIFFData*)biff;
-(IBAction)doSearch:(id)sender;
@end
