// Copyright 2014-present 650 Industries. All rights reserved.

#import "BKSlidingViewController.h"

#import "BKDeltaCalculator.h"
#import "UIViewController+BKTag.h"

typedef NS_ENUM(NSUInteger, BKSlidingViewControllerVisibility) {
    BKSlidingViewControllerVisibilityUnchanged,
    BKSlidingViewControllerVisibilityShouldShow,
    BKSlidingViewControllerVisibilityShouldHide,
};

@interface BKSlidingViewController () <UIScrollViewDelegate> {
    BOOL _needsSelectedIndexUpdate;
}

- (void)setNeedsSelectedIndexUpdate;
- (BOOL)needsSelectedIndexUpdate;
- (void)updateSelectedIndexIfNeeded;

@end

@implementation BKSlidingViewController {
    UIScrollView *_scrollView;

    NSMutableArray *_viewControllers;
    NSMutableArray *_viewControllerParentViews;
    NSMapTable *_viewControllersVisible;
    NSMapTable *_viewControllersShouldChangeVisibility;

    CGFloat _interPageSpacing;
}

@synthesize viewControllers = _viewControllers;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _interPageSpacing = 1;
        _viewControllers = [NSMutableArray array];
        _viewControllerParentViews = [NSMutableArray array];
        _viewControllersVisible = [NSMapTable weakToStrongObjectsMapTable];
        _viewControllersShouldChangeVisibility = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.backgroundColor = [UIColor blackColor];
    _scrollView.bounces = NO;
    _scrollView.delaysContentTouches = NO;
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:_scrollView];
}

- (void)viewWillLayoutSubviews
{
    CGRect scrollViewRect = self.view.bounds;
    scrollViewRect.size.width += _interPageSpacing;
    _scrollView.frame = scrollViewRect;

    [_viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIView *parentView = _viewControllerParentViews[idx];

        CGRect baseRect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
        CGRect offsetRect = CGRectOffset(baseRect, idx * CGRectGetWidth(_scrollView.bounds), 0);
        parentView.frame = offsetRect;
        ((UIViewController *)obj).view.frame = parentView.bounds;
    }];

}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
}

#pragma mark - View controller selection

- (void)setViewControllers:(NSArray *)viewControllers
{
    // Skip no-ops
    if (_viewControllers == viewControllers || [_viewControllers isEqualToArray:viewControllers]) {
        return;
    }

    UIViewController *maximallyVisibleVC = [self _maximallyVisibleViewController];

    // [[[ Calculate viewcontroller differences and sync up the parent views.
    NSDictionary *differences = [BKDeltaCalculator resolveDifferencesBetweenOldArray:_viewControllers newArray:viewControllers];
    NSIndexSet *removedIndices = differences[BKValueChangeRemovedKey];
    NSIndexSet *addedIndices = differences[BKValueChangeAddedKey];

    NSArray *removedViewControllers = [_viewControllers objectsAtIndexes:removedIndices];
    NSArray *addedViewControllers = [viewControllers objectsAtIndexes:addedIndices];

    NSArray *removedParentViews = [_viewControllerParentViews objectsAtIndexes:removedIndices];
    [_viewControllerParentViews removeObjectsAtIndexes:removedIndices];
    [_viewControllers removeObjectsAtIndexes:removedIndices];

    [addedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        UIViewController *addedVC = addedViewControllers[idx];
        UIView *parentView = [[UIView alloc] init];
        [parentView addSubview:addedVC.view];

        [_viewControllers insertObject:addedVC atIndex:idx];
        [_viewControllerParentViews insertObject:parentView atIndex:idx];
    }];
    NSArray *addedParentViews = [_viewControllerParentViews objectsAtIndexes:addedIndices];

    for (UIViewController *addedVC in addedViewControllers) {
        [self _setViewController:addedVC visible:NO];
    }
    for (UIViewController *removedVC in removedViewControllers) {
        [self _setViewController:removedVC visible:NO];
    }
    // ]]]

    // Reconciliation logic: view controller selection
    UIViewController *targetViewController;
    if ([_viewControllers containsObject:_selectedViewController]) {
        targetViewController = _selectedViewController;
    } else if (_selectedIndex < _viewControllers.count) {
        targetViewController = _viewControllers[_selectedIndex];
    } else {
        targetViewController = [_viewControllers lastObject];
    }

    [UIView animateWithDuration:0 animations:^{ // Inherit animation context if any
        [self.view layoutIfNeeded];

        for (UIViewController *viewController in removedViewControllers) {
            [viewController willMoveToParentViewController:nil];
        }
        [addedViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self addChildViewController:(UIViewController *)obj];
            UIView *parentView = addedParentViews[idx];
            [_scrollView addSubview:parentView];
        }];

        _scrollView.contentSize = CGSizeMake(_viewControllers.count * CGRectGetWidth(_scrollView.bounds), CGRectGetHeight(_scrollView.bounds));
        [self.view layoutIfNeeded];

        // Force reselection of the view controller
        [self _setSelectedViewController:targetViewController];
        [self setNeedsSelectedIndexUpdate];
        [self updateSelectedIndexIfNeeded];
        [self _scrollViewportFromViewController:maximallyVisibleVC toViewController:targetViewController];
    } completion:^(BOOL finished) {
        [removedViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIView *parentView = removedParentViews[idx];
            [parentView removeFromSuperview];
            [(UIViewController *)obj removeFromParentViewController];
        }];
        for (UIViewController *viewController in addedViewControllers) {
            [viewController didMoveToParentViewController:self];
        }
    }];
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    if (_selectedViewController != selectedViewController) {
        UIViewController *previousSelectedVC = _selectedViewController;
        [self _setSelectedViewController:selectedViewController];
        [self _scrollViewportFromViewController:previousSelectedVC toViewController:_selectedViewController];
    }
}

// Doesn't set the viewport
- (void)_setSelectedViewController:(UIViewController *)selectedViewController
{
    if (_selectedViewController != selectedViewController) {
        _selectedViewController = selectedViewController;
        [self setNeedsSelectedIndexUpdate];
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    if (_selectedIndex != selectedIndex) {
        NSAssert(selectedIndex < _viewControllers.count, @"Cannot select an index which is out of range");
        UIViewController *previousSelectedVC = _selectedViewController;
        [self _setSelectedViewController:_viewControllers[selectedIndex]];
        [self _scrollViewportFromViewController:previousSelectedVC toViewController:_selectedViewController];
    }
}

#pragma mark - Selection update neediness

- (void)setNeedsSelectedIndexUpdate
{
    _needsSelectedIndexUpdate = YES;
}

- (BOOL)needsSelectedIndexUpdate
{
    return _needsSelectedIndexUpdate;
}

- (void)updateSelectedIndexIfNeeded
{
    if (_needsSelectedIndexUpdate) {
        NSUInteger newSelectedIndex = [_viewControllers indexOfObject:_selectedViewController];
        NSAssert(newSelectedIndex != NSNotFound, @"Cannot select a view controller which is not present");

        if (_selectedIndex != newSelectedIndex) {
            [self willChangeValueForKey:@"selectedIndex"];
            _selectedIndex = newSelectedIndex;
            [self didChangeValueForKey:@"selectedIndex"];
        }
        [self setNeedsStatusBarAppearanceUpdate];

        _needsSelectedIndexUpdate = NO;
    }
}

#pragma mark - Tagging

- (UIViewController *)viewControllerWithTag:(NSInteger)tag
{
    for (UIViewController *viewController in self.viewControllers) {
        if (viewController.bk_tag == tag) {
            return viewController;
        }
    }
    return nil;
}

- (NSInteger)indexWithTag:(NSInteger)tag
{
    for (NSUInteger i = 0; i < self.viewControllers.count; i++) {
        UIViewController *viewController = self.viewControllers[i];
        if (viewController.bk_tag == tag) {
            return i;
        }
    }
    return NSNotFound;
}

#pragma mark - Child view controller status bar methods

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return _selectedViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return _selectedViewController;
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat scrollViewWidth = CGRectGetWidth(scrollView.bounds);
    CGRect visibleRect = [self _viewport];

    CGFloat middleOffset = CGRectGetMidX(visibleRect);
    CGFloat approximateMiddleIndex = middleOffset / scrollViewWidth;
    NSInteger middleIndex = (NSInteger)floor(approximateMiddleIndex);

    NSUInteger minIndex = middleIndex > 0 ? middleIndex - 1 : 0;
    NSUInteger maxIndex = middleIndex < (_viewControllers.count - 1) ? middleIndex + 1 : _viewControllers.count - 1;
    NSRange validIndexRange = NSMakeRange(minIndex, maxIndex - minIndex + 1);
    NSIndexSet *validIndicesToCheck = [NSIndexSet indexSetWithIndexesInRange:validIndexRange];
    [_viewControllers enumerateObjectsAtIndexes:validIndicesToCheck
                                        options:0
                                     usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                         UIViewController *vc = obj;
                                         UIView *parentView = _viewControllerParentViews[idx];

                                         BOOL intersects = CGRectIntersectsRect(visibleRect, ((CALayer *)parentView.layer.presentationLayer).frame);
                                         if (intersects) {
                                             [self _setViewController:vc shouldChangeVisibility:BKSlidingViewControllerVisibilityShouldShow];
                                             [self _updateAppearanceForViewControllerIfNeeded:vc animated:YES];
                                         }
                                     }];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    UIViewController *maximallyVisibleVC = [self _maximallyVisibleViewController];
    for (UIViewController *viewController in _viewControllers) {
        if (maximallyVisibleVC == viewController) {
            continue;
        }
        [self _setViewController:viewController shouldChangeVisibility:BKSlidingViewControllerVisibilityShouldHide];
        [self _updateAppearanceForViewControllerIfNeeded:viewController animated:NO];
    }

    [self _setSelectedViewController:maximallyVisibleVC];
    [self updateSelectedIndexIfNeeded];
}

#pragma mark - Rotation (NOTE: currently disabled)

// Disabled for now - rotation isn't production-ready.
- (BOOL)shouldAutorotate
{
    return NO;
}

#if defined(__IPHONE_8_0)
// iOS 8
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        CGFloat screenWidth = CGRectGetWidth(_scrollView.bounds);
        _scrollView.contentOffset = CGPointMake(self.selectedIndex * screenWidth, 0);
        _scrollView.contentSize = CGSizeMake(_viewControllers.count * CGRectGetWidth(_scrollView.bounds), CGRectGetHeight(_scrollView.bounds));
    } completion:nil];

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}
#endif

// iOS <= 7
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGFloat screenWidth = CGRectGetWidth(_scrollView.bounds);
    _scrollView.contentOffset = CGPointMake(self.selectedIndex * screenWidth, 0);
    _scrollView.contentSize = CGSizeMake(_viewControllers.count * CGRectGetWidth(_scrollView.bounds), CGRectGetHeight(_scrollView.bounds));
    [self.view layoutIfNeeded];

    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - Helpers

- (UIViewController *)_maximallyVisibleViewController
{
    // Find visible view controllers
    CGRect visibleRect = [self _viewport];
    NSArray *visibleViewControllers = [self _viewControllersVisibleInRect:visibleRect];

    __block CGFloat maximumArea = -1;
    __block UIViewController *maximallyVisibleVC = nil;
    [visibleViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *visibleVC = obj;
        UIView *parentView = _viewControllerParentViews[idx];
        CGRect intersection = CGRectIntersection(visibleRect, parentView.frame);
        CGFloat area = intersection.size.width * intersection.size.height;
        if (area > maximumArea) {
            maximumArea = area;
            maximallyVisibleVC = visibleVC;
        }
    }];
    return maximallyVisibleVC;
}

- (CGRect)_viewport
{
    CALayer *visibleLayer = _scrollView.layer.presentationLayer;
    CGRect visibleRect = visibleLayer.bounds;
    return visibleRect;
}

- (NSArray *)_viewControllersVisibleInRect:(CGRect)rect
{
    NSMutableArray *visibleViewControllers = [NSMutableArray array];
    [_viewControllerParentViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *visibleVC = _viewControllers[idx];
        UIView *parentView = obj;
        if (CGRectIntersectsRect(rect, parentView.frame)) {
            [visibleViewControllers addObject:visibleVC];
        }
    }];
    return visibleViewControllers;
}

- (void)_scrollViewportFromViewController:(UIViewController *)fromViewController
                         toViewController:(UIViewController *)toViewController
{
    CGRect targetRect = toViewController.view.superview.frame;
    CGFloat zoomScale = CGRectGetWidth(toViewController.view.superview.frame) / fmax(CGRectGetWidth(self.view.bounds), 1); // fmax to avoid div-by-0
    CGRect transformedRect = CGRectApplyAffineTransform(targetRect, CGAffineTransformMakeScale(zoomScale, zoomScale));
    _scrollView.contentOffset = transformedRect.origin;
    _scrollView.zoomScale = zoomScale;

    // Magic to figure out if our scrollview is animating its contentOffset change. Must happen _after_ the change,
    // because it works by detecting the added animation. NOTE: 0.001 seems to be the usual animation duration for
    // 'instant' animations. 0.25 is CATransaction's default animationDuration (for implicit animations).
    CAAnimation *animation = [_scrollView.layer animationForKey:@"bounds"];
    // if someone disabled actions and there are _no_ animations, nil < 0.001
    BOOL isAnimating = animation.duration > 0.001;

    [self _setViewController:fromViewController shouldChangeVisibility:BKSlidingViewControllerVisibilityShouldHide];
    [self _setViewController:toViewController shouldChangeVisibility:BKSlidingViewControllerVisibilityShouldShow];

    [self updateSelectedIndexIfNeeded];

    [self _updateAppearanceForViewControllerIfNeeded:fromViewController animated:isAnimating];
    [self _updateAppearanceForViewControllerIfNeeded:toViewController animated:isAnimating];
}

- (void)_updateAppearanceForViewControllerIfNeeded:(UIViewController *)viewController animated:(BOOL)animated
{
    BOOL needed = [self _appearanceTransitionNeededForViewController:viewController];
    if (!needed) {
        [self _setViewController:viewController shouldChangeVisibility:BKSlidingViewControllerVisibilityUnchanged];
        return;
    }

    BOOL isAppearing = [self _shouldChangeVisibilityForViewController:viewController] == BKSlidingViewControllerVisibilityShouldShow;
    [viewController beginAppearanceTransition:isAppearing animated:animated];

    void (^animationBlock)(void) = ^{
        if (isAppearing) {
            viewController.view.hidden = NO;
        }
        [self _setViewController:viewController visible:isAppearing];
    };
    void (^completionBlock)(void) = ^{
        [viewController endAppearanceTransition];
        [self _setViewController:viewController shouldChangeVisibility:BKSlidingViewControllerVisibilityUnchanged];
    };

    if (!animated) {
        animationBlock();
        completionBlock();
    } else {
        [UIView animateWithDuration:0
                         animations:animationBlock
                         completion:^(BOOL finished) {
                             completionBlock();
                         }];
    }
}

- (BOOL)_appearanceTransitionNeededForViewController:(UIViewController *)viewController
{
    BOOL isVisible = [self _visibilityForViewController:viewController];
    BKSlidingViewControllerVisibility desiredVisibility = [self _shouldChangeVisibilityForViewController:viewController];
    switch (desiredVisibility) {
        case BKSlidingViewControllerVisibilityUnchanged:
            return NO;
        case BKSlidingViewControllerVisibilityShouldShow:
            return !isVisible;
        case BKSlidingViewControllerVisibilityShouldHide:
            return isVisible;
    }
}

- (BOOL)_visibilityForViewController:(UIViewController *)viewController
{
    return [(NSNumber *)[_viewControllersVisible objectForKey:viewController] boolValue];
}

- (void)_setViewController:(UIViewController *)viewController visible:(BOOL)visible
{
    [_viewControllersVisible setObject:@(visible) forKey:viewController];
}

- (BKSlidingViewControllerVisibility)_shouldChangeVisibilityForViewController:(UIViewController *)viewController
{
    return [(NSNumber *)[_viewControllersShouldChangeVisibility objectForKey:viewController] unsignedIntegerValue];
}

- (void)_setViewController:(UIViewController *)viewController shouldChangeVisibility:(BKSlidingViewControllerVisibility)change
{
    [_viewControllersShouldChangeVisibility setObject:@(change) forKey:viewController];
}

@end