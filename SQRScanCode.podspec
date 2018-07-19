Pod::Spec.new do |s|

  s.name         = "SQRScanCode"
  s.version      = "0.0.4"
  s.summary  	 = '扫描条形码和二维码'
  s.homepage     = "https://github.com/pengruiCode/SQRScanCode.git"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = {'pengrui' => 'pengruiCode@163.com'}
  s.source       = { :git => 'https://github.com/pengruiCode/SQRScanCode.git', :tag => s.version}
  s.platform 	 = :ios, "8.0"
  s.source_files = "SQRScanCode/**/*.{h,m}"
  s.resource     = 'SQRScanCode/Resource/*.png'
  s.requires_arc = true
  s.description  = <<-DESC
			扫描条形码和二维码并返回
                   DESC

  s.subspec "SQRBaseDefineWithFunction" do |ss|
     ss.dependency "SQRBaseDefineWithFunction"
  end

 end