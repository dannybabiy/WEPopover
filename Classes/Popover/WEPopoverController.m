//
//  WEPopoverController.m
//  WEPopover
//
//  Created by Werner Altewischer on 02/09/10.
//  Copyright 2010 Werner IT Consultancy. All rights reserved.
//

#import "WEPopoverController.h"
#import "WEPopoverParentView.h"
#import "UIBarButtonItem+WEPopover.h"

#define FADE_DURATION 0.25

@interface WEPopoverController(Private)

- (UIView *)keyView;
- (void)updateBackgroundPassthroughViews;
- (void)setView:(UIView *)v;
- (CGRect)displayAreaForView:(UIView *)theView;
- (void)dismissPopoverAnimated:(BOOL)animated userInitiated:(BOOL)userInitiated;

@end


@implementation WEPopoverController

@synthesize contentViewController;
@synthesize popoverContentSize;
@synthesize popoverVisible;
@synthesize popoverArrowDirection;
@synthesize delegate;
@synthesize view;
@synthesize context;
@synthesize passthroughViews;
@synthesize anchorView;

- (id)init {
	if ((self = [super init])) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(keyboardWillShow:) 
                                                     name:UIKeyboardWillShowNotification 
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(keyboardWillHide:) 
                                                     name:UIKeyboardWillHideNotification 
                                                   object:nil];
	}
	return self;
}

- (id)initWithContentViewController:(UIViewController *)viewController {
	if ((self = [self init])) {
		self.contentViewController = viewController;
	}
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIKeyboardWillShowNotification 
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIKeyboardWillHideNotification 
                                                  object:nil];
	[self dismissPopoverAnimated:NO];
}

- (void)setContentViewController:(UIViewController *)vc {
	if (vc != contentViewController) {
		contentViewController = vc;
		popoverContentSize = CGSizeZero;
	}
}

//Overridden setter to copy the passthroughViews to the background view if it exists already
- (void)setPassthroughViews:(NSArray *)array {
	passthroughViews = nil;
	if (array) {
		passthroughViews = [[NSArray alloc] initWithArray:array];
	}
	[self updateBackgroundPassthroughViews];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)theContext {
	
	if ([animationID isEqual:@"FadeIn"]) {
		self.view.userInteractionEnabled = YES;
		popoverVisible = YES;
		[contentViewController viewDidAppear:YES];
	} else {
		popoverVisible = NO;
		[contentViewController viewDidDisappear:YES];
		[self.view removeFromSuperview];
		self.view = nil;
		[backgroundView removeFromSuperview];
		backgroundView = nil;
		
		BOOL userInitiatedDismissal = [(__bridge NSNumber *)theContext boolValue];
		
		if (userInitiatedDismissal) {
			//Only send message to delegate in case the user initiated this event, which is if he touched outside the view
			[delegate popoverControllerDidDismissPopover:self];
		}
	}
}

- (void)dismissPopoverAnimated:(BOOL)animated {
	
	[self dismissPopoverAnimated:animated userInitiated:NO];
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item 
			   permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections 
							   animated:(BOOL)animated {
	
	UIView *v = [self keyView];
	CGRect rect = [item frameInView:v];
	
	return [self presentPopoverFromRect:rect inView:v permittedArrowDirections:arrowDirections animated:animated];
}

- (void)presentPopoverFromRect:(CGRect)rect 
						inView:(UIView *)theView 
	  permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections 
					  animated:(BOOL)animated {
	
	
	[self dismissPopoverAnimated:NO];
    
    // Store original values for repositioning
    anchorRect = rect;
    permittedArrowDirections = arrowDirections;
    self.anchorView = theView;
	
	//First force a load view for the contentViewController so the popoverContentSize is properly initialized
	contentViewController.view;
	
	if (CGSizeEqualToSize(popoverContentSize, CGSizeZero)) {
		popoverContentSize = contentViewController.contentSizeForViewInPopover;
	}
	
	CGRect displayArea = [self displayAreaForView:theView];
	
	WEPopoverContainerView *containerView = [[WEPopoverContainerView alloc] initWithSize:self.popoverContentSize anchorRect:rect displayArea:displayArea permittedArrowDirections:arrowDirections];
	popoverArrowDirection = containerView.arrowDirection;
	
	UIView *keyView = self.keyView;
	
	backgroundView = [[WETouchableView alloc] initWithFrame:keyView.bounds];
	backgroundView.contentMode = UIViewContentModeScaleToFill;
	backgroundView.autoresizingMask = ( UIViewAutoresizingFlexibleLeftMargin |
									   UIViewAutoresizingFlexibleWidth |
									   UIViewAutoresizingFlexibleRightMargin |
									   UIViewAutoresizingFlexibleTopMargin |
									   UIViewAutoresizingFlexibleHeight |
									   UIViewAutoresizingFlexibleBottomMargin);
	backgroundView.backgroundColor = [UIColor clearColor];
	backgroundView.delegate = self;
	
	[keyView addSubview:backgroundView];
	
	containerView.frame = [theView convertRect:containerView.frame toView:backgroundView];
	
	[backgroundView addSubview:containerView];
	
	containerView.contentView = contentViewController.view;
	containerView.autoresizingMask = ( UIViewAutoresizingFlexibleLeftMargin |
									  UIViewAutoresizingFlexibleRightMargin);
	
	self.view = containerView;
	[self updateBackgroundPassthroughViews];
	
	[contentViewController viewWillAppear:animated];
	
	[self.view becomeFirstResponder];
	
	if (animated) {
		self.view.alpha = 0.0;
		
		[UIView beginAnimations:@"FadeIn" context:nil];
		
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
		[UIView setAnimationDuration:FADE_DURATION];
		
		self.view.alpha = 1.0;
		
		[UIView commitAnimations];
	} else {
		popoverVisible = YES;
		[contentViewController viewDidAppear:animated];
	}	
}

- (void)repositionPopoverFromRect:(CGRect)rect
						   inView:(UIView *)theView
		 permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections {
	
	CGRect displayArea = [self displayAreaForView:theView];
	WEPopoverContainerView *containerView = (WEPopoverContainerView *)self.view;
	[containerView updatePositionWithAnchorRect:rect
									displayArea:displayArea
					   permittedArrowDirections:arrowDirections];
	
	popoverArrowDirection = containerView.arrowDirection;
	containerView.frame = [theView convertRect:containerView.frame toView:backgroundView];
}

- (void)setPopoverContentSize:(CGSize)size animated:(BOOL)animated {
	CGRect displayArea = [self displayAreaForView:anchorView];
	WEPopoverContainerView *containerView = (WEPopoverContainerView *)self.view;	
	[UIView animateWithDuration:animated ? .3 : 0 animations:^{
		[containerView updateDisplayArea:displayArea newSize:size];
		containerView.frame = [anchorView convertRect:containerView.frame toView:backgroundView];
	}];
}

#pragma mark -
#pragma mark WETouchableViewDelegate implementation

- (void)viewWasTouched:(WETouchableView *)view {
	if (popoverVisible) {
		if (!delegate || [delegate popoverControllerShouldDismissPopover:self]) {
			[self dismissPopoverAnimated:YES userInitiated:YES];
		}
	}
}

#pragma mark -
#pragma mark - Keyboard handlers

- (void)updateContainerView:(NSNotification*)keyboardNotification{
    
    // Get keyboard rect.
    NSDictionary* userInfo = [keyboardNotification userInfo];
    CGRect keyboardEndFrame;
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    // Convert coordinates.
    keyboardEndFrame = [anchorView convertRect:keyboardEndFrame fromView:nil];
    
    // Figure out new visible area.
    CGRect displayArea = [self displayAreaForView:anchorView];
    CGRect intersection = CGRectIntersection(displayArea, keyboardEndFrame);
    if (!CGRectIsNull(intersection)) {
        displayArea.size.height -= intersection.size.height;
    }

    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    [UIView animateWithDuration:duration
                          delay:0 
                        options:animationCurve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         // Update container view.
                         WEPopoverContainerView *containerView = (WEPopoverContainerView *)self.view;
                         [containerView updateDisplayArea:displayArea];
                         containerView.frame = [anchorView convertRect:containerView.frame toView:backgroundView];
                     
     } completion:^(BOOL finished) {
         
     }];
}

- (void)keyboardWillShow:(NSNotification*)notification{
        [self updateContainerView:notification];
    }    

- (void)keyboardWillHide:(NSNotification*)notification{
        [self updateContainerView:notification];
    }    



@end


@implementation WEPopoverController(Private)

- (UIView *)keyView {
	UIWindow *w = [[UIApplication sharedApplication] keyWindow];
	if (w.subviews.count > 0) {
		return [w.subviews objectAtIndex:0];
	} else {
		return w;
	}
}

- (void)setView:(UIView *)v {
	if (view != v) {
		view = v;
	}
}

- (void)updateBackgroundPassthroughViews {
	backgroundView.passthroughViews = passthroughViews;
}


- (void)dismissPopoverAnimated:(BOOL)animated userInitiated:(BOOL)userInitiated {
	if (self.view) {
		[contentViewController viewWillDisappear:animated];
		popoverVisible = NO;
		[self.view resignFirstResponder];
		if (animated) {
			
			self.view.userInteractionEnabled = NO;
			[UIView beginAnimations:@"FadeOut" context:(__bridge void *)([NSNumber numberWithBool:userInitiated])];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
			
			[UIView setAnimationDuration:FADE_DURATION];
			
			self.view.alpha = 0.0;
			
			[UIView commitAnimations];
		} else {
			[contentViewController viewDidDisappear:animated];
			[self.view removeFromSuperview];
			self.view = nil;
			[backgroundView removeFromSuperview];
			backgroundView = nil;
		}
	}
}

- (CGRect)displayAreaForView:(UIView *)theView {
	CGRect displayArea = CGRectZero;
	if ([theView conformsToProtocol:@protocol(WEPopoverParentView)] && [theView respondsToSelector:@selector(displayAreaForPopover)]) {
		displayArea = [(id <WEPopoverParentView>)theView displayAreaForPopover];
	} else {
		displayArea = [[[UIApplication sharedApplication] keyWindow] convertRect:[[UIScreen mainScreen] applicationFrame] toView:theView];
	}
	return displayArea;
}

@end
