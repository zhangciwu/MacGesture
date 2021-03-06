//
//  CanvasView.m
//  MouseGesture
//
//  Created by keakon on 11-11-14.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import "CanvasView.h"
#import "RulesList.h"
#import "MGOptionsDefine.h"

@implementation CanvasView

static NSImage *leftImage;
static NSImage *rightImage;
static NSImage *upImage;
static NSImage *downImage;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    leftImage = [NSImage imageNamed:@"left.png"];
    rightImage = [NSImage imageNamed:@"right.png"];
    downImage = [NSImage imageNamed:@"down.png"];
    upImage = [NSImage imageNamed:@"up.png"];

    if (self) {
        color = [MGOptionsDefine getLineColor];
        points = [[NSMutableArray alloc] init];
        directionToDraw = @"";
        radius = 2;
    }

    return self;
}

- (float)getGestureImageScale {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:@"gestureSize"] / 100 * 1.25;
}

- (void)drawDirection {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"showGesturePreview"]) {
        return;
    }

    // This should be called in drawRect
    float scale = [self getGestureImageScale];
    float scaledHeight = scale * leftImage.size.height;
    float scaledWidth = scale * leftImage.size.width;
    
    CGRect screenRect = [[NSScreen mainScreen] frame];
    NSInteger y = (screenRect.size.height - scaledHeight) / 2;
    NSInteger beginx = (screenRect.size.width - scaledWidth * directionToDraw.length) / 2;
    
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    for (NSInteger i = 0; i < directionToDraw.length; i++) {
        NSImage *image = nil;
        switch ([directionToDraw characterAtIndex:i]) {
            case 'L':
                image = leftImage;
                break;
            case 'R':
                image = rightImage;
                break;
            case 'U':
                image = upImage;
                break;
            case 'D':
                image = downImage;
                break;
            default:
                break;
        }
        [image drawInRect:NSMakeRect(beginx + i * scaledWidth, y, scaledWidth, scaledHeight) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawNote {
    // This should be called in drawRect
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"showGestureNote"]) {
        return;
    }
    NSInteger index = [[RulesList sharedRulesList] suitedRuleWithGesture:directionToDraw];
    NSString *note = @"";
    if (index == -1)
        return;
    else
        note = [[RulesList sharedRulesList] noteAtIndex:index];
    if (![note isEqualToString:@""]) {

        CGRect screenRect = [[NSScreen mainScreen] frame];

        NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] objectForKey:@"noteFontName"] size:[[NSUserDefaults standardUserDefaults] doubleForKey:@"noteFontSize"]];

        NSDictionary *textAttributes = @{NSFontAttributeName : font};

        CGSize size = [note sizeWithAttributes:textAttributes];
        float x = ((screenRect.size.width - size.width) / 2);
        float y = ((screenRect.size.height + leftImage.size.height * [self getGestureImageScale]) / 2);
        
        CGContextRef context = [[NSGraphicsContext currentContext]
                                graphicsPort];
        CGContextSetRGBFillColor (context, 0, 0, 0, 0.1);
        CGContextFillRect (context, CGRectMake (x, y, size.width,
                                                size.height));
        
        [note drawAtPoint:NSMakePoint(x, y) withAttributes:textAttributes];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    // draw mouse line
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"disableMousePath"]) {
        NSBezierPath *path = [NSBezierPath bezierPath];
        path.lineWidth = radius * 2;
        [color setStroke];
        if (points.count >= 1) {
            [path moveToPoint:[points[0] pointValue]];
        }
        for (int i = 1; i < points.count; i++) {
            [path lineToPoint:[points[i] pointValue]];
        }

        [path stroke];
    }

    //[textImage drawInRect:NSScreen.mainScreen.frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [self drawDirection];
    [self drawNote];

}


- (void)drawLineFromPoint:(NSPoint)point1 toPoint:(NSPoint)point2 {
    [points addObject:[NSValue valueWithPoint:point1]];
    [points addObject:[NSValue valueWithPoint:point2]];
    self.needsDisplay = YES;
}

- (void)clear {
    [points removeAllObjects];
    directionToDraw = @"";
    self.needsDisplay = YES;
}

- (void)resizeTo:(NSRect)frame {
    self.frame = frame;

    self.needsDisplay = YES;
}


- (void)mouseDown:(NSEvent *)event {
    lastLocation = [NSEvent mouseLocation];
    NSWindow *w = self.window;
    NSScreen *s = w.screen;
    lastLocation.x -= s.frame.origin.x;
    lastLocation.y -= s.frame.origin.y;
#ifdef DEBUG
    NSLog(@"frame:%@, window:%@, screen:%@", NSStringFromRect(self.frame), NSStringFromRect(w.frame), NSStringFromRect(s.frame));
    NSLog(@"%@", NSStringFromPoint(lastLocation));
#endif
    [points addObject:[NSValue valueWithPoint:lastLocation]];
}

- (void)mouseDragged:(NSEvent *)event {

    @autoreleasepool {
        NSPoint newLocation = event.locationInWindow;
        NSWindow *w = self.window;
        NSScreen *s = w.screen;
        newLocation.x -= s.frame.origin.x;
        newLocation.y -= s.frame.origin.y;

//		[self drawCircleAtPoint:newLocation];
        [points addObject:[NSValue valueWithPoint:newLocation]];
        self.needsDisplay = YES;
//		[self setNeedsDisplayInRect:NSMakeRect(fmin(lastLocation.x - radius, newLocation.x - radius),
//											   fmin(lastLocation.y - radius, newLocation.y - radius),
//											   abs(newLocation.x - lastLocation.x) + radius * 2,
//											   abs(newLocation.y - lastLocation.y) + radius * 2)];
        lastLocation = newLocation;
    }

}

- (void)mouseUp:(NSEvent *)event {
    [self clear];
}


- (void)writeDirection:(NSString *)directionStr; {
    directionToDraw = directionStr;

    self.needsDisplay = YES;
}

@end
