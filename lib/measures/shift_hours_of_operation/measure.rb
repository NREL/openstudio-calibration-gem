# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ShiftHoursOfOperation < OpenStudio::Measure::ModelMeasure
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
    return 'This will only impact schedule rulesets. It will impact the default profile, rules, and summer and winter design days. It will use methods in openstudio-standards to infer hours of operation, develop a parametric formula for all of the ruleset schedules, alter the hours of operation inputs to that formula and then re-apply the schedules. Input is expose to set ramp frequency of the resulting schedules. If inputs are such that no changes are requested, bypass the measure with NA so that it will not be parameterized. An advanced option for this measure would be bool to use hours of operation from OSM schedule ruleset hours of operation instead of inferring from standards. This should allow different parts of the building to have different hours of operation in the seed model.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # the name of the space to add to the model
    space_name = OpenStudio::Measure::OSArgument.makeStringArgument('space_name', true)
    space_name.setDisplayName('New space name')
    space_name.setDescription('This name will be used as the name of the new space.')
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

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getSpaces.size} spaces.")

    # add a new space to the model
    new_space = OpenStudio::Model::Space.new(model)
    new_space.setName(space_name)

    # echo the new space's name back to the user
    runner.registerInfo("Space #{new_space.name} was added.")

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")

    return true
  end
end

# register the measure to be used by the application
ShiftHoursOfOperation.new.registerWithApplication
