#import "IAoVProgressView.h"

static void _drawKnobInRect(NSRect knobRect);
static void _drawFrameInRect(NSRect frameRect);
static void _drawStringInRect(NSString* string, NSRect rect, NSTextAlignment align);



static void _drawKnobInRect(NSRect r)
{
  // Center knob in given rect
  //r.origin.x += (int)((float)(r.size.width - 7)/2.0);
  //r.origin.y += (int)((float)(r.size.height - 7)/2.0);
  // Draw diamond
  /*NSRectFillUsingOperation(NSMakeRect(r.origin.x + 3.0f, r.origin.y + 6.0f, 1.0f, 1.0f), NSCompositeSourceOver);
  NSRectFillUsingOperation(NSMakeRect(r.origin.x + 2.0, r.origin.y + 5.0f, 3.0, 1.0), NSCompositeSourceOver);
  NSRectFillUsingOperation(NSMakeRect(r.origin.x + 1, r.origin.y + 4, 5.0, 1.0), NSCompositeSourceOver);
  NSRectFillUsingOperation(NSMakeRect(r.origin.x + 0, r.origin.y + 3, 7.0, 1.0), NSCompositeSourceOver);
  NSRectFillUsingOperation(NSMakeRect(r.origin.x + 1, r.origin.y + 2, 5.0, 1.0), NSCompositeSourceOver);
  NSRectFillUsingOperation(NSMakeRect(r.origin.x + 2, r.origin.y + 1, 3.0, 1.0), NSCompositeSourceOver);
  NSRectFillUsingOperation(NSMakeRect(r.origin.x + 3, r.origin.y + 0, 1.0, 1.0), NSCompositeSourceOver);*/
  //NSRectFillUsingOperation(r, NSCompositeSourceOver);
  r = NSInsetRect(r, 2.0, 2.0);
  NSBezierPath* path = [[NSBezierPath alloc] init];
  [path moveToPoint:NSMakePoint(r.origin.x, r.origin.y + (r.size.height / 2.0))];
  [path lineToPoint:NSMakePoint(r.origin.x + (r.size.width / 2.0), r.origin.y + r.size.height)];
  [path lineToPoint:NSMakePoint(r.origin.x + r.size.width, r.origin.y + (r.size.height / 2.0))];
  [path lineToPoint:NSMakePoint(r.origin.x + (r.size.width / 2.0), r.origin.y)];
  [path closePath];
  [path setLineWidth:1.0];
  [path stroke];
  [path fill];
  [path release];
}

static void _drawFrameInRect(NSRect r)
{
  NSRectFillUsingOperation(NSMakeRect(r.origin.x, r.origin.y, r.size.width, 1), NSCompositeSourceOver);
  NSRectFillUsingOperation(NSMakeRect(r.origin.x, r.origin.y + r.size.height-1, r.size.width, 1), NSCompositeSourceOver);
  NSRectFillUsingOperation(NSMakeRect(r.origin.x, r.origin.y, 1, r.size.height), NSCompositeSourceOver);
  NSRectFillUsingOperation(NSMakeRect(r.origin.x + r.size.width-1, r.origin.y, 1, r.size.height), NSCompositeSourceOver);
}

static void _drawStringInRect(NSString* string, NSRect rect, NSTextAlignment align)
{
  if (string.length)
  {
    NSMutableDictionary* attributes = [[NSMutableDictionary alloc] init];
    NSFont* font = [NSFont fontWithName:@"Menlo" size:10];
    [attributes setObject:font forKey:NSFontAttributeName];
    [attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = align;
    [attributes setObject:style forKey:NSParagraphStyleAttributeName];
    NSString* toDraw = string;
    //float descent = [[attributes objectForKey:NSFontAttributeName] descender];
    NSSize strSize = [toDraw sizeWithAttributes:attributes];
    //NSLog(@"str height %f, rect height %f", strSize.height, r.size.height);
    NSPoint strOrigin;
    strOrigin.y = rect.origin.y + (rect.size.height - strSize.height)/2;
    if (align == NSTextAlignmentLeft)
    {
      strOrigin.x = rect.origin.x;
    }
    else if (align == NSTextAlignmentRight)
    {
      strOrigin.x = rect.origin.x + rect.size.width - strSize.width;
    }
    else
    {
      strOrigin.x = rect.origin.x + (rect.size.width - strSize.width)/2;
    }
    [toDraw drawAtPoint:strOrigin withAttributes:attributes];
    [attributes release];
    [style release];
  }
}

@implementation IAoVProgressView
// Sizes are relative to each other, not pixels
// Horizontal sizes
// The left and right margins are based on height, not width.
#define progressWidth (5.0)
#define leftSpaceWidth (1.0)
#define titleWidth (5.0)
#define rightSpaceWidth (1.0)
#define timeWidth (5.0)
#define totalWidth (progressWidth + leftSpaceWidth + titleWidth + rightSpaceWidth + timeWidth)
// Vertical sizes
#define topHeight (1.0)
#define textHeight (2.0)
#define middleHeight (1.0)
#define trackHeight (1.6)
#define bottomHeight (1.0)
#define totalHeight (topHeight + textHeight + middleHeight + trackHeight + bottomHeight)
// Pixel widths
#define progressWidthPx(r) (progressWidth / totalWidth * (r.size.width - (2.0 * topHeightPx(r))))
#define leftSpaceWidthPx(r) (leftSpaceWidth / totalWidth * (r.size.width - (2.0 * topHeightPx(r))))
#define titleWidthPx(r) (titleWidth / totalWidth * (r.size.width - (2.0 * topHeightPx(r))))
#define rightSpaceWidthPx(r) (rightSpaceWidth / totalWidth * (r.size.width - (2.0 * topHeightPx(r))))
#define timeWidthPx(r) (timeWidth / totalWidth * (r.size.width - (2.0 * topHeightPx(r))))
#define trackWidthPx(r) (r.size.width - (2.0 * topHeightPx(r)))
// Pixel heights
#define topHeightPx(r) (topHeight / totalHeight * r.size.height)
#define textHeightPx(r) (textHeight / totalHeight * r.size.height)
#define middleHeightPx(r) (middleHeight / totalHeight * r.size.height)
#define trackHeightPx(r) (trackHeight / totalHeight * r.size.height)
#define bottomHeightPx(r) (bottomHeight / totalHeight * r.size.height)
// Coordinates
#define progressX(r) (r.origin.x + topHeightPx(r))
#define titleX(r) (progressX(r) + progressWidthPx(r) + leftSpaceWidthPx(r))
#define timeX(r) (titleX(r) + titleWidthPx(r) + rightSpaceWidthPx(r))
#define textY(r) (r.origin.y + bottomHeightPx(r) + trackHeightPx(r) + middleHeightPx(r))
#define trackX(r) (r.origin.x + topHeightPx(r))
#define trackY(r) (r.origin.y + bottomHeightPx(r))
// Rectangles
#define progressRect(r) (NSMakeRect(progressX(r), textY(r), progressWidthPx(r), textHeightPx(r)))
#define titleRect(r) (NSMakeRect(titleX(r), textY(r), titleWidthPx(r), textHeightPx(r)))
#define timeRect(r) (NSMakeRect(timeX(r), textY(r), timeWidthPx(r), textHeightPx(r)))
#define trackRect(r) (NSMakeRect(trackX(r), trackY(r), trackWidthPx(r), trackHeightPx(r)))
#define kKnobInset 7

NSColor* IAoVProgressViewACMColor;
NSColor* IAoVProgressViewOGGColor;
NSColor* IAoVProgressViewWAVColor;

@synthesize trackingValue = _trackingValue;
+(void)initialize
{
  IAoVProgressViewACMColor = [[NSColor colorWithCalibratedRed:0.94f green:0.98f
                                       blue:0.79f alpha:1.0f] retain];
  IAoVProgressViewOGGColor = [[NSColor colorWithCalibratedRed:0.79f green:0.94f
                                       blue:0.98f alpha:1.0f] retain];
  IAoVProgressViewWAVColor = [[NSColor colorWithCalibratedRed:0.98f green:0.79f
                                       blue:0.94f alpha:1.0f] retain];
}

-(id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  return self;
}

-(id)initWithCoder:(NSCoder*)coder
{
  self = [super initWithCoder:coder];
  return self;
}

-(void)dealloc
{
  [self setColor:nil];
  if (_title) [_title release];
  [super dealloc];
}

-(void)prepareForInterfaceBuilder
{
  _loopPct = 0.1;
  _epiloguePct = 0.88;
  _length = 60.0;
}

-(void)drawRect:(NSRect)rect
{
  rect = [self bounds];
  //rect = NSInsetRect([self bounds], 1.0f, 1.0f);
  if (!_color)
    [self setColor:IAoVProgressViewACMColor];
  [_color set];
  NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:4.0f yRadius:4.0f];
  [path fill];
  [[NSColor colorWithCalibratedRed:0.2f green:0.3f blue:0.1f alpha:1.0f] set];
  [path stroke];
  if (_length)
  {
    // Progress text field
    double secs = _length * (_tracking ? _trackingValue : _value);
    NSString* timeStr = [self _copyTimeStringFromDouble:secs];
    NSRect r = [self bounds];
    rect = progressRect(r);
    [[NSColor blackColor] set];
    _drawStringInRect(timeStr, rect, NSTextAlignmentLeft);
    [timeStr release];
    timeStr = [self _copyTimeStringFromDouble:_length];
    rect = timeRect(r);
    [[NSColor blackColor] set];
    _drawStringInRect(timeStr, rect, NSTextAlignmentRight);
    [timeStr release];
  }
  if (_title)
  {
    NSRect r = [self bounds];
    rect = titleRect(r);
    _drawStringInRect(_title, rect, NSTextAlignmentCenter);
  }
  [self _drawTrack];
}

-(NSString*)_copyTimeStringFromDouble:(double)d
{
  return [[NSString alloc] initWithFormat:@"%d:%02d:%04.1f",
                           (int)(d / 3600.0),
                           (int)(d / 60.0) % 60,
                           fmod(d, 60.0)];
}

-(void)_drawTrack
{
  NSRect r = [self bounds];
  NSRect rect = trackRect(r);
  NSRect knobRect = rect;
  // Indicate loop point
  if (_loopPct != 0.0)
  {
    NSRect loopRect = rect;
    loopRect.size.width *= _loopPct;
    [[[NSColor blackColor] colorWithAlphaComponent:0.1f] set];
    NSRectFillUsingOperation(loopRect, NSCompositeSourceOver);
  }
  if (0.0 < _epiloguePct && _epiloguePct < 1.0)
  {
    NSRect loopRect = rect;
    loopRect.origin.x += ((_epiloguePct) * rect.size.width);
    loopRect.size.width *= (1.0 - _epiloguePct);
    [[[NSColor blackColor] colorWithAlphaComponent:0.2f] set];
    NSRectFillUsingOperation(loopRect, NSCompositeSourceOver);
  }
  [[NSColor blackColor] set];
  _drawFrameInRect(rect);
  knobRect.size.width = knobRect.size.height;
  knobRect.origin.x += (rect.size.width - knobRect.size.width) * ((_tracking) ? _trackingValue : _value);
  if (_length)
  {
    _drawKnobInRect(knobRect);
  }
  // Draw shadow
  [[[NSColor blackColor] colorWithAlphaComponent:0.1f] set];
  rect.origin.x++;
  rect.origin.y++;
  knobRect.origin.x++;
  knobRect.origin.y++;
  _drawFrameInRect(rect);
  if (_length)
  {
    _drawKnobInRect(knobRect);
  }
}

-(void)setDelegate:(id)delegate
{
  if (delegate) [delegate retain];
  if (_delegate) [_delegate release];
  _delegate = delegate;
}

-(void)setTitle:(NSString*)title
{
  if (title) [title retain];
  if (_title) [_title release];
  _title = title;
  [self setNeedsDisplay:YES];
}

-(void)setColor:(NSColor*)color
{
  if (color) [color retain];
  if (_color) [_color release];
  _color = color;
  [self setNeedsDisplay:YES];
}

-(void)setLength:(double)length
{
  if (_length != length)
  {
    if (length < 0.0) length = 0.0;
    _length = length;
    if (!_tracking) [self setNeedsDisplay:YES];
  }
}

-(double)trackingValue {return _trackingValue;}
-(double)doubleValue {return _value;}

-(void)setDoubleValue:(double)val
{
  if (_value != val)
  {
    if (val < 0.0) val = 0.0;
    else if (val > 1.0) val = 1.0;
    _value = val;
    if (!_tracking) [self setNeedsDisplay:YES];
  }
}

-(void)setTrackingValue:(double)val
{
  if (_trackingValue != val)
  {
    if (val < 0.0) val = 0.0;
    else if (val > 1.0) val = 1.0;
    _trackingValue = val;
    if (_tracking) [self setNeedsDisplay:YES];
  }
}

-(void)setLoopPct:(double)pct
{
  if (_loopPct != pct)
  {
    _loopPct = pct;
    [self setNeedsDisplay:YES];
  }
}

-(void)setEpiloguePct:(double)pct
{
  if (pct < 0.0) pct = 0.0;
  if (pct > 1.0) pct = 1.0;
  if (_epiloguePct != pct)
  {
    _epiloguePct = pct;
    [self setNeedsDisplay:YES];
  }
}

#pragma mark Event Handling
-(void)mouseDown:(NSEvent*)evt
{
  BOOL done = NO;
  NSPoint where = [self convertPoint:[evt locationInWindow] fromView:nil];
  NSRect r = [self bounds];
  NSRect trackRect = trackRect(r);
  BOOL isInside = [self mouse:where inRect:trackRect];
  if (!isInside) return;
  _tracking = YES;
  double val = (where.x - trackRect.origin.x) / trackRect.size.width;
  if (val < 0.0) val = 0.0;
  if (val > 1.0) val = 1.0;
  [self setTrackingValue:val];
  double oldValue = _value;
  while (!done)
  {
    evt = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
    where = [self convertPoint:[evt locationInWindow] fromView:nil];
    //isInside = [self mouse:where inRect:trackRect];
    switch (evt.type)
    {
      case NSEventTypeLeftMouseDragged:
      val = (where.x - trackRect.origin.x) / trackRect.size.width;
      if (val < 0.0) val = 0.0;
      if (val > 1.0) val = 1.0;
      [self setTrackingValue:val];
      //[self highlight:isInside];
      break;

      case NSEventTypeLeftMouseUp:
      _value = _trackingValue;
      done = YES;
      break;

      default:
      break;
    }
  }
  if (oldValue != _value &&
      _delegate && [_delegate respondsToSelector:@selector(IAoVProgressViewValueChanged:)])
  {
    [_delegate IAoVProgressViewValueChanged:self];
  }
  _tracking = NO;
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
