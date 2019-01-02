#
# Be sure to run `pod lib lint ReduxyRouter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ReduxyRouter'
  s.version          = '0.3.0'
  s.summary          = 'Router extension for Reduxy'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
ReduxyRouter is test implementation of router system for Reduxy.
ReduxyRouter is in charge of creation and transitions of Routables which are NSObjects conforming ReduxyRoutable protocol.
ReduxyRouter uses step by step route/unroute to transition from a Routable to other Routable.

It is designed to enable to use with  ReduxyRecorder, but it is just a test implementation so maybe run uncompletely in Apps which have complex transitions or used with ReduxyRecorder.

                       DESC

  s.homepage         = 'https://github.com/skyofdwarf/ReduxyRouter'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'skyofdwarf' => 'skyofdwarf@gmail.com' }
  s.source           = { :git => 'https://github.com/skyofdwarf/ReduxyRouter.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'ReduxyRouter/Classes/**/*'
  
  # s.resource_bundles = {
  #   'ReduxyRouter' => ['ReduxyRouter/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Reduxy', '~> 0.3'
end
