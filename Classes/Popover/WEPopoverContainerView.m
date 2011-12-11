//
//  WEPopoverContainerViewProperties.m
//  WEPopover
//
//  Created by Werner Altewischer on 02/09/10.
//  Copyright 2010 Werner IT Consultancy. All rights reserved.
//

#import "WEPopoverContainerView.h"

@implementation WEPopoverContainerViewProperties

@synthesize bgImageName, upArrowImageName, downArrowImageName, leftArrowImageName, rightArrowImageName, topBgMargin, bottomBgMargin, leftBgMargin, rightBgMargin, topBgCapSize, leftBgCapSize;
@synthesize leftContentMargin, rightContentMargin, topContentMargin, bottomContentMargin, arrowMargin;

- (void)dealloc {
	self.bgImageName = nil;
	self.upArrowImageName = nil;
	self.downArrowImageName = nil;
	self.leftArrowImageName = nil;
	self.rightArrowImageName = nil;
	[super dealloc];
}

@end
#import <QuartzCore/QuartzCore.h>

@interface WEPopoverContainerView(Private)

- (void)determineGeometryForSize:(CGSize)theSize anchorRect:(CGRect)anchorRect displayArea:(CGRect)displayArea permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections;
- (CGSize)contentSize;
- (void)setProperties:(WEPopoverContainerViewProperties *)props;
- (void)initView;
- (void)layoutView;

@end

@implementation WEPopoverContainerView

@synthesize arrowDirection, contentView;

- (CGRect)correctedDisplayAreaForRect:(CGRect)rect {
    int padding = 2;
    return CGRectInset(rect, padding, padding);
}

- (id)initWithSize:(CGSize)theSize 
		anchorRect:(CGRect)anchorRect 
	   displayArea:(CGRect)displayArea
permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections
		properties:(WEPopoverContainerViewProperties *)theProperties {
	if ((self = [super initWithFrame:CGRectZero])) {
		
		[self setProperties:theProperties];
		originalSize = theSize;	
        originalAnchorRect = anchorRect;
		[self determineGeometryForSize:originalSize 
                            anchorRect:anchorRect 
                           displayArea:[self correctedDisplayAreaForRect:displayArea] 
              permittedArrowDirections:permittedArrowDirections];
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = YES;
		self.userInteractionEnabled = YES;
        [self initView];
        [self layoutView];
	}
	return self;
}

- (void)dealloc {
	[properties release];
	[contentView release];
	[bgImage release];
	[arrowImage release];
	[super dealloc];
}

- (void)updateDisplayArea:(CGRect)displayArea {
    [self determineGeometryForSize:originalSize 
                        anchorRect:originalAnchorRect 
                       displayArea:[self correctedDisplayAreaForRect:displayArea] 
          permittedArrowDirections:arrowDirection];
    [self layoutView];
}

- (void)updatePositionWithAnchorRect:(CGRect)anchorRect 
						 displayArea:(CGRect)displayArea
			permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections {
    
    [self determineGeometryForSize:originalSize 
                        anchorRect:anchorRect 
                       displayArea:[self correctedDisplayAreaForRect:displayArea] 
          permittedArrowDirections:permittedArrowDirections];
    [self initView];
    [self layoutView];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	return CGRectContainsPoint(contentRect, point);	
} 

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
}

- (void)setContentView:(UIView *)v {
	if (v != contentView) {
		[contentView release];
		contentView = [v retain];		
		contentView.frame = contentRect;
        contentView.autoresizingMask = UIViewAutoresizingNone;
        contentView.layer.cornerRadius = 4;
        contentView.layer.masksToBounds = YES;
        contentView.opaque = NO;
		[self addSubview:contentView];
	}
}



@end

@implementation WEPopoverContainerView(Private)
																	 

- (CGSize)contentSize {
	return contentRect.size;
}

- (CGRect)checkRect:(CGRect)rect inArea:(CGRect)area checkAction:(WEPopoverCheckBounds)checkAction fixAction:(WEPopoverFixAction)fixAction {
    BOOL needToFix = NO;
    switch (checkAction) {
        case WEPopoverCheckBoundsLeft:
            needToFix = (CGRectGetMinX(rect) < CGRectGetMinX(area));
            break;
        case WEPopoverCheckBoundsRight:
            needToFix = (CGRectGetMaxX(rect) > CGRectGetMaxX(area));
            break;
        case WEPopoverCheckBoundsBottom:
            needToFix = (CGRectGetMaxY(rect) > CGRectGetMaxY(area));
            break;
        case WEPopoverCheckBoundsTop:
            needToFix = (CGRectGetMinY(rect) < CGRectGetMinY(area));
            break;
    }
    if (!needToFix) return rect;
    float diff = 0.0;
    switch (fixAction) {
        case WEPopoverShiftLeft:
            rect.origin.x -= CGRectGetMaxX(rect) - CGRectGetMaxX(area);
            break;
        case WEPopoverShiftRight:
            rect.origin.x += CGRectGetMinX(area) - CGRectGetMinX(rect);
            break;
        case WEPopoverShiftDown:
            rect.origin.y += CGRectGetMinY(area) - CGRectGetMinY(rect);
            break;
        case WEPopoverShiftUp:
            rect.origin.y -= CGRectGetMaxY(rect) - CGRectGetMaxY(area);
            break;
        case WEPopoverCutLeft:
            diff = MAX(0, CGRectGetMinX(area) - CGRectGetMinX(rect));
            rect.size.width -= diff;
            rect.origin.x += diff;
            break;
        case WEPopoverCutRight:
            rect.size.width -= MAX(0, CGRectGetMaxX(rect) - CGRectGetMaxX(area));
            break;
        case WEPopoverCutTop:
            diff = MAX(0, CGRectGetMinY(area) - CGRectGetMinY(rect));
            rect.size.height -= diff;
            rect.origin.y += diff;
            break;
        case WEPopoverCutBottom:
            rect.size.height -= MAX(0, CGRectGetMaxY(rect) - CGRectGetMaxY(area));
            break;
    }
    return rect;
}

- (float)arrowPositionForRect:(CGRect)rect anchorPoint:(CGPoint)anchor arrowDirection:(UIPopoverArrowDirection)direction {
    int leftSideArrowPadding = 10;
    int rightSideArrowPadding = 10;
    int topSideArrowPadding = 25;
    int bottomSideArrowPadding = 10;
    float arrowWidth = 27.0;
    float position;
    switch (direction) {
        case UIPopoverArrowDirectionUp:
        case UIPopoverArrowDirectionDown:
            position = MAX(leftSideArrowPadding, anchor.x-rect.origin.x-arrowWidth/2.0);
            position = MIN(position, rect.size.width-rightSideArrowPadding-arrowWidth);
            if ((position+arrowWidth/2.0) > anchor.x-rect.origin.x) {
                // TODO: Make use of a left corner image
            } else if ((position+arrowWidth/2.0) < anchor.x) {
                // TODO: Make use of a right corner image
            }
            break;
        case UIPopoverArrowDirectionLeft:
        case UIPopoverArrowDirectionRight:
            position = MAX(topSideArrowPadding, anchor.y-rect.origin.y-arrowWidth/2.0);
            position = MIN(position, rect.size.height-bottomSideArrowPadding-arrowWidth);
            if ((position+arrowWidth/2.0) > anchor.y-rect.origin.y) {
                // TODO: Make use of a top corner image
            } else if ((position+arrowWidth/2.0) < anchor.y) {
                // TODO: Make use of a bottom corner image
            }
            break;
    }
    return position;
}

- (void)determineGeometryForSize:(CGSize)contentSize anchorRect:(CGRect)anchorRect displayArea:(CGRect)displayArea permittedArrowDirections:(UIPopoverArrowDirection)supportedArrowDirections {	
	
	//Determine the frame, it should not go outside the display area
	UIPopoverArrowDirection arrowDirectionTest = UIPopoverArrowDirectionUp;
	backgroundRect = CGRectZero;
    arrowDirection = UIPopoverArrowDirectionUnknown;
    CGFloat biggestSurface = 0.0f;
    
    int contentPadding = 6;
    int arrowHeight = 15;
    
	while (arrowDirectionTest <= UIPopoverArrowDirectionRight) {
		
		if ((supportedArrowDirections & arrowDirectionTest)) {
			
            CGSize contentSizeTest = contentSize;
            CGRect bgRectTest = CGRectZero;
            CGPoint anchorPointTest = CGPointZero;
            
            // Starting rect based on the content size.
            bgRectTest = CGRectMake(0, 0, contentSizeTest.width, contentSizeTest.height);
            bgRectTest = CGRectInset(bgRectTest, -contentPadding, -contentPadding);
            
			switch (arrowDirectionTest) {
				case UIPopoverArrowDirectionUp:
					
					anchorPointTest = CGPointMake(CGRectGetMidX(anchorRect), CGRectGetMaxY(anchorRect));
					
                    // Check if anchorPoint is under the displayArea (due to keyboard showing)
                    if (anchorPointTest.y > CGRectGetMaxY(displayArea)) {
                        // Shift the point to the visible area
                        anchorPointTest.y = CGRectGetMaxY(displayArea);
                    }
                    
                    bgRectTest.size.height += arrowHeight;
                    
                    // Position the rect centered to the anchor.
                    bgRectTest.origin.x = anchorPointTest.x - bgRectTest.size.width/2;
                    bgRectTest.origin.y = anchorPointTest.y;
                    
					// Fix position and size. 
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsRight fixAction:WEPopoverShiftLeft];
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsLeft fixAction:WEPopoverShiftRight];
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsRight fixAction:WEPopoverCutRight];
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsBottom fixAction:WEPopoverCutBottom];
                    
                    break;
                    
                    
				case UIPopoverArrowDirectionDown:
					
					anchorPointTest = CGPointMake(CGRectGetMidX(anchorRect), CGRectGetMinY(anchorRect));
                    
                    // Check if anchorPoint is under the displayArea (due to keyboard showing)
                    if (anchorPointTest.y > CGRectGetMaxY(displayArea)) {
                        // Shift the point to the visible area
                        anchorPointTest.y = CGRectGetMaxY(displayArea);
                    }
                    
                    bgRectTest.size.height += arrowHeight;
                    
                    // Position the rect centered to the anchor.
                    bgRectTest.origin.x = anchorPointTest.x - bgRectTest.size.width/2;
                    bgRectTest.origin.y = anchorPointTest.y - bgRectTest.size.height;
                    
                    // Fix position and size. 
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsRight fixAction:WEPopoverShiftLeft];
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsLeft fixAction:WEPopoverShiftRight];
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsRight fixAction:WEPopoverCutRight];
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsTop fixAction:WEPopoverCutTop];
                    break;
                    
                    
				case UIPopoverArrowDirectionLeft:
					
					anchorPointTest = CGPointMake(CGRectGetMaxX(anchorRect), CGRectGetMidY(anchorRect));
					
                    // Check if anchorPoint is under the displayArea (due to keyboard showing)
                    if (anchorPointTest.y > CGRectGetMaxY(displayArea)) {
                        // Shift the point to the visible area
                        anchorPointTest.y = CGRectGetMaxY(displayArea);
                    }
                    
                    bgRectTest.size.width += arrowHeight;
                    
                    // Position the rect centered to the anchor.
                    bgRectTest.origin.x = anchorPointTest.x;
                    bgRectTest.origin.y = anchorPointTest.y - bgRectTest.size.height/2;
                    
                    // Fix position and size. 
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsTop fixAction:WEPopoverShiftDown];
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsBottom fixAction:WEPopoverShiftUp];
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsTop fixAction:WEPopoverCutTop];
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsRight fixAction:WEPopoverCutRight];
                    
                    break;
      
                    
				case UIPopoverArrowDirectionRight:
					
					anchorPointTest = CGPointMake(CGRectGetMinX(anchorRect), CGRectGetMidY(anchorRect));
                    
                    // Check if anchorPoint is under the displayArea (due to keyboard showing)
                    if (anchorPointTest.y > CGRectGetMaxY(displayArea)) {
                        // Shift the point to the visible area
                        anchorPointTest.y = CGRectGetMaxY(displayArea);
                    }
                    
                    bgRectTest.size.width += arrowHeight;
                    
                    // Position the rect centered to the anchor.
                    bgRectTest.origin.x = anchorPointTest.x - bgRectTest.size.width;
                    bgRectTest.origin.y = anchorPointTest.y - bgRectTest.size.height/2;

                    // Fix position and size. 
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsTop fixAction:WEPopoverShiftDown];
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsBottom fixAction:WEPopoverShiftUp];
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsTop fixAction:WEPopoverCutTop];
                    bgRectTest = [self checkRect:bgRectTest inArea:displayArea checkAction:WEPopoverCheckBoundsLeft fixAction:WEPopoverCutLeft];
                    
					break;
			}
            
            // Figure out the new adjusted content rect.
            bgRectTest = CGRectIntegral(bgRectTest);
            CGRect contentRectTest = CGRectMake(0, 0, bgRectTest.size.width, bgRectTest.size.height);
            switch (arrowDirectionTest) {
                case UIPopoverArrowDirectionUp:
                    contentRectTest.size.height -= arrowHeight;
                    contentRectTest.origin.y += arrowHeight;
                    break;
                case UIPopoverArrowDirectionDown:
                    contentRectTest.size.height -= arrowHeight;
                    break;
                case UIPopoverArrowDirectionLeft:
                    contentRectTest.size.width -= arrowHeight;
                    contentRectTest.origin.x += arrowHeight;
                    break;
                case UIPopoverArrowDirectionRight:
                    contentRectTest.size.width -= arrowHeight;
                    break;
            }
            contentRectTest = CGRectInset(contentRectTest, contentPadding, contentPadding);
            
			// Check surface area of the contentRect instead of background due to the difference of size between the images.
			CGFloat surface = fabsf(contentRectTest.size.width) * fabsf(contentRectTest.size.height);
            
			if (surface > biggestSurface) {
				biggestSurface = surface;
				backgroundRect = bgRectTest;
                contentRect = contentRectTest;
				arrowDirection = arrowDirectionTest;
                arrowOffset = [self arrowPositionForRect:bgRectTest anchorPoint:anchorPointTest arrowDirection:arrowDirection];    
			}
		}
		
		arrowDirectionTest <<= 1;
	}
	
	NSAssert(!CGRectEqualToRect(backgroundRect, CGRectNull), @"backgroundRect is null");
    
    if (contentView) {
        contentView.frame = contentRect;
    }
}

- (UIImage *)croppedImage:(UIImage*)image rect:(CGRect)rect {
    CGImageRef croppedImg = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage *img = [UIImage imageWithCGImage:croppedImg scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(croppedImg);
    return img;
}
- (UIImage *)image:(UIImage*)image withOrientation:(UIImageOrientation)orientation {
    return [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:orientation];
}


- (void)initView {
    
    [leftOfArrow removeFromSuperview];
    [leftSideOfArrowStretch removeFromSuperview];
    [arrow removeFromSuperview];
    [rightSideOfArrowStretch removeFromSuperview];
    [rightOfArrow removeFromSuperview];
    [midStretch removeFromSuperview];
    [oppositeOfArrowStretch removeFromSuperview];
    
    UIImage *backImage = nil;
    
    switch (arrowDirection) {
		case UIPopoverArrowDirectionUp:
			backImage = [UIImage imageNamed:@"UIPopoverViewBlackBackgroundArrowUp.png"];
            leftOfArrowRect = CGRectMake(0, 0, 9, 37);
            rightOfArrowRect = CGRectMake(38, 0, 9, 37);
            sideOfArrowStretchRect = CGRectMake(9, 0, 1, 37);
            arrowRect = CGRectMake(10, 0, 27, 37);
            midStretchRect = CGRectMake(0, 37, 47, 1);
            oppositeOfArrowStretchRect = CGRectMake(0, 38, 47, 9);
            
            midStretch = [[UIImageView alloc] initWithImage:[[self croppedImage:backImage rect:midStretchRect] stretchableImageWithLeftCapWidth:leftOfArrowRect.size.width topCapHeight:0]];
            oppositeOfArrowStretch = [[UIImageView alloc] initWithImage:[[self croppedImage:backImage rect:oppositeOfArrowStretchRect] stretchableImageWithLeftCapWidth:leftOfArrowRect.size.width topCapHeight:0]];
            
			break;
            
		case UIPopoverArrowDirectionDown:
			backImage = [UIImage imageNamed:@"UIPopoverViewBlackBackgroundArrowDown.png"];
            leftOfArrowRect = CGRectMake(38, 24, 9, 23);
            rightOfArrowRect = CGRectMake(0, 24, 9, 23);
            sideOfArrowStretchRect = CGRectMake(9, 24, 1, 23);
            arrowRect = CGRectMake(10, 24, 27, 23);
            midStretchRect = CGRectMake(0, 23, 47, 1);
            oppositeOfArrowStretchRect = CGRectMake(0, 0, 47, 23);
            
            midStretch = [[UIImageView alloc] initWithImage:[[self croppedImage:backImage rect:midStretchRect] stretchableImageWithLeftCapWidth:leftOfArrowRect.size.width topCapHeight:0]];
            oppositeOfArrowStretch = [[UIImageView alloc] initWithImage:[[self croppedImage:backImage rect:oppositeOfArrowStretchRect] stretchableImageWithLeftCapWidth:leftOfArrowRect.size.width topCapHeight:0]];
            
			break;
		
		case UIPopoverArrowDirectionRight:
            backImage = [UIImage imageNamed:@"UIPopoverViewBlackBackgroundArrowRight.png"];
            leftOfArrowRect = CGRectMake(10, 0, 23, 24);
            rightOfArrowRect = CGRectMake(10, 53, 23, 9);
            sideOfArrowStretchRect = CGRectMake(10, 24, 23, 1);
            arrowRect = CGRectMake(10, 25, 23, 27);
            midStretchRect = CGRectMake(9, 0, 1, 62);
            oppositeOfArrowStretchRect = CGRectMake(0, 0, 9, 62);
            
            midStretch = [[UIImageView alloc] initWithImage:[[self croppedImage:backImage rect:midStretchRect] stretchableImageWithLeftCapWidth:0 topCapHeight:leftOfArrowRect.size.height]];
            oppositeOfArrowStretch = [[UIImageView alloc] initWithImage:[[self croppedImage:backImage rect:oppositeOfArrowStretchRect] stretchableImageWithLeftCapWidth:0 topCapHeight:leftOfArrowRect.size.height]];
            
			break;
            
        case UIPopoverArrowDirectionLeft:
            backImage = [UIImage imageNamed:@"UIPopoverViewBlackBackgroundArrowLeft.png"];
            leftOfArrowRect = CGRectMake(0, 53, 23, 9);
            rightOfArrowRect = CGRectMake(0, 0, 23, 24);
            sideOfArrowStretchRect = CGRectMake(0, 24, 23, 1);
            arrowRect = CGRectMake(0, 25, 23, 27);
            midStretchRect = CGRectMake(23, 0, 1, 62);
            oppositeOfArrowStretchRect = CGRectMake(24, 0, 9, 62);
            
            midStretch = [[UIImageView alloc] initWithImage:[[self croppedImage:backImage rect:midStretchRect] stretchableImageWithLeftCapWidth:0 topCapHeight:rightOfArrowRect.size.height]];
            oppositeOfArrowStretch = [[UIImageView alloc] initWithImage:[[self croppedImage:backImage rect:oppositeOfArrowStretchRect] stretchableImageWithLeftCapWidth:0 topCapHeight:rightOfArrowRect.size.height]];
            
            break;
	}
    
    
    
    leftOfArrow = [[UIImageView alloc] initWithImage:[self croppedImage:backImage rect:leftOfArrowRect]];
    rightOfArrow = [[UIImageView alloc] initWithImage:[self croppedImage:backImage rect:rightOfArrowRect]];
    leftSideOfArrowStretch = [[UIImageView alloc] initWithImage:[self croppedImage:backImage rect:sideOfArrowStretchRect]];
    rightSideOfArrowStretch = [[UIImageView alloc] initWithImage:[self croppedImage:backImage rect:sideOfArrowStretchRect]];
    arrow = [[UIImageView alloc] initWithImage:[self croppedImage:backImage rect:arrowRect]];
    
    [self insertSubview:leftOfArrow atIndex:0];
    [self insertSubview:leftSideOfArrowStretch atIndex:0];
    [self insertSubview:arrow atIndex:0];
    [self insertSubview:rightSideOfArrowStretch atIndex:0];
    [self insertSubview:rightOfArrow atIndex:0];
    [self insertSubview:midStretch atIndex:0];
    [self insertSubview:oppositeOfArrowStretch atIndex:0];
}
         
    

- (void)layoutView { 
    self.frame = backgroundRect;
    
    switch (arrowDirection) {
		case UIPopoverArrowDirectionUp:
            rightOfArrow.frame = CGRectMake(backgroundRect.size.width-rightOfArrowRect.size.width, 0, rightOfArrowRect.size.width, rightOfArrowRect.size.height);
            arrow.frame = CGRectMake(arrowOffset, 0, arrowRect.size.width, arrowRect.size.height);
            leftSideOfArrowStretch.frame = CGRectMake(sideOfArrowStretchRect.origin.x, sideOfArrowStretchRect.origin.y, arrowOffset - leftOfArrowRect.size.width, sideOfArrowStretchRect.size.height);
            rightSideOfArrowStretch.frame = CGRectMake(CGRectGetMaxX(arrow.frame), sideOfArrowStretchRect.origin.y, backgroundRect.size.width - rightOfArrowRect.size.width - CGRectGetMaxX(arrow.frame), sideOfArrowStretchRect.size.height);
            oppositeOfArrowStretch.frame = CGRectMake(0, backgroundRect.size.height-oppositeOfArrowStretchRect.size.height, backgroundRect.size.width, oppositeOfArrowStretchRect.size.height);
            midStretch.frame = CGRectMake(0, leftOfArrowRect.size.height, backgroundRect.size.width, backgroundRect.size.height - oppositeOfArrowStretchRect.size.height - leftOfArrowRect.size.height);
			break;
		case UIPopoverArrowDirectionDown:
            oppositeOfArrowStretch.frame = CGRectMake(0, 0, backgroundRect.size.width, oppositeOfArrowStretchRect.size.height);
            rightOfArrow.frame = CGRectMake(0, backgroundRect.size.height-rightOfArrowRect.size.height, rightOfArrowRect.size.width, rightOfArrowRect.size.height);
            leftOfArrow.frame = CGRectMake(backgroundRect.size.width-leftOfArrowRect.size.width, rightOfArrow.frame.origin.y, leftOfArrowRect.size.width, leftOfArrowRect.size.height);
            rightSideOfArrowStretch.frame = CGRectMake(rightOfArrowRect.size.width, rightOfArrow.frame.origin.y, arrowOffset-rightOfArrowRect.size.width, sideOfArrowStretchRect.size.height);
            arrow.frame = CGRectMake(arrowOffset, rightSideOfArrowStretch.frame.origin.y, arrowRect.size.width, arrowRect.size.height);
            leftSideOfArrowStretch.frame = CGRectMake(CGRectGetMaxX(arrow.frame), arrow.frame.origin.y, leftOfArrow.frame.origin.x-CGRectGetMaxX(arrow.frame), sideOfArrowStretchRect.size.height);
            midStretch.frame = CGRectMake(0, oppositeOfArrowStretchRect.size.height, backgroundRect.size.width, backgroundRect.size.height-oppositeOfArrowStretchRect.size.height-rightOfArrowRect.size.height);
			break;
		case UIPopoverArrowDirectionRight:
            oppositeOfArrowStretch.frame = CGRectMake(0, 0, oppositeOfArrowStretchRect.size.width, backgroundRect.size.height);
            leftOfArrow.frame = CGRectMake(backgroundRect.size.width-leftOfArrowRect.size.width, 0, leftOfArrowRect.size.width, leftOfArrowRect.size.height);
            midStretch.frame = CGRectMake(oppositeOfArrowStretchRect.size.width, 0, leftOfArrow.frame.origin.x-oppositeOfArrowStretchRect.size.width, backgroundRect.size.height);
            rightOfArrow.frame = CGRectMake(leftOfArrow.frame.origin.x, backgroundRect.size.height-rightOfArrowRect.size.height, rightOfArrowRect.size.width, rightOfArrowRect.size.height);
            arrow.frame = CGRectMake(leftOfArrow.frame.origin.x, arrowOffset, arrowRect.size.width, arrowRect.size.height);
            leftSideOfArrowStretch.frame = CGRectMake(backgroundRect.size.width-sideOfArrowStretchRect.size.width, leftOfArrowRect.size.height, sideOfArrowStretchRect.size.width, arrowOffset-leftOfArrowRect.size.height);
            rightSideOfArrowStretch.frame = CGRectMake(leftSideOfArrowStretch.frame.origin.x, CGRectGetMaxY(arrow.frame), sideOfArrowStretchRect.size.width, rightOfArrow.frame.origin.y-CGRectGetMaxY(arrow.frame));
			break;
        case UIPopoverArrowDirectionLeft:
            rightOfArrow.frame = rightOfArrowRect;
            arrow.frame = CGRectMake(0, arrowOffset, arrowRect.size.width, arrowRect.size.height);
            rightSideOfArrowStretch.frame = CGRectMake(0, rightOfArrowRect.size.height, sideOfArrowStretchRect.size.width, arrowOffset-rightOfArrowRect.size.height);
            leftOfArrow.frame = CGRectMake(0, backgroundRect.size.height-leftOfArrowRect.size.height, leftOfArrowRect.size.width, leftOfArrowRect.size.height);
            leftSideOfArrowStretch.frame = CGRectMake(0, CGRectGetMaxY(arrow.frame), sideOfArrowStretchRect.size.width, leftOfArrow.frame.origin.y-CGRectGetMaxY(arrow.frame));
            oppositeOfArrowStretch.frame = CGRectMake(backgroundRect.size.width-oppositeOfArrowStretchRect.size.width, 0, oppositeOfArrowStretchRect.size.width, backgroundRect.size.height);
            midStretch.frame = CGRectMake(CGRectGetMaxX(rightOfArrow.frame), 0, oppositeOfArrowStretch.frame.origin.x-CGRectGetMaxX(rightOfArrow.frame), backgroundRect.size.height);
			break;
	}
}

@end