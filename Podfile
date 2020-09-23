def firebaseStuff
  pod 'Firebase/Analytics'
  pod 'Firebase/Core'
  pod 'Firebase/Firestore'
  pod 'Firebase/Database'
  pod 'FirebaseUI'
  pod 'Firebase/Auth'
  pod 'FirebaseUI/Phone'
end

def google
  pod 'GoogleMaps'
  pod 'GooglePlaces'
end

target 'OneSignalNotificationServiceExtension' do
  #only copy below line
  platform :ios, '12.2'
  use_frameworks!  
  pod 'OneSignal', '>= 2.11.2', '< 3.0'
end

target 'Gossp' do
  platform :ios, '12.2'
  use_frameworks!
  pod 'OneSignal', '>= 2.11.2', '< 3.0'
  pod 'Tagging', :git => 'https://github.com/kaankaray/Tagging.git', :commit => 'a30b7d91bfc49b221108baeb0d61fbfd08dcc6e2'
  google
  firebaseStuff
end
