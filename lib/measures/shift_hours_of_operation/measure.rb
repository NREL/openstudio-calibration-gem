# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio-standards'

# load OpenStudio measure libraries from openstudio-extension gem
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_helper_methods'

# start the measure
class ShiftHoursOfOperation < OpenStudio::Measure::ModelMeasure

  # resource file modules
  include OsLib_HelperMethods

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Shift Hours of Operation'
  end

  # human readable description
  def description
    return 'This measure will infer the hours of operation for the building and then will shift the start of the hours of operation and change the duration of the hours of operation. In an alternate workflow you can directly pass in target start and duration rather than a shift and delta. Inputs can vary for weekday, Saturday, and Sunday. '
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This will only impact schedule rulesets. It will use methods in openstudio-standards to infer hours of operation, develop a parametric formula for all of the ruleset schedules, alter the hours of operation inputs to that formula and then re-apply the schedules. Input is expose to set ramp frequency of the resulting schedules. If inputs are such that no changes are requested, bypass the measure with NA so that it will not be parameterized. An advanced option for this measure would be bool to use hours of operation from OSM schedule ruleset hours of operation instead of inferring from standards. This should allow different parts of the building to have different hours of operation in the seed model.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # delta hoo_start for weekdays
    hoo_start_weekday = OpenStudio::Measure::OSArgument.makeDoubleArgument('hoo_start_weekday', true)
    hoo_start_weekday.setDisplayName('Shift the weekday start of hours of operation.')
    hoo_start_weekday.setDescription('Use decimal hours so an 1 hour and 15 minute shift would be 1.25. Positive value moves the hour of operation later')
    hoo_start_weekday.setDefaultValue(0.0)
    hoo_start_weekday.setUnits('Hours')
    args << hoo_start_weekday

    # delta hoo_dur for weekday
    hoo_dur_weekday = OpenStudio::Measure::OSArgument.makeDoubleArgument('hoo_dur_weekday', true)
    hoo_dur_weekday.setDisplayName('Extend the weekday of hours of operation.')
    hoo_dur_weekday.setDescription('Use decimal hours so an 1 hour and 15 minute would be 1.25. Positive value makes the hour of operation longer.')
    hoo_dur_weekday .setDefaultValue(0.0)
    hoo_dur_weekday.setUnits('Hours')
    args << hoo_dur_weekday

    # todo - could include every day of the week

    # delta hoo_start for saturdays
    hoo_start_saturday = OpenStudio::Measure::OSArgument.makeDoubleArgument('hoo_start_saturday', true)
    hoo_start_saturday.setDisplayName('Shift the saturday start of hours of operation.')
    hoo_start_saturday.setDescription('Use decimal hours so an 1 hour and 15 minute shift would be 1.25. Positive value moves the hour of operation later')
    hoo_start_saturday.setDefaultValue(0.0)
    hoo_start_saturday.setUnits('Hours')
    args << hoo_start_saturday

    # delta hoo_dur for saturday
    hoo_dur_saturday = OpenStudio::Measure::OSArgument.makeDoubleArgument('hoo_dur_saturday', true)
    hoo_dur_saturday.setDisplayName('Extend the saturday of hours of operation.')
    hoo_dur_saturday.setDescription('Use decimal hours so an 1 hour and 15 minute would be 1.25. Positive value makes the hour of operation longer.')
    hoo_dur_saturday.setDefaultValue(0.0)
    hoo_dur_saturday.setUnits('Hours')
    args << hoo_dur_saturday

    # delta hoo_start for sundays
    hoo_start_sunday = OpenStudio::Measure::OSArgument.makeDoubleArgument('hoo_start_sunday', true)
    hoo_start_sunday.setDisplayName('Shift the sunday start of hours of operation.')
    hoo_start_sunday.setDescription('Use decimal hours so an 1 hour and 15 minute shift would be 1.25. Positive value moves the hour of operation later')
    hoo_start_sunday.setDefaultValue(0.0)
    hoo_start_sunday.setUnits('Hours')
    args << hoo_start_sunday

    # delta hoo_dur for sunday
    hoo_dur_sunday = OpenStudio::Measure::OSArgument.makeDoubleArgument('hoo_dur_sunday', true)
    hoo_dur_sunday.setDisplayName('Extend the sunday of hours of operation.')
    hoo_dur_sunday.setDescription('Use decimal hours so an 1 hour and 15 minute would be 1.25. Positive value makes the hour of operation longer.')
    hoo_dur_sunday.setDefaultValue(0.0)
    hoo_dur_sunday.setUnits('Hours')
    args << hoo_dur_sunday

    # todo - could include start and end days to have delta or absolute values applied to.

    # make an argument for delta_values
    delta_values = OpenStudio::Measure::OSArgument.makeBoolArgument('delta_values', true)
    delta_values.setDisplayName('Hours of operation values treated as deltas')
    delta_values.setDescription('When this is true the hours of operation start and duration represent a delta from the original model values. When switched to false they represent absolute values.')
    delta_values.setDefaultValue(true)
    args << delta_values

    # make an argument for target_hoo_from_model
    target_hoo_from_model = OpenStudio::Measure::OSArgument.makeBoolArgument('target_hoo_from_model', true) 
    target_hoo_from_model.setDisplayName('Use model hours of operation as target')
    target_hoo_from_model.setDescription('The default behavior is for this to be false. When changed to true all of the hours of operation start and duration values will be ignored as the bool to treat those values as relative or absolue. Instead the hours of operation schedules for the model will be used.')
    target_hoo_from_model.setDefaultValue(false)
    args << target_hoo_from_model

=begin
    # make an argument for infer_hoo
    # todo - need to confirm I can create formulas when whole building doesn't have the same hours of operation
    infer_hoo = OpenStudio::Measure::OSArgument.makeBoolArgument('infer_hoo', true) 
    infer_hoo.setDisplayName('Infer hours of operation')
    infer_hoo.setDescription('When true this will evaluate the occupancy for the building to infer a whole building horus of operation for different days of the week and different times of the year. When set to false this will use the hours of operation default schedule set for each part of the building as the starting hours of operation to alter. The measure will fail if set to value and valid hours of operation schedules are not setup.')
    infer_hoo.setDefaultValue(true)
    args << infer_hoo
=end

    # make an argument for infer_parametric_schedules
    infer_parametric_schedules = OpenStudio::Measure::OSArgument.makeBoolArgument('infer_parametric_schedules', true)
    infer_parametric_schedules.setDisplayName('Use parametric schedule formaulas already stored in the model.')
    infer_parametric_schedules.setDescription('When this is true the parametric schedule formulas will be generated from the existing model schedules. When false it expects the model already has parametric formulas stored.')
    infer_parametric_schedules.setDefaultValue(true)
    args << infer_parametric_schedules

    # todo - add argument for fraction_of_daily_occ_range

    # todo - add argument for step frequency, which is hours per step (should be fractional 1 or less generally)

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args then return false end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getSpaces.size} spaces.")

    # load standards
    standard = Standard.build('90.1-2004') # selected template doesn't matter

    # infer hours of operation for the building
    # @param fraction_of_daily_occ_range [Double] fraction above/below daily min range required to start and end hours of operation
    hours_of_operation = standard.model_infer_hours_of_operation_building(model,fraction_of_daily_occ_range: 0.25,gen_occ_profile: true, gen_occ_profile: true)
    puts hours_of_operation

    # report back hours of operation
    hours_of_operation_hash = standard.space_hours_of_operation(model.getSpaces.first)
    puts "hours of operation: #{hours_of_operation_hash.keys.first}: #{hours_of_operation_hash.values.inspect}"

    # model_setup_parametric_schedules
    parametric_inputs = standard.model_setup_parametric_schedules(model,gather_data_only: false)
    puts "parametric inputs: #{parametric_inputs.keys.first.name}: #{parametric_inputs.values.first.inspect}"

    # todo - alter hours of operate per measure arguments
    # (instead of trying to dynamically change hoo ask values, create new hoo values, reset schedule, add in new values)

    # model_build_parametric_schedules
    # todo - add argument for step frequency
    parametric_schedules = standard.model_apply_parametric_schedules(model)
    puts "created #{parametric_schedules.size} parametric schedules"

    # temp code to inspect formulas
    # todo - make schedule with this in args where it is editable (like a GUI) filter for schedules that are used so not so many arguments, maybe crazy with some many schedules and rules
    model.getScheduleRulesets.each do |sch|
      puts "*** Formulas for #{sch.name}"
      # todo - checking if schedule is used is good, but also need to add thermostats to the model
      sch_days = [sch.defaultDaySchedule]
      sch.scheduleRules.each do |rule|
        sch_days << rule.daySchedule
      end
      sch_days.each do |sch_day|
        prop = sch_day.additionalProperties.getFeatureAsString('param_day_profile')
        puts prop
      end
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")

    return true
  end
end

# register the measure to be used by the application
ShiftHoursOfOperation.new.registerWithApplication
