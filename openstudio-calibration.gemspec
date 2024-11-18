lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openstudio/calibration/version'

Gem::Specification.new do |spec|
  spec.name          = 'openstudio-calibration'
  spec.version       = OpenStudio::Calibration::VERSION
  spec.authors       = ['Brian Ball', 'Nicholas Long']
  spec.email         = ['brian.ball@nrel.gov', 'nicholas.long@nrel.gov']

  spec.summary       = 'Library and measures for OpenStudio Calibration'
  spec.description   = 'Library and measures for OpenStudio Calibration'
  spec.homepage      = 'https://openstudio.net'
  spec.summary       = 'openstudio base gem for creating generic extensions with encapsulated data and measures.'
  spec.description   = 'openstudio base gem for creating generic extensions with encapsulated data and measures.'
  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/NREL/openstudio-calibration-gem/issues',
    'changelog_uri' => 'https://github.com/NREL/openstudio-calibration-gem/blob/develop/CHANGELOG.md',
    # 'documentation_uri' =>  'https://www.rubydoc.info/gems/openstudio-calibration-gem/#{gem.version}',
    'source_code_uri' => "https://github.com/NREL/openstudio-calibration-gem/tree/v#{spec.version}"
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|lib.measures.*tests|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 3.2.2'

  spec.add_dependency 'bundler', '~> 2.4.10'
  spec.add_dependency 'openstudio-extension', '~> 0.8.2'
  spec.add_dependency 'openstudio-standards', '0.7.0'

  # if we need the following dependencies pinned, 
  # let's set them in extension-gem for next release
  spec.add_dependency 'multipart-post', '2.4.0'
  spec.add_dependency 'addressable', '2.8.1'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
  spec.add_development_dependency 'octokit', '4.18.0' # for change logs
end
