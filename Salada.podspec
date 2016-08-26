Pod::Spec.new do |s|

  s.name         = "Salada"
  s.version      = "0.1"
  s.summary      = "Salad is a Model for Firebase database. It can handle Snapshot of Firebase easily."
  s.homepage     = "https://github.com/1amageek/Salada"
  s.license      = { :type => "BSD" }
  s.author    = "1amageek"
  s.social_media_url   = "https://twitter.com/1_am_a_geek"
  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/1amageek/Salada.git", :tag => "#{s.version}" }
  s.source_files  = ["Salada/Salada.swift"]
  s.exclude_files = []
  s.dependency  "Firebase"

end
