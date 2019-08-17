# platform :ios, '9.0'
  
target 'UXSDKDemo' do
  use_frameworks!
  pod 'DJI-SDK-iOS', '~> 4.9.1'
  pod 'DJI-UXSDK-iOS', '~> 4.9'
  pod 'DJIWidget', '~> 1.5'
  pod 'Socket.IO-Client-Swift', :git => 'https://github.com/triniwiz/socket.io-client-swift.git'
end

post_install do |installer|
installer.pods_project.targets.each do |target|
target.build_configurations.each do |config|
config.build_settings['SWIFT_VERSION'] = '4.2'
end
end
end
