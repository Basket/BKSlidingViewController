// Copyright 2014-present 650 Industries. All rights reserved.

#import "UIViewController+BKTag.h"

@import ObjectiveC;

static const void *UIViewControllerBKTagKey = "UIViewControllerBKTagKey";

@implementation UIViewController (BKTag)

- (void)bk_setTag:(NSInteger)tag
{
    NSNumber *value = [NSNumber numberWithInteger:tag];
    objc_setAssociatedObject(self, UIViewControllerBKTagKey, value, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSInteger)bk_tag
{
    NSNumber *value = objc_getAssociatedObject(self, UIViewControllerBKTagKey);
    if (value) {
        return [value integerValue];
    } else {
        return 0;
    }
}

@end
