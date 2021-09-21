# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'fileutils'

require 'minitest/autorun'

class CalibrationReportsEnhanced_Test < Minitest::Test
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

    if is_openstudio_2?
      setup_test_2(test_name, epw_path)
    else
      setup_test_1(test_name, epw_path)
    end
  end

  # calibration_reports
  def test_CalibrationReportsEnhanced
    test_name = 'calibration_reports'

    # create an instance of the measure
    measure = CalibrationReportsEnhanced.new

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
  def test_CalibrationReportsEnhanced_NoGas
    test_name = 'calibration_reports_no_gas'

    # load model, remove gas bills, save to new file
    raw_model_path = "#{File.dirname(__FILE__)}/ExampleModel.osm"
    vt = OpenStudio::OSVersion::VersionTranslator.new
    model = vt.loadModel(raw_model_path)
    assert(!model.empty?)
    model = model.get
    utilityBills = model.getUtilityBills
    assert_equal(2, utilityBills.size)
    utilityBills.each do |utilityBill|
      utilityBill.remove if utilityBill.fuelType == 'Gas'.to_FuelType
    end
    utilityBills = model.getUtilityBills
    assert_equal(1, utilityBills.size)
    altered_model_path = OpenStudio::Path.new("#{run_dir(test_name)}/ExampleModelNoGasInput.osm")
    FileUtils.mkdir_p run_dir(test_name)
    model.save(altered_model_path, true)

    # set model_in_path to new altered copy of model
    model_in_path = altered_model_path

    # create an instance of the measure
    measure = CalibrationReportsEnhanced.new

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

  # calibration_reports_no_demand
  def test_CalibrationReportsEnhanced_NoDemand
    test_name = 'calibration_reports_no_demand'

    # load model, remove gas bills, save to new file
    raw_model_path = "#{File.dirname(__FILE__)}/ExampleModel.osm"
    vt = OpenStudio::OSVersion::VersionTranslator.new
    model = vt.loadModel(raw_model_path)
    assert(!model.empty?)
    model = model.get
    utilityBills = model.getUtilityBills
    assert_equal(2, utilityBills.size)
    utilityBills.each do |utilityBill|
      next unless utilityBill.fuelType == 'Electricity'.to_FuelType
      utilityBill.billingPeriods.each(&:resetPeakDemand)
    end
    utilityBills = model.getUtilityBills
    assert_equal(2, utilityBills.size)
    altered_model_path = OpenStudio::Path.new("#{run_dir(test_name)}/ExampleModelNoDemandInput.osm")
    FileUtils.mkdir_p run_dir(test_name)
    model.save(altered_model_path, true)

    # set model_in_path to new altered copy of model
    model_in_path = altered_model_path

    # create an instance of the measure
    measure = CalibrationReportsEnhanced.new

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

  # calibration_reports_with_two_gas_bills
  def test_CalibrationReportsEnhanced_TwoGas
    test_name = 'calibration_reports_two_gas'

    # load model, remove gas bills, save to new file
    raw_model_path = "#{File.dirname(__FILE__)}/ExampleModel.osm"
    vt = OpenStudio::OSVersion::VersionTranslator.new
    model = vt.loadModel(raw_model_path)
    assert(!model.empty?)
    model = model.get
    utilityBills = model.getUtilityBills
    assert_equal(2, utilityBills.size)
    utilityBills.each do |utilityBill|
      utilityBill.clone(model) if utilityBill.fuelType == 'Gas'.to_FuelType
    end
    utilityBills = model.getUtilityBills
    assert_equal(3, utilityBills.size)
    altered_model_path = OpenStudio::Path.new("#{run_dir(test_name)}/ExampleModelTwoGasInput.osm")
    FileUtils.mkdir_p run_dir(test_name)
    model.save(altered_model_path, true)

    # set model_in_path to new altered copy of model
    model_in_path = altered_model_path

    # create an instance of the measure
    measure = CalibrationReportsEnhanced.new

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
      assert(result.warnings.size == 1)
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

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  # calibration_reports
  def test_CalibrationFuelOil2
    skip 'Remove once CI is using 2.7.0 or later'

    test_name = 'calibration_fuel_oil2'
    model_in_path = "#{File.dirname(__FILE__)}/ExampleModel_FuelOil.osm"

    # create an instance of the measure
    measure = CalibrationReportsEnhanced.new

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
    setup_test(test_name, idf_output_requests, model_in_path)

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
      # assert(result.warnings.size == 0)
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
    assert_equal(3, model.getUtilityBills.size)
    model.getUtilityBills.each do |utilityBill|
      assert(!utilityBill.billingPeriods.empty?)
      utilityBill.billingPeriods.each do |billingPeriod|
        assert(!billingPeriod.modelConsumption.empty?)
      end

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
end
