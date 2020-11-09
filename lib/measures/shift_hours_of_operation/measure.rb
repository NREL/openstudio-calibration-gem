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

    # todo - could include start and end days to have delta or absolute values applied to. (maybe decimal between 1.0 and 13.0 month where 3.50 would be March 15th)

    # make an argument for delta_values
    delta_values = OpenStudio::Measure::OSArgument.makeBoolArgument('delta_values', true)
    delta_values.setDisplayName('Hours of operation values treated as deltas')
    delta_values.setDescription('When this is true the hours of operation start and duration represent a delta from the original model values. When switched to false they represent absolute values.')
    delta_values.setDefaultValue(true)
    args << delta_values

    # make an argument for infer_parametric_schedules
    infer_parametric_schedules = OpenStudio::Measure::OSArgument.makeBoolArgument('infer_parametric_schedules', true)
    infer_parametric_schedules.setDisplayName('Dynamically generate parametric schedules from current ruleset schedules.')
    infer_parametric_schedules.setDescription('When this is true the parametric schedule formulas and hours of operation will be generated from the existing model schedules. When false it expects the model already has parametric formulas stored.')
    infer_parametric_schedules.setDefaultValue(true)
    args << infer_parametric_schedules

    # delta hoo_start for sundays
    fraction_of_daily_occ_range = OpenStudio::Measure::OSArgument.makeDoubleArgument('fraction_of_daily_occ_range', true)
    fraction_of_daily_occ_range.setDisplayName('Fraction of Daily Occupancy Range.')
    fraction_of_daily_occ_range.setDescription('This determine what fraction of occupancy be considered operating conditions. This fraction is normalized to expanded to range seen over the full year and does not necessary equal fraction of design occupancy. This value should be between 0 and 1.0 and is only used if dynamically generated parametric schedules are used.')
    fraction_of_daily_occ_range.setDefaultValue(0.25)
    fraction_of_daily_occ_range.setUnits('Hours')
    args << fraction_of_daily_occ_range

    # make an argument for target_hoo_from_model
    # Should only be true when infer_parametric_schedules is false
    target_hoo_from_model = OpenStudio::Measure::OSArgument.makeBoolArgument('target_hoo_from_model', true)
    target_hoo_from_model.setDisplayName('Use model hours of operation as target')
    target_hoo_from_model.setDescription('The default behavior is for this to be false. This can not be used unless Dynamically generate parametric schedules from current ruleset schedules is set to false and if the schedules in the model already have parametric profiles. When changed to true all of the hours of operation start and duration values will be ignored as the bool to treat those values as relative or absolute. Instead the hours of operation schedules for the model will be used.')
    target_hoo_from_model.setDefaultValue(false)
    args << target_hoo_from_model

    # todo - add argument for step frequency, which is hours per step (should be fractional 1 or less generally).
    # For now it defaults to simulation timestep

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args then return false end

    # todo - add in error checking for arguments

    # load standards
    standard = Standard.build('90.1-2004') # selected template doesn't matter

    if args['infer_parametric_schedules']
      # infer hours of operation for the building
      # @param fraction_of_daily_occ_range [Double] fraction above/below daily min range required to start and end hours of operation
      occ_fraction = args['fraction_of_daily_occ_range']
      hours_of_operation = standard.model_infer_hours_of_operation_building(model,fraction_of_daily_occ_range: occ_fraction,gen_occ_profile: true)
      runner.registerInfo("Inferring initial hours of operation for the building and generating parametric profile formulas.")

      # report back hours of operation
      initial_hoo_range = []
      hours_of_operation_hash_test = standard.space_hours_of_operation(model.getSpaces.first)
      hours_of_operation_hash_test.each do |hoo_key,val|
        initial_hoo_range << val[:hoo_hours]
        runner.registerInfo("For Profile Index #{hoo_key} hours of operation run for #{val[:hoo_hours]} hours, from #{val[:hoo_start]} to #{val[:hoo_end]} and is used for #{val[:days_used].size} days of the year.")
      end

      # model_setup_parametric_schedules
      parametric_inputs = standard.model_setup_parametric_schedules(model,gather_data_only: false)

      # report initial condition of model
      runner.registerInitialCondition("Initial inferred hours of operation for the building range from #{initial_hoo_range.min} to #{initial_hoo_range.max} hours a day. Setup formulas for #{parametric_inputs.size} parametric schedules")

    else
      # report initial condition of model
      runner.registerInitialCondition("Parametric schedules and hours of operation scheules were not gnerated by this measure.")
    end

    # gather hours of operation schedules used by this model
    used_hoo_sch_sets = {}
    model.getSpaces.sort.each do |space|
      default_sch_type = OpenStudio::Model::DefaultScheduleType.new('HoursofOperationSchedule')
      hours_of_operation = space.getDefaultSchedule(default_sch_type)
      if !hours_of_operation.is_initialized
        runner.registerWarning("Hours of Operation Schedule is not set for #{space.name}.")
        next
      end
      hours_of_operation_hash = standard.space_hours_of_operation(space)
      used_hoo_sch_sets[hours_of_operation.get] = hours_of_operation_hash
    end

    # loop through and alter hours of operation schedules
    runner.registerInfo("There are #{used_hoo_sch_sets.uniq.size} hours of operation schedules in the model to alter.")
    used_hoo_sch_sets.uniq.each do |hoo_sch,hours_of_operation_hash|
      if ! hoo_sch.to_ScheduleRuleset.is_initialized
        runner.registerWarning("#{hoo_sch.name} is not schedule schedule ruleset, will not be altered by this method.")
        next
      end
      hoo_sch = hoo_sch.to_ScheduleRuleset.get

      year_description = hoo_sch.model.yearDescription.get
      year = year_description.assumedYear
      year_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('January'), 1, year)
      year_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('December'), 31, year)

      # todo -  determine if default profile is all weekday, all sat, all sun, or a mix. If it is a mix need to make new rules above it (may need to make method to get days of week)
      default_prof = hoo_sch.defaultDaySchedule
      new_weekday_prof = default_prof.clone(model).to_ScheduleDay.get
      new_weekday_rule = OpenStudio::Model::ScheduleRule.new(hoo_sch, new_weekday_prof)

      hoo_sch.setScheduleRuleIndex(new_weekday_rule, hoo_sch.scheduleRules.size - 1)
      new_weekday_rule.setApplyMonday(true)
      new_weekday_rule.setApplyTuesday(true)
      new_weekday_rule.setApplyWednesday(true)
      new_weekday_rule.setApplyThursday(true)
      new_weekday_rule.setApplyFriday(true)

      # check if default days are used at all
      profile_indexes_used = hoo_sch.getActiveRuleIndices(year_start_date, year_end_date).uniq
      if ! profile_indexes_used.include?(-1)
        # don't need new profile, can use default
        new_weekday_rule.remove
        new_weekday_rule = hoo_sch.defaultDaySchedule
      end

      # todo - add in code ot check for requested duration bigger than 24 hours and lock it at 24.

      # gather info and edit selected profile
      if args['delta_values']
        orig_hoo_start = hours_of_operation_hash[-1][:hoo_start]
        orig_hoo_dur = hours_of_operation_hash[-1][:hoo_hours]
        if orig_hoo_start + args['hoo_start_weekday'] <= 24.0
          new_hoo_start = orig_hoo_start + args['hoo_start_weekday']
        else
          new_hoo_start = orig_hoo_start + args['hoo_start_weekday'] - 24.0
        end
        if new_hoo_start + args['hoo_dur_weekday'] + orig_hoo_dur <= 24.0
          new_hoo_end = new_hoo_start + args['hoo_dur_weekday'] + orig_hoo_dur
        else
          new_hoo_end = new_hoo_start + args['hoo_dur_weekday'] + orig_hoo_dur - 24.0
        end
      else
        new_hoo_start = args ['hoo_start_weekday']
        if args['hoo_start_weekday'] + args['hoo_dur_weekday'] <= 24.0
          new_hoo_end = args['hoo_start_weekday'] + args['hoo_dur_weekday']
        else
          new_hoo_end = args['hoo_start_weekday'] + args['hoo_dur_weekday'] - 24.0
        end
      end

      # todo - create method so this code can be used for sat and sun not just weekday,
      # todo - when date range arg is used and not full year will never want to change default profile
      # todo - any other rules that are mixed should be spilt, keep stacking order with new ones right above instead of at the top of all rules.
      #
      # setup hoo start time
      target_start_hr = new_hoo_start.truncate
      target_start_min = ((new_hoo_start - target_start_hr) * 60.0).truncate
      target_start_time = OpenStudio::Time.new(0, target_start_hr, target_start_min, 0)

      # setup hoo end time
      target_end_hr = new_hoo_end.truncate
      target_end_min = ((new_hoo_end - target_end_hr) * 60.0).truncate
      target_end_time = OpenStudio::Time.new(0, target_end_hr, target_end_min, 0)

      # adding new values
      new_weekday_rule.clearValues
      new_weekday_rule.addValue(target_start_time,0)
      new_weekday_rule.addValue(target_end_time,1)
      os_time_24 = OpenStudio::Time.new(0, 24, 0, 0)
      if target_end_time > target_start_time
        new_weekday_rule.addValue(os_time_24,0)
      else
        new_weekday_rule.addValue(os_time_24,1)
      end
    end

    # todo - adding hours of operation to a schedule that doesn't have them to start with, like a sunday, can be problematic
    # todo - start of day may not be reliable and there may not be formula inputs to show what occupied behavior is
    # todo - in a situation like that it could be good to get formula from day that was non-zero to start with like weekday or saturday.
    # todo - maybe standards can do something like this when making the formulas in the first place.
    # model_build_parametric_schedules
    parametric_schedules = standard.model_apply_parametric_schedules(model)
    runner.registerInfo("Created #{parametric_schedules.size} parametric schedules.")

=begin
    # todo - remove temp code that inspects formulas
    model.getScheduleRulesets.each do |sch|

      # get ceiling and floor
      floor = sch.additionalProperties.getFeatureAsDouble('param_sch_floor')
      ceiling = sch.additionalProperties.getFeatureAsDouble('param_sch_ceiling')
      puts "*** Formulas for #{sch.name}, floor: #{floor}, ceiling: #{ceiling}"

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
=end

    # todo - make a method for this
    # list zero separate from min-max range
    zero_hoo = []
    final_hoo_start_range = []
    final_hoo_end_range = []
    final_hoo_dur_range = []
    model.getSpaces.sort.each do |space|
      default_sch_type = OpenStudio::Model::DefaultScheduleType.new('HoursofOperationSchedule')
      hours_of_operation = space.getDefaultSchedule(default_sch_type)
      if !hours_of_operation.is_initialized
        runner.registerWarning("Hours of Operation Schedule is not set for #{space.name}.")
        next
      end
      hours_of_operation_hash = standard.space_hours_of_operation(space)
      hours_of_operation_hash.each do |hoo_key,val|
        if val[:hoo_hours] == 0.0
          zero_hoo << val[:hoo_hours]
        else
          final_hoo_dur_range << val[:hoo_hours]
          final_hoo_start_range << val[:hoo_start]
        end
      end
    end

    # report final condition of model
    if zero_hoo.size > 0
      runner.registerFinalCondition("Across the building the non-zero hours of operation range from #{final_hoo_dur_range.min} hours to #{final_hoo_dur_range.max} hours. Start of hours of operation range from #{final_hoo_start_range.min} to #{final_hoo_start_range.max}. One or more hours of operation schedules used contain a profile with 0 hours of operation.")
    else
      runner.registerFinalCondition("Across the building the hours of operation range from #{final_hoo_dur_range.min} hours to #{final_hoo_dur_range.max} hours. Start of hours of operation range from #{final_hoo_start_range.min} to #{final_hoo_start_range.max}.")
    end

    return true
  end
end

# register the measure to be used by the application
ShiftHoursOfOperation.new.registerWithApplication
