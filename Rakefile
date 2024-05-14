# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# Load in the rake tasks from the base extension gem
require 'openstudio/extension/rake_task'
require 'openstudio/calibration'
rake_task = OpenStudio::Extension::RakeTask.new
rake_task.set_extension_class(OpenStudio::Calibration::Extension, 'nrel/openstudio-calibration-gem')

require 'rubocop/rake_task'
RuboCop::RakeTask.new

require 'openstudio_measure_tester/rake_task'
OpenStudioMeasureTester::RakeTask.new

task default: :spec
