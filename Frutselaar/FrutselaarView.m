//
//  FrutselaarView.m
//  Frutselaar
//
//  Created by Thomas Okken on 01-12-2023.
//

#import "FrutselaarView.h"

#define GRIDSIZE 25
#define MAXLENGTH 100
#define STEP_TIME_MS 50
#define HOLD_STEPS 40

@implementation FrutselaarView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        path = NULL;
        grid = NULL;
        [self setAnimationTimeInterval:STEP_TIME_MS / 1000.0];
        scale = (int) ((frame.size.width < frame.size.height ? frame.size.width : frame.size.height) / GRIDSIZE);
        if (scale >= 8)
            scale &= ~7;
        srandom((unsigned int) time(NULL));
        pw = (int) frame.size.width;
        ph = (int) frame.size.height;
    }
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)startAnimation
{
    grid = (char *) malloc(GRIDSIZE * GRIDSIZE);
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
    CGContextSetRGBFillColor(myContext, 0, 0, 0, 1.0);
    CGContextFillRect(myContext, NSRectToCGRect(rect));
    
    if (grid == NULL)
        return;

    CGContextSetRGBStrokeColor(myContext, 0.0, 1.0, 0.0, 1.0);
    CGContextSetLineWidth(myContext, scale / 8);
    
    char *cp = grid;
    for (int y = 0; y < GRIDSIZE; y++)
        for (int x = 0; x < GRIDSIZE; x++) {
            int c = *cp++;
            if (c < 1 || c > 6)
                continue;
            CGContextBeginPath(myContext);
            switch (c) {
                case 1: // │
                    CGContextMoveToPoint(myContext, xoff + (x + 0.5) * scale, yoff + y * scale);
                    CGContextAddLineToPoint(myContext, xoff + (x + 0.5) * scale, yoff + (y + 1) * scale);
                    break;
                case 2: // ─
                    CGContextMoveToPoint(myContext, xoff + x * scale, yoff + (y + 0.5) * scale);
                    CGContextAddLineToPoint(myContext, xoff + (x + 1) * scale, yoff + (y + 0.5) * scale);
                    break;
                case 3: // └
                    CGContextMoveToPoint(myContext, xoff + (x + 0.5) * scale, yoff + y * scale);
                    CGContextAddArcToPoint(myContext, xoff + (x + 0.5) * scale, yoff + (y + 0.5) * scale, xoff + (x + 1) * scale, yoff + (y + 0.5) * scale, 0.5 * scale);
                    break;
                case 4: // ┌
                    CGContextMoveToPoint(myContext, xoff + (x + 0.5) * scale, yoff + (y + 1) * scale);
                    CGContextAddArcToPoint(myContext, xoff + (x + 0.5) * scale, yoff + (y + 0.5) * scale, xoff + (x + 1) * scale, yoff + (y + 0.5) * scale, 0.5 * scale);
                    break;
                case 5: // ┐
                    CGContextMoveToPoint(myContext, xoff + x * scale, yoff + (y + 0.5) * scale);
                    CGContextAddArcToPoint(myContext, xoff + (x + 0.5) * scale, yoff + (y + 0.5) * scale, xoff + (x + 0.5) * scale, yoff + (y + 1) * scale, 0.5 * scale);
                    break;
                case 6: // ┘
                    CGContextMoveToPoint(myContext, xoff + x * scale, yoff + (y + 0.5) * scale);
                    CGContextAddArcToPoint(myContext, xoff + (x + 0.5) * scale, yoff + (y + 0.5) * scale, xoff + (x + 0.5) * scale, yoff + y * scale, 0.5 * scale);
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
            int d = path[i];
            if (d != 1) {
                if (d == 2)
                    dir--;
                else
                    dir++;
                dir &= 3;
            }
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
        }
        if (xmax - xmin + 1 > GRIDSIZE || ymax - ymin + 1 > GRIDSIZE) {
            free(path);
            goto retry;
        }
        
        // We have a good path; final initializations
        x = -xmin;
        y = -ymin;
        xoff = (pw - (xmax - xmin + 1) * scale) / 2;
        yoff = (ph - (ymax - ymin + 1) * scale) / 2;
        dir = 0;
        pos = 0;
        memset(grid, 0, GRIDSIZE * GRIDSIZE);
    }
    
    if (pos < length) {
        int c = path[pos++];
        switch (dir) {
            case 0:
                grid[x + y * GRIDSIZE] = c == 1 ? 1 : c == 2 ? 5 : 4;
                break;
            case 1:
                grid[x + y * GRIDSIZE] = c == 1 ? 2 : c == 2 ? 6 : 5;
                break;
            case 2:
                grid[x + y * GRIDSIZE] = c == 1 ? 1 : c == 2 ? 3 : 6;
                break;
            case 3:
                grid[x + y * GRIDSIZE] = c == 1 ? 2 : c == 2 ? 4 : 3;
                break;
        }
        if (c != 1) {
            if (c == 2)
                dir--;
            else
                dir++;
            dir &= 3;
        }
        switch (dir) {
            case 0: y--; break;
            case 1: x++; break;
            case 2: y++; break;
            case 3: x--; break;
        }
        // TODO: Don't call setNeedsDisplayInRect, but draw the cell immediately
        [self setNeedsDisplayInRect:CGRectMake(0, 0, pw, ph)];
    } else {
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
