Pod::Spec.new do |s|

  s.name         = "KiteImageEditor"
  s.version      = "1.0.0"
  s.summary      = "A simple editor that allows panning and rotating and image within a container"
  s.description  = <<-DESC
  A simple editor that allows panning and rotating and image to fit a container. The editor also guarantees not white space left after the image is panned around.
                   DESC

  s.license      = "MIT"
  s.platform     = :ios, "10.0"
  s.authors      = { 'Jaime Landazuri' => 'jlandazuri42@gmail.com' }
  s.homepage     = 'https://www.kite.ly'
  s.source       = { :git => "https://github.com/OceanLabs/KiteImageEditor-iOS.git", :tag => "#{s.version}" }
  s.source_files  = ["KiteImageEditor/**/*.swift"]
  s.swift_version = "4.1"
  s.resource_bundles  = { 'KiteImageEditorResources' => ['KiteImageEditor/KiteImageEditor.storyboard', 'KiteImageEditor/KiteImageEditor.xcassets'] }
  s.module_name         = 'KiteImageEditor'

end