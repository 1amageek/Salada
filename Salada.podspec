Pod::Spec.new do |s|
  s.name                    = "Salada"
  s.version                 = "4.0"
  s.summary                 = "Firebase Realtime database model framework"
  s.homepage                = "https://github.com/1amageek/Salada"
  s.license                 = { :type => 'BSD', :file => 'SaladaFrameworks/LICENSE' }
  s.author                  = "1amageek"
  s.social_media_url        = "https://twitter.com/1amageek"
  s.platform     = :ios, "11.0"
  # s.ios.deployment_target = "11.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"
  s.source                  = { :git => "https://github.com/1amageek/Salada.git", :tag => "#{s.version}" }
  s.source_files            = "Salada/**/*.swift"
  s.requires_arc = true
  s.static_framework = true
  s.dependency "Firebase/Core"
  s.dependency "Firebase/Database"
  s.dependency "Firebase/Storage"
end

