// Copyright 2014-present 650 Industries. All rights reserved.

@import UIKit;

/**
 Attach `NSInteger` tags to `UIViewController` classes.
 */
@interface UIViewController (BKTag)

/**
 An integer that you can use to identify view controllers in your application.
 
 @discussion The default value is 0. You can set the value of this tag and use that value to identify the view controller later.
 */
@property (nonatomic, assign, setter=bk_setTag:, getter=bk_tag) NSInteger bk_tag;

@end
