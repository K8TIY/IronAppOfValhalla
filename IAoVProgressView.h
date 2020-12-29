#import <Cocoa/Cocoa.h>
#import <QuartzCore/CATextLayer.h>
#import <QuartzCore/CAGradientLayer.h>

extern NSColor* IAoVProgressViewACMColor;
extern NSColor* IAoVProgressViewOGGColor;
extern NSColor* IAoVProgressViewWAVColor;


@protocol IAoVProgressViewValue
-(void)IAoVProgressViewValueChanged:(id)sender;
@end


IB_DESIGNABLE @interface IAoVProgressView : NSView
{
  id        _delegate;
  NSColor*  _color;
  NSString* _title;
  double    _value; // A value between 0.0 and 1.0 inclusive.
  double    _trackingValue;
  double    _length; // In seconds
  double    _loopPct;
  double    _epiloguePct;
  BOOL      _tracking;
}
@property(readonly) double trackingValue;
-(void)setDelegate:(id)delegate;
-(void)setColor:(NSColor*)color;
-(void)setTitle:(NSString*)title;
-(void)setLength:(double)length;
-(void)setDoubleValue:(double)val;
-(void)setTrackingValue:(double)val; // FIXME: should this be private?
-(void)setLoopPct:(double)pct;
-(void)setEpiloguePct:(double)pct;
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
