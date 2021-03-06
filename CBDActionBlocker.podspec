Pod::Spec.new do |s|


  s.name         = "CBDActionBlocker"
  s.version      = "1.0.0"
  s.summary      = "CBDActionBlocker provides an NSTimer-like class for blocking method calls."

  s.author       = { "Colas Bardavid" => "colas.bardavid@gmail.com" }
  s.homepage     = "https://github.com/colasbd/CBDActionBlocker"

  s.license      = { :type => 'MIT'}

  s.source       = { :git => 'https://github.com/colasbd/CBDActionBlocker.git', 
                     :tag =>  "#{s.version}" }  

  s.framework    = 'Foundation'

  s.source_files = 'Classes/**/*.{h,m}'

  s.requires_arc = true
  
end
