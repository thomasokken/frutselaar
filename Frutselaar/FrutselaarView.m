//
//  FrutselaarView.m
//  Frutselaar
//
//  Created by Thomas Okken on 01-12-2023.
//

#import "FrutselaarView.h"

#define CELLSIZE 8
#define LINEWIDTH 1

@implementation FrutselaarView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        path = NULL;
        grid = NULL;
        [self setAnimationTimeInterval:1/30.0];
        w = (int) (frame.size.width / CELLSIZE);
        h = (int) (frame.size.height / CELLSIZE);
        xoff = ((int) frame.size.width - w * CELLSIZE) / 2;
        yoff = ((int) frame.size.height - h * CELLSIZE) / 2;
    }
    return self;
}

- (void)startAnimation
{
    grid = (char *) malloc(w * h);
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
    free(path);
    path = NULL;
    free(grid);
    grid = NULL;
}

- (void)drawRect:(NSRect)rect
{
    CGContextRef myContext = (CGContextRef) [[NSGraphicsContext currentContext] CGContext];
    CGContextSetRGBFillColor(myContext, 0.0, 0.0, 0.0, 1.0);
    CGContextFillRect(myContext, NSRectToCGRect(rect));
    
    if (grid == NULL)
        return;

    CGContextSetRGBStrokeColor(myContext, 0.0, 1.0, 0.0, 1.0);
    CGContextSetLineWidth(myContext, LINEWIDTH);
    
    char *cp = grid;
    for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++) {
            int c = *cp++;
            if (c < 1 || c > 6)
                continue;
            CGContextBeginPath(myContext);
            switch (c) {
                case 1: // │
                    CGContextMoveToPoint(myContext, xoff + (x + 0.5) * CELLSIZE, yoff + y * CELLSIZE);
                    CGContextAddLineToPoint(myContext, xoff + (x + 0.5) * CELLSIZE, yoff + (y + 1) * CELLSIZE);
                    break;
                case 2: // ─
                    CGContextMoveToPoint(myContext, xoff + x * CELLSIZE, yoff + (y + 0.5) * CELLSIZE);
                    CGContextAddLineToPoint(myContext, xoff + (x + 1) * CELLSIZE, yoff + (y + 0.5) * CELLSIZE);
                    break;
                case 3: // └
                    CGContextMoveToPoint(myContext, xoff + (x + 0.5) * CELLSIZE, yoff + y * CELLSIZE);
                    CGContextAddArcToPoint(myContext, xoff + (x + 0.5) * CELLSIZE, yoff + (y + 0.5) * CELLSIZE, xoff + (x + 1) * CELLSIZE, yoff + (y + 0.5) * CELLSIZE, 0.5 * CELLSIZE);
                    break;
                case 4: // ┌
                    CGContextMoveToPoint(myContext, xoff + (x + 0.5) * CELLSIZE, yoff + (y + 1) * CELLSIZE);
                    CGContextAddArcToPoint(myContext, xoff + (x + 0.5) * CELLSIZE, yoff + (y + 0.5) * CELLSIZE, xoff + (x + 1) * CELLSIZE, yoff + (y + 0.5) * CELLSIZE, 0.5 * CELLSIZE);
                    break;
                case 5: // ┐
                    CGContextMoveToPoint(myContext, xoff + x * CELLSIZE, yoff + (y + 0.5) * CELLSIZE);
                    CGContextAddArcToPoint(myContext, xoff + (x + 0.5) * CELLSIZE, yoff + (y + 0.5) * CELLSIZE, xoff + (x + 0.5) * CELLSIZE, yoff + (y + 1) * CELLSIZE, 0.5 * CELLSIZE);
                    break;
                case 6: // ┘
                    CGContextMoveToPoint(myContext, xoff + x * CELLSIZE, yoff + (y + 0.5) * CELLSIZE);
                    CGContextAddArcToPoint(myContext, xoff + (x + 0.5) * CELLSIZE, yoff + (y + 0.5) * CELLSIZE, xoff + (x + 0.5) * CELLSIZE, yoff + y * CELLSIZE, 0.5 * CELLSIZE);
                    break;
            }
            CGContextDrawPath(myContext, kCGPathStroke);
        }
}

- (void)animateOneFrame
{
    // TODO -- This is where everything is going to happen
    // Note that you can draw incrementally here; it is not necessary to let drawRect do all the drawing.
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
