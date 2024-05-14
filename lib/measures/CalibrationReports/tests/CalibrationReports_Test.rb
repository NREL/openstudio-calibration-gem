# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure'
require 'minitest/autorun'

class CalibrationReports_Test < Minitest::Test
  def is_openstudio_2?
    begin
      workflow = OpenStudio::WorkflowJSON.new
    rescue StandardError
      return false
    end
    true
  end

  def model_in_path_default
    "#{File.dirname(__FILE__)}/ExampleModel.osm"
  end

  def epw_path_default
    # make sure we have a weather data location
    epw = nil
    epw = OpenStudio::Path.new("#{File.dirname(__FILE__)}/USA_CO_Golden-NREL.724666_TMY3.epw")
    assert(File.exist?(epw.to_s))
    epw.to_s
  end

  def run_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def model_out_path(test_name)
    "#{run_dir(test_name)}/TestOutput.osm"
  end

  def workspace_path(test_name)
    if is_openstudio_2?
      "#{run_dir(test_name)}/run/in.idf"
    else
      "#{run_dir(test_name)}/ModelToIdf/in.idf"
    end
  end

  def sql_path(test_name)
    if is_openstudio_2?
      "#{run_dir(test_name)}/run/eplusout.sql"
    else
      "#{run_dir(test_name)}/ModelToIdf/EnergyPlusPreProcess-0/EnergyPlus-0/eplusout.sql"
    end
  end

  def report_path(test_name)
    "#{run_dir(test_name)}/report.html"
  end

  # method for running the test simulation using OpenStudio 1.x API
  def setup_test_1(test_name, epw_path)
    co = OpenStudio::Runmanager::ConfigOptions.new(true)
    co.findTools(false, true, false, true)

    unless File.exist?(sql_path(test_name))
      puts 'Running EnergyPlus'

      wf = OpenStudio::Runmanager::Workflow.new('modeltoidf->energypluspreprocess->energyplus')
      wf.add(co.getTools)
      job = wf.create(OpenStudio::Path.new(run_dir(test_name)), OpenStudio::Path.new(model_out_path(test_name)), OpenStudio::Path.new(epw_path))

      rm = OpenStudio::Runmanager::RunManager.new
      rm.enqueue(job, true)
      rm.waitForFinished
    end
  end

  # method for running the test simulation using OpenStudio 2.x API
  def setup_test_2(test_name, epw_path)
    osw_path = File.join(run_dir(test_name), 'in.osw')
    osw_path = File.absolute_path(osw_path)

    workflow = OpenStudio::WorkflowJSON.new
    workflow.setSeedFile(File.absolute_path(model_out_path(test_name)))
    workflow.setWeatherFile(File.absolute_path(epw_path))
    workflow.saveAs(osw_path)

    cli_path = OpenStudio.getOpenStudioCLI
    cmd = "\"#{cli_path}\" run -w \"#{osw_path}\""
    puts cmd
    system(cmd)
  end

  # create test files if they do not exist when the test first runs
  def setup_test(test_name, idf_output_requests, model_in_path = model_in_path_default, epw_path = epw_path_default)
    FileUtils.mkdir_p(run_dir(test_name)) unless File.exist?(run_dir(test_name))
    assert(File.exist?(run_dir(test_name)))

    FileUtils.rm(report_path(test_name)) if File.exist?(report_path(test_name))

    assert(File.exist?(model_in_path))

    if File.exist?(model_out_path(test_name))
      FileUtils.rm(model_out_path(test_name))
    end

    # convert output requests to OSM for testing, OS App and PAT will add these to the E+ Idf
    workspace = OpenStudio::Workspace.new('Draft'.to_StrictnessLevel, 'EnergyPlus'.to_IddFileType)
    workspace.addObjects(idf_output_requests)
    rt = OpenStudio::EnergyPlus::ReverseTranslator.new
    request_model = rt.translateWorkspace(workspace)

    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(model_in_path)
    assert(!model.empty?)
    model = model.get
    model.addObjects(request_model.objects)
    model.save(model_out_path(test_name), true)

    if ENV['OPENSTUDIO_TEST_NO_CACHE_SQLFILE'] && File.exist?(sql_path(test_name))
      FileUtils.rm_f(sql_path(test_name))
    end

    if is_openstudio_2?
      setup_test_2(test_name, epw_path)
    else
      setup_test_1(test_name, epw_path)
    end
  end

  # calibration_reports
  def test_CalibrationReports
    test_name = 'calibration_reports'
    model_in_path = "#{File.dirname(__FILE__)}/ExampleModel.osm"

    # create an instance of the measure
    measure = CalibrationReports.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      assert(temp_arg_var.setValue(args_hash[arg.name])) if args_hash[arg.name]
      argument_map[arg.name] = temp_arg_var
    end

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert_equal(0, idf_output_requests.size)

    # mimic the process of running this measure in OS App or PAT. Optionally set custom model_in_path and custom epw_path.
    epw_path = epw_path_default
    setup_test(test_name, idf_output_requests)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw_path))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw_path)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    FileUtils.rm(report_path(test_name)) if File.exist?(report_path(test_name))
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)
      assert(result.warnings.empty?)
    ensure
      Dir.chdir(start_dir)
    end

    model = runner.lastOpenStudioModel
    assert(!model.empty?)
    model = model.get

    sqlFile = runner.lastEnergyPlusSqlFile
    assert(!sqlFile.empty?)
    sqlFile = sqlFile.get

    model.setSqlFile(sqlFile)

    # must have a runPeriod
    runPeriod = model.runPeriod
    assert(!runPeriod.empty?)

    # must have a calendarYear
    yearDescription = model.yearDescription
    assert(!yearDescription.empty?)
    calendarYear = yearDescription.get.calendarYear
    assert(!calendarYear.empty?)

    # check for varying demand
    model.getUtilityBills.each do |utilityBill|
      next if utilityBill.peakDemandUnitConversionFactor.empty?

      hasVaryingDemand = false
      modelPeakDemand = 0.0
      count = 0
      utilityBill.billingPeriods.each do |billingPeriod|
        peakDemand = billingPeriod.modelPeakDemand
        next if peakDemand.empty?

        temp = peakDemand.get
        if count == 0
          modelPeakDemand = temp
        else
          if modelPeakDemand != temp
            hasVaryingDemand = true
            break
          end
        end
        count += 1
      end
      assert(hasVaryingDemand) if count > 1
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  # calibration_reports_no_gas
  def test_CalibrationReports_NoGas
    test_name = 'calibration_reports_no_gas'

    #     # load model, remove gas bills, save to new file
    #     raw_model_path = "#{File.dirname(__FILE__)}/ExampleModel.osm"
    #     vt = OpenStudio::OSVersion::VersionTranslator.new
    #     model = vt.loadModel(raw_model_path)
    #     assert(!model.empty?)
    #     model = model.get
    #     utilityBills = model.getUtilityBills
    #     assert_equal(2, utilityBills.size)
    #     utilityBills.each do |utilityBill|
    #       if utilityBill.fuelType == 'Gas'.to_FuelType
    #         utilityBill.remove
    #       end
    #     end
    #     utilityBills = model.getUtilityBills
    #     assert_equal(1, utilityBills.size)
    #     altered_model_path = OpenStudio::Path.new("#{run_dir(test_name)}/ExampleModelNoGasInput.osm")
    #     model.save(altered_model_path, true)
    #
    #     # set model_in_path to new altered copy of model
    #     model_in_path = altered_model_path

    # dynamically generated test model creating issues on CI, so using pre-made test model for now.
    model_in_path = "#{File.dirname(__FILE__)}/ExampleModelNoGasInput.osm"

    # create an instance of the measure
    measure = CalibrationReports.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      assert(temp_arg_var.setValue(args_hash[arg.name])) if args_hash[arg.name]
      argument_map[arg.name] = temp_arg_var
    end

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert_equal(0, idf_output_requests.size)

    # mimic the process of running this measure in OS App or PAT. Optionally set custom model_in_path and custom epw_path.
    epw_path = epw_path_default
    sleep = 4 # try adding sleep for stability when test model is being created within test fails inconsistently
    setup_test(test_name, idf_output_requests, model_in_path.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw_path))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw_path)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    FileUtils.rm(report_path(test_name)) if File.exist?(report_path(test_name))
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)
      assert(result.warnings.empty?)
    ensure
      Dir.chdir(start_dir)
    end

    model = runner.lastOpenStudioModel
    assert(!model.empty?)
    model = model.get

    sqlFile = runner.lastEnergyPlusSqlFile
    assert(!sqlFile.empty?)
    sqlFile = sqlFile.get

    model.setSqlFile(sqlFile)

    # must have a runPeriod
    runPeriod = model.runPeriod
    assert(!runPeriod.empty?)

    # must have a calendarYear
    yearDescription = model.yearDescription
    assert(!yearDescription.empty?)
    calendarYear = yearDescription.get.calendarYear
    assert(!calendarYear.empty?)

    # check for varying demand
    model.getUtilityBills.each do |utilityBill|
      next if utilityBill.peakDemandUnitConversionFactor.empty?

      hasVaryingDemand = false
      modelPeakDemand = 0.0
      count = 0
      utilityBill.billingPeriods.each do |billingPeriod|
        peakDemand = billingPeriod.modelPeakDemand
        next if peakDemand.empty?

        temp = peakDemand.get
        if count == 0
          modelPeakDemand = temp
        else
          if modelPeakDemand != temp
            hasVaryingDemand = true
            break
          end
        end
        count += 1
      end
      assert(hasVaryingDemand) if count > 1
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  # calibration_reports_no_gas
  def test_CalibrationReports_NoDemand
    test_name = 'calibration_reports_no_demand'

    #     # load model, remove gas bills, save to new file
    #     raw_model_path = "#{File.dirname(__FILE__)}/ExampleModel.osm"
    #     vt = OpenStudio::OSVersion::VersionTranslator.new
    #     model = vt.loadModel(raw_model_path)
    #     assert(!model.empty?)
    #     model = model.get
    #     utilityBills = model.getUtilityBills
    #     assert_equal(2, utilityBills.size)
    #     utilityBills.each do |utilityBill|
    #       if utilityBill.fuelType == 'Electricity'.to_FuelType
    #         utilityBill.billingPeriods.each(&:resetPeakDemand)
    #       end
    #     end
    #     utilityBills = model.getUtilityBills
    #     assert_equal(2, utilityBills.size)
    #     altered_model_path = OpenStudio::Path.new("#{run_dir(test_name)}/ExampleModelNoDemandInput.osm")
    #     model.save(altered_model_path, true)
    #
    #     # set model_in_path to new altered copy of model
    #     model_in_path = altered_model_path

    # dynamically generated test model creating issues on CI, so using pre-made test model for now.
    model_in_path = "#{File.dirname(__FILE__)}/ExampleModelNoDemandInput.osm"

    # create an instance of the measure
    measure = CalibrationReports.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      assert(temp_arg_var.setValue(args_hash[arg.name])) if args_hash[arg.name]
      argument_map[arg.name] = temp_arg_var
    end

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert_equal(0, idf_output_requests.size)

    # mimic the process of running this measure in OS App or PAT. Optionally set custom model_in_path and custom epw_path.
    epw_path = epw_path_default
    sleep = 4 # try adding sleep for stability when test model is being created within test fails inconsistently
    setup_test(test_name, idf_output_requests, model_in_path.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw_path))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw_path)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    FileUtils.rm(report_path(test_name)) if File.exist?(report_path(test_name))
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)
      assert(result.warnings.empty?)
    ensure
      Dir.chdir(start_dir)
    end

    model = runner.lastOpenStudioModel
    assert(!model.empty?)
    model = model.get

    sqlFile = runner.lastEnergyPlusSqlFile
    assert(!sqlFile.empty?)
    sqlFile = sqlFile.get

    model.setSqlFile(sqlFile)

    # must have a runPeriod
    runPeriod = model.runPeriod
    assert(!runPeriod.empty?)

    # must have a calendarYear
    yearDescription = model.yearDescription
    assert(!yearDescription.empty?)
    calendarYear = yearDescription.get.calendarYear
    assert(!calendarYear.empty?)

    # check for no demand
    model.getUtilityBills.each do |utilityBill|
      utilityBill.billingPeriods.each do |billingPeriod|
        assert(billingPeriod.peakDemand.empty?)
      end
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end
end
