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
class CoilHeatingElectricMultiplier < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    'Heating Coils Electric Multiplier'
  end

  # human readable description
  def description
    'This is a general purpose measure to calibrate Electric Heating Coils with a Multiplier.'
  end

  # human readable description of modeling approach
  def modeler_description
    'It will be used for calibration of rated capacity and efficiency and parasitic loads. User can choose between a SINGLE coil or ALL the Coils.'
  end

  def change_name(object, coil_efficiency_multiplier, coil_capacity_multiplier)
    nameString = object.name.get.to_s
    if coil_efficiency_multiplier != 1.0
      nameString += " #{coil_efficiency_multiplier.round(2)}x coilEff"
    end
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
        next if component.to_CoilHeatingGas.empty?
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
    loop_display_names << '*All Electric Heating Coils*'
    loop_handles << '0'
    loop_display_names << '*None*'

    # make a choice argument for space type
    coil_arg = OpenStudio::Measure::OSArgument.makeChoiceArgument('coil', loop_handles, loop_display_names)
    coil_arg.setDisplayName('Apply the Measure to a SINGLE Electric Heating Coil, ALL the Electric Heating Coils or NONE.')
    coil_arg.setDefaultValue('*All Electric Heating Coils*') # if no space type is chosen this will run on the entire building
    args << coil_arg

    # coil_efficiency_multiplier
    coil_efficiency_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('coil_efficiency_multiplier', true)
    coil_efficiency_multiplier.setDisplayName('Multiplier for coil Efficiency.')
    coil_efficiency_multiplier.setDescription('Multiplier for coil Efficiency.')
    coil_efficiency_multiplier.setDefaultValue(1.0)
    args << coil_efficiency_multiplier

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
    coil_efficiency_multiplier = runner.getDoubleArgumentValue('coil_efficiency_multiplier', user_arguments)
    check_multiplier(runner, coil_efficiency_multiplier)

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
          unless supply_component.to_CoilHeatingElectric.empty?
            coils << supply_component.to_CoilHeatingElectric.get
          end
        end
      end
    elsif coil_handle == 0.to_s
      # coils set to NONE so do nothing
      runner.registerInfo('Applying change to NONE Coils')
    elsif !coil_handle.empty?
      # Single coil handle found, check if object is good
      if !coil_object.get.to_CoilHeatingElectric.empty?
        runner.registerInfo("Applying change to #{coil_object.get.name} coil")
        coils << coil_object.get.to_CoilHeatingElectric.get
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
      if coil_capacity_multiplier != 1.0
        if coil.nominalCapacity.is_initialized
          runner.registerInfo("Applying nominalCapacity #{coil_capacity_multiplier}x multiplier to #{coil.name.get}.")
          coil.setNominalCapacity(coil.nominalCapacity.get * coil_capacity_multiplier)
          altered_capacity << coil.handle.to_s
          altered_coil = true
        end
      end

      # modify coil_efficiency_multiplier
      if coil_efficiency_multiplier != 1.0
        runner.registerInfo("Applying efficiency #{coil_efficiency_multiplier}x multiplier to #{coil.name.get}.")
        if coil.efficiency * coil_efficiency_multiplier <= 1
          coil.setEfficiency(coil.efficiency * coil_efficiency_multiplier)
        else
          coil.setEfficiency(1.0)
          runner.registerWarning("#{coil_efficiency_multiplier}x multiplier results in Efficiency greater than 1.")
        end
        altered_coilefficiency << coil.handle.to_s
        altered_coil = true
      end

      next unless altered_coil
      altered_coils << coil.handle.to_s
      change_name(coil, coil_efficiency_multiplier, coil_capacity_multiplier)
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
CoilHeatingElectricMultiplier.new.registerWithApplication
