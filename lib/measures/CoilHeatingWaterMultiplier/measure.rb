# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# start the measure
class CoilHeatingWaterMultiplier < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    'Heating Coils Water Multiplier'
  end

  # human readable description
  def description
    'This is a general purpose measure to calibrate Water Heating Coils with a Multiplier.'
  end

  # human readable description of modeling approach
  def modeler_description
    'It will be used for calibration of rated capacity and efficiency and parasitic loads. User can choose between a SINGLE coil or ALL the Coils.'
  end

  def change_name(object, ua_factor, coil_capacity_multiplier)
    nameString = object.name.get.to_s
    nameString += " #{ua_factor.round(2)}x UA" if ua_factor != 1.0
    if coil_capacity_multiplier != 1.0
      nameString += " #{coil_capacity_multiplier.round(2)}x coilCap"
    end
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
        next if component.to_CoilHeatingWater.empty?

        show_loop = true
        loop_handles << component.handle.to_s
        loop_display_names << component.name.to_s
      end

      # if loop as object of correct type then add to hash.
      # if show_loop == true
      # loop_handles << value.handle.to_s
      # loop_display_names << key
      # end
    end

    # add building to string vector with space type
    building = model.getBuilding
    loop_handles << building.handle.to_s
    loop_display_names << '*All Water Heating Coils*'
    loop_handles << '0'
    loop_display_names << '*None*'

    # make a choice argument for space type
    coil_arg = OpenStudio::Measure::OSArgument.makeChoiceArgument('coil', loop_handles, loop_display_names)
    coil_arg.setDisplayName('Apply the Measure to a SINGLE Water Heating Coil, ALL the Water Heating Coils or NONE.')
    coil_arg.setDefaultValue('*All Water Heating Coils*') # if no space type is chosen this will run on the entire building
    args << coil_arg

    # ua_factor
    ua_factor = OpenStudio::Measure::OSArgument.makeDoubleArgument('ua_factor', true)
    ua_factor.setDisplayName('Multiplier for UA coefficient.')
    ua_factor.setDescription('Multiplier for UA coefficient.')
    ua_factor.setDefaultValue(1.0)
    args << ua_factor

    # coil_capacity_multiplier
    coil_capacity_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('coil_capacity_multiplier', true)
    coil_capacity_multiplier.setDisplayName('Multiplier for coil Capacity.')
    coil_capacity_multiplier.setDescription('Multiplier for coil Capacity.')
    coil_capacity_multiplier.setDefaultValue(1.0)
    args << coil_capacity_multiplier

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

    coil_capacity_multiplier = runner.getDoubleArgumentValue('coil_capacity_multiplier', user_arguments)
    check_multiplier(runner, coil_capacity_multiplier)
    ua_factor = runner.getDoubleArgumentValue('ua_factor', user_arguments)
    check_multiplier(runner, ua_factor)

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
          unless supply_component.to_CoilHeatingWater.empty?
            coils << supply_component.to_CoilHeatingWater.get
          end
        end
      end
    elsif coil_handle == 0.to_s
      # coils set to NONE so do nothing
      runner.registerInfo('Applying change to NONE Coils')
    elsif !coil_handle.empty?
      # Single coil handle found, check if object is good
      if !coil_object.get.to_CoilHeatingWater.empty?
        runner.registerInfo("Applying change to #{coil_object.get.name} coil")
        coils << coil_object.get.to_CoilHeatingWater.get
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
      # coil_capacity_multiplier
      if coil_capacity_multiplier != 1.0 && coil.ratedCapacity.is_initialized
        runner.registerInfo("Applying ratedCapacity #{coil_capacity_multiplier}x multiplier to #{coil.name.get}.")
        coil.setRatedCapacity(coil.ratedCapacity.get * coil_capacity_multiplier)
        altered_capacity << coil.handle.to_s
        altered_coil = true
      end

      # modify ua_factor
      if ua_factor != 1.0 && coil.uFactorTimesAreaValue.is_initialized
        runner.registerInfo("Applying uFactorTimesAreaValue #{ua_factor}x multiplier to #{coil.name.get}.")
        coil.setUFactorTimesAreaValue(coil.uFactorTimesAreaValue.get * ua_factor)
        altered_coilefficiency << coil.handle.to_s
        altered_coil = true
      end

      next unless altered_coil

      altered_coils << coil.handle.to_s
      change_name(coil, ua_factor, coil_capacity_multiplier)
      runner.registerInfo("coil name changed to: #{coil.name.get}")
    end

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
CoilHeatingWaterMultiplier.new.registerWithApplication
