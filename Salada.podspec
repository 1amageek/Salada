Pod::Spec.new do |s|

  s.name         = "Salada"
  s.version      = "1.0"
  s.summary      = "Salada is OR Mapper for Firebase."
  s.homepage     = "https://github.com/1amageek/Salada"
  s.license      = { :type => "BSD" }
  s.author    = "1amageek"
  s.social_media_url   = "https://twitter.com/1amageek"
  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/1amageek/Salada.git", :tag => "#{s.version}" }
  s.source_files  = ["Salada/Salada.swift", "Salada/Salada+Datasource.swift", "Salada/Salada+Relation.swift", "Salada/Referenceable.swift"]
  s.exclude_files = []
  s.dependency	"Firebase"
  s.dependency	"Firebase/Database"
  s.dependency	"Firebase/Storage"

end
