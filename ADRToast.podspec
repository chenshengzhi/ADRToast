
Pod::Spec.new do |s|

  s.name         = "ADRToast"
  s.version      = "0.0.1"
  s.summary      = "my toast"

  s.description  = <<-DESC
                   show toast
                   DESC

  s.homepage     = "https://github.com/chenshengzhi/ADRToast"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = { "陈圣治" => "csz2136@163.com" }

  s.platform     = :ios

  s.source       = { :git => "https://github.com/chenshengzhi/ADRToast.git", :tag => s.version.to_s }

  s.source_files  = "*.{h,m}"

  s.requires_arc = true

end
