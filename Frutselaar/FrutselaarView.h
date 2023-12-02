//
//  FrutselaarView.h
//  Frutselaar
//
//  Created by Thomas Okken on 01-12-2023.
//

#import <ScreenSaver/ScreenSaver.h>

@interface FrutselaarView : ScreenSaverView {
    int w, h, xoff, yoff;
    char *path;
    char *grid;
    int delay;
}

@end
