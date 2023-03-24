#
#  Be sure to run `pod spec lint StarTrek.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
    s.name                  = "StarTrek"
    s.version               = "0.1.2"
    s.summary               = "Interstellar Transport"
    s.description           = <<-DESC
            This is a library of common interfaces for network connections.
                              DESC
    s.homepage              = "https://github.com/moky/StarTrek"
    s.license               = { :type => 'MIT', :file => 'LICENSE' }
    s.author                = { "Albert Moky" => "albert.moky@gmail.com" }
    # s.social_media_url    = "https://twitter.com/AlbertMoky"
    s.source                = { :git => 'https://github.com/moky/StarTrek.git', :tag => s.version.to_s }
    # s.platform            = :ios, "11.0"
    s.ios.deployment_target = '12.0'

    s.source_files          = "StarTrek/Classes", "StarTrek/Classes/**/*.{h,m}"
    # s.exclude_files       = "Classes/Exclude"
    s.public_header_files   = "StarTrek/Classes/**/*.h"

    # s.frameworks          = 'Security'
    # s.requires_arc        = true

    s.dependency "FiniteStateMachine", "~> 2.3.1"
    s.dependency 'ObjectKey', '~> 0.1.3'
end
