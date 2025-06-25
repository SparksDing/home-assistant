# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'home-assistant' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'SwiftProtobuf', '~> 1.17.0' # 指定 SwiftProtobuf 的版本

  # Pods for home-assistant

  target 'home-assistantTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'SwiftProtobuf', '~> 1.17.0' # 指定 SwiftProtobuf 的版本
  end

  target 'home-assistantUITests' do
    # Pods for testing
    pod 'SwiftProtobuf', '~> 1.17.0' # 指定 SwiftProtobuf 的版本
  end

end
