Pod::Spec.new do |s|

  
  s.name         = "ADRToast"
  s.version      = "0.0.1"
  s.summary      = "my toast."

  s.description  = <<-DESC    
                   * my toast
                   * my toast
                   * my toast
                   DESC

  s.homepage     = "https://github.com/chenshengzhi/ADRToast"

  s.license          = 'MIT'

  s.author             = { "陈圣治" => "csz2136@163.com" }

  s.platform     = :ios, "5.0"
  s.requires_arc = true 

  s.source       = { :git => "https://github.com/chenshengzhi/ADRToast.git", :tag => s.version.to_s }
  s.public_header_files = "*.h"

  s.source_files  = "*.{h,m}"

  s.public_header_files = "*.h"

end
