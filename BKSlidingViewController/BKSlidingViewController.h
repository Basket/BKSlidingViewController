// Copyright 2014-present 650 Industries.

@import UIKit;

/**
 `BKSlidingViewController` is a container view controller designed to slide view controllers in a scroll view, and to do
 so with an API mimicking that of `UITabBarController`.
 
 `BKSlidingViewController` methods may be called from within UIView animation blocks.
 */
@interface BKSlidingViewController : UIViewController

// These are designed to respect their animation context's duration. Call them from an animation
// block if so desired.

/**
 The view controllers displayed by the sliding view controller.
 */
@property (nonatomic, copy) NSArray *viewControllers;

/**
 The view controller being shown by the sliding view controller.
 */
@property (nonatomic, weak) UIViewController *selectedViewController;

/**
 The index of the view controller being shown by the sliding view controller.
 */
@property (nonatomic, assign) NSInteger selectedIndex;

/**
 The view controller in the sliding view controller assigned the given tag.
 
 @param tag The tag for the desired view controller.
 @return the first UIViewController whose tag matches.
 */
- (UIViewController *)viewControllerWithTag:(NSInteger)tag;

/**
 The index of the view controller in the sliding view controller assigned the given tag.

 @param tag The tag for the desired view controller index.
 @return the first index whose UIViewController's tag matches.
 */
- (NSInteger)indexWithTag:(NSInteger)tag;

@end
