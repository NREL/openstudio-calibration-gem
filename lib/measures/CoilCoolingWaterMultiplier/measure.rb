# start the measure
class CoilCoolingWaterMultiplier < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Cooling Coils Water Multiplier"
  end

  # human readable description
  def description
    return "This is a general purpose measure to calibrate Water Cooling Coils with a Multiplier."
  end

  # human readable description of modeling approach
  def modeler_description
    return "It will be used for calibration of inlet water temperatures, inlet and outlet air temperatures and design flowrates. User can choose between a SINGLE coil or ALL the Coils."
  end
  
  def change_name(object,design_water_flow_rate,design_air_flow_rate,design_inlet_water_temperature,design_inlet_air_temperature,design_outlet_air_temperature,design_inlet_air_humidity_ratio)
    nameString = "#{object.name.get}"
    if design_water_flow_rate != 1.0
      nameString = nameString + " #{design_water_flow_rate.round(2)}x waterDFR"
    end
    if design_air_flow_rate != 1.0
      nameString = nameString + " #{design_air_flow_rate.round(2)}x airDFR"
    end
    if design_inlet_water_temperature != 1.0
      nameString = nameString + " #{design_inlet_water_temperature.round(2)}x DIWT"
    end
    if design_inlet_air_temperature != 1.0
      nameString = nameString + " #{design_inlet_air_temperature.round(2)}x DIAT"
    end
    if design_outlet_air_temperature != 1.0
      nameString = nameString + " #{design_outlet_air_temperature.round(2)}x DOAT"
    end
    if design_inlet_air_humidity_ratio != 1.0
      nameString = nameString + " #{design_inlet_air_humidity_ratio.round(2)}x DIAHR"
    end
    object.setName(nameString)
  end
  
  def check_multiplier(runner, multiplier)
    if multiplier < 0
      runner.registerError("Multiplier #{multiplier} cannot be negative.")
      return false
    end
  end
  
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #populate choice argument for constructions that are applied to surfaces in the model
    loop_handles = OpenStudio::StringVector.new
    loop_display_names = OpenStudio::StringVector.new

    #putting air loops and names into hash
    loop_args = model.getAirLoopHVACs
    loop_args_hash = {}
    loop_args.each do |loop_arg|
      loop_args_hash[loop_arg.name.to_s] = loop_arg
    end

    #looping through sorted hash of air loops
    loop_args_hash.sort.map do |key,value|
      show_loop = false
      components = value.supplyComponents
      components.each do |component|
        if not component.to_CoilCoolingWater.empty?
          show_loop = true
          loop_handles << component.handle.to_s
          loop_display_names << component.name.to_s
        end
      end

      #if loop as object of correct type then add to hash.
      # if show_loop == true
        # loop_handles << value.handle.to_s
        # loop_display_names << key
      # end
    end

    #add building to string vector with space type
    building = model.getBuilding
    loop_handles << building.handle.to_s
    loop_display_names << "*All Water Cooling Coils*"
    loop_handles << "0"
    loop_display_names << "*None*"

    #make a choice argument for space type
    coil_arg = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("coil", loop_handles, loop_display_names)
    coil_arg.setDisplayName("Apply the Measure to a SINGLE Water Cooling Coil, ALL the Water Cooling Coils or NONE.")
    coil_arg.setDefaultValue("*All Water Cooling Coils*") #if no space type is chosen this will run on the entire building
    args << coil_arg
    
    # design_water_flow_rate
    design_water_flow_rate = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("design_water_flow_rate", true)
    design_water_flow_rate.setDisplayName("Multiplier for Design Water Flow Rate.")
    design_water_flow_rate.setDescription("Multiplier for Design Water Flow Rate.")
    design_water_flow_rate.setDefaultValue(1.0)
    args << design_water_flow_rate
    
    # design_air_flow_rate
    design_air_flow_rate = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("design_air_flow_rate", true)
    design_air_flow_rate.setDisplayName("Multiplier for Design Air Flow Rate.")
    design_air_flow_rate.setDescription("Multiplier for Design Air Flow Rate.")
    design_air_flow_rate.setDefaultValue(1.0)
    args << design_air_flow_rate   

    # design_inlet_water_temperature
    design_inlet_water_temperature = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("design_inlet_water_temperature", true)
    design_inlet_water_temperature.setDisplayName("Multiplier for Inlet Water Temperature.")
    design_inlet_water_temperature.setDescription("Multiplier for Inlet Water Temperature.")
    design_inlet_water_temperature.setDefaultValue(1.0)
    args << design_inlet_water_temperature
    
    # design_inlet_air_temperature
    design_inlet_air_temperature = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("design_inlet_air_temperature", true)
    design_inlet_air_temperature.setDisplayName("Multiplier for Inlet Air Temperature.")
    design_inlet_air_temperature.setDescription("Multiplier for Inlet Air Temperature.")
    design_inlet_air_temperature.setDefaultValue(1.0)
    args << design_inlet_air_temperature 

    # design_outlet_air_temperature
    design_outlet_air_temperature = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("design_outlet_air_temperature", true)
    design_outlet_air_temperature.setDisplayName("Multiplier for Outlet Air Temperature.")
    design_outlet_air_temperature.setDescription("Multiplier for Outlet Air Temperature.")
    design_outlet_air_temperature.setDefaultValue(1.0)
    args << design_outlet_air_temperature
    
    # design_inlet_air_humidity_ratio
    design_inlet_air_humidity_ratio = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("design_inlet_air_humidity_ratio", true)
    design_inlet_air_humidity_ratio.setDisplayName("Multiplier for Inlet Air Humidity Ratio.")
    design_inlet_air_humidity_ratio.setDescription("Multiplier for Inlet Air Humidity Ratio.")
    design_inlet_air_humidity_ratio.setDefaultValue(1.0)
    args << design_inlet_air_humidity_ratio     
    
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
    coil_object = runner.getOptionalWorkspaceObjectChoiceValue("coil",user_arguments,model)
    coil_handle = runner.getStringArgumentValue("coil",user_arguments)

    design_air_flow_rate = runner.getDoubleArgumentValue("design_air_flow_rate",user_arguments)
    check_multiplier(runner, design_air_flow_rate)
    design_water_flow_rate = runner.getDoubleArgumentValue("design_water_flow_rate",user_arguments)
    check_multiplier(runner, design_water_flow_rate)
    design_inlet_air_temperature = runner.getDoubleArgumentValue("design_inlet_air_temperature",user_arguments)
    check_multiplier(runner, design_inlet_air_temperature)
    design_outlet_air_temperature = runner.getDoubleArgumentValue("design_outlet_air_temperature",user_arguments)
    check_multiplier(runner, design_outlet_air_temperature)
    design_inlet_air_humidity_ratio = runner.getDoubleArgumentValue("design_inlet_air_humidity_ratio",user_arguments)
    check_multiplier(runner, design_inlet_air_humidity_ratio)
    design_inlet_water_temperature = runner.getDoubleArgumentValue("design_inlet_water_temperature",user_arguments)
    check_multiplier(runner, design_inlet_water_temperature)
    
    #find objects to change
    coils = []
    building = model.getBuilding
    building_handle = building.handle.to_s
    runner.registerInfo("coil_handle: #{coil_handle}")
    #setup coils
    if coil_handle == building_handle
      #Use ALL coils
      runner.registerInfo("Applying change to ALL Coils")
      loops = model.getAirLoopHVACs
      #loop through air loops
      loops.each do |loop|
        supply_components = loop.supplyComponents
        #find coils on loops
        supply_components.each do |supply_component|
          if not supply_component.to_CoilCoolingWater.empty?
            coils << supply_component.to_CoilCoolingWater.get
          end
        end   
      end      
    elsif coil_handle == 0.to_s
      #coils set to NONE so do nothing
      runner.registerInfo("Applying change to NONE Coils")
    elsif not coil_handle.empty?
      #Single coil handle found, check if object is good    
      if not coil_object.get.to_CoilCoolingWater.empty?
        runner.registerInfo("Applying change to #{coil_object.get.name.to_s} coil")
        coils << coil_object.get.to_CoilCoolingWater.get
      else
        runner.registerError("coil with handle #{coil_handle} could not be found.")
      end
    else
      runner.registerError("coil handle is empty.")
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
      # design_air_flow_rate
      if design_air_flow_rate != 1.0
        if coil.designAirFlowRate.is_initialized
          runner.registerInfo("Applying designAirFlowRate #{design_air_flow_rate}x multiplier to #{coil.name.get}.")
          coil.setDesignAirFlowRate(coil.designAirFlowRate.get * design_air_flow_rate)          
          altered_capacity << coil.handle.to_s
          altered_coil = true
        end
      end
      
      # modify design_water_flow_rate
      if design_water_flow_rate != 1.0
        if coil.designWaterFlowRate.is_initialized
          runner.registerInfo("Applying designWaterFlowRate #{design_water_flow_rate}x multiplier to #{coil.name.get}.")
          coil.setDesignWaterFlowRate(coil.designWaterFlowRate.get * design_water_flow_rate)         
          altered_coilefficiency << coil.handle.to_s
          altered_coil = true
        end
      end
      
       # design_inlet_air_temperature
      if design_inlet_air_temperature != 1.0
        if coil.designInletAirTemperature.is_initialized
          runner.registerInfo("Applying designInletAirTemperature #{design_inlet_air_temperature}x multiplier to #{coil.name.get}.")
          coil.setDesignInletAirTemperature(coil.designInletAirTemperature.get * design_inlet_air_temperature)          
          altered_capacity << coil.handle.to_s
          altered_coil = true
        end
      end
      
      # modify design_inlet_water_temperature
      if design_inlet_water_temperature != 1.0
        if coil.designInletWaterTemperature.is_initialized
          runner.registerInfo("Applying designInletWaterTemperature #{design_inlet_water_temperature}x multiplier to #{coil.name.get}.")
          coil.setDesignInletWaterTemperature(coil.designInletWaterTemperature.get * design_inlet_water_temperature)         
          altered_coilefficiency << coil.handle.to_s
          altered_coil = true
        end
      end
      
      # design_inlet_air_humidity_ratio
      if design_inlet_air_humidity_ratio != 1.0
        if coil.designInletAirHumidityRatio.is_initialized
          runner.registerInfo("Applying designInletAirHumidityRatio #{design_inlet_air_humidity_ratio}x multiplier to #{coil.name.get}.")
          coil.setDesignInletAirHumidityRatio(coil.designInletAirHumidityRatio.get * design_inlet_air_humidity_ratio)          
          altered_capacity << coil.handle.to_s
          altered_coil = true
        end
      end
      
      # modify design_outlet_air_temperature
      if design_outlet_air_temperature != 1.0
        if coil.designOutletAirTemperature.is_initialized
          runner.registerInfo("Applying designOutletAirTemperature #{design_outlet_air_temperature}x multiplier to #{coil.name.get}.")
          coil.setDesignOutletAirTemperature(coil.designOutletAirTemperature.get * design_outlet_air_temperature)         
          altered_coilefficiency << coil.handle.to_s
          altered_coil = true
        end
      end      
      if altered_coil
        altered_coils << coil.handle.to_s
        change_name(coil,design_water_flow_rate,design_air_flow_rate,design_inlet_water_temperature,design_inlet_air_temperature,design_outlet_air_temperature,design_inlet_air_humidity_ratio)
        runner.registerInfo("coil name changed to: #{coil.name.get}")
      end
    end #end coil loop
    
    # na if nothing in model to look at
    if altered_coils.size == 0
      runner.registerAsNotApplicable("No Coils were altered in the model")
      return true
    end

    # report final condition of model
    runner.registerFinalCondition("#{altered_coils.size} Coils objects were altered.")

    return true

  end

end

# register the measure to be used by the application
CoilCoolingWaterMultiplier.new.registerWithApplication
