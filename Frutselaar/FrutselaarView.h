//
//  FrutselaarView.h
//  Frutselaar
//
//  Created by Thomas Okken on 01-12-2023.
//

#import <ScreenSaver/ScreenSaver.h>

@interface FrutselaarView : ScreenSaverView {
    int pw, ph, scale;
    int length, pos;
    char *path;
    char *grid;
    int delay;
    int x, y, xoff, yoff, dir;
}

@end
