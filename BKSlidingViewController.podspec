Pod::Spec.new do |s|
  s.name             = "BKSlidingViewController"
  s.version          = "1.0.0"
  s.summary          = "A side-scrolling view controller container class with a minimal, UITabBarController-like API."
  s.description      = <<-DESC
                       UIPageViewController seems somewhat rigidly designed for paginated content, and is very efficient at lazily instantiating many view controllers with a particular pattern (before/after) and specific spatial metaphors. While it can do many things well, customization is ultimately limited by permissible alterations of the UIPageViewController class.

                       BKSlidingViewController is an open-source substitute for applications desiring view controllers laid out horizontally, presented with a UITabBarController-like API.
                       DESC
  s.homepage         = "https://github.com/Basket/BKSlidingViewController"
  s.license          = 'MIT'
  s.author           = { "Andrew Toulouse" => "andrew@atoulou.se" }
  s.source           = { :git => "https://github.com/Basket/BKSlidingViewController.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.dependency 'BKDeltaCalculator', '~> 1.0'

  s.source_files = 'BKSlidingViewController/*.{h,m}'
  s.frameworks = 'UIKit'
end
