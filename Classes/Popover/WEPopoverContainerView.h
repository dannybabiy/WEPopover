//
//  WEPopoverContainerView.h
//  WEPopover
//
//  Created by Werner Altewischer on 02/09/10.
//  Copyright 2010 Werner IT Consultancy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	WEPopoverCheckBoundsLeft,
    WEPopoverCheckBoundsRight,
    WEPopoverCheckBoundsBottom,
    WEPopoverCheckBoundsTop,
} WEPopoverCheckBounds;

typedef enum {
    WEPopoverShiftLeft,
    WEPopoverShiftRight,
    WEPopoverShiftDown,
    WEPopoverShiftUp,
    WEPopoverCutLeft,
    WEPopoverCutRight,
    WEPopoverCutTop,
    WEPopoverCutBottom
} WEPopoverFixAction;


@class WEPopoverContainerView;

/**
 * @brief Container/background view for displaying a popover view.
 */
@interface WEPopoverContainerView : UIView {
	UIImage *bgImage;
	UIImage *arrowImage;
	
	UIPopoverArrowDirection arrowDirection;
	
    CGRect originalAnchorRect;
	CGSize originalSize;
	UIView *contentView;
    CGRect contentRect;
    CGRect backgroundRect;
    float arrowOffset;
    
    CGRect leftOfArrowRect;
    CGRect rightOfArrowRect;
    CGRect sideOfArrowStretchRect;
    CGRect arrowRect;
    CGRect midStretchRect;
    CGRect oppositeOfArrowStretchRect;
    
    UIImageView *leftOfArrow;
    UIImageView *rightOfArrow;
    UIImageView *leftSideOfArrowStretch;
    UIImageView *rightSideOfArrowStretch;
    UIImageView *midStretch;
    UIImageView *oppositeOfArrowStretch;
    UIImageView *arrow;
}

/**
 * @brief The current arrow direction for the popover.
 */
@property (nonatomic, readonly) UIPopoverArrowDirection arrowDirection;

/**
 * @brief The content view being displayed.
 */
@property (nonatomic, retain) UIView *contentView;

/**
 * @brief Initializes the position of the popover with a size, anchor rect, display area and permitted arrow directions. 
 * If the last is not supplied the defaults are taken (requires images to be present in bundle representing a black rounded background with partial transparency).
 */
- (id)initWithSize:(CGSize)theSize 
		anchorRect:(CGRect)anchorRect 
	   displayArea:(CGRect)displayArea
permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections;	

/**
 * @brief To update the position of the popover with a new anchor rect, display area and permitted arrow directions
 */
- (void)updatePositionWithAnchorRect:(CGRect)anchorRect 
						 displayArea:(CGRect)displayArea
			permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections;	

/**
 * @brief Updates the display area using existing anchorRect and arrowDirection. So that you can animate between positions.
 */
- (void)updateDisplayArea:(CGRect)displayArea;

@end
