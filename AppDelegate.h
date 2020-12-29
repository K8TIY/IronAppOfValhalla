//
//  AppDelegate.h
//  NACMP
//
//  Created by Hall, Brian on 12/18/18.
//  Copyright © 2018 blugs.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACMGame.h"
#import "GameWindow.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
  IBOutlet NSWindow*           _mainWindow;
  NSMutableArray<ACMGame*>*    _games;
  NSMutableArray<NSButton*>*   _buttons;
  NSMutableArray<GameWindow*>* _gameWindows;
}
-(IBAction)openGameDirectory:(id)sender;
-(IBAction)gameButtonAction:(id)sender;
@end

