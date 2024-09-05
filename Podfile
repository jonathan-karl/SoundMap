# Uncomment the next line to define a global platform for your project

platform :ios, '17.2'

target 'SoundMap' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Noise
  pod 'GoogleMaps', '8.4.0'
  pod 'Google-Maps-iOS-Utils'
  pod 'GooglePlaces'
  pod 'GoogleSignIn'
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'FirebaseFirestore'
  pod 'FirebaseAnalytics'
  pod 'FirebaseStorage'
  pod 'Charts'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.2'
    end
  end
  
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.2'
      end
    end
  end
end