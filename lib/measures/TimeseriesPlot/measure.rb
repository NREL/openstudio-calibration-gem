# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

require 'erb'

# start the measure
class TimeseriesPlot < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    'Timeseries Plot'
  end

  # human readable description
  def description
    'Creates an interactive timeseries plot of selected variable.'
  end

  # human readable description of modeling approach
  def modeler_description
    'NOTE: This will load and respond slowly in the OS app, especially if you select * on a variable with many possible keys or you select timestep data.  Suggest you open it in a web browser like Chrome instead.'
  end

  # define the arguments that the user will input
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for the variable name
    variable_name = OpenStudio::Measure::OSArgument.makeStringArgument('variable_name', true)
    variable_name.setDisplayName('Enter Variable Name.')
    variable_name.setDescription('Valid values can be found in the eplusout.rdd file after a simulation is run.')
    args << variable_name

    # make an argument for the electric tariff
    reporting_frequency_chs = OpenStudio::StringVector.new
    reporting_frequency_chs << 'Detailed'
    reporting_frequency_chs << 'Timestep'
    reporting_frequency_chs << 'Zone Timestep'
    reporting_frequency_chs << 'Hourly'
    reporting_frequency_chs << 'Daily'
    reporting_frequency_chs << 'Monthly'
    reporting_frequency_chs << 'Runperiod'
    reporting_frequency = OpenStudio::Measure::OSArgument.makeChoiceArgument('reporting_frequency', reporting_frequency_chs, true)
    reporting_frequency.setDisplayName('Reporting Frequency.')
    reporting_frequency.setDefaultValue('Hourly')
    args << reporting_frequency

    # make an argument for the key_value
    key_value = OpenStudio::Measure::OSArgument.makeStringArgument('key_value', true)
    key_value.setDisplayName('Enter Key Name.')
    key_value.setDescription('Enter * for all objects or the full name of a specific object to.')
    key_value.setDefaultValue('*')
    args << key_value

    env = OpenStudio::Measure::OSArgument.makeStringArgument('env', true)
    env.setDisplayName('availableEnvPeriods')
    env.setDescription('availableEnvPeriods')
    env.setDefaultValue('RUN PERIOD 1')
    args << env

    args
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments, user_arguments)

    # Assign the user inputs to variables
    variable_name = runner.getStringArgumentValue('variable_name', user_arguments)
    reporting_frequency = runner.getStringArgumentValue('reporting_frequency', user_arguments)
    key_value = runner.getStringArgumentValue('key_value', user_arguments)
    env = runner.getStringArgumentValue('env', user_arguments)

    # set ann_env_pd to be user defined arg
    ann_env_pd = env

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    sql = runner.lastEnergyPlusSqlFile
    if sql.empty?
      runner.registerError('Cannot find last sql file.')
      return false
    end
    sql = sql.get
    model.setSqlFile(sql)

    find_avail = TRUE
    if find_avail
      ts = sql.availableTimeSeries
      runner.registerInfo("available timeseries: #{ts}")
      runner.registerInfo('')
      envs = sql.availableEnvPeriods
      envs.each do |env_s|
        freqs = sql.availableReportingFrequencies(env_s)
        runner.registerInfo("available EnvPeriod: #{env_s}, available ReportingFrequencies: #{freqs}")
        freqs.each do |freq|
          vn = sql.availableVariableNames(env_s, freq.to_s)
          runner.registerInfo("available variable names: #{vn}")
          vn.each do |v|
            kv = sql.availableKeyValues(env_s, freq.to_s, v)
            runner.registerInfo("variable names: #{v}")
            runner.registerInfo("available key value: #{kv}")
          end
        end
      end
    end

    # Get the weather file run period (as opposed to design day run period)
    # ann_env_pd = nil
    # sql.availableEnvPeriods.each do |env_pd|
    # env_type = sql.environmentType(env_pd)
    # if env_type.is_initialized
    # if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
    # ann_env_pd = env_pd
    # end
    # end
    # end

    # if ann_env_pd == false
    # runner.registerError("Can't find a weather runperiod, make sure you ran an annual simulation, not just the design days.")
    # return false
    # end

    # Method to translate from OpenStudio's time formatting
    # to Javascript time formatting
    # OpenStudio time
    # 2009-May-14 00:10:00   Raw string
    # Javascript time
    # 2009/07/12 12:34:56
    def to_JSTime(os_time)
      js_time = os_time.to_s
      # Replace the '-' with '/'
      js_time = js_time.tr('-', '/')
      # Replace month abbreviations with numbers
      js_time = js_time.gsub('Jan', '01')
      js_time = js_time.gsub('Feb', '02')
      js_time = js_time.gsub('Mar', '03')
      js_time = js_time.gsub('Apr', '04')
      js_time = js_time.gsub('May', '05')
      js_time = js_time.gsub('Jun', '06')
      js_time = js_time.gsub('Jul', '07')
      js_time = js_time.gsub('Aug', '08')
      js_time = js_time.gsub('Sep', '09')
      js_time = js_time.gsub('Oct', '10')
      js_time = js_time.gsub('Nov', '11')
      js_time.gsub('Dec', '12')
    end

    # Create an array of arrays of variables
    variables_to_graph = []
    if key_value == '*'
      # Get all the key values from the sql file
      runner.registerInfo("Plotting #{sql.availableKeyValues(ann_env_pd, reporting_frequency, variable_name).size} variables")
      sql.availableKeyValues(ann_env_pd, reporting_frequency, variable_name).each do |kv|
        variables_to_graph << [variable_name, reporting_frequency, kv]
        runner.registerInfo("Plotting #{kv}")
      end
    else
      runner.registerInfo("Plotting #{variable_name}: #{reporting_frequency}: #{key_value}")
      variables_to_graph << [variable_name, reporting_frequency, key_value]
      runner.registerInfo("variables_to_graph: #{variables_to_graph}")
    end

    # Create a new series like this
    # for each condition series we want to plot
    # {"name" : "series 1",
    # "color" : "purple",
    # "data" :[{ "x": 20, "y": 0.015, "time": "2009/07/12 12:34:56"},
    # { "x": 25, "y": 0.008, "time": "2009/07/12 12:34:56"},
    # { "x": 30, "y": 0.005, "time": "2009/07/12 12:34:56"}]
    # }
    all_series = []
    variables_to_graph.each_with_index do |var_to_graph, j|
      var_name = var_to_graph[0]
      freq = var_to_graph[1]
      kv = var_to_graph[2]

      runner.registerInfo("sqlcall: #{ann_env_pd},#{freq},#{var_name},#{kv}")
      # Get the y axis values
      y_timeseries = sql.timeSeries(ann_env_pd, freq, var_name, kv)
      if y_timeseries.empty?
        runner.registerWarning("No data found for '#{ann_env_pd}: #{freq}: #{var_name}: #{kv}'")
        next
      else
        y_timeseries = y_timeseries.get
      end
      y_vals = y_timeseries.values

      # Convert time stamp format to be more readable
      js_date_times = []
      y_timeseries.dateTimes.each do |date_time|
        js_date_times << to_JSTime(date_time)
      end

      # Store the timeseries data to hash for later
      # export to the HTML file
      series = {}
      series['name'] = kv.to_s
      series['type'] = var_name.to_s
      series['units'] = y_timeseries.units
      data = []
      for i in 0..(js_date_times.size - 1)
        point = {}
        point['y'] = y_vals[i].round(2)
        point['time'] = js_date_times[i]
        data << point
      end
      series['data'] = data
      all_series << series

      # increment color selection
      j += 1
    end

    # Convert all_series to JSON.
    # This JSON will be substituted
    # into the HTML file.
    require 'json'
    all_series = all_series.to_json

    # read in template
    html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.erb"
    html_in_path = if File.exist?(html_in_path)
                     html_in_path
                   else
                     "#{File.dirname(__FILE__)}/report.html.erb"
                   end
    html_in = ''
    File.open(html_in_path, 'r') do |file|
      html_in = file.read
    end

    # configure template with variable values
    renderer = ERB.new(html_in)
    html_out = renderer.result(binding)

    # write html file
    html_out_path = './report.html'
    File.open(html_out_path, 'w') do |file|
      file << html_out
      # make sure data is written to the disk one way or the other
      begin
        file.fsync
      rescue StandardError
        file.flush
      end
    end

    # close the sql file
    sql.close

    true
  end
end

# register the measure to be used by the application
TimeseriesPlot.new.registerWithApplication
