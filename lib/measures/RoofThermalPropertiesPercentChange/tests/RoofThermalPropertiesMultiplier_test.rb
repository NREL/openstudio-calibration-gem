# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'minitest/autorun'

class RoofThermalPropertiesPercentChange_Test < Minitest::Test
  def test_RoofThermalPropertiesPercentChange
    # create an instance of the measure
    measure = RoofThermalPropertiesPercentChange.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/example_model.osm"
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(3, arguments.size)
    assert_equal('r_value_perc_change', arguments[0].name)
    assert_equal('solar_abs_perc_change', arguments[1].name)
    assert_equal('thermal_mass_perc_change', arguments[2].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    r_value_perc_change = arguments[0].clone
    assert(r_value_perc_change.setValue(1.2))
    argument_map['r_value_perc_change'] = r_value_perc_change

    solar_abs_perc_change = arguments[1].clone
    assert(solar_abs_perc_change.setValue(1.4))
    argument_map['solar_abs_perc_change'] = solar_abs_perc_change

    thermal_mass_perc_change = arguments[2].clone
    assert(thermal_mass_perc_change.setValue(0.3))
    argument_map['thermal_mass_perc_change'] = thermal_mass_perc_change

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
  end
end
