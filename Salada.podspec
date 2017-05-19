Pod::Spec.new do |s|
  s.name                  = "Salada"
  s.version               = "2.0"
  s.summary               = "Salada is OR Mapper for Firebase."
  s.homepage              = "https://github.com/1amageek/Salada"
  s.license               = { :type => "BSD" }
  s.author                = "1amageek"
  s.social_media_url      = "https://twitter.com/1amageek"
  s.platform              = :ios
  s.ios.deployment_target = "8.0"
  s.ios.framework         = "UIKit"
  s.requires_arc          = true
  s.source	              = { :git => "https://github.com/1amageek/Salada.git", :tag => "#{s.version}" }
  s.source_files          = "Salada/**/*.swift"
  
  s.dependency 'Firebase/Core'
  s.dependency "Firebase/Database"
  s.dependency "Firebase/Storage"

  s.pod_target_xcconfig = {

      "OTHER_LDFLAGS" => '$(inherited) ' +
      '-framework "FirebaseCore" ' +
      '-framework "FirebaseDatabase" ' +
      '-framework "FirebaseStorage" ' +
      '-framework "FirebaseInstanceID" ',

      "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => 'YES',

      "FRAMEWORK_SEARCH_PATHS" => '$(inherited) ' +
      '"${PODS_ROOT}/FirebaseCore/Frameworks" ' +
      '"${PODS_ROOT}/FirebaseDatabase/Frameworks" ' +
      '"${PODS_ROOT}/FirebaseStorage/Frameworks" ' +
      '"${PODS_ROOT}/FirebaseInstanceID/Frameworks" '
  }

end
