# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require_relative '../spec_helper'

RSpec.describe OpenStudio::Calibration do
  it 'has a version number' do
    expect(OpenStudio::Calibration::VERSION).not_to be nil
  end

  it 'has a measures directory' do
    instance = OpenStudio::Calibration::Extension.new
    expect(File.exist?(File.join(instance.measures_dir, 'AddMonthlyJSONUtilityData/'))).to be true
  end
end
