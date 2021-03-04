# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# start the measure
class WaterHeaterMixedPercentChange < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    'Water Heater Mixed Percent Change'
  end

  # human readable description
  def description
    'This is a general purpose measure to calibrate WaterHeaterMixed with a Percent Change.'
  end

  # human readable description of modeling approach
  def modeler_description
    'It will be used for calibration of WaterHeaterMixed. User can choose between a SINGLE WaterHeaterMixed or ALL the WaterHeaterMixed objects.'
  end

  def change_name(object, maximum_capacity_multiplier, minimum_capacity_multiplier, thermal_efficiency_multiplier, fuel_type, orig_fuel_type)
    nameString = object.name.get.to_s
    if maximum_capacity_multiplier != 0.0
      nameString += " #{maximum_capacity_multiplier.round(2)}x maxCap"
    end
    if minimum_capacity_multiplier != 0.0
      nameString += " #{minimum_capacity_multiplier.round(2)}x minCap"
    end
    if thermal_efficiency_multiplier != 0.0
      nameString += " #{thermal_efficiency_multiplier.round(2)}x thermEff"
    end
    nameString += " #{fuel_type} fuel Change" if orig_fuel_type != fuel_type
    object.setName(nameString)
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
    maximum_capacity_multiplier.setDisplayName('Percent Change for Heater Maximum Capacity.')
    maximum_capacity_multiplier.setDescription('Percent Change for Heater Maximum Capacity.')
    maximum_capacity_multiplier.setDefaultValue(0.0)
    maximum_capacity_multiplier.setMinValue(0.0)
    args << maximum_capacity_multiplier

    # minimum_capacity_multiplier
    minimum_capacity_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('minimum_capacity_multiplier', true)
    minimum_capacity_multiplier.setDisplayName('Percent Change for Heater Minimum Capacity.')
    minimum_capacity_multiplier.setDescription('Percent Change for Heater Minimum Capacity.')
    minimum_capacity_multiplier.setDefaultValue(0.0)
    args << minimum_capacity_multiplier

    # thermal_efficiency_multiplier
    thermal_efficiency_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('thermal_efficiency_multiplier', true)
    thermal_efficiency_multiplier.setDisplayName('Percent Change for Thermal Efficiency.')
    thermal_efficiency_multiplier.setDescription('Percent Change for Thermal Efficiency.')
    thermal_efficiency_multiplier.setDefaultValue(0.0)
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
    maximum_capacity_multiplier = runner.getDoubleArgumentValue('maximum_capacity_multiplier', user_arguments)
    minimum_capacity_multiplier = runner.getDoubleArgumentValue('minimum_capacity_multiplier', user_arguments)

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
    runner.registerInitialCondition("Applying Percent Change to #{water_heaters.size} Water Heaters.")

    # loop through space types
    water_heaters.each do |water_heater|
      altered_heater = false
      # modify maximum_capacity_multiplier
      if maximum_capacity_multiplier != 0.0
        if water_heater.heaterMaximumCapacity.is_initialized
          runner.registerInfo("Applying #{maximum_capacity_multiplier}x maximum capacity Percent Change to #{water_heater.name.get}.")
          water_heater.setHeaterMaximumCapacity(water_heater.heaterMaximumCapacity.get + water_heater.heaterMaximumCapacity.get * maximum_capacity_multiplier * 0.01)
          altered_max_cap << water_heater.handle.to_s
          altered_heater = true
        end
      end

      # modify minimum_capacity_multiplier
      if minimum_capacity_multiplier != 0.0
        if water_heater.heaterMinimumCapacity.is_initialized
          runner.registerInfo("Applying #{minimum_capacity_multiplier}x minimum capacity Percent Change to #{water_heater.name.get}.")
          water_heater.setHeaterMaximumCapacity(water_heater.heaterMinimumCapacity.get + water_heater.heaterMinimumCapacity.get * minimum_capacity_multiplier * 0.01)
          altered_min_cap << water_heater.handle.to_s
          altered_heater = true
        end
      end

      # modify thermal_efficiency_multiplier
      if thermal_efficiency_multiplier != 0.0
        if water_heater.heaterThermalEfficiency.is_initialized
          runner.registerInfo("Applying #{thermal_efficiency_multiplier}x thermal efficiency Percent Change to #{water_heater.name.get}.")
          water_heater.setHeaterThermalEfficiency(water_heater.heaterThermalEfficiency.get + water_heater.heaterThermalEfficiency.get * thermal_efficiency_multiplier * 0.01)
          altered_thermalefficiency << water_heater.handle.to_s
          altered_heater = true
        end
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
    end # end water_heater loop

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
WaterHeaterMixedPercentChange.new.registerWithApplication
