Pod::Spec.new do |s|

  s.name                    = "Salada"
  s.version                 = "3.2"
  s.summary                 = "Firebase Realtime database model framework"
  s.homepage                = "https://github.com/1amageek/Salada"
  s.license                 = { :type => 'BSD', :file => 'SaladaFrameworks/LICENSE' }
  s.author                  = "1amageek"
  s.social_media_url        = "https://twitter.com/1amageek"
  s.platform                = :ios
  s.ios.deployment_target   = "10.0"
  s.ios.framework           = "FirebaseDatabase", "FirebaseStorage"
  s.requires_arc            = true
  s.source                  = { :git => "https://github.com/1amageek/Salada.git" }
  s.source_files            = "Salada/**/*.swift"

#s.dependency "Firebase"
  s.dependency "Firebase/Database"
  s.dependency "Firebase/Storage"
  s.xcconfig = {
#    'FRAMEWORK_SEARCH_PATHS' => '"${PODS_ROOT}/FirebaseDatabase/Frameworks" "${PODS_ROOT}/FirebaseStorage/Frameworks"',
#    'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Firebase/**"'


#"CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => 'YES',
'HEADER_SEARCH_PATHS' => ' "${PODS_ROOT}/Firebase/**" ' +
' "${PODS_ROOT}/GoogleToolboxForMac/**" ' +
' "${PODS_ROOT}/GTMSessionFetcher/**" ',

"FRAMEWORK_SEARCH_PATHS" => '$(inherited) ' +
'"${PODS_ROOT}/FirebaseAnalytics/Frameworks" ' +
'"${PODS_ROOT}/FirebaseCore/Frameworks" ' +
'"${PODS_ROOT}/FirebaseDatabase/Frameworks" ' +
'"${PODS_ROOT}/FirebaseInstanceID/Frameworks" ' +
'"${PODS_ROOT}/FirebaseStorage/Frameworks" '


#"CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => 'YES',
#"FRAMEWORK_SEARCH_PATHS" => '$(inherited) ' +
#'"${PODS_ROOT}/FirebaseCore/Frameworks" ' +
#'"${PODS_ROOT}/FirebaseDatabase/Frameworks" ' +
#'"${PODS_ROOT}/FirebaseStorage/Frameworks" ' +
#'"${PODS_ROOT}/FirebaseInstanceID/Frameworks" '
  }

end
