# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# start the measure
class ConstructionLayerZeroMaterialProperties < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    'Change Parameters Of Material (Layer 0 of Construction)'
  end

  # human readable description
  def description
    'This measure changes properties of Layer 0 for a specific construction.'
  end

  # human readable description of modeling approach
  def modeler_description
    'This measure changes the Layer 0 properties of Thickness, Density, Thermal Absorptance, Solar Absorptance, Visible Absoptance, Thermal Conductivity, Specific Heat.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # populate choice argument for constructions that are applied to surfaces in the model
    construction_handles = OpenStudio::StringVector.new
    construction_display_names = OpenStudio::StringVector.new

    # putting space types and names into hash
    construction_args = model.getConstructions
    construction_args_hash = {}
    construction_args.each do |construction_arg|
      construction_args_hash[construction_arg.name.to_s] = construction_arg
    end

    # looping through sorted hash of constructions
    construction_args_hash.sort.map do |key, value|
      # only include if construction is used on surface
      if value.getNetArea > 0
        construction_handles << value.handle.to_s
        construction_display_names << key
      end
    end

    # make an argument for construction
    construction = OpenStudio::Measure::OSArgument.makeChoiceArgument('construction', construction_handles, construction_display_names, true)
    construction.setDisplayName('Choose a Construction to Alter.')
    args << construction

    # make an argument thickness
    thickness = OpenStudio::Measure::OSArgument.makeDoubleArgument('thickness', true)
    thickness.setDisplayName('Thickness of Layer 0')
    thickness.setDescription('Set Thickness of Layer 0. 0 value means do not change from default.')
    thickness.setDefaultValue(0)
    thickness.setUnits('m')
    args << thickness

    # make an argument density
    density = OpenStudio::Measure::OSArgument.makeDoubleArgument('density', true)
    density.setDisplayName('Density of Layer 0')
    density.setDescription('Set Density of Layer 0. 0 value means do not change from default.')
    density.setUnits('kg/m^3')
    density.setDefaultValue(0)
    args << density

    # make an argument thermal_absorptance
    thermal_absorptance = OpenStudio::Measure::OSArgument.makeDoubleArgument('thermal_absorptance', true)
    thermal_absorptance.setDisplayName('Thermal Absorptance of Layer 0')
    thermal_absorptance.setDescription('Set Thermal Absorptance of Layer 0. 0 value means do not change from default.')
    thermal_absorptance.setUnits('fraction')
    thermal_absorptance.setDefaultValue(0)
    args << thermal_absorptance

    # make an argument solar_absorptance
    solar_absorptance = OpenStudio::Measure::OSArgument.makeDoubleArgument('solar_absorptance', true)
    solar_absorptance.setDisplayName('Solar Absorptance of Layer 0')
    solar_absorptance.setDescription('Set Solar Absorptance of Layer 0. 0 value means do not change from default.')
    solar_absorptance.setUnits('fraction')
    solar_absorptance.setDefaultValue(0)
    args << solar_absorptance

    # make an argument visible_absorptance
    visible_absorptance = OpenStudio::Measure::OSArgument.makeDoubleArgument('visible_absorptance', true)
    visible_absorptance.setDisplayName('Visible Absorptance of Layer 0')
    visible_absorptance.setDescription('Set Visible Absorptance of Layer 0. 0 value means do not change from default.')
    visible_absorptance.setUnits('fraction')
    visible_absorptance.setDefaultValue(0)
    args << visible_absorptance

    # make an argument conductivity
    thermal_conductivity = OpenStudio::Measure::OSArgument.makeDoubleArgument('thermal_conductivity', true)
    thermal_conductivity.setDisplayName('Thermal Conductivity of Layer 0')
    thermal_conductivity.setDescription('Set Thermal Conductivity of Layer 0. 0 value means do not change from default.')
    thermal_conductivity.setDefaultValue(0)
    thermal_conductivity.setUnits('W/(m*K)')
    args << thermal_conductivity

    # make an argument specific_heat
    specific_heat = OpenStudio::Measure::OSArgument.makeDoubleArgument('specific_heat', true)
    specific_heat.setDisplayName('Specific Heat of Layer 0')
    specific_heat.setDescription('Set Specific Heat of Layer 0. 0 value means do not change from default.')
    specific_heat.setUnits('J/(kg*K)')
    specific_heat.setDefaultValue(0)
    args << specific_heat

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
    construction = runner.getOptionalWorkspaceObjectChoiceValue('construction', user_arguments, model) # model is passed in because of argument type
    thermal_absorptance = runner.getDoubleArgumentValue('thermal_absorptance', user_arguments)
    solar_absorptance = runner.getDoubleArgumentValue('solar_absorptance', user_arguments)
    visible_absorptance = runner.getDoubleArgumentValue('visible_absorptance', user_arguments)
    thermal_conductivity = runner.getDoubleArgumentValue('thermal_conductivity', user_arguments)
    specific_heat = runner.getDoubleArgumentValue('specific_heat', user_arguments)
    thickness = runner.getDoubleArgumentValue('thickness', user_arguments)
    density = runner.getDoubleArgumentValue('density', user_arguments)

    # check the construction for reasonableness
    if construction.empty?
      handle = runner.getStringArgumentValue('construction', user_arguments)
      if handle.empty?
        runner.registerError('No construction was chosen.')
      else
        runner.registerError("The selected construction with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if !construction.get.to_Construction.empty?
        construction = construction.get.to_Construction.get
      else
        runner.registerError('Script Error - argument not showing up as construction.')
        return false
      end
    end

    initial_r_value_ip = OpenStudio.convert(1.0 / construction.thermalConductance.to_f, 'm^2*K/W', 'ft^2*h*R/Btu')
    runner.registerInitialCondition("The Initial R-value of #{construction.name} is #{initial_r_value_ip} (ft^2*h*R/Btu).")
    runner.registerValue('initial_r_value_ip', initial_r_value_ip.to_f, 'ft^2*h*R/Btu')
    # get layers
    layers = construction.layers

    # steel layer is always first layer
    layer = layers[0].to_StandardOpaqueMaterial.get
    runner.registerInfo("Initial thermal_absorptance: #{layer.thermalAbsorptance}")
    runner.registerInfo("Initial solar_absorptance: #{layer.solarAbsorptance}")
    runner.registerInfo("Initial visible_absorptance: #{layer.visibleAbsorptance}")
    runner.registerInfo("Initial thermal_conductivity: #{layer.thermalConductivity}")
    runner.registerInfo("Initial specific_heat: #{layer.specificHeat}")
    runner.registerInfo("Initial thickness: #{layer.thickness}")
    runner.registerInfo("Initial density: #{layer.density}")

    # set layer properties
    layer.setThermalAbsorptance(thermal_absorptance) if thermal_absorptance != 0
    layer.setSolarAbsorptance(solar_absorptance) if solar_absorptance != 0
    layer.setVisibleAbsorptance(visible_absorptance) if visible_absorptance != 0
    layer.setThermalConductivity(thermal_conductivity) if thermal_conductivity != 0
    layer.setSpecificHeat(specific_heat) if specific_heat != 0
    layer.setThickness(thickness) if thickness != 0
    layer.setDensity(density) if density != 0

    runner.registerInfo("Final thermal_absorptance: #{layer.thermalAbsorptance}")
    runner.registerInfo("Final solar_absorptance: #{layer.solarAbsorptance}")
    runner.registerInfo("Final visible_absorptance: #{layer.visibleAbsorptance}")
    runner.registerInfo("Final thermal_conductivity: #{layer.thermalConductivity}")
    runner.registerInfo("Final specific_heat: #{layer.specificHeat}")
    runner.registerInfo("Final thickness: #{layer.thickness}")
    runner.registerInfo("Final density: #{layer.density}")

    # report initial condition
    final_r_value_ip = OpenStudio.convert(1 / construction.thermalConductance.to_f, 'm^2*K/W', 'ft^2*h*R/Btu')
    runner.registerFinalCondition("The Final R-value of #{construction.name} is #{final_r_value_ip} (ft^2*h*R/Btu).")
    runner.registerValue('final_r_value_ip', final_r_value_ip.to_f, 'ft^2*h*R/Btu')

    true
  end
end

# this allows the measure to be used by the application
ConstructionLayerZeroMaterialProperties.new.registerWithApplication
