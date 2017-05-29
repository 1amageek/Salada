platform :ios, '8.0'

target 'Salada' do
  use_frameworks!
  pod 'Firebase/Database'
  pod 'Firebase/Storage'
end

target 'SaladBar' do
  use_frameworks!
  pod 'Firebase/Database'
  pod 'Firebase/Storage'
end

target 'TestApp' do
  use_frameworks!
  pod 'Firebase/Database'
  pod 'Firebase/Storage'

  target 'TestAppTests' do
    inherit! :search_paths
    pod 'Firebase/Database'
    pod 'Firebase/Storage'
    pod 'Quick'
    pod 'Nimble'
  end

  target 'TestAppUITests' do
    inherit! :search_paths
    pod 'Firebase/Database'
    pod 'Firebase/Storage'
  end
end
