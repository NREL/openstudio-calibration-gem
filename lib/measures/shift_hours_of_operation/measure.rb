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

  # get model hoo info
  def hoo_summary(model,runner,standard)

    hoo_summary_hash = {}
    hoo_summary_hash[:zero_hoo] = []
    hoo_summary_hash[:final_hoo_start_range] = []
    hoo_summary_hash[:final_hoo_dur_range] = []
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
          hoo_summary_hash[:zero_hoo] << val[:hoo_hours]
        else
          hoo_summary_hash[:final_hoo_dur_range] << val[:hoo_hours]
          hoo_summary_hash[:final_hoo_start_range] << val[:hoo_start]
        end
      end
    end

    return hoo_summary_hash
  end

  # process hoo schedules for various days of the week
  # todo - when date range arg is used and not full year will never want to change default profile
  def process_hoo(used_hoo_sch_sets,model,runner,args,days_of_week,hoo_start_dows,hoo_dur_dows)

    # profiles added to this will be processed
    altered_schedule_days = {} # key is profile value is original index position defined in used_hoo_sch_sets

    # loop through horus of operation schedules
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

      orig_profile_indexes_used = hoo_sch.getActiveRuleIndices(year_start_date, year_end_date)
      orig_num_days_default_used = orig_profile_indexes_used.count(-1)
      if orig_num_days_default_used > 0
        default_prof = hoo_sch.defaultDaySchedule

        # clone default profile as rule that sits above it so it can be evauluated and used if needed
        new_prof = default_prof.clone(model).to_ScheduleDay.get
        new_rule = OpenStudio::Model::ScheduleRule.new(hoo_sch, new_prof)
        hoo_sch.setScheduleRuleIndex(new_rule, hoo_sch.scheduleRules.size - 1)

        # set days of week for clone to match days of week passed into the method
        if days_of_week.include?('mon')
          new_rule.setApplyMonday(true)
        end
        if days_of_week.include?('tue')
          new_rule.setApplyTuesday(true)
        end
        if days_of_week.include?('wed')
          new_rule.setApplyWednesday(true)
        end
        if days_of_week.include?('thur')
          new_rule.setApplyThursday(true)
        end
        if days_of_week.include?('fri')
          new_rule.setApplyFriday(true)
        end
        if days_of_week.include?('sat')
          new_rule.setApplySaturday(true)
        end
        if days_of_week.include?('sun')
          new_rule.setApplySunday(true)
        end

        # check if default days are used at all
        profile_indexes_used = hoo_sch.getActiveRuleIndices(year_start_date, year_end_date)
        num_days_new_profile_used = profile_indexes_used.count(hoo_sch.scheduleRules.size - 1)
        if ! profile_indexes_used.uniq.include?(-1) && num_days_new_profile_used > 0
          # don't need new profile, can use default
          new_rule.remove
          altered_schedule_days[hoo_sch.defaultDaySchedule] = -1
        elsif num_days_new_profile_used == 0.0
          # can remove cloned rule and skip the default profile (don't pass into array)
          new_rule.remove
        else
          altered_schedule_days[new_rule.daySchedule] = -1 # use hoo that was applicable to the default before it was cloned
        end
      end

      # use this to link to hoo from hours_of_operation_hash
      counter_of_orig_index = hoo_sch.scheduleRules.size - 1

      hoo_sch.scheduleRules.reverse.each do |rule|

        # inspect days of the week
        actual_days_of_week_for_profile = []
        if rule.applyMonday then actual_days_of_week_for_profile << 'mon' end
        if rule.applyTuesday then actual_days_of_week_for_profile << 'tue' end
        if rule.applyWednesday then actual_days_of_week_for_profile << 'wed' end
        if rule.applyThursday then actual_days_of_week_for_profile << 'thur' end
        if rule.applyFriday then actual_days_of_week_for_profile << 'fri' end
        if rule.applySaturday then actual_days_of_week_for_profile << 'sat' end
        if rule.applySunday then actual_days_of_week_for_profile << 'sun' end

        # if an exact match for the rules passed in are met, this rule can be edited in place (update later for date range)
        day_of_week_intersect = days_of_week & actual_days_of_week_for_profile
        current_rule_index = rule.ruleIndex
        if days_of_week == actual_days_of_week_for_profile
          altered_schedule_days[rule.daySchedule] = counter_of_orig_index

        # if this rule contains the requested days of the week and another then a clone should be made above this with only the requested days of the week that are also already on for this rule
        elsif day_of_week_intersect.size > 0

          # clone default profile as rule that sits above it so it can be evaluated and used if needed
          new_rule = rule.clone(model).to_ScheduleRule.get
          hoo_sch.setScheduleRuleIndex(new_rule, current_rule_index) # the cloned rule should be just above what was cloned

          # update days of week for rule
          if day_of_week_intersect.include?('mon')
            new_rule.setApplyMonday(true)
          else
            new_rule.setApplyMonday(false)
          end
          if day_of_week_intersect.include?('tue')
            new_rule.setApplyTuesday(true)
          else
            new_rule.setApplyTuesday(false)
          end
          if day_of_week_intersect.include?('wed')
            new_rule.setApplyWednesday(true)
          else
            new_rule.setApplyWednesday(false)
          end
          if day_of_week_intersect.include?('thur')
            new_rule.setApplyThursday(true)
          else
            new_rule.setApplyThursday(false)
          end
          if day_of_week_intersect.include?('fri')
            new_rule.setApplyFriday(true)
          else
            new_rule.setApplyFriday(false)
          end
          if day_of_week_intersect.include?('sat')
            new_rule.setApplySaturday(true)
          else
            new_rule.setApplySaturday(false)
          end
          if day_of_week_intersect.include?('sun')
            new_rule.setApplySunday(true)
          else
            new_rule.setApplySunday(false)
          end

          # add to array
          altered_schedule_days[new_rule.daySchedule] = counter_of_orig_index
        end

        # adjust the count used to find hoo from hours_of_operation_hash
        counter_of_orig_index -= 1

      end
      runner.registerInfo("For #{hoo_sch.name} #{days_of_week.inspect} #{altered_schedule_days.size} profiles will be processed.")

      # convert altered_schedule_days to hash where key is profile and value is key of index in hours_of_operation_hash

      # loop through profiles to changes
      altered_schedule_days.each do |new_profile,hoo_hash_index|

        # gather info and edit selected profile
        if args['delta_values']
          orig_hoo_start = hours_of_operation_hash[hoo_hash_index][:hoo_start]
          orig_hoo_dur = hours_of_operation_hash[hoo_hash_index][:hoo_hours]

          # check for duration grater than 224 or lower than 0
          max_dur_delta = 24 - orig_hoo_dur
          min_dur_delta = orig_hoo_dur * -1.0
          if hoo_dur_dows > max_dur_delta
            target_dur = 24.0
            runner.registerWarning("For profile in #{hoo_sch.name} duration is being capped at 24 hours.")
          elsif hoo_dur_dows < min_dur_delta
            target_dur = 0.0
            runner.registerWarning("For profile in #{hoo_sch.name} duration is being limited to a low of 0 hours.")
          else
            target_dur = hoo_dur_dows + orig_hoo_dur
          end

          # setup new hoo values with delta
          if orig_hoo_start + hoo_start_dows <= 24.0
            new_hoo_start = orig_hoo_start + hoo_start_dows
          else
            new_hoo_start = orig_hoo_start + hoo_start_dows - 24.0
          end
          if new_hoo_start + hoo_dur_dows + orig_hoo_dur <= 24.0
            new_hoo_end = new_hoo_start + target_dur
          else
            new_hoo_end = new_hoo_start + target_dur - 24.0
          end
        else
          new_hoo_start = hoo_start_dows
          if hoo_start_dows + hoo_dur_dows <= 24.0
            new_hoo_end = hoo_start_dows + hoo_dur_dows
          else
            new_hoo_end = hoo_start_dows + hoo_dur_dows - 24.0
          end
        end

        # setup hoo start time
        target_start_hr = new_hoo_start.truncate
        target_start_min = ((new_hoo_start - target_start_hr) * 60.0).truncate
        target_start_time = OpenStudio::Time.new(0, target_start_hr, target_start_min, 0)

        # setup hoo end time
        target_end_hr = new_hoo_end.truncate
        target_end_min = ((new_hoo_end - target_end_hr) * 60.0).truncate
        target_end_time = OpenStudio::Time.new(0, target_end_hr, target_end_min, 0)

        runner.registerInfo("inspecting profile values #{new_profile.values}")

        # adding new values
        # todo - update this to work when hoo is 0 or 24, which right now isn't perfect
        new_profile.clearValues
        new_profile.addValue(target_start_time,0)
        new_profile.addValue(target_end_time,1)
        os_time_24 = OpenStudio::Time.new(0, 24, 0, 0)
        if target_end_time > target_start_time
          new_profile.addValue(os_time_24,0)
        else
          new_profile.addValue(os_time_24,1)
        end
      end

    end

    return altered_schedule_days

  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args then return false end

    # check expected values of double arguments
    fraction = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, 'min' => 0.0, 'max' => 1.0, 'min_eq_bool' => true, 'max_eq_bool' => true, 'arg_array' => ['fraction_of_daily_occ_range'])

    neg_24__24 = ['hoo_start_weekday',
               'hoo_dur_weekday',
               'hoo_start_saturday',
               'hoo_dur_saturday',
               'hoo_start_sunday',
               'hoo_dur_sunday']
    time_hours = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, 'min' => -24.0, 'max' => 24.0, 'min_eq_bool' => true, 'max_eq_bool' => true, 'arg_array' => neg_24__24)

    # load standards
    standard = Standard.build('90.1-2004') # selected template doesn't matter

    if args['infer_parametric_schedules']
      # infer hours of operation for the building
      # @param fraction_of_daily_occ_range [Double] fraction above/below daily min range required to start and end hours of operation
      occ_fraction = args['fraction_of_daily_occ_range']
      standard.model_infer_hours_of_operation_building(model,fraction_of_daily_occ_range: occ_fraction,gen_occ_profile: true)
      runner.registerInfo("Inferring initial hours of operation for the building and generating parametric profile formulas.")

      # report back hours of operation
      initial_hoo_range = []
      hours_of_operation_hash_test = standard.space_hours_of_operation(model.getSpaces.first)
      hours_of_operation_hash_test.each do |hoo_key,val|
        initial_hoo_range << val[:hoo_hours]
        runner.registerInfo("For Profile Index #{hoo_key} hours of operation run for #{val[:hoo_hours]} hours, from #{val[:hoo_start]} to #{val[:hoo_end]} and is used for #{val[:days_used].size} days of the year.")
      end

      # model_setup_parametric_schedules
      # todo - there should be arg here that can have formula based on fraction of day and no hours is argument to gather_inputs_parametric_schedules method. need to update high level methods in standards to support input for this
      standard.model_setup_parametric_schedules(model,gather_data_only: false)
    end

    # report final condition of model
    hoo_summary_hash = hoo_summary(model,runner,standard)
    if hoo_summary_hash[:zero_hoo].size > 0
      runner.registerInitialCondition("Across the building the non-zero hours of operation range from #{hoo_summary_hash[:final_hoo_dur_range].min} hours to #{hoo_summary_hash[:final_hoo_dur_range].max} hours. Start of hours of operation range from #{hoo_summary_hash[:final_hoo_start_range].min} to #{hoo_summary_hash[:final_hoo_start_range].max}. One or more hours of operation schedules used contain a profile with 0 hours of operation.")
    else
      runner.registerInitialCondition("Across the building the hours of operation range from #{hoo_summary_hash[:final_hoo_dur_range].min} hours to #{hoo_summary_hash[:final_hoo_dur_range].max} hours. Start of hours of operation range from #{hoo_summary_hash[:final_hoo_start_range].min} to #{hoo_summary_hash[:final_hoo_start_range].max}.")
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

    # process weekday profiles
    runner.registerInfo("Altering hours of operation schedules for weekday profiles")
    weekday = process_hoo(used_hoo_sch_sets,model,runner,args,['mon','tue','wed','thur','fri'],args['hoo_start_weekday'],args['hoo_dur_weekday'])

    # process saturday profiles
    runner.registerInfo("Altering hours of operation schedules for saturday profiles")
    saturday = process_hoo(used_hoo_sch_sets,model,runner,args,['sat'],args['hoo_start_saturday'],args['hoo_dur_saturday'])

    # process sunday profiles
    runner.registerInfo("Altering hours of operation schedules for sunday profiles")
    sunday = process_hoo(used_hoo_sch_sets,model,runner,args,['sun'],args['hoo_start_sunday'],args['hoo_dur_sunday'])

    # todo - need to address this error when manipulating schedules
    # [openstudio.standards.ScheduleRuleset] <1> Pre-interpolated processed hash for Large Office Bldg Equip Default Schedule has one or more out of order conflicts: [[3.5, 0.8], [4.5, 0.6], [5.0, 0.6], [7.0, 0.5], [9.0, 0.4], [6.0, 0.4], [10.0, 0.9], [16.5, 0.9], [17.5, 0.8], [18.5, 0.9], [21.5, 0.9]]. Method will stop because Error on Out of Order was set to true.
    # model_build_parametric_schedules
    parametric_schedules = standard.model_apply_parametric_schedules(model, ramp_frequency: nil, infer_hoo_for_non_assigned_objects: true, error_on_out_of_order: true)
    runner.registerInfo("Created #{parametric_schedules.size} parametric schedules.")

    # report final condition of model
    hoo_summary_hash = hoo_summary(model,runner,standard)
    if hoo_summary_hash[:zero_hoo].size > 0
      runner.registerFinalCondition("Across the building the non-zero hours of operation range from #{hoo_summary_hash[:final_hoo_dur_range].min} hours to #{hoo_summary_hash[:final_hoo_dur_range].max} hours. Start of hours of operation range from #{hoo_summary_hash[:final_hoo_start_range].min} to #{hoo_summary_hash[:final_hoo_start_range].max}. One or more hours of operation schedules used contain a profile with 0 hours of operation.")
    else
      runner.registerFinalCondition("Across the building the hours of operation range from #{hoo_summary_hash[:final_hoo_dur_range].min} hours to #{hoo_summary_hash[:final_hoo_dur_range].max} hours. Start of hours of operation range from #{hoo_summary_hash[:final_hoo_start_range].min} to #{hoo_summary_hash[:final_hoo_start_range].max}.")
    end

    # todo - adding hours of operation to a schedule that doesn't have them to start with, like a sunday, can be problematic
    # todo - start of day may not be reliable and there may not be formula inputs to show what occupied behavior is
    # todo - in a situation like that it could be good to get formula from day that was non-zero to start with like weekday or saturday.
    # todo - maybe standards can do something like this when making the formulas in the first place.

    return true
  end
end

# register the measure to be used by the application
ShiftHoursOfOperation.new.registerWithApplication
