Gem::Specification.new do |s|
	s.name				= 'vlille'
	s.version			= '0.1.0'
	s.platform		= Gem::Platform::RUBY
	s.authors			= ['Samuel Loretan']
	s.email				= ['tynril@gmail.com']
	s.summary			= 'Easy access to the VLille data exposed by the official API.'
	s.description	= 'Easy access to the VLille data exposed by the official API.'
	
	s.add_dependency	'httparty'	'~> 0.11.0'
	s.add_dependency	'multi_xml'	'>= 0.5.2'

	s.files				= `git ls-files`.split("\n")
	s.test_files	= `git ls-files -- {test}/*`.split("\n")
end
