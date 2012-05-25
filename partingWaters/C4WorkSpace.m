//
//  C4WorkSpace.m
//  partingWaters
//
//  Created by Travis Kirton on 12-05-25.
//  Copyright (c) 2012 POSTFL. All rights reserved.
//

#import "C4WorkSpace.h" 

@interface C4WorkSpace ()
-(void)allowPartTheWaters;
-(void)reduceVolume;

@property (readwrite) CGPoint startPoint;
@property (readwrite) BOOL canPartTheWaters, partingTheWatersHasBegun;
@property (readwrite, strong) C4Sample *ocean, *thunder;
@property (readwrite, strong) NSTimer *volumeTimer;
@property (readwrite) CGFloat volumeReductionInterval;

@property (readwrite, strong) C4Movie *calm, *calmGlitch, *open, *water;
@property (readwrite, strong) C4Image *mask;
@end

@implementation C4WorkSpace {
}
@synthesize canPartTheWaters, partingTheWatersHasBegun, startPoint;
@synthesize ocean, thunder, volumeTimer, volumeReductionInterval;
@synthesize calm, calmGlitch, open, water;
@synthesize mask;

-(void)setup {
    
    self.ocean = [C4Sample sampleNamed:@"redsea.m4a"];
    [self.ocean prepareToPlay];
    self.ocean.loops = YES;
    
    self.thunder = [C4Sample sampleNamed:@"loud.m4a"];
    [self.thunder prepareToPlay];
    self.thunder.loops = YES;
    self.thunder.volume = 0.0f;
    
    [self.ocean play];
    [self.thunder play];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    longPress.minimumPressDuration = 0.5f;
    [self.canvas addGestureRecognizer:longPress];
    
    self.canPartTheWaters = YES;
    self.partingTheWatersHasBegun = NO;
    
    //create movies
    calm = [C4Movie movieNamed:@"calm.mov"];
    calmGlitch = [C4Movie movieNamed:@"calm_glitch.mov"];
    open = [C4Movie movieNamed:@"open.mov"];
    water = [C4Movie movieNamed:@"water.mov"];
    
    //create mask
    mask = [C4Image imageNamed:@"mask.png"];
    
    //set up open movie
    open.layer.mask = mask.layer;
    open.height = 768;
    open.loops = YES;
    open.origin = CGPointMake(-768, -1024);
    open.transform = CGAffineTransformMakeRotation(HALF_PI);
    open.userInteractionEnabled = NO;
    
    //set up calm movie
    calm.height = 768;
    calm.loops = YES;
    calm.transform = CGAffineTransformMakeRotation(HALF_PI);
    calm.origin = CGPointZero;
    calm.userInteractionEnabled = NO;
    
    water.transform = CGAffineTransformMakeRotation(HALF_PI);
    water.origin = CGPointZero;
    water.alpha = 0.1;
    water.loops = YES;
    water.userInteractionEnabled = NO;
    
    //set up calm glitch
    calmGlitch.height = 768;
    calmGlitch.loops = YES;
    calmGlitch.transform = CGAffineTransformMakeRotation(HALF_PI);
    calmGlitch.origin = CGPointZero;
    calmGlitch.alpha = 0.0f;
    calmGlitch.userInteractionEnabled = NO;
    
    [self.canvas addMovie:calm];
    [self.canvas addMovie:water];
    [self.canvas addMovie:calmGlitch];
    
    [self.canvas addMovie:open];
}

-(void)handleLongPressGesture:(id)sender {
    UILongPressGestureRecognizer *lp = (UILongPressGestureRecognizer *)sender;
    CGPoint touchPoint = [lp locationInView:self.canvas];
    switch (lp.state) {
        case UIGestureRecognizerStateBegan:
            if(touchPoint.x < 50) {
                self.open.animationDuration = 0.0f;
                self.partingTheWatersHasBegun = YES;
                self.startPoint = CGPointMake(touchPoint.x-self.open.frame.size.width-50, touchPoint.y-1024);
                self.open.origin = self.startPoint;
            }
            break;
        case UIGestureRecognizerStateChanged:
            if(self.partingTheWatersHasBegun) {
                self.thunder.volume = touchPoint.x / 768.0f;
                self.ocean.volume = 1.0-self.thunder.volume;
                
                self.open.origin = CGPointMake(touchPoint.x-self.open.frame.size.width, self.open.origin.y);
            }
            break;
        case UIGestureRecognizerStateEnded:
            if(self.partingTheWatersHasBegun) {
                self.canvas.userInteractionEnabled = NO;
                self.canPartTheWaters = NO;
                self.open.animationDuration = touchPoint.x/768 * 3.0 + 1.0f;
                self.open.origin = self.startPoint;
                
                CGFloat frames = open.animationDuration * 30.0f;
                self.volumeReductionInterval = self.thunder.volume / frames;
                
                self.volumeTimer = [NSTimer timerWithTimeInterval:1.0f/30.0f target:self selector:@selector(reduceVolume) userInfo:nil repeats:YES];
                
                [[NSRunLoop mainRunLoop] addTimer:self.volumeTimer forMode:NSDefaultRunLoopMode];
                [self performSelector:@selector(allowPartTheWaters) 
                           withObject:nil 
                           afterDelay:open.animationDuration+0.1];
            }
            break;
        default:
            break;
    }
}

-(void)allowPartTheWaters {
    [self.volumeTimer invalidate];
    self.canPartTheWaters = YES;
    self.partingTheWatersHasBegun = NO;
    self.canvas.userInteractionEnabled = YES;
}

-(void)reduceVolume {
    if(self.partingTheWatersHasBegun == YES) {
        CGFloat newVolume = self.thunder.volume - self.volumeReductionInterval;
        if(newVolume >= 0.0f) {
            self.thunder.volume = newVolume;        
            self.ocean.volume = 1.0f - self.thunder.volume;
        }
    }
}

@end
