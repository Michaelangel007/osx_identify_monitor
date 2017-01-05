/*
OSX Identify Monitor
Michaelangel007
Date: January 2017
Version: 1.0

Known Bugs: Need to Command-Tab away then back before can click on menu

Compile:

    gcc identify_monitor.m -framework Cocoa -x objective-c -o "Identify Monitor.app"
*/

// Includes
    #import <Foundation/Foundation.h>
    #import <Cocoa/Cocoa.h>


// Consts
    #define MAX_DISPLAYS 9

// Globals
    int     gnView = 0 ;

// Implementation
// ________________________________________________________________________

    /*
        Segment order

           3
        x-----x
        |     |
       6|     |7
        |  2  |
        x-----x
        |     |
       4|     |5
        |     |
        x-----x
           1

    */
    typedef struct LineSegment
    {
        CGPoint from;
        CGPoint to  ;
    } LineSegment;

    LineSegment gaSegment[ 8 ] =
    {
        { { 0, 0 }, { 0, 0 } }, // 0 = n/a
        { { 0, 1 }, { 1, 1 } }, // 1st
        { { 0,0.5}, { 1,0.5} }, // 2nd
        { { 0, 0 }, { 1, 0 } }, // 3rd
        { { 0,0.5}, { 0, 1 } }, // 4th
        { { 1,0.5}, { 1, 1 } }, // 5th
        { { 0, 0 }, { 0,0.5} }, // 6th
        { { 1, 0 }, { 1,0.5} }, // 7th
    };

    int gaDigitSegments[ 10 ] =
    { //  1|2|3|4| 5| 6| 7  // bitmask for segments
          1|  4|8|16|32|64, // 0
                  16|   64, // 1
          1|2|4|8|      64, // 2
          1|2|4|  16|   64, // 3
            2|    16|32|64, // 4
          1|2|4|  16|32   , // 5
          1|2|4|8|16|32   , // 6
              4|  16|   64, // 7
          1|2|4|8|16|32|64, // 8
          1|2|4|  16|32|64, // 9
    };

    // ========================================================================
    void drawDigitLED( int digit, NSColor *fg, NSRect scale )
    {
        if( digit < 0)
            digit = 0;
        if( digit > 9)
            digit = 9;

        float screenW = scale.size.width;
        float screenH = scale.size.height;

        float scaleX = (screenW - 1) / 4;
        float scaleY = (screenH - 1)    ;

        int iSegment;
        int bMask = gaDigitSegments[ digit ];

        float thickness = 64.0;
        float nudge = thickness / screenH;

        NSBezierPath * path = [NSBezierPath bezierPath];
        [path setLineWidth: thickness];

        for( iSegment = 1; iSegment <= 8; iSegment++ )
        {
            if (bMask & 1 )
            {
                NSPoint from = gaSegment[ iSegment ].from;
                NSPoint to   = gaSegment[ iSegment ].to  ;

                // Screen Origin is top left
                from.y = 1.0 - from.y;
                to  .y = 1.0 - to  .y;

                // "Safe Area" nudge in from screen edge
                if( from.y <= 0.0 ) from.y += nudge;
                if( from.y >= 1.0 ) from.y -= nudge;

                if( to.y <= 0.0 ) to.y += nudge;
                if( to.y >= 1.0 ) to.y -= nudge;

                // Un-normalize
                from.x *= scaleX; from.y *= scaleY;
                to  .x *= scaleX; to  .y *= scaleY;

                // Center
                from.x += (screenW - scaleX) * 0.5;
                to  .x += (screenW - scaleX) * 0.5;

                // Draw
                [path moveToPoint: from ];    
                [path lineToPoint: to   ];
                [fg set];
                [path stroke];
            }

            bMask >>= 1;
        }
    }

// ________________________________________________________________________

@interface MyView : NSView
    @property(assign) NSColor* fg;
    @property(assign) int      digit; // 0 .. 8
    @property(assign) NSRect   offset;
@end

@implementation MyView
    // ========================================================================
    - (void)drawRect:(NSRect)rect
    {
        NSColor *color = [self fg];
        int      digit = [self digit];
        NSRect   size  = [self offset];

        drawDigitLED( digit + 1, color, size );
    }

    // ========================================================================
    -(BOOL) shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent
    {
        return YES;
    }

    // ========================================================================
    - (BOOL)acceptsFirstResponder
    {
        return NO;
    }

    // ========================================================================
    - (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
    {
        return NO;
    }
@end

// ________________________________________________________________________

@interface MyOverlay : NSWindow
{
    MyView *_pView;
}
@end

@implementation MyOverlay

    -(id) 
        initWithContentRect:(NSRect)             contentRect
        styleMask          :(NSUInteger)         windowstyle
        backing            :(NSBackingStoreType) bufferingType
        defer              :(BOOL)               deferCreation
    {
        self = [super
            initWithContentRect:contentRect
            styleMask: windowstyle   // NSTitledWindowMask NSBorderlessWindowMask
            backing  : bufferingType // NSBackingStoreBuffered
            defer    : deferCreation // NO
        ];

        if (self)
        {
            [self setHasShadow      : NO ];
            [self setAlphaValue     : 1.0];
            [self setOpaque         : NO ];
            [self setBackgroundColor:[NSColor clearColor]];

            [self setCollectionBehavior:
                ( NSWindowCollectionBehaviorCanJoinAllSpaces
                | NSWindowCollectionBehaviorStationary
                | NSWindowCollectionBehaviorIgnoresCycle
                )
            ];
            [self orderFrontRegardless];

            MyView *pView = [[MyView alloc] initWithFrame:contentRect];
            pView.wantsLayer   = true;
            pView.needsDisplay = true;

            pView.offset = contentRect;
            pView.digit  = gnView;

            _pView = pView;
            [self setContentView: pView];
        }

        return self;
    }

    // ========================================================================
    - (void)setColorFG: (NSColor*)theColor
    {
        _pView.fg = theColor;
    }

    // ========================================================================
    - (BOOL)canBecomeMainWindow
    {
        return YES;
    }

    // ========================================================================
    - (BOOL)canBecomeKeyWindow
    {
        return YES;
    }

    // ========================================================================
    - (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
    {
        return NO;
    }

    // ========================================================================
    - (BOOL)acceptsMouseMovedEvents
    {
        return NO;
    }

    // ========================================================================
    - (BOOL)acceptsFirstResponder
    {
        return NO;
    }

    // Can click through BUT
    // ========================================================================
    - (BOOL) ignoresMouseEvents
    {
        return YES;
    }

    // Don't accept mouse click
    // ========================================================================
    - (NSView*)hitTest:(NSPoint)aPoint
    {
        return nil;
    }
@end

int main ()
{
    [NSAutoreleasePool new];
    [NSApplication     sharedApplication];
    [NSApp             setActivationPolicy:NSApplicationActivationPolicyRegular];

    id menubar     = [[NSMenu     new] autorelease];
    id appMenuItem = [[NSMenuItem new] autorelease];

    [menubar addItem:appMenuItem];
    [NSApp setMainMenu:menubar];

    id appMenu      = [[NSMenu new] autorelease];
    id appName      = [[NSProcessInfo processInfo] processName];
    id quitTitle    = [@"Quit " stringByAppendingString:appName];
    id quitMenuItem =
    [
        [
            [NSMenuItem alloc]
            initWithTitle:quitTitle
            action:@selector(terminate:) keyEquivalent:@"q"
        ]
        autorelease
    ];

    [appMenu     addItem:quitMenuItem];
    [appMenuItem setSubmenu:appMenu  ];

    float hue = 0.0; // cycle: Red, Green, Blue

    for( NSScreen *pScreen in [NSScreen screens] )
    {
        NSRect   rect = [pScreen frame];
        NSColor *fg   = [NSColor colorWithCalibratedHue:hue saturation:1.0 brightness:1.0 alpha:1];

        id window =
        [
            [
                [MyOverlay alloc]
                initWithContentRect:rect
                styleMask: NSBorderlessWindowMask
                backing  : NSBackingStoreBuffered defer:NO
            ]
            autorelease
        ];

        [window setColorFG:fg];

        [window setLevel:kCGMaximumWindowLevel];
        [window setTitle:appName];
        [window makeKeyAndOrderFront:nil];

        gnView++;
        if( gnView > MAX_DISPLAYS )
            break;

        hue += 120./360.;
        if( hue >= 1.0)
        {
            hue -= 1.0;
            hue += 60./360.; // cycle: Yellow, Cyan, Magenta
        }
    }

    [NSApp activateIgnoringOtherApps:YES];
    [NSApp run];

    return 0;
}

