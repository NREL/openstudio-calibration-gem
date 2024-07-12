# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio-standards'

# start the measure
class InspectAndEditParametricSchedules < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Inspect and Edit Parametric Schedules'
  end

  # human readable description
  def description
    return 'This model will create arguments out of additional property inputs for parametric schedules in the model. You can use this just to inspect, or you can alter the inputs. It will not make parametric inputs for schedules that are not already setup as parametric. If you want to generate parametric schedules you can first run the Shift Hours of Operation Schedule with default 0 argument values for change in hours of operation.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This can be used in apply measure now, or can be used in a parametric workflow to load in any custom user profiles or floor/ceiling values.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # code to inspect formulas and code floor/ceiling values
    model.getScheduleRulesets.sort.each do |sch|
      # get ceiling and floor
      floor = sch.additionalProperties.getFeatureAsDouble('param_sch_floor')
      ceiling = sch.additionalProperties.getFeatureAsDouble('param_sch_ceiling')
      if floor.is_initialized || ceiling.is_initialized

        # argument for floor
        arg_name = "#{sch.name} Floor Value"
        floor_val = OpenStudio::Measure::OSArgument.makeDoubleArgument(arg_name.downcase.gsub(' ', '_'), true)
        floor_val.setDisplayName(arg_name)
        floor_val.setDescription('floor can be used by formulas')
        floor_val.setDefaultValue(floor.get)
        args << floor_val

        # argument for floor
        arg_name = "#{sch.name} Ceiling Value"
        ceiling_val = OpenStudio::Measure::OSArgument.makeDoubleArgument(arg_name.downcase.gsub(' ', '_'), true)
        ceiling_val.setDisplayName(arg_name)
        ceiling_val.setDescription('ceiling can be used by formulas')
        ceiling_val.setDefaultValue(ceiling.get)
        args << ceiling_val

      end

      # loop through rules
      sch_days = {}
      sch.scheduleRules.each do |rule|
        if rule.startDate.is_initialized
          start_date = "#{rule.startDate.get.monthOfYear.value}/#{rule.startDate.get.dayOfMonth}"
        else
          start_date = 'na'
        end
        if rule.startDate.is_initialized
          end_date = "#{rule.endDate.get.monthOfYear.value}/#{rule.endDate.get.dayOfMonth}"
        else
          end_date = 'na'
        end
        dow = []
        if rule.applyMonday then dow << 'mon' end
        if rule.applyTuesday then dow << 'tue' end
        if rule.applyWednesday then dow << 'wed' end
        if rule.applyThursday then dow << 'thur' end
        if rule.applyFriday then dow << 'fri' end
        if rule.applySaturday then dow << 'sat' end
        if rule.applySunday then dow << 'sun' end

        sch_days[rule.daySchedule] = "#{dow.inspect} from #{start_date} through #{end_date}"
      end

      # add default profile
      sch_days[sch.defaultDaySchedule] = 'default profile'

      # should appear in similar oder to GUI now with default on the bottom
      sch_days.each do |sch_day, description|
        prop = sch_day.additionalProperties.getFeatureAsString('param_day_profile')
        if prop.is_initialized

          # argument for formulas
          arg_name = "#{sch.name}_#{sch_day.name}"
          formula = OpenStudio::Measure::OSArgument.makeStringArgument(arg_name.downcase.gsub(' ', '_'), true)
          formula.setDisplayName(arg_name)
          formula.setDescription(description)
          formula.setDefaultValue(prop.to_s)
          args << formula
        end
      end
    end

    # merge internal loads
    apply_parametric_sch = OpenStudio::Measure::OSArgument.makeBoolArgument('apply_parametric_sch', true)
    apply_parametric_sch.setDisplayName('Apply Parametric Schedules to the Model')
    apply_parametric_sch.setDescription('When this is true the parametric schedules will be regenerated based on modified formulas, ceiling and floor values, and current horus of operation for building.')
    apply_parametric_sch.setDefaultValue(true)
    args << apply_parametric_sch

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)
    args = Hash[args.collect{ |k, v| [k.to_s, v] }]
    if !args then return false end
      
    # open channel to log messages
    reset_log

    # Turn debugging output on/off
    debug = false

    # load standards
    standard = Standard.build('90.1-2004') # selected template doesn't matter

    # change formulas, ceiling, adn floor values from arguments
    counter_parametric_schedules = []
    model.getScheduleRulesets.sort.each do |sch|
      # get ceiling and floor
      floor = sch.additionalProperties.getFeatureAsDouble('param_sch_floor')
      ceiling = sch.additionalProperties.getFeatureAsDouble('param_sch_ceiling')
      if floor.is_initialized || ceiling.is_initialized

        # argument for floor
        arg_name = "#{sch.name} Floor Value"
        sch.additionalProperties.setFeature('param_sch_floor', args[arg_name.downcase.gsub(' ', '_')])

        # argument for ceiling
        arg_name = "#{sch.name} Ceiling Value"
        sch.additionalProperties.setFeature('param_sch_ceiling', args[arg_name.downcase.gsub(' ', '_')])
      end

      # loop through rules
      sch_days = {}
      sch.scheduleRules.each do |rule|
        sch_days[rule.daySchedule] = nil
      end

      # add default profile
      sch_days[sch.defaultDaySchedule] = 'default profile'

      # should appear in similar oder to GUI now with default on the bottom
      sch_days.each do |sch_day, not_used|
        prop = sch_day.additionalProperties.getFeatureAsString('param_day_profile')
        if prop.is_initialized

          # argument for formulas
          arg_name = "#{sch.name}_#{sch_day.name}"
          sch_day.additionalProperties.setFeature('param_day_profile', args[arg_name.downcase.gsub(' ', '_')])

          # add to counter for initial condition
          counter_parametric_schedules << sch

        end
      end
    end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{counter_parametric_schedules.uniq.size.size} parametric schedules.")

    # if requested re-generate schedules
    if args['apply_parametric_sch']
      parametric_schedules = OpenstudioStandards::Schedules.model_apply_parametric_schedules(model, ramp_frequency: nil, infer_hoo_for_non_assigned_objects: true, error_on_out_of_order: true)
      runner.registerInfo("Applying #{parametric_schedules.size} parametric schedules.")
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{parametric_schedules.size} parametric schedules.")

    # gather log
    log_messages_to_runner(runner, debug)
    reset_log
    

    return true
  end
end

# register the measure to be used by the application
InspectAndEditParametricSchedules.new.registerWithApplication
