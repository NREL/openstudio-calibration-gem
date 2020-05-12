lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openstudio/calibration_measures/version'

Gem::Specification.new do |spec|
  spec.name          = 'openstudio-calibration-measures'
  spec.version       = OpenStudio::CalibrationMeasures::VERSION
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
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.5.0'

  spec.add_dependency 'bundler', '~> 2.1'
  spec.add_dependency 'openstudio-extension', '~> 0.2.3'
  spec.add_dependency 'openstudio-standards', '~> 0.2.11'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
end
