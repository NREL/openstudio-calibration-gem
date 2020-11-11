# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

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
    model.getScheduleRulesets.each do |sch|

      # get ceiling and floor
      floor = sch.additionalProperties.getFeatureAsDouble('param_sch_floor')
      ceiling = sch.additionalProperties.getFeatureAsDouble('param_sch_ceiling')
      if floor.is_initialized || ceiling.is_initialized
        puts "*** Formulas for #{sch.name}, floor: #{floor}, ceiling: #{ceiling}"
      end

      # loop through rules
      sch_days = {}
      sch.scheduleRules.reverse.each do |rule|
        if rule.startDate.is_initialized
          start_date = "#{rule.startDate.get.monthOfYear}/#{rule.startDate.get.dayOfMonth}"
        else
          start_date = "1/1"
        end
        if rule.startDate.is_initialized
          end_date = "#{rule.endDate.get.monthOfYear}/#{rule.endDate.get.dayOfMonth}"
        else
          end_date = "12/31"
        end
        dow = []
        if rule.applyMonday then dow << "mon" end
        if rule.applyTuesday then dow << "tue" end
        if rule.applyWednesday then dow << "wed" end
        if rule.applyThursday then dow << "thur" end
        if rule.applyFriday then dow << "fri" end
        if rule.applySaturday then dow << "sat" end
        if rule.applySunday then dow << "sun" end

        sch_days[rule.daySchedule] = "#{dow.inspect} from #{start_date} through #{end_date}"
      end

      # add default profile
      sch_days[sch.defaultDaySchedule] = "default profile"

      # should appear in similar oder to GUI now with default on the bottom
      sch_days.each do |sch_day,description|
        prop = sch_day.additionalProperties.getFeatureAsString('param_day_profile')
        if prop.is_initialized

          # the name of the space to add to the model
          arg_name = "#{sch.name}_#{sch_day.name}"
          formula = OpenStudio::Measure::OSArgument.makeStringArgument(arg_name.downcase.gsub(" ","_"), true)
          formula.setDisplayName(arg_name)
          # todo - add days of the week and date range, identify default as what it is
          formula.setDescription(description)
          formula.setDefaultValue(prop.to_s)
          args << formula

          puts prop
        end
      end
    end

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    #space_name = runner.getStringArgumentValue('space_name', user_arguments)

    # code to inspect formulas and code floor/ceiling values
    model.getScheduleRulesets.each do |sch|

      # get ceiling and floor
      floor = sch.additionalProperties.getFeatureAsDouble('param_sch_floor')
      ceiling = sch.additionalProperties.getFeatureAsDouble('param_sch_ceiling')
      if floor.is_initialized || ceiling.is_initialized
        puts "*** Formulas for #{sch.name}, floor: #{floor}, ceiling: #{ceiling}"
      end
      sch_days = [sch.defaultDaySchedule]
      sch.scheduleRules.each do |rule|
        sch_days << rule.daySchedule
      end
      sch_days.each do |sch_day|
        prop = sch_day.additionalProperties.getFeatureAsString('param_day_profile')
        if prop.is_initialized
          puts prop
        end
      end
    end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getSpaces.size} spaces.")

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")

    return true
  end
end

# register the measure to be used by the application
InspectAndEditParametricSchedules.new.registerWithApplication
