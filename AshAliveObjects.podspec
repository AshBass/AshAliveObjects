Pod::Spec.new do |spec|
  spec.name             = "AshAliveObjects"
  spec.version          = "0.0.1"
  spec.summary          = "A set of in-app debugging and exploration tools for iOS"
  spec.description      = "AshAliveObjects"
  spec.homepage         = "https://github.com/AshBass/AshAliveObjects.git"
  spec.license          = { :type => "BSD", :file => "LICENSE" }
  spec.author           = { "Ash" => "ashbass@163.com" }
  spec.platform         = :ios, "9.0"
  spec.source           = { :git => "https://github.com/AshBass/AshAliveObjects.git", :tag => "#{spec.version}" }
  spec.source_files     = [
    'Classes/AshAliveObjects.{h,c,m,mm}',
    'Classes/AshMallocObjectsOC.{h,c,m,mm}',
    'Classes/RetainChecker/AshRetainChecker.{h,c,m,mm}',
    'Classes/RetainChecker/AshRetainCheckerModel.{h,c,m,mm}',
    'Classes/RetainChecker/BlockRetainChecker/arc/AshBlockRetainSupport.{h,c,m,mm}',
    'Classes/RetainChecker/BlockRetainChecker/mrc/AshBlockRetainModel.{h,c,m,mm}',
    'Classes/RetainChecker/BlockRetainChecker/mrc/AshBlockRetainChecker.{h,c,m,mm}'
  ]
  spec.requires_arc = false
  spec.requires_arc = [
    'Classes/AshAliveObjects.{h,c,m,mm}',
    'Classes/AshMallocObjectsOC.{h,c,m,mm}',
    'Classes/RetainChecker/AshRetainChecker.{h,c,m,mm}',
    'Classes/RetainChecker/AshRetainCheckerModel.{h,c,m,mm}',
    'Classes/RetainChecker/BlockChecker/arc/AshBlockRetainSupport.{h,c,m,mm}'
  ]

end
