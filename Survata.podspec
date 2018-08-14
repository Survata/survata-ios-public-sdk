Pod::Spec.new do |s|
  s.name             = "Survata"
  s.version          = "2.0.0"
  s.summary          = "Survata SDK"
  s.homepage         = "https://github.com/Survata/survata-ios-public-sdk"
  s.license          = 'MIT'
  s.author           = { "Rex Sheng" => "https://github.com/b051" }
  s.source           = { :git => "https://github.com/Survata/survata-ios-public-sdk.git", :tag => s.version.to_s }
  s.requires_arc     = true
  s.platform         = :ios, "8.0"
  s.source_files     = "Survata/*.swift"
  s.resources        = "Survata/*.html", "Survata/*.png"
end
