# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# start the measure
class GeneralCalibrationMeasureMultiplier < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    'General Calibration Measure Multiplier'
  end

  # human readable description
  def description
    'This is a general purpose measure to calibrate space and space type elements with a Multiplier.'
  end

  # human readable description of modeling approach
  def modeler_description
    'It will be used for calibration of space and spaceType loads as well as infiltration, and outdoor air. User can choose between a SINGLE SpaceType or ALL the SpaceTypes as well as a SINGLE Space or ALL the Spaces.'
  end

  def change_name(object, multiplier)
    if multiplier != 1
      object.setName("#{object.name.get} #{multiplier.round(2)}x Multiplier")
    end
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
    space_type_handles = OpenStudio::StringVector.new
    space_type_display_names = OpenStudio::StringVector.new

    # putting model object and names into hash
    space_type_args = model.getSpaceTypes
    space_type_args_hash = {}
    space_type_args.each do |space_type_arg|
      space_type_args_hash[space_type_arg.name.to_s] = space_type_arg
    end

    # looping through sorted hash of model objects
    space_type_args_hash.sort.map do |key, value|
      # only include if space type is used in the model
      unless value.spaces.empty?
        space_type_handles << value.handle.to_s
        space_type_display_names << key
      end
    end

    # add building to string vector with space type
    building = model.getBuilding
    space_type_handles << building.handle.to_s
    space_type_display_names << '*All SpaceTypes*'
    space_type_handles << '0'
    space_type_display_names << '*None*'

    # make a choice argument for space type
    space_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('space_type', space_type_handles, space_type_display_names)
    space_type.setDisplayName('Apply the Measure to a SINGLE SpaceType, ALL the SpaceTypes or NONE.')
    space_type.setDefaultValue('*All SpaceTypes*') # if no space type is chosen this will run on the entire building
    args << space_type

    # make a choice argument for model objects
    space_handles = OpenStudio::StringVector.new
    space_display_names = OpenStudio::StringVector.new

    # putting model object and names into hash
    space_args = model.getSpaces
    space_args_hash = {}
    space_args.each do |space_arg|
      space_args_hash[space_arg.name.to_s] = space_arg
    end

    # looping through sorted hash of model objects
    space_args_hash.sort.map do |key, value|
      space_handles << value.handle.to_s
      space_display_names << key
    end

    # add building to string vector with spaces
    building = model.getBuilding
    space_handles << building.handle.to_s
    space_display_names << '*All Spaces*'
    space_handles << '0'
    space_display_names << '*None*'

    # make a choice argument for space type
    space = OpenStudio::Measure::OSArgument.makeChoiceArgument('space', space_handles, space_display_names)
    space.setDisplayName('Apply the Measure to a SINGLE Space, ALL the Spaces or NONE.')
    space.setDefaultValue('*All Spaces*') # if no space type is chosen this will run on the entire building
    args << space

    # Lights multiplier
    lights_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('Lights_multiplier', true)
    lights_multiplier.setDisplayName('Multiplier for Lights.')
    lights_multiplier.setDescription('Multiplier for Lights.')
    lights_multiplier.setDefaultValue(1.0)
    lights_multiplier.setMinValue(0.0)
    args << lights_multiplier

    # Luminaire multiplier
    luminaire_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('Luminaire_multiplier', true)
    luminaire_multiplier.setDisplayName('Multiplier for Luminaire.')
    luminaire_multiplier.setDescription('Multiplier for Luminaire.')
    luminaire_multiplier.setDefaultValue(1.0)
    args << luminaire_multiplier

    # Electric Equipment multiplier
    electric_equip_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('ElectricEquipment_multiplier', true)
    electric_equip_multiplier.setDisplayName('Multiplier for Electric Equipment.')
    electric_equip_multiplier.setDescription('Multiplier for Electric Equipment.')
    electric_equip_multiplier.setDefaultValue(1.0)
    args << electric_equip_multiplier

    # Gas Equipment multiplier
    gas_equip_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('GasEquipment_multiplier', true)
    gas_equip_multiplier.setDisplayName('Multiplier for Gas Equipment.')
    gas_equip_multiplier.setDescription('Multiplier for Gas Equipment.')
    gas_equip_multiplier.setDefaultValue(1.0)
    args << gas_equip_multiplier

    # OtherEquipment multiplier
    other_equip_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('OtherEquipment_multiplier', true)
    other_equip_multiplier.setDisplayName('Multiplier for OtherEquipment.')
    other_equip_multiplier.setDescription('Multiplier for OtherEquipment.')
    other_equip_multiplier.setDefaultValue(1.0)
    args << other_equip_multiplier

    # occupancy multiplier
    occ_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('People_multiplier', true)
    occ_multiplier.setDisplayName('Multiplier for number of people.')
    occ_multiplier.setDescription('Multiplier for number of people.')
    occ_multiplier.setDefaultValue(1.0)
    args << occ_multiplier

    # internalMass multiplier
    mass_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('InternalMass_multiplier', true)
    mass_multiplier.setDisplayName('Multiplier for Internal Mass.')
    mass_multiplier.setDescription('Multiplier for Internal Mass.')
    mass_multiplier.setDefaultValue(1.0)
    args << mass_multiplier

    # infiltration multiplier
    infil_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('Infiltration_multiplier', true)
    infil_multiplier.setDisplayName('Multiplier for infiltration.')
    infil_multiplier.setDescription('Multiplier for infiltration.')
    infil_multiplier.setDefaultValue(1.0)
    args << infil_multiplier

    # ventilation multiplier
    vent_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('Ventilation_multiplier', true)
    vent_multiplier.setDisplayName('Multiplier for Ventilation.')
    vent_multiplier.setDescription('Multiplier for Ventilation.')
    vent_multiplier.setDefaultValue(1.0)
    args << vent_multiplier

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
    space_type_object = runner.getOptionalWorkspaceObjectChoiceValue('space_type', user_arguments, model)
    space_type_handle = runner.getStringArgumentValue('space_type', user_arguments)
    space_object = runner.getOptionalWorkspaceObjectChoiceValue('space', user_arguments, model)
    space_handle = runner.getStringArgumentValue('space', user_arguments)
    occ_multiplier = runner.getDoubleArgumentValue('People_multiplier', user_arguments)
    check_multiplier(runner, occ_multiplier)
    infil_multiplier = runner.getDoubleArgumentValue('Infiltration_multiplier', user_arguments)
    check_multiplier(runner, infil_multiplier)
    vent_multiplier = runner.getDoubleArgumentValue('Ventilation_multiplier', user_arguments)
    check_multiplier(runner, vent_multiplier)
    mass_multiplier = runner.getDoubleArgumentValue('InternalMass_multiplier', user_arguments)
    check_multiplier(runner, mass_multiplier)
    electric_equip_multiplier = runner.getDoubleArgumentValue('ElectricEquipment_multiplier', user_arguments)
    check_multiplier(runner, electric_equip_multiplier)
    gas_equip_multiplier = runner.getDoubleArgumentValue('GasEquipment_multiplier', user_arguments)
    check_multiplier(runner, gas_equip_multiplier)
    other_equip_multiplier = runner.getDoubleArgumentValue('OtherEquipment_multiplier', user_arguments)
    check_multiplier(runner, other_equip_multiplier)
    lights_multiplier = runner.getDoubleArgumentValue('Lights_multiplier', user_arguments)
    check_multiplier(runner, lights_multiplier)
    luminaire_multiplier = runner.getDoubleArgumentValue('Luminaire_multiplier', user_arguments)
    check_multiplier(runner, luminaire_multiplier)

    # find objects to change
    space_types = []
    spaces = []
    building = model.getBuilding
    building_handle = building.handle.to_s
    runner.registerInfo("space_type_handle: #{space_type_handle}")
    runner.registerInfo("space_handle: #{space_handle}")
    # setup space_types
    if space_type_handle == building_handle
      # Use ALL SpaceTypes
      runner.registerInfo('Applying change to ALL SpaceTypes')
      space_types = model.getSpaceTypes
    elsif space_type_handle == 0.to_s
      # SpaceTypes set to NONE so do nothing
      runner.registerInfo('Applying change to NONE SpaceTypes')
    elsif !space_type_handle.empty?
      # Single SpaceType handle found, check if object is good
      if !space_type_object.get.to_SpaceType.empty?
        runner.registerInfo("Applying change to #{space_type_object.get.name} SpaceType")
        space_types << space_type_object.get.to_SpaceType.get
      else
        runner.registerError("SpaceType with handle #{space_type_handle} could not be found.")
      end
    else
      runner.registerError('SpaceType handle is empty.')
      return false
    end

    # setup spaces
    if space_handle == building_handle
      # Use ALL Spaces
      runner.registerInfo('Applying change to ALL Spaces')
      spaces = model.getSpaces
    elsif space_handle == 0.to_s
      # Spaces set to NONE so do nothing
      runner.registerInfo('Applying change to NONE Spaces')
    elsif !space_handle.empty?
      # Single Space handle found, check if object is good
      if !space_object.get.to_Space.empty?
        runner.registerInfo("Applying change to #{space_object.get.name} Space")
        spaces << space_object.get.to_Space.get
      else
        runner.registerError("Space with handle #{space_handle} could not be found.")
      end
    else
      runner.registerError('Space handle is empty.')
      return false
    end

    altered_people_objects = []
    altered_infiltration_objects = []
    altered_outdoor_air_objects = []
    altered_internalmass_objects = []
    altered_lights_objects = []
    altered_luminaires_objects = []
    altered_electric_equip_objects = []
    altered_gas_equip_objects = []
    altered_other_equip_objects = []

    # report initial condition of model
    runner.registerInitialCondition("Applying Multiplier to #{space_types.size} space types and #{spaces.size} spaces.")
    runner.registerInfo("Applying Multiplier to #{space_types.size} space types.")

    # loop through space types
    space_types.each do |space_type|
      # modify lights
      space_type.lights.each do |light|
        # get and alter multiplier
        if !altered_lights_objects.include? light.handle.to_s
          runner.registerInfo("Applying #{lights_multiplier}x multiplier to #{light.name.get}.")
          light.setMultiplier(lights_multiplier)
          # update hash and change name
          change_name(light, lights_multiplier)
          altered_lights_objects << light.handle.to_s
        else
          runner.registerInfo("Skipping change to #{light.name.get}")
        end
      end

      # modify luminaire
      space_type.luminaires.each do |light|
        # get and alter multiplier
        if !altered_luminaires_objects.include? light.handle.to_s
          runner.registerInfo("Applying #{luminaire_multiplier}x multiplier to #{light.name.get}.")
          light.setMultiplier(luminaire_multiplier)
          # update hash and change name
          change_name(light, luminaire_multiplier)
          altered_luminaires_objects << light.handle.to_s
        else
          runner.registerInfo("Skipping change to #{light.name.get}")
        end
      end

      # modify electric equip
      space_type.electricEquipment.each do |equip|
        # get and alter multiplier
        if !altered_electric_equip_objects.include? equip.handle.to_s
          runner.registerInfo("Applying #{electric_equip_multiplier}x multiplier to #{equip.name.get}.")
          equip.setMultiplier(electric_equip_multiplier)
          # update hash and change name
          change_name(equip, electric_equip_multiplier)
          altered_electric_equip_objects << equip.handle.to_s
        else
          runner.registerInfo("Skipping change to #{equip.name.get}")
        end
      end

      # modify gas equip
      space_type.gasEquipment.each do |equip|
        # get and alter multiplier
        if !altered_gas_equip_objects.include? equip.handle.to_s
          runner.registerInfo("Applying #{gas_equip_multiplier}x multiplier to #{equip.name.get}.")
          equip.setMultiplier(gas_equip_multiplier)
          # update hash and change name
          change_name(equip, gas_equip_multiplier)
          altered_gas_equip_objects << equip.handle.to_s
        else
          runner.registerInfo("Skipping change to #{equip.name.get}")
        end
      end

      # modify other equip
      space_type.otherEquipment.each do |equip|
        # get and alter multiplier
        if !altered_other_equip_objects.include? equip.handle.to_s
          runner.registerInfo("Applying #{other_equip_multiplier}x multiplier to #{equip.name.get}.")
          equip.setMultiplier(other_equip_multiplier)
          # update hash and change name
          change_name(equip, other_equip_multiplier)
          altered_other_equip_objects << equip.handle.to_s
        else
          runner.registerInfo("Skipping change to #{equip.name.get}")
        end
      end

      # modify occupancy
      space_type.people.each do |peps|
        # get and alter multiplier
        if !altered_people_objects.include? peps.handle.to_s
          runner.registerInfo("Applying #{occ_multiplier}x multiplier to #{peps.name.get}.")
          peps.setMultiplier(occ_multiplier)
          # update hash and change name
          change_name(peps, occ_multiplier)
          altered_people_objects << peps.handle.to_s
        else
          runner.registerInfo("Skipping change to #{peps.name.get}")
        end
      end

      # modify infiltration
      space_type.spaceInfiltrationDesignFlowRates.each do |infiltration|
        if !altered_infiltration_objects.include? infiltration.handle.to_s
          if infiltration.flowperExteriorSurfaceArea.is_initialized
            runner.registerInfo("Applying #{infil_multiplier}x Multiplier to #{infiltration.name.get} FlowperExteriorSurfaceArea.")
            infiltration.setFlowperExteriorSurfaceArea(infiltration.flowperExteriorSurfaceArea.get * infil_multiplier)
          end
          if infiltration.airChangesperHour.is_initialized
            runner.registerInfo("Applying #{infil_multiplier}x Multiplier to #{infiltration.name.get} AirChangesperHour.")
            infiltration.setAirChangesperHour(infiltration.airChangesperHour.get * infil_multiplier)
          end
          if infiltration.designFlowRate.is_initialized
            runner.registerInfo("Applying #{infil_multiplier}x Multiplier to #{infiltration.name.get} designFlowRate.")
            infiltration.setDesignFlowRate(infiltration.designFlowRate.get * infil_multiplier)
          end
          if infiltration.flowperSpaceFloorArea.is_initialized
            runner.registerInfo("Applying #{infil_multiplier}x Multiplier to #{infiltration.name.get} flowperSpaceFloorArea.")
            infiltration.setFlowperSpaceFloorArea(infiltration.flowperSpaceFloorArea.get * infil_multiplier)
          end
          if infiltration.flowperExteriorWallArea.is_initialized
            runner.registerInfo("Applying #{infil_multiplier}x Multiplier to #{infiltration.name.get} flowperExteriorWallArea.")
            infiltration.setFlowperExteriorWallArea(infiltration.flowperExteriorWallArea.get * infil_multiplier)
          end
          # add to hash and change name
          change_name(infiltration, infil_multiplier)
          altered_infiltration_objects << infiltration.handle.to_s
        else
          runner.registerInfo("Skipping change to #{infiltration.name.get}")
        end
      end

      # modify outdoor air
      if space_type.designSpecificationOutdoorAir.is_initialized
        outdoor_air = space_type.designSpecificationOutdoorAir.get
        # alter values if not already done
        if !altered_outdoor_air_objects.include? outdoor_air.handle.to_s
          runner.registerInfo("Applying #{vent_multiplier}x Multiplier to #{outdoor_air.name.get} OutdoorAirFlowperPerson.")
          outdoor_air.setOutdoorAirFlowperPerson(outdoor_air.outdoorAirFlowperPerson * vent_multiplier)
          runner.registerInfo("Applying #{vent_multiplier}x Multiplier to #{outdoor_air.name.get} OutdoorAirFlowperFloorArea.")
          outdoor_air.setOutdoorAirFlowperFloorArea(outdoor_air.outdoorAirFlowperFloorArea * vent_multiplier)
          runner.registerInfo("Applying #{vent_multiplier}x Multiplier to #{outdoor_air.name.get} OutdoorAirFlowAirChangesperHour.")
          outdoor_air.setOutdoorAirFlowAirChangesperHour(outdoor_air.outdoorAirFlowAirChangesperHour * vent_multiplier)
          runner.registerInfo("Applying #{vent_multiplier}x Multiplier to #{outdoor_air.name.get} OutdoorAirFlowRate.")
          outdoor_air.setOutdoorAirFlowRate(outdoor_air.outdoorAirFlowRate * vent_multiplier)
          # add to hash and change name
          change_name(outdoor_air, vent_multiplier)
          altered_outdoor_air_objects << outdoor_air.handle.to_s
        else
          runner.registerInfo("Skipping change to #{outdoor_air.name.get}")
        end
      end

      # modify internal mass
      space_type.internalMass.each do |internalmass|
        # get and alter multiplier
        if !altered_internalmass_objects.include? internalmass.handle.to_s
          runner.registerInfo("Applying #{mass_multiplier}x multiplier to #{internalmass.name.get}.")
          internalmass.setMultiplier(mass_multiplier)
          # update hash and change name
          change_name(internalmass, mass_multiplier)
          altered_internalmass_objects << internalmass.handle.to_s
        else
          runner.registerInfo("Skipping change to #{internalmass.name.get}")
        end
      end
    end

    runner.registerInfo("altered_lights_objects: #{altered_lights_objects}")
    runner.registerInfo("altered_luminaires_objects: #{altered_luminaires_objects}")
    runner.registerInfo("altered_electric_equip_objects: #{altered_electric_equip_objects}")
    runner.registerInfo("altered_gas_equip_objects: #{altered_gas_equip_objects}")
    runner.registerInfo("altered_other_equip_objects: #{altered_other_equip_objects}")
    runner.registerInfo("altered_people_objects: #{altered_people_objects}")
    runner.registerInfo("altered_infiltration_objects: #{altered_infiltration_objects}")
    runner.registerInfo("altered_outdoor_air_objects: #{altered_outdoor_air_objects}")
    runner.registerInfo("altered_internalmass_objects: #{altered_internalmass_objects}")

    # report initial condition of model
    runner.registerInfo("Applying Variable Multipliers to #{spaces.size} spaces.")

    # loop through space types
    spaces.each do |space|
      # modify lights
      space.lights.each do |light|
        # get and alter multiplier
        if !altered_lights_objects.include? light.handle.to_s
          runner.registerInfo("Applying #{lights_multiplier}x multiplier to #{light.name.get}.")
          light.setMultiplier(lights_multiplier)
          # update hash and change name
          change_name(light, lights_multiplier)
          altered_lights_objects << light.handle.to_s
        else
          runner.registerInfo("Skipping change to #{light.name.get}")
        end
      end

      # modify luminaire
      space.luminaires.each do |light|
        # get and alter multiplier
        if !altered_luminaires_objects.include? light.handle.to_s
          runner.registerInfo("Applying #{luminaire_multiplier}x multiplier to #{light.name.get}.")
          light.setMultiplier(luminaire_multiplier)
          # update hash and change name
          change_name(light, luminaire_multiplier)
          altered_luminaires_objects << light.handle.to_s
        else
          runner.registerInfo("Skipping change to #{light.name.get}")
        end
      end

      # modify electric equip
      space.electricEquipment.each do |equip|
        # get and alter multiplier
        if !altered_electric_equip_objects.include? equip.handle.to_s
          runner.registerInfo("Applying #{electric_equip_multiplier}x multiplier to #{equip.name.get}.")
          equip.setMultiplier(electric_equip_multiplier)
          # update hash and change name
          change_name(equip, electric_equip_multiplier)
          altered_electric_equip_objects << equip.handle.to_s
        else
          runner.registerInfo("Skipping change to #{equip.name.get}")
        end
      end

      # modify gas equip
      space.gasEquipment.each do |equip|
        # get and alter multiplier
        if !altered_gas_equip_objects.include? equip.handle.to_s
          runner.registerInfo("Applying #{gas_equip_multiplier}x multiplier to #{equip.name.get}.")
          equip.setMultiplier(gas_equip_multiplier)
          # update hash and change name
          change_name(equip, gas_equip_multiplier)
          altered_gas_equip_objects << equip.handle.to_s
        else
          runner.registerInfo("Skipping change to #{equip.name.get}")
        end
      end

      # modify other equip
      space.otherEquipment.each do |equip|
        # get and alter multiplier
        if !altered_other_equip_objects.include? equip.handle.to_s
          runner.registerInfo("Applying #{other_equip_multiplier}x multiplier to #{equip.name.get}.")
          equip.setMultiplier(other_equip_multiplier)
          # update hash and change name
          change_name(equip, other_equip_multiplier)
          altered_other_equip_objects << equip.handle.to_s
        else
          runner.registerInfo("Skipping change to #{equip.name.get}")
        end
      end

      # modify occupancy
      space.people.each do |peps|
        # get and alter multiplier
        if !altered_people_objects.include? peps.handle.to_s
          runner.registerInfo("Applying #{occ_multiplier}x multiplier to #{peps.name.get}.")
          peps.setMultiplier(occ_multiplier)
          # update hash and change name
          change_name(peps, occ_multiplier)
          altered_people_objects << peps.handle.to_s
        else
          runner.registerInfo("Skipping change to #{peps.name.get}")
        end
      end

      # modify infiltration
      space.spaceInfiltrationDesignFlowRates.each do |infiltration|
        if !altered_infiltration_objects.include? infiltration.handle.to_s
          if infiltration.flowperExteriorSurfaceArea.is_initialized
            runner.registerInfo("Applying #{infil_multiplier}x Multiplier to #{infiltration.name.get} FlowperExteriorSurfaceArea.")
            infiltration.setFlowperExteriorSurfaceArea(infiltration.flowperExteriorSurfaceArea.get * infil_multiplier)
          end
          if infiltration.airChangesperHour.is_initialized
            runner.registerInfo("Applying #{infil_multiplier}x Multiplier to #{infiltration.name.get} AirChangesperHour.")
            infiltration.setAirChangesperHour(infiltration.airChangesperHour.get * infil_multiplier)
          end
          if infiltration.designFlowRate.is_initialized
            runner.registerInfo("Applying #{infil_multiplier}x Multiplier to #{infiltration.name.get} designFlowRate.")
            infiltration.setDesignFlowRate(infiltration.designFlowRate.get * infil_multiplier)
          end
          if infiltration.flowperSpaceFloorArea.is_initialized
            runner.registerInfo("Applying #{infil_multiplier}x Multiplier to #{infiltration.name.get} flowperSpaceFloorArea.")
            infiltration.setFlowperSpaceFloorArea(infiltration.flowperSpaceFloorArea.get * infil_multiplier)
          end
          if infiltration.flowperExteriorWallArea.is_initialized
            runner.registerInfo("Applying #{infil_multiplier}x Multiplier to #{infiltration.name.get} flowperExteriorWallArea.")
            infiltration.setFlowperExteriorWallArea(infiltration.flowperExteriorWallArea.get * infil_multiplier)
          end
          # add to hash and change name
          change_name(infiltration, infil_multiplier)
          altered_infiltration_objects << infiltration.handle.to_s
        else
          runner.registerInfo("Skipping change to #{infiltration.name.get}")
        end
      end

      # modify outdoor air
      if space.designSpecificationOutdoorAir.is_initialized
        outdoor_air = space.designSpecificationOutdoorAir.get
        # alter values if not already done
        if !altered_outdoor_air_objects.include? outdoor_air.handle.to_s
          runner.registerInfo("Applying #{vent_multiplier}x Multiplier to #{outdoor_air.name.get} OutdoorAirFlowperPerson.")
          outdoor_air.setOutdoorAirFlowperPerson(outdoor_air.outdoorAirFlowperPerson * vent_multiplier)
          runner.registerInfo("Applying #{vent_multiplier}x Multiplier to #{outdoor_air.name.get} OutdoorAirFlowperFloorArea.")
          outdoor_air.setOutdoorAirFlowperFloorArea(outdoor_air.outdoorAirFlowperFloorArea * vent_multiplier)
          runner.registerInfo("Applying #{vent_multiplier}x Multiplier to #{outdoor_air.name.get} OutdoorAirFlowAirChangesperHour.")
          outdoor_air.setOutdoorAirFlowAirChangesperHour(outdoor_air.outdoorAirFlowAirChangesperHour * vent_multiplier)
          runner.registerInfo("Applying #{vent_multiplier}x Multiplier to #{outdoor_air.name.get} OutdoorAirFlowRate.")
          outdoor_air.setOutdoorAirFlowRate(outdoor_air.outdoorAirFlowRate * vent_multiplier)
          # add to hash and change name
          change_name(outdoor_air, vent_multiplier)
          altered_outdoor_air_objects << outdoor_air.handle.to_s
        else
          runner.registerInfo("Skipping change to #{outdoor_air.name.get}")
        end
      end

      # modify internal mass
      space.internalMass.each do |internalmass|
        # get and alter multiplier
        if !altered_internalmass_objects.include? internalmass.handle.to_s
          runner.registerInfo("Applying #{mass_multiplier}x multiplier to #{internalmass.name.get}.")
          internalmass.setMultiplier(mass_multiplier)
          # update hash and change name
          change_name(internalmass, mass_multiplier)
          altered_internalmass_objects << internalmass.handle.to_s
        else
          runner.registerInfo("Skipping change to #{internalmass.name.get}")
        end
      end
    end

    runner.registerInfo("altered_lights_objects: #{altered_lights_objects}")
    runner.registerInfo("altered_luminaires_objects: #{altered_luminaires_objects}")
    runner.registerInfo("altered_electric_equip_objects: #{altered_electric_equip_objects}")
    runner.registerInfo("altered_gas_equip_objects: #{altered_gas_equip_objects}")
    runner.registerInfo("altered_other_equip_objects: #{altered_other_equip_objects}")
    runner.registerInfo("altered_people_objects: #{altered_people_objects}")
    runner.registerInfo("altered_infiltration_objects: #{altered_infiltration_objects}")
    runner.registerInfo("altered_outdoor_air_objects: #{altered_outdoor_air_objects}")
    runner.registerInfo("altered_internalmass_objects: #{altered_internalmass_objects}")

    # na if nothing in model to look at
    if altered_lights_objects.size + altered_luminaires_objects.size + altered_electric_equip_objects.size + altered_gas_equip_objects.size + altered_other_equip_objects.size + altered_people_objects.size + altered_infiltration_objects.size + altered_outdoor_air_objects.size + altered_internalmass_objects.size == 0
      runner.registerAsNotApplicable('No objects to alter were found in the model')
      return true
    end

    # report final condition of model
    runner.registerFinalCondition("#{altered_lights_objects.size} light objects were altered. #{altered_luminaires_objects.size} luminaire objects were altered. #{altered_electric_equip_objects.size} electric Equipment objects were altered. #{altered_gas_equip_objects.size} gas Equipment objects were altered. #{altered_other_equip_objects.size} otherEquipment objects were altered. #{altered_people_objects.size} people objects were altered. #{altered_infiltration_objects.size} infiltration objects were altered. #{altered_outdoor_air_objects.size} ventilation objects were altered. #{altered_internalmass_objects.size} internal mass objects were altered.")

    true
  end
end

# register the measure to be used by the application
GeneralCalibrationMeasureMultiplier.new.registerWithApplication
