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

    # delta hoo_start for weekdays
    hoo_start_weekday = OpenStudio::Measure::OSArgument.makeDoubleArgument('hoo_start_weekday', true)
    hoo_start_weekday.setDisplayName('Shift the weekday start of hours of operation.')
    hoo_start_weekday.setDescription('Use decimal hours so an 1 hour and 15 minute shift would be 1.25. Positive value moves the hour of operation later')
    hoo_start_weekday.setUnits('Hours')
    args << hoo_start_weekday

    # delta hoo_dur for weekday
    hoo_dur_weekday = OpenStudio::Measure::OSArgument.makeDoubleArgument('hoo_dur_weekday', true)
    hoo_dur_weekday.setDisplayName('Extend the weekday of hours of operation.')
    hoo_dur_weekday.setDescription('Use decimal hours so an 1 hour and 15 minute would be 1.25. Positive value makes the hour of operation longer.')
    hoo_dur_weekday.setUnits('Hours')
    args << hoo_dur_weekday

    # todo - could include every day of the week

    # delta hoo_start for saturdays
    hoo_start_saturday = OpenStudio::Measure::OSArgument.makeDoubleArgument('hoo_start_saturday', true)
    hoo_start_saturday.setDisplayName('Shift the saturday start of hours of operation.')
    hoo_start_saturday.setDescription('Use decimal hours so an 1 hour and 15 minute shift would be 1.25. Positive value moves the hour of operation later')
    hoo_start_saturday.setUnits('Hours')
    args << hoo_start_saturday

    # delta hoo_dur for saturday
    hoo_dur_saturday = OpenStudio::Measure::OSArgument.makeDoubleArgument('hoo_dur_saturday', true)
    hoo_dur_saturday.setDisplayName('Extend the saturday of hours of operation.')
    hoo_dur_saturday.setDescription('Use decimal hours so an 1 hour and 15 minute would be 1.25. Positive value makes the hour of operation longer.')
    hoo_dur_saturday.setUnits('Hours')
    args << hoo_dur_saturday

    # delta hoo_start for sundays
    hoo_start_sunday = OpenStudio::Measure::OSArgument.makeDoubleArgument('hoo_start_sunday', true)
    hoo_start_sunday.setDisplayName('Shift the sunday start of hours of operation.')
    hoo_start_sunday.setDescription('Use decimal hours so an 1 hour and 15 minute shift would be 1.25. Positive value moves the hour of operation later')
    hoo_start_sunday.setUnits('Hours')
    args << hoo_start_sunday

    # delta hoo_dur for sunday
    hoo_dur_sunday = OpenStudio::Measure::OSArgument.makeDoubleArgument('hoo_dur_sunday', true)
    hoo_dur_sunday.setDisplayName('Extend the sunday of hours of operation.')
    hoo_dur_sunday.setDescription('Use decimal hours so an 1 hour and 15 minute would be 1.25. Positive value makes the hour of operation longer.')
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
