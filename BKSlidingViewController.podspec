Pod::Spec.new do |s|
  s.name             = "BKSlidingViewController"
  s.version          = "0.0.1"
  s.summary          = "A side-scrolling view controller container class with a minimal, UITabBarController-like API."
  s.description      = <<-DESC
                       UIPageViewController seems somewhat rigidly designed for paginated content, and is very efficient at lazily instantiating many view controllers with a particular pattern (before/after) and specific spatial metaphors. While it can do many things well, customization is ultimately limited by permissible alterations of the UIPageViewController class.

                       BKSlidingViewController is an open-source substitute for applications desiring view controllers laid out horizontally, presented with a UITabBarController-like API.

                       Also included is BKDeltaCalculator, a convenience class for transforming an input of two arrays (before/after) into a set of changes, usable (for example) to produce a set of insert/replace/delete commands into a table view to avoid expensive UITableView reloads.
                       DESC
  s.homepage         = "https://github.com/Basket/BKSlidingViewController"
  s.license          = 'MIT'
  s.author           = { "Andrew Toulouse" => "andrew@atoulou.se" }
  s.source           = { :git => "https://github.com/Basket/BKSlidingViewController.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'BKSlidingViewController/*.{h,m}'
  s.frameworks = 'UIKit'
end
