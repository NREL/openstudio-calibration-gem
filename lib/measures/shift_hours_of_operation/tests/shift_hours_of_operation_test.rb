# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ShiftHoursOfOperationTest < Minitest::Test
  def test_good_argument_values
    # create an instance of the measure
    measure = ShiftHoursOfOperation.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/example_model.osm"
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['hoo_start_weekday'] = 4.0
    args_hash['hoo_dur_weekday'] = 4.5
    args_hash['hoo_start_saturday'] = -2.0
    args_hash['hoo_dur_saturday'] = -1.0
    args_hash['hoo_dur_sunday'] = 1 # TODO: - isn't going to have any impact on formulas the way it is setup now
    args_hash['hoo_start_sunday'] = 3 # todo - isn't going to have any impact on formulas the way it is setup now
    # args_hash['fraction_of_daily_occ_range'] = 0.5
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
    # assert(result.info.size == 1)
    # assert(result.warnings.empty?)

    # save the model to test output directory
    output_file_path = "#{File.dirname(__FILE__)}//output/test_output.osm"
    model.save(output_file_path, true)
  end

  def test_example_default_args
    # create an instance of the measure
    measure = ShiftHoursOfOperation.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/example_model.osm"
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    # args_hash['hoo_start_weekday'] = 4.0
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # save the model to test output directory
    output_file_path = "#{File.dirname(__FILE__)}//output/test_example_default.osm"
    model.save(output_file_path, true)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
    # assert(result.info.size == 1)
    # assert(result.warnings.empty?)
  end

  def test_simple_model
    # create an instance of the measure
    measure = ShiftHoursOfOperation.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/SimpleModel.osm"
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    # args_hash['hoo_start_weekday'] = 4.0
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # save the model to test output directory
    output_file_path = "#{File.dirname(__FILE__)}//output/test_simple_model.osm"
    model.save(output_file_path, true)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
    # assert(result.info.size == 1)
    # assert(result.warnings.empty?)
  end

  def test_target_hoo_from_model
    # create an instance of the measure
    measure = ShiftHoursOfOperation.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/target_hoo_from_model.osm"
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['test_target_hoo_from_model'] = true
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # save the model to test output directory
    output_file_path = "#{File.dirname(__FILE__)}//output/test_target_hoo_from_model.osm"
    model.save(output_file_path, true)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
    # assert(result.info.size == 1)
    # assert(result.warnings.empty?)
  end

  def test_delta_values_false
    # create an instance of the measure
    measure = ShiftHoursOfOperation.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/SimpleModel.osm" # todo change test back to delta_values_false.osm or add new test
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['hoo_start_weekday'] = 8.0
    args_hash['hoo_dur_weekday'] = 16.0
    args_hash['delta_values'] = false
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # save the model to test output directory
    output_file_path = "#{File.dirname(__FILE__)}//output/test_delta_values_false.osm"
    model.save(output_file_path, true)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
    # assert(result.info.size == 1)
    # assert(result.warnings.empty?)
  end

  def test_delta_values_false2
    # create an instance of the measure
    measure = ShiftHoursOfOperation.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/delta_values_false.osm"
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['hoo_start_weekday'] = 8.0
    args_hash['hoo_dur_weekday'] = 17.0
    args_hash['hoo_start_saturday'] = 5.0
    args_hash['hoo_dur_saturday'] = 20.0
    args_hash['hoo_start_sunday'] = 8.0
    args_hash['hoo_dur_sunday'] = 10.0
    args_hash['delta_values'] = false
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # save the model to test output directory
    output_file_path = "#{File.dirname(__FILE__)}//output/test_delta_values_false2.osm"
    model.save(output_file_path, true)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
    # assert(result.info.size == 1)
    # assert(result.warnings.empty?)
  end

  # todo - figure out why for both delta_values false no parametric schules are being made, adn even initial condition of model isn't being reported cleanly, but tehre is no ruby failure.
  # todo - these tests have a unique test model, maybe that is issue, not sure why needed a different model. delta_values_false.osm
  # todo - when I chacned test model to SimpleModel it did fix the initial condition but not final condition, but did make file schedules instead of 0, but why can't they be inspected
  def test_hoo_var_method_hourly
    # create an instance of the measure
    measure = ShiftHoursOfOperation.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/SimpleModel.osm"
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['hoo_start_weekday'] = 8.0
    args_hash['hoo_dur_weekday'] = 17.0
    args_hash['hoo_start_saturday'] = 8.0
    args_hash['hoo_dur_saturday'] = 10.0
    args_hash['hoo_start_sunday'] = 8.0
    args_hash['hoo_dur_sunday'] = 10.0
    args_hash['delta_values'] = false
    args_hash['hoo_var_method'] = 'hours' # default updated to fractional
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # save the model to test output directory
    output_file_path = "#{File.dirname(__FILE__)}//output/test_hoo_var_method_hourly.osm"
    model.save(output_file_path, true)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
    # assert(result.info.size == 1)
    # assert(result.warnings.empty?)
  end

end
