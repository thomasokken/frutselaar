//
//  FrutselaarView.m
//  Frutselaar
//
//  Created by Thomas Okken on 01-12-2023.
//

#import "FrutselaarView.h"

#define CELLSIZE 8
#define LINEWIDTH 1
#define MAXLENGTH 10
#define STEP_TIME_MS 100
#define HOLD_STEPS 20

static int instanceCount = 0;

@implementation FrutselaarView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        instance = instanceCount++;
        NSLog(@"FRUTS(%d): Initializing", instance);
        path = NULL;
        grid = NULL;
        [self setAnimationTimeInterval:STEP_TIME_MS / 1000.0];
        w = (int) (frame.size.width / CELLSIZE);
        h = (int) (frame.size.height / CELLSIZE);
        srandom((unsigned int) time(NULL));
        pw = (int) frame.size.width;
        ph = (int) frame.size.height;
    }
    return self;
}

- (void)startAnimation
{
    NSLog(@"FRUTS(%d): startAnimation", instance);
    grid = (char *) malloc(w * h);
    [super startAnimation];
}

- (void)stopAnimation
{
    NSLog(@"FRUTS(%d): stopAnimation", instance);
    [super stopAnimation];
    free(path);
    path = NULL;
    free(grid);
    grid = NULL;
}

- (void)drawRect:(NSRect)rect
{
    NSLog(@"FRUTS(%d): drawRect [ %g %g %g %g ]", instance, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    CGContextRef myContext = (CGContextRef) [[NSGraphicsContext currentContext] CGContext];
    CGContextSetRGBFillColor(myContext, 0.25, 0.25, 0.25, 1.0);
    CGContextFillRect(myContext, NSRectToCGRect(rect));
    
    if (grid == NULL)
        return;

    CGContextSetRGBStrokeColor(myContext, 0.0, 1.0, 0.0, 1.0);
    CGContextSetLineWidth(myContext, LINEWIDTH);
    /*
    CGContextBeginPath(myContext);
    CGContextMoveToPoint(myContext, 10, 10);
    CGContextAddLineToPoint(myContext, pw - 10, ph - 10);
    CGContextStrokePath(myContext);
    */
    
    char *cp = grid;
    for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++) {
            int c = *cp++;
            if (c < 1 || c > 6)
                continue;
            NSLog(@"FRUTS(%d): segment %d at (%d, %d)", instance, c, xoff + x * CELLSIZE, yoff + y * CELLSIZE);
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
            CGContextStrokePath(myContext);
        }
}

- (void)animateOneFrame
{
    if (path == NULL) {
        // Generate path
        retry:
        NSLog(@"FRUTS(%d): Generating path", instance);
        length = (int) ((random() / 2147483648.0) * MAXLENGTH) + 1;
        path = (char *) malloc(4 * (length + 1));
        bool straight = true;
        for (int i = 0; i < length; i++) {
            int d = (int) ((random() / 2147483648.0) * 3) + 1;
            path[i] = d;
            if (d != 1)
                straight = !straight;
        }
        if (straight)
            path[length++] = (int) ((random() / 2147483648.0) * 2) + 2;
        memcpy(path + length, path, length);
        memcpy(path + 2 * length, path, 2 * length);
        length *= 4;
        
        // Figure out path size
        x = 0;
        y = 0;
        dir = 0;
        int xmax = 0, xmin = 0, ymax = 0, ymin = 0;
        for (int i = 0; i < length; i++) {
            switch (dir) {
                case 0:
                    y--;
                    if (y < ymin)
                        ymin = y;
                    break;
                case 1:
                    x++;
                    if (x > xmax)
                        xmax = x;
                    break;
                case 2:
                    y++;
                    if (y > ymax)
                        ymax = y;
                    break;
                case 3:
                    x--;
                    if (x < xmin)
                        xmin = x;
                    break;
            }
            int d = path[i];
            if (d != 1) {
                if (d == 2)
                    dir--;
                else
                    dir++;
                dir %= 4;
            }
        }
        if (xmax - xmin + 1 > w || ymax - ymin + 1 > h) {
            free(path);
            goto retry;
        }
        
        // We have a good path; final initializations
        x = -xmin;
        y = -ymin;
        xoff = (pw - (xmax - xmin + 1) * CELLSIZE) / 2;
        yoff = (ph - (ymax - ymin + 1) * CELLSIZE) / 2;
        dir = 0;
        pos = 0;
        memset(grid, 0, w * h);
    }
    
    if (pos < length) {
        int c = path[pos++];
        NSLog(@"FRUTS(%d): Drawing cell %d at (%d, %d)", instance, c, x, y);
        switch (dir) {
            case 0:
                grid[x + y * w] = c == 1 ? 1 : c == 2 ? 5 : 4;
                y--;
                break;
            case 1:
                grid[x + y * w] = c == 1 ? 2 : c == 2 ? 6 : 5;
                x++;
                break;
            case 2:
                grid[x + y * w] = c == 1 ? 1 : c == 2 ? 3 : 6;
                y++;
                break;
            case 3:
                grid[x + y * w] = c == 1 ? 2 : c == 2 ? 4 : 3;
                x--;
                break;
        }
        if (c != 1) {
            if (c == 2)
                dir--;
            else
                dir++;
            dir %= 4;
        }
        // TODO: Don't call setNeedsDisplayInRect, but draw the cell immediately
        [self setNeedsDisplayInRect:CGRectMake(0, 0, pw, ph)];
    } else {
        NSLog(@"FRUTS(%d): Waiting", instance);
        pos++;
        if (pos - length > HOLD_STEPS) {
            free(path);
            path = NULL;
        }
    }
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
