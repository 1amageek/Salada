Pod::Spec.new do |s|
  s.name         = "Salada"
  s.version      = "1.0"
  s.summary      = "Salada is OR Mapper for Firebase."
  s.homepage     = "https://github.com/1amageek/Salada"
  s.license      = { :type => "BSD" }
  s.author    = "1amageek"
  s.social_media_url   = "https://twitter.com/1amageek"
  s.platform     = :ios
  s.ios.deployment_target = "8.0"
  s.ios.framework = "UIKit"
  s.ios.vendored_frameworks = "SaladaFrameworks/*/Frameworks/*.framework"
  s.requires_arc = true
  s.source       = { :http => "https://github.com/1amageek/Salada/releases/download/1.0/SaladaFrameworks.zip" }
  s.default_subspecs = "Salada"

  s.subspec "Salada" do |salada|
    salada.source_files = "Salada/Salada.swift", "Salada/Salada+Datasource.swift", "Salada/Salada+Relation.swift", "Salada/Referenceable.swift"
    salada.dependency "Firebase/Database"
    salada.dependency "Firebase/Storage"
  end

end
