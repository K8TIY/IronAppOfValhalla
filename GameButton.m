#import "GameButton.h"

@implementation GameButton

-(instancetype)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  [self setButtonType:NSButtonTypeMomentaryLight];
  //[self setBezelStyle:NSBezelStyleRounded];
  [self setBezelStyle:NSBezelStyleRegularSquare];
  [self setBordered:YES];
  self.showsBorderOnlyWhileMouseInside = YES;
  //self.imagePosition = NSImageOnly;
  self.imageScaling = NSImageScaleProportionallyDown;
  self.imagePosition = NSImageLeft;
  NSRect track = [self local_trackingRect];
  NSTrackingArea* trackingArea = [[NSTrackingArea alloc]
                                  initWithRect:track
                                  options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                  owner:self userInfo:nil];
  [self addTrackingArea:trackingArea];
  [trackingArea release];
  return self;
}

-(void)drawRect:(NSRect)dirtyRect
{
  [super drawRect:dirtyRect];
  NSGraphicsContext* gc = [NSGraphicsContext currentContext];
  [gc saveGraphicsState];
  if (_hiliteX)
  {
    NSRect track = [self local_trackingRect];
    //track = NSInsetRect(track, 1, 1);
    
    // Create our circle path
    NSBezierPath* circlePath = [NSBezierPath bezierPath];
    [circlePath appendBezierPathWithOvalInRect:track];
    // Outline and fill the path
    [[NSColor blackColor] setFill];
    [circlePath fill];
    track = NSInsetRect(track, 2, 2);
    circlePath = [NSBezierPath bezierPath];
    [circlePath appendBezierPathWithOvalInRect:track];
    [[NSColor whiteColor] setStroke];
    [circlePath setLineWidth:3.0];
    [circlePath stroke];
    // Inset the circle by 1/4
    NSRect xrect = NSInsetRect(track, track.size.width / 4.0, track.size.height / 4.0);
    NSBezierPath* xpath = [[NSBezierPath alloc] init];
    [xpath moveToPoint:NSMakePoint(xrect.origin.x, xrect.origin.y)];
    [xpath lineToPoint:NSMakePoint(xrect.origin.x + xrect.size.width,
                                   xrect.origin.y + xrect.size.height)];
    [xpath closePath];
    [xpath setLineWidth:4.0];
    [xpath stroke];
    [xpath release];
    xpath = [[NSBezierPath alloc] init];
    [xpath moveToPoint:NSMakePoint(xrect.origin.x, xrect.origin.y + xrect.size.height)];
    [xpath lineToPoint:NSMakePoint(xrect.origin.x + xrect.size.width, xrect.origin.y)];
    [xpath closePath];
    [xpath setLineWidth:4.0];
    [xpath stroke];
    [xpath release];
  }
  [gc restoreGraphicsState];
}

#define kFractionOfButton (13.0)
#define kFractionOfButtonMinusOne (kFractionOfButton - 1.0)
-(NSRect)local_trackingRect
{
  NSRect track = [self bounds];
  // Upper right third of bounds
  track.origin.x += track.size.width * (kFractionOfButtonMinusOne / kFractionOfButton);
  if (![self isFlipped])
    track.origin.y += track.size.height * (kFractionOfButtonMinusOne / kFractionOfButton);
  track.size.width /= kFractionOfButton;
  track.size.height = track.size.width;
  track.origin.x -= 5;
  if ([self isFlipped]) track.origin.y += 5;
  else track.origin.y -= 5;
  return track;
}

-(void)mouseEntered:(NSEvent*)e
{
  #pragma unused (e)
  _hiliteX = YES;
  [self setNeedsDisplay:YES];
}

-(void)mouseExited:(NSEvent*)e
{
  #pragma unused (e)
  _hiliteX = NO;
  [self setNeedsDisplay:YES];
}

-(void)mouseDown:(NSEvent*)e
{
  if (_hiliteX)
  {
    
  }
  else
  {
    [super mouseDown:e];
  }
}

-(void)mouseUp:(NSEvent*)e
{
  if (_hiliteX)
  {
    if (_delegate && [_delegate respondsToSelector:@selector(gameButtonDidClose:)])
    {
      [_delegate gameButtonDidClose:self];
    }
  }
  else
  {
    [super mouseUp:e];
  }
}

-(void)setDelegate:(id)obj
{
  [obj retain];
  if (_delegate) [_delegate release];
  _delegate = obj;
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
