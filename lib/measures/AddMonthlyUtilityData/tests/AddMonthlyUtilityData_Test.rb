# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'minitest/autorun'

class AddMonthlyUtilityData_Test < Minitest::Test
  def test_AddMonthlyUtilityData
    # create an instance of the measure
    measure = AddMonthlyUtilityData.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(5, arguments.size)
    assert_equal('electric_json', arguments[0].name)
    assert_equal('gas_json', arguments[1].name)
    assert_equal('water_json', arguments[2].name)
    assert_equal('start_date', arguments[3].name)
    assert_equal('end_date', arguments[4].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    electric_json = arguments[0].clone
    assert(electric_json.setValue("#{File.dirname(__FILE__)}/electric_billed_usages.json"))
    argument_map['electric_json'] = electric_json

    gas_json = arguments[1].clone
    assert(gas_json.setValue("#{File.dirname(__FILE__)}/gas_billed_usages.json"))
    argument_map['gas_json'] = gas_json

    start_date = arguments[2].clone
    assert(start_date.setValue('2012-06-19'))
    argument_map['start_date'] = start_date

    end_date = arguments[3].clone
    assert(end_date.setValue('2013-05-20'))
    argument_map['end_date'] = end_date

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
  end
end
