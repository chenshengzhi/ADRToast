Pod::Spec.new do |s|

  
  s.name         = "ADRToast"
  s.version      = "0.0.1"
  s.summary      = "A short description of ADRToast."

  s.description  = <<-DESC    
                   * my toast
                   DESC

  s.homepage     = "https://github.com/chenshengzhi/ADRToast"


  s.author             = { "陈圣治" => "csz2136@163.com" }

  s.platform     = :ios
  s.platform     = :ios, "5.0"


  s.source       = { :git => "https://github.com/chenshengzhi/ADRToast.git", :tag => s.version.to_s }


  s.source_files  = "*.{h,m}"

  s.public_header_files = "*.h"

end
