#import "IAoVTableView.h"

@implementation IAoVTableView
-(void)keyDown:(NSEvent*)evt
{
  NSString* characters = [evt characters];
  BOOL handled = NO;
  if ((characters.length == 1) && ![evt isARepeat])
  {
    unichar ch = [characters characterAtIndex:0];
    switch (ch)
    {
      case NSNewlineCharacter:
      case NSCarriageReturnCharacter:
      case NSEnterCharacter:
      {
        id del = [self delegate];
        SEL sel = @selector(tableView:didReceiveReturn:);
        if (del && [del respondsToSelector:sel])
        {
          [del performSelector:sel withObject:self withObject:evt];
          handled = YES;
        }
      }
      break;
      
      /*case NSTabCharacter:
      if (([evt modifierFlags] & NSShiftKeyMask) != NSShiftKeyMask)
        [[self window] selectKeyViewFollowingView:self];
      else
        [[self window] selectKeyViewPrecedingView:self];
      handled = YES;
      break;*/
    }
  }
  if (!handled) [super keyDown:evt];
}

/*-(BOOL)becomeFirstResponder
{
  NSInteger row = [self selectedRow];
  if (row == -1) [self selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
  return [super becomeFirstResponder];
}*/

@end

@implementation IAoVOutlineView
-(void)keyDown:(NSEvent*)evt
{
  NSString* characters = [evt characters];
  BOOL handled = NO;
  if ((characters.length == 1) && ![evt isARepeat])
  {
    unichar ch = [characters characterAtIndex:0];
    switch (ch)
    {
      case NSNewlineCharacter:
      case NSCarriageReturnCharacter:
      case NSEnterCharacter:
      {
        NSIndexSet* selection = [self selectedRowIndexes];
        if (selection.count == 1)
        {
          id item = [self itemAtRow:[selection firstIndex]];
          if ([self isExpandable:item])
          {
            if ([self isItemExpanded:item])
            {
              [self collapseItem:item];
            }
            else
            {
              [self expandItem:item];
            }
            handled = YES;
          }
          else
          {
            id del = [self delegate];
            SEL sel = @selector(outlineView:didReceiveReturn:);
            if (del && [del respondsToSelector:sel])
            {
              [del performSelector:sel withObject:self withObject:evt];
              handled = YES;
            }
          }
        }
      }
      break;
    }
  }
  if (!handled) [super keyDown:evt];
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
