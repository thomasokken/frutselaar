//
//  Frutselaar.cpp
//  Frutselaar
//
//  Created by Thomas Okken on 16-12-2024.
//

// Windows Header Files
#include <windows.h>
//#include <wingdi.h>
#include <ScrnSave.h>
// C RunTime Header Files
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>

#define GRIDSIZE 25
#define MAXLENGTH 100
#define STEP_TIME_MS 50
#define HOLD_STEPS 40

static int pw, ph, scale;
static int length, pos;
static char *path;
static char *grid;
static int delay;
static int x, y, xoff, yoff, dir;

static UINT_PTR timer = 0;

LRESULT WINAPI ScreenSaverProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_CREATE:
        {
            wcscpy_s(szAppName, L"Frutselaar");
            wcscpy_s(szIniFile, L"");

            path = NULL;
            grid = NULL;
            RECT r;
            GetClientRect(hwnd, &r);
            long width = r.right - r.left;
            long height = r.bottom - r.top;
            scale = (int) ((width < height ? width : height) / GRIDSIZE);
            if (scale >= 8)
                scale &= ~7;
            srand((unsigned int) GetTickCount());
            pw = (int) width;
            ph = (int) height;

            grid = (char *) malloc(GRIDSIZE * GRIDSIZE);
            path = NULL;

            timer = SetTimer(hwnd, 1, STEP_TIME_MS, NULL);
            break;
        }

        case WM_ERASEBKGND:
        {
            HDC hdc = GetDC(hwnd);
            RECT r;
            GetClientRect(hwnd, &r);
            FillRect(hdc, &r, (HBRUSH) GetStockObject(BLACK_BRUSH));
            ReleaseDC(hwnd, hdc);
            break;
        }

        case WM_TIMER:
        {
            if (path == NULL) {
                // Generate path
                retry:
                length = (int) ((rand() / (double) RAND_MAX) * MAXLENGTH) + 1;
                path = (char*) malloc(4 * (length + 1));
                bool straight = true;
                for (int i = 0; i < length; i++) {
                    int d = (int) ((rand() / (double) RAND_MAX) * 3) + 1;
                    path[i] = d;
                    if (d != 1)
                        straight = !straight;
                }
                if (straight)
                    path[length++] = (int) ((rand() / (double) RAND_MAX) * 2) + 2;
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

                HDC hdc = GetDC(hwnd);
                RECT r;
                r.left = xoff + x * scale;
                r.top = yoff + y * scale;
                r.right = r.left + scale;
                r.bottom = r.top + scale;
                FillRect(hdc, &r, (HBRUSH) GetStockObject(BLACK_BRUSH));
                c = grid[x + y * GRIDSIZE];
                HPEN pen = CreatePen(PS_SOLID, scale / 8, RGB(0, 255, 0));
                HPEN oldPen = (HPEN) SelectObject(hdc, pen);
                switch (c) {
                    case 1: // │
                        MoveToEx(hdc, xoff + (x + 0.5) * scale, yoff + y * scale, NULL);
                        LineTo(hdc, xoff + (x + 0.5) * scale, yoff + (y + 1) * scale);
                        break;
                    case 2: // ─
                        MoveToEx(hdc, xoff + x * scale, yoff + (y + 0.5) * scale, NULL);
                        LineTo(hdc, xoff + (x + 1) * scale, yoff + (y + 0.5) * scale);
                        break;
                    case 3: // └
                        Arc(hdc,
                            xoff + (x + 0.5) * scale, yoff + (y - 0.5) * scale,
                            xoff + (x + 1.5) * scale, yoff + (y + 0.5) * scale,
                            xoff + (x + 0.5) * scale, yoff + y * scale,
                            xoff + (x + 1) * scale, yoff + (y + 0.5) * scale);
                        break;
                    case 4: // ┌
                        Arc(hdc,
                            xoff + (x + 0.5) * scale, yoff + (y + 0.5) * scale,
                            xoff + (x + 1.5) * scale, yoff + (y + 1.5) * scale,
                            xoff + (x + 1) * scale, yoff + (y + 0.5) * scale,
                            xoff + (x + 0.5) * scale, yoff + (y + 1) * scale);
                        break;
                    case 5: // ┐
                        Arc(hdc,
                            xoff + (x - 0.5) * scale, yoff + (y + 0.5) * scale,
                            xoff + (x + 0.5) * scale, yoff + (y + 1.5) * scale,
                            xoff + (x + 0.5) * scale, yoff + (y + 1) * scale,
                            xoff + x * scale, yoff + (y + 0.5) * scale);
                        break;
                    case 6: // ┘
                        Arc(hdc,
                            xoff + (x - 0.5) * scale, yoff + (y - 0.5) * scale,
                            xoff + (x + 0.5) * scale, yoff + (y + 0.5) * scale,
                            xoff + x * scale, yoff + (y + 0.5) * scale,
                            xoff + (x + 0.5) * scale, yoff + y * scale);
                        break;
                }
                SelectObject(hdc, oldPen);
                DeleteObject(pen);
                ReleaseDC(hwnd, hdc);

                switch (dir) {
                    case 0: y--; break;
                    case 1: x++; break;
                    case 2: y++; break;
                    case 3: x--; break;
                }
            } else {
                pos++;
                if (pos - length > HOLD_STEPS) {
                    free(path);
                    path = NULL;
                    HDC hdc = GetDC(hwnd);
                    RECT r;
                    GetClientRect(hwnd, &r);
                    FillRect(hdc, &r, (HBRUSH) GetStockObject(BLACK_BRUSH));
                    ReleaseDC(hwnd, hdc);
                }
            }
            break;
        }

        case WM_DESTROY:
        {
            if (timer != 0) {
                KillTimer(hwnd, timer);
                timer = 0;
            }
            free(grid);
            grid = NULL;
            free(path);
            path = NULL;
            break;
        }
    }

    // DefScreenSaverProc processes any messages ignored by ScreenSaverProc. 
    return DefScreenSaverProc(hwnd, message, wParam, lParam);
}

BOOL WINAPI ScreenSaverConfigureDialog(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    // Should never be called
    return TRUE;
}

BOOL WINAPI RegisterDialogClasses(HANDLE hInst)
{
    // Should never be called
    return TRUE;
}