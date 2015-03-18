// Copyright 2015-present Andy Toulouse.

#import "BKSlidingViewController.h"

@protocol BKSlidingViewControllerDelegate;

/**
 Additional functionality for `BKSlidingViewController` beyond its thin `UITabBarController`-like interface.
 */
@interface BKSlidingViewController ()

/**
 Return the amount the sliding view controller has scrolled in the range [0.0, 1.0], with the percentages are defined as:
 
 0%   The first view controller is centered.
 50%  If there is only one view controller, it is centered.
 100% The last view controller is centered.
 */
@property (nonatomic, assign, readonly) CGFloat percentScrolled;

/**
 The delegate for the sliding view controller.
 */
@property (nonatomic, weak) id<BKSlidingViewControllerDelegate> delegate;

@end

/**
 The delegate protocol for the sliding view controller.
 */
@protocol BKSlidingViewControllerDelegate <NSObject>

@optional

/**
 Called when the sliding view controller will begin dragging. Analogous to the corresponding scrollView method.
 */
- (void)slidingViewControllerWillBeginDragging:(BKSlidingViewController *)slidingViewController;

/**
 Called when the sliding view controller scrolls. Analogous to the corresponding scrollView method.
 */
- (void)slidingViewControllerDidScroll:(BKSlidingViewController *)slidingViewController;

/**
 Called when the sliding view controller ends decelerating. Analogous to the corresponding scrollView method.
 */
- (void)slidingViewControllerDidEndDecelerating:(BKSlidingViewController *)slidingViewController;
@end