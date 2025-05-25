platform :ios, '17.2'
target 'SoundMap' do
  use_frameworks!
  
  pod 'GoogleMaps', '8.4.0'
  pod 'Google-Maps-iOS-Utils'
  pod 'GooglePlaces'
  pod 'GoogleSignIn'
  pod 'GoogleSignInSwift'
  pod 'GoogleAnalytics'
  pod 'Firebase'
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'FirebaseAnalytics'
  pod 'FirebaseStorage'
  pod 'Charts'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.2'

      # Fix for BoringSSL-GRPC
      if target.name == 'BoringSSL-GRPC'
        target.source_build_phase.files.each do |file|
          if file.settings && file.settings['COMPILER_FLAGS']
            flags = file.settings['COMPILER_FLAGS'].split
            flags = flags.reject { |flag| flag == '-G' || flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
            file.settings['COMPILER_FLAGS'] = flags.join(' ')
          end
        end
      end
    end
  end
end