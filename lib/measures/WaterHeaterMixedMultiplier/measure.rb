# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# start the measure
class WaterHeaterMixedMultiplier < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    'Water Heater Mixed Multiplier'
  end

  # human readable description
  def description
    'This is a general purpose measure to calibrate WaterHeaterMixed with a Multiplier.'
  end

  # human readable description of modeling approach
  def modeler_description
    'It will be used for calibration of WaterHeaterMixed. User can choose between a SINGLE WaterHeaterMixed or ALL the WaterHeaterMixed objects.'
  end

  def change_name(object, maximum_capacity_multiplier, minimum_capacity_multiplier, thermal_efficiency_multiplier, fuel_type, orig_fuel_type)
    nameString = object.name.get.to_s
    if maximum_capacity_multiplier != 1.0
      nameString += " #{maximum_capacity_multiplier.round(2)}x maxCap"
    end
    if minimum_capacity_multiplier != 1.0
      nameString += " #{minimum_capacity_multiplier.round(2)}x minCap"
    end
    if thermal_efficiency_multiplier != 1.0
      nameString += " #{thermal_efficiency_multiplier.round(2)}x thermEff"
    end
    nameString += " #{fuel_type} fuel Change" if orig_fuel_type != fuel_type
    object.setName(nameString)
  end

  def check_multiplier(runner, multiplier)
    if multiplier < 0
      runner.registerError("Multiplier #{multiplier} cannot be negative.")
      false
    end
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a choice argument for model objects
    water_heater_handles = OpenStudio::StringVector.new
    water_heater_display_names = OpenStudio::StringVector.new

    # putting model object and names into hash
    water_heater_args = model.getWaterHeaterMixeds
    water_heater_args.each do |water_heater_arg|
      water_heater_handles << water_heater_arg.handle.to_s
      water_heater_display_names << water_heater_arg.name.to_s
    end

    # add building to string vector with space type
    building = model.getBuilding
    water_heater_handles << building.handle.to_s
    water_heater_display_names << '*All WaterHeaterMixeds*'
    water_heater_handles << '0'
    water_heater_display_names << '*None*'

    # make a choice argument for space type
    water_heater = OpenStudio::Measure::OSArgument.makeChoiceArgument('water_heater', water_heater_handles, water_heater_display_names)
    water_heater.setDisplayName('Apply the Measure to a SINGLE WaterHeaterMixed, ALL the WaterHeaterMixeds or NONE.')
    water_heater.setDefaultValue('*All WaterHeaterMixeds*') # if no space type is chosen this will run on the entire building
    args << water_heater

    # maximum_capacity_multiplier
    maximum_capacity_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('maximum_capacity_multiplier', true)
    maximum_capacity_multiplier.setDisplayName('Multiplier for Heater Maximum Capacity.')
    maximum_capacity_multiplier.setDescription('Multiplier for Heater Maximum Capacity.')
    maximum_capacity_multiplier.setDefaultValue(1.0)
    maximum_capacity_multiplier.setMinValue(0.0)
    args << maximum_capacity_multiplier

    # minimum_capacity_multiplier
    minimum_capacity_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('minimum_capacity_multiplier', true)
    minimum_capacity_multiplier.setDisplayName('Multiplier for Heater Minimum Capacity.')
    minimum_capacity_multiplier.setDescription('Multiplier for Heater Minimum Capacity.')
    minimum_capacity_multiplier.setDefaultValue(1.0)
    args << minimum_capacity_multiplier

    # thermal_efficiency_multiplier
    thermal_efficiency_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('thermal_efficiency_multiplier', true)
    thermal_efficiency_multiplier.setDisplayName('Multiplier for Thermal Efficiency.')
    thermal_efficiency_multiplier.setDescription('Multiplier for Thermal Efficiency.')
    thermal_efficiency_multiplier.setDefaultValue(1.0)
    args << thermal_efficiency_multiplier

    # make a choice argument for fuel type
    fuel_type = OpenStudio::StringVector.new
    fuel_type << 'NaturalGas'
    fuel_type << 'Electricity'
    fuel_type << 'PropaneGas'

    # heater_fuel_type
    heater_fuel_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('fuel_type', fuel_type, fuel_type)
    heater_fuel_type.setDisplayName('Heater Fuel Type.')
    heater_fuel_type.setDescription('Heater Fuel Type.')
    heater_fuel_type.setDefaultValue('NaturalGas')
    args << heater_fuel_type

    args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    unless runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    water_heater_object = runner.getOptionalWorkspaceObjectChoiceValue('water_heater', user_arguments, model)
    water_heater_handle = runner.getStringArgumentValue('water_heater', user_arguments)
    fuel_type = runner.getStringArgumentValue('fuel_type', user_arguments)
    thermal_efficiency_multiplier = runner.getDoubleArgumentValue('thermal_efficiency_multiplier', user_arguments)
    check_multiplier(runner, thermal_efficiency_multiplier)
    maximum_capacity_multiplier = runner.getDoubleArgumentValue('maximum_capacity_multiplier', user_arguments)
    check_multiplier(runner, maximum_capacity_multiplier)
    minimum_capacity_multiplier = runner.getDoubleArgumentValue('minimum_capacity_multiplier', user_arguments)
    check_multiplier(runner, minimum_capacity_multiplier)

    # find objects to change
    water_heaters = []
    building = model.getBuilding
    building_handle = building.handle.to_s
    runner.registerInfo("water_heater_handle: #{water_heater_handle}")
    # setup water_heaters
    if water_heater_handle == building_handle
      # Use ALL SpaceTypes
      runner.registerInfo('Applying change to ALL SpaceTypes')
      water_heaters = model.getWaterHeaterMixeds
    elsif water_heater_handle == 0.to_s
      # SpaceTypes set to NONE so do nothing
      runner.registerInfo('Applying change to NONE SpaceTypes')
    elsif !water_heater_handle.empty?
      # Single WaterHeaterMixed handle found, check if object is good
      if !water_heater_object.get.to_WaterHeaterMixed.empty?
        runner.registerInfo("Applying change to #{water_heater_object.get.name} WaterHeaterMixed")
        water_heaters << water_heater_object.get.to_WaterHeaterMixed.get
      else
        runner.registerError("WaterHeaterMixed with handle #{water_heater_handle} could not be found.")
      end
    else
      runner.registerError('WaterHeaterMixed handle is empty.')
      return false
    end

    altered_heaters = []
    altered_thermalefficiency = []
    altered_max_cap = []
    altered_min_cap = []

    # report initial condition of model
    runner.registerInitialCondition("Applying Multiplier to #{water_heaters.size} Water Heaters.")

    # loop through space types
    water_heaters.each do |water_heater|
      altered_heater = false
      # modify maximum_capacity_multiplier
      if maximum_capacity_multiplier != 1.0 && water_heater.heaterMaximumCapacity.is_initialized
        runner.registerInfo("Applying #{maximum_capacity_multiplier}x maximum capacity multiplier to #{water_heater.name.get}.")
        water_heater.setHeaterMaximumCapacity(water_heater.heaterMaximumCapacity.get * maximum_capacity_multiplier)
        altered_max_cap << water_heater.handle.to_s
        altered_heater = true
      end

      # modify minimum_capacity_multiplier
      if minimum_capacity_multiplier != 1.0 && water_heater.heaterMinimumCapacity.is_initialized
        runner.registerInfo("Applying #{minimum_capacity_multiplier}x minimum capacity multiplier to #{water_heater.name.get}.")
        water_heater.setHeaterMaximumCapacity(water_heater.heaterMinimumCapacity.get * minimum_capacity_multiplier)
        altered_min_cap << water_heater.handle.to_s
        altered_heater = true
      end

      # modify thermal_efficiency_multiplier
      if thermal_efficiency_multiplier != 1.0 && water_heater.heaterThermalEfficiency.is_initialized
        runner.registerInfo("Applying #{thermal_efficiency_multiplier}x thermal efficiency multiplier to #{water_heater.name.get}.")
        water_heater.setHeaterThermalEfficiency(water_heater.heaterThermalEfficiency.get * thermal_efficiency_multiplier)
        altered_thermalefficiency << water_heater.handle.to_s
        altered_heater = true
      end

      orig_fuel_type = water_heater.heaterFuelType
      if orig_fuel_type != fuel_type
        runner.registerInfo("Changing Fuel Type to #{fuel_type} for #{water_heater.name.get}.")
        water_heater.setHeaterFuelType(fuel_type)
        altered_heater = true
      end

      next unless altered_heater

      altered_heaters << water_heater.handle.to_s
      change_name(water_heater, maximum_capacity_multiplier, minimum_capacity_multiplier, thermal_efficiency_multiplier, fuel_type, orig_fuel_type)
      runner.registerInfo("WaterHeater name changed to: #{water_heater.name.get}")
    end

    # na if nothing in model to look at
    if altered_heaters.empty?
      runner.registerAsNotApplicable('No WaterHeaters were altered in the model')
      return true
    end

    # report final condition of model
    runner.registerFinalCondition("#{altered_heaters.size} WaterHeater objects were altered.")

    true
  end
end

# register the measure to be used by the application
WaterHeaterMixedMultiplier.new.registerWithApplication
