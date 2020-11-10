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

    # the name of the space to add to the model
    space_name = OpenStudio::Measure::OSArgument.makeStringArgument('space_name', true)
    space_name.setDisplayName('New space name')
    space_name.setDescription('This name will be used as the name of the new space.')
    space_name.setDefaultValue("just a test")
    args << space_name

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
    space_name = runner.getStringArgumentValue('space_name', user_arguments)

    # check the space_name for reasonableness
    if space_name.empty?
      runner.registerError('Empty space name was entered.')
      return false
    end

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
