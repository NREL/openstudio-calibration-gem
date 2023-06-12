# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# start the measure
class CoilCoolingDXTwoSpeedPercentChange < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    'Cooling Coils DX Two Speed Percent Change'
  end

  # human readable description
  def description
    'This is a general purpose measure to calibrate DX Cooling Coils with a Percent Change.'
  end

  # human readable description of modeling approach
  def modeler_description
    'It will be used for calibration of rated capacity and efficiency and parasitic loads. User can choose between a Two coil or ALL the Coils.'
  end

  def change_name(object, rated_highspeed_cop_perc_change, rated_highspeed_cooling_capacity_perc_change, rated_lowspeed_cop_perc_change, rated_lowspeed_cooling_capacity_perc_change)
    nameString = object.name.get.to_s
    if rated_highspeed_cop_perc_change != 1.0
      nameString += " #{rated_highspeed_cop_perc_change.round(2)}x coilEff"
    end
    if rated_highspeed_cooling_capacity_perc_change != 1.0
      nameString += " #{rated_highspeed_cooling_capacity_perc_change.round(2)}x coilCap"
    end
    if rated_lowspeed_cooling_capacity_perc_change != 1.0
      nameString += " #{rated_lowspeed_cooling_capacity_perc_change.round(2)}x coilEff"
    end
    if rated_lowspeed_cop_perc_change != 1.0
      nameString += " #{rated_lowspeed_cop_perc_change.round(2)}x coilCap"
    end
    object.setName(nameString)
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # populate choice argument for constructions that are applied to surfaces in the model
    loop_handles = OpenStudio::StringVector.new
    loop_display_names = OpenStudio::StringVector.new

    # putting air loops and names into hash
    loop_args = model.getAirLoopHVACs
    loop_args_hash = {}
    loop_args.each do |loop_arg|
      loop_args_hash[loop_arg.name.to_s] = loop_arg
    end

    # looping through sorted hash of air loops
    loop_args_hash.sort.map do |_key, value|
      show_loop = false
      components = value.supplyComponents
      components.each do |component|
        next if component.to_CoilCoolingDXTwoSpeed.empty?
        show_loop = true
        loop_handles << component.handle.to_s
        loop_display_names << component.name.to_s
      end

      # if loop as object of correct type then add to hash.
      # if show_loop == true
      #  loop_handles << value.handle.to_s
      #  loop_display_names << key
      # end
    end

    # add building to string vector with space type
    building = model.getBuilding
    loop_handles << building.handle.to_s
    loop_display_names << '*All DX Cooling Coils*'
    loop_handles << '0'
    loop_display_names << '*None*'

    # make a choice argument for space type
    coil_arg = OpenStudio::Measure::OSArgument.makeChoiceArgument('coil', loop_handles, loop_display_names)
    coil_arg.setDisplayName('Apply the Measure to a Two DX Cooling Coil, ALL the DX Cooling Coils or NONE.')
    coil_arg.setDefaultValue('*All DX Cooling Coils*') # if no space type is chosen this will run on the entire building
    args << coil_arg

    # rated_highspeed_cop_perc_change
    rated_highspeed_cop_perc_change = OpenStudio::Measure::OSArgument.makeDoubleArgument('rated_highspeed_cop_perc_change', true)
    rated_highspeed_cop_perc_change.setDisplayName('Percent Change for High Speed COP.')
    rated_highspeed_cop_perc_change.setDescription('Percent Change for High Speed COP.')
    rated_highspeed_cop_perc_change.setDefaultValue(0.0)
    args << rated_highspeed_cop_perc_change

    # rated_lowspeed_cop_perc_change
    rated_lowspeed_cop_perc_change = OpenStudio::Measure::OSArgument.makeDoubleArgument('rated_lowspeed_cop_perc_change', true)
    rated_lowspeed_cop_perc_change.setDisplayName('Percent Change for Low Speed COP.')
    rated_lowspeed_cop_perc_change.setDescription('Percent Change for Low Speed COP.')
    rated_lowspeed_cop_perc_change.setDefaultValue(0.0)
    args << rated_lowspeed_cop_perc_change

    # rated_highspeed_cooling_capacity_perc_change
    rated_highspeed_cooling_capacity_perc_change = OpenStudio::Measure::OSArgument.makeDoubleArgument('rated_highspeed_cooling_capacity_perc_change', true)
    rated_highspeed_cooling_capacity_perc_change.setDisplayName('Percent Change for High Speed coil cooling Capacity.')
    rated_highspeed_cooling_capacity_perc_change.setDescription('Percent Change for High Speed coil cooling Capacity.')
    rated_highspeed_cooling_capacity_perc_change.setDefaultValue(0.0)
    args << rated_highspeed_cooling_capacity_perc_change

    # rated_lowspeed_cooling_capacity_perc_change
    rated_lowspeed_cooling_capacity_perc_change = OpenStudio::Measure::OSArgument.makeDoubleArgument('rated_lowspeed_cooling_capacity_perc_change', true)
    rated_lowspeed_cooling_capacity_perc_change.setDisplayName('Percent Change for Low Speed coil cooling Capacity.')
    rated_lowspeed_cooling_capacity_perc_change.setDescription('Percent Change for Low Speed coil cooling Capacity.')
    rated_lowspeed_cooling_capacity_perc_change.setDefaultValue(0.0)
    args << rated_lowspeed_cooling_capacity_perc_change

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
    coil_object = runner.getOptionalWorkspaceObjectChoiceValue('coil', user_arguments, model)
    coil_handle = runner.getStringArgumentValue('coil', user_arguments)

    rated_highspeed_cooling_capacity_perc_change = runner.getDoubleArgumentValue('rated_highspeed_cooling_capacity_perc_change', user_arguments)
    rated_highspeed_cop_perc_change = runner.getDoubleArgumentValue('rated_highspeed_cop_perc_change', user_arguments)
    rated_lowspeed_cooling_capacity_perc_change = runner.getDoubleArgumentValue('rated_lowspeed_cooling_capacity_perc_change', user_arguments)
    rated_lowspeed_cop_perc_change = runner.getDoubleArgumentValue('rated_lowspeed_cop_perc_change', user_arguments)

    # find objects to change
    coils = []
    building = model.getBuilding
    building_handle = building.handle.to_s
    runner.registerInfo("coil_handle: #{coil_handle}")
    # setup coils
    if coil_handle == building_handle
      # Use ALL coils
      runner.registerInfo('Applying change to ALL Coils')
      loops = model.getAirLoopHVACs
      # loop through air loops
      loops.each do |loop|
        supply_components = loop.supplyComponents
        # find coils on loops
        supply_components.each do |supply_component|
          unless supply_component.to_CoilCoolingDXTwoSpeed.empty?
            coils << supply_component.to_CoilCoolingDXTwoSpeed.get
          end
        end
      end
    elsif coil_handle == 0.to_s
      # coils set to NONE so do nothing
      runner.registerInfo('Applying change to NONE Coils')
    elsif !coil_handle.empty?
      # Two coil handle found, check if object is good
      if !coil_object.get.to_CoilCoolingDXTwoSpeed.empty?
        runner.registerInfo("Applying change to #{coil_object.get.name} coil")
        coils << coil_object.get.to_CoilCoolingDXTwoSpeed.get
      else
        runner.registerError("coil with handle #{coil_handle} could not be found.")
      end
    else
      runner.registerError('coil handle is empty.')
      return false
    end

    # report initial condition of model
    runner.registerInitialCondition("Coils to change: #{coils.size}")
    runner.registerInfo("Coils to change: #{coils.size}")
    altered_coils = []
    altered_capacity = []
    altered_coilefficiency = []
    # loop through coils
    coils.each do |coil|
      altered_coil = false
      # rated_highspeed_cooling_capacity_perc_change
      if rated_highspeed_cooling_capacity_perc_change != 0.0
        if coil.ratedHighSpeedTotalCoolingCapacity.is_initialized
          runner.registerInfo("Applying ratedHighSpeedTotalCoolingCapacity #{rated_highspeed_cooling_capacity_perc_change} Percent Change to #{coil.name.get}.")
          coil.setRatedHighSpeedTotalCoolingCapacity(coil.ratedHighSpeedTotalCoolingCapacity.get + coil.ratedHighSpeedTotalCoolingCapacity.get * rated_highspeed_cooling_capacity_perc_change * 0.01)
          altered_capacity << coil.handle.to_s
          altered_coil = true
        end
      end

      # rated_lowspeed_cooling_capacity_perc_change
      if rated_lowspeed_cooling_capacity_perc_change != 0.0
        if coil.ratedLowSpeedTotalCoolingCapacity.is_initialized
          runner.registerInfo("Applying ratedLowSpeedTotalCoolingCapacity #{rated_lowspeed_cooling_capacity_perc_change} Percent Change to #{coil.name.get}.")
          coil.setRatedLowSpeedTotalCoolingCapacity(coil.ratedLowSpeedTotalCoolingCapacity.get + coil.ratedLowSpeedTotalCoolingCapacity.get * rated_lowspeed_cooling_capacity_perc_change * 0.01)
          altered_capacity << coil.handle.to_s
          altered_coil = true
        end
      end

      # modify rated_highspeed_cop_perc_change
      if rated_highspeed_cop_perc_change != 0.0
          runner.registerInfo("Applying ratedHighSpeedCOP #{rated_highspeed_cop_perc_change} Percent Change to #{coil.name.get}.")
          coil.setRatedHighSpeedCOP(coil.ratedHighSpeedCOP + coil.ratedHighSpeedCOP * rated_highspeed_cop_perc_change * 0.01)
          altered_coilefficiency << coil.handle.to_s
          altered_coil = true
      end

      # modify rated_lowspeed_cop_perc_change
      if rated_lowspeed_cop_perc_change != 0.0
          runner.registerInfo("Applying ratedLowSpeedCOP #{rated_lowspeed_cop_perc_change} Percent Change to #{coil.name.get}.")
          coil.setRatedLowSpeedCOP(coil.ratedLowSpeedCOP + coil.ratedLowSpeedCOP * rated_lowspeed_cop_perc_change * 0.01)
          altered_coilefficiency << coil.handle.to_s
          altered_coil = true
      end

      next unless altered_coil
      altered_coils << coil.handle.to_s
      change_name(coil, rated_highspeed_cop_perc_change, rated_highspeed_cooling_capacity_perc_change, rated_lowspeed_cop_perc_change, rated_lowspeed_cooling_capacity_perc_change)
      runner.registerInfo("coil name changed to: #{coil.name.get}")
    end # end coil loop

    # na if nothing in model to look at
    if altered_coils.empty?
      runner.registerAsNotApplicable('No Coils were altered in the model')
      return true
    end

    # report final condition of model
    runner.registerFinalCondition("#{altered_coils.size} Coils objects were altered.")

    true
  end
end

# register the measure to be used by the application
CoilCoolingDXTwoSpeedPercentChange.new.registerWithApplication
