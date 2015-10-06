Pod::Spec.new do |s|
  s.name         = "FMSocker"
  s.version      = "0.0.2"
  s.summary      = "iOS Socker client for handling multiple web socket channels on a single connection."
  s.homepage     = "https://github.com/5monkeys/socker-ios"
  s.license      = "MIT"
  s.author       = { "Hannes Ljungberg" => "hannes@5monkeys.se" }
  s.source       = { :git => 'https://github.com/5monkeys/socker-ios.git', :tag => s.version.to_s }
  s.source_files = "FMSocker/*.{h,m}"
  s.requires_arc = true
  s.platform     = :ios, '6.0'
  s.dependency "SocketRocket", "~> 0.4.1"
end
