#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'image_picker_plus'
  s.version          = '0.5.10'
  s.summary          = 'Customization of the gallery display or even camera and video.'
  s.description      = <<-DESC
Customization of the gallery display or even camera and video.
                       DESC
  s.homepage         = 'https://github.com/AhmedAbdoElhawary/image_picker_plus.git'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ahmed Abdo Elhawary' => 'email@example.com' }
  s.source           = { :path => '.' }

  s.source_files         = 'Classes/**/*'
  s.public_header_files  = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '13.0'
end

