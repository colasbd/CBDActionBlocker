Pod::Spec.new do |s|
  s.name         = "CBDActionBlocker"
  s.version      = "0.0.4"
  s.summary      = "CBDActionBlocker provides an NSTimer-like class for blocking method calls."
  s.homepage     = "http://github.com/layervault/LVDebounce"
  s.license      = 'MIT'
  s.author       = { "Colas Bardavid" => "colas.bardavid@gmail.com" }
  s.source       = { :git => "https://github.com/layervault/LVDebounce.git", :tag => "0.0.4" }
  s.source_files = '*.{h,m}'
  s.framework    = 'Foundation'
  s.requires_arc = true
end
