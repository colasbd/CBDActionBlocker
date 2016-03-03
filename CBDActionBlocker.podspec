Pod::Spec.new do |s|
  s.name         = "CBDActionBlocker"
  s.version      = "1.0.0"
  s.summary      = "CBDActionBlocker provides an NSTimer-like class for blocking method calls."
  s.homepage     = "https://colasjojo@bitbucket.org/colasjojo/cbdactionblocker.git"
  s.license      = 'MIT'
  s.author       = { "Colas Bardavid" => "colas.bardavid@gmail.com" }
  s.source       = { :git => 'https://colasjojo@bitbucket.org/colasjojo/cbdactionblocker.git', 
                     :tag =>  "#{s.version}" }  s.source_files = '*.{h,m}'
  s.framework    = 'Foundation'
  s.requires_arc = true
end
