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
class RValueOfInsulationForConstructionMultiplier < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    'Change R-value of Insulation Layer for Construction By a Multiplier'
  end

  # human readable description
  def description
    'Change R-value of Insulation Layer for Construction By a Multiplier'
  end

  # human readable description of modeling approach
  def modeler_description
    'Change R-value of Insulation Layer for Construction By a Multiplier'
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

    # make an argument insulation R-value
    r_value_multplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('r_value_multplier', true)
    r_value_multplier.setDisplayName('Multiplier for R-value for Insulation Layer of Construction.')
    r_value_multplier.setDefaultValue(1.0)
    args << r_value_multplier

    args
  end # end the arguments method

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    unless runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    construction = runner.getOptionalWorkspaceObjectChoiceValue('construction', user_arguments, model) # model is passed in because of argument type
    r_value_multplier = runner.getDoubleArgumentValue('r_value_multplier', user_arguments)
    check_multiplier(runner, r_value_multplier)
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
    end # end of if construction.empty?

    # set limit for minimum insulation. This is used to limit input and for inferring insulation layer in construction.
    min_expected_r_value_multplier_ip = 1 # ip units

    # report initial condition
    initial_r_value_ip = OpenStudio.convert(1.0 / construction.thermalConductance.to_f, 'm^2*K/W', 'ft^2*h*R/Btu')
    runner.registerInitialCondition("The Initial R-value of #{construction.name} is #{initial_r_value_ip} (ft^2*h*R/Btu).")
    runner.registerValue('initial_r_value_ip', initial_r_value_ip.to_f, 'ft^2*h*R/Btu')

    # TODO: - find and test insulation
    construction_layers = construction.layers
    max_thermal_resistance_material = construction_layers[0]
    max_thermal_resistance_material_index = 0
    counter = 0
    thermal_resistance_values = []

    # loop through construction layers and infer insulation layer/material
    construction_layers.each do |construction_layer|
      construction_layer_r_value = construction_layer.to_OpaqueMaterial.get.thermalResistance
      unless thermal_resistance_values.empty?
        if construction_layer_r_value > thermal_resistance_values.max
          max_thermal_resistance_material = construction_layer
          max_thermal_resistance_material_index = counter
        end
      end
      thermal_resistance_values << construction_layer_r_value
      counter += 1
    end
    if thermal_resistance_values.max <= OpenStudio.convert(min_expected_r_value_multplier_ip, 'ft^2*h*R/Btu', 'm^2*K/W').get
      runner.registerAsNotApplicable("Construction '#{construction.name}' does not appear to have an insulation layer and was not altered.")
      return true
    end

    # clone insulation material
    new_material = max_thermal_resistance_material.clone(model)
    new_material = new_material.to_OpaqueMaterial.get
    new_material.setName("#{max_thermal_resistance_material.name} (R #{r_value_multplier.round(2)}x Multiplier)") if r_value_multplier != 1
    construction.eraseLayer(max_thermal_resistance_material_index)
    construction.insertLayer(max_thermal_resistance_material_index, new_material)
    runner.registerInfo("For construction'#{construction.name}', '#{max_thermal_resistance_material.name}' was altered.")

    # edit clone material
    new_material_matt = new_material.to_Material
    unless new_material_matt.empty?
      starting_thickness = new_material_matt.get.thickness
      target_thickness = starting_thickness * r_value_multplier
      final_thickness = new_material_matt.get.setThickness(target_thickness)
    end
    new_material_massless = new_material.to_MasslessOpaqueMaterial
    unless new_material_massless.empty?
      starting_thermal_resistance = new_material_massless.get.thermalResistance
      final_thermal_resistance = new_material_massless.get.setThermalResistance(starting_thermal_resistance * r_value_multplier)
    end
    new_material_airgap = new_material.to_AirGap
    unless new_material_airgap.empty?
      starting_thermal_resistance = new_material_airgap.get.thermalResistance
      final_thermal_resistance = new_material_airgap.get.setThermalResistance(starting_thermal_resistance * r_value_multplier)
    end

    # report initial condition
    final_r_value_ip = OpenStudio.convert(1 / construction.thermalConductance.to_f, 'm^2*K/W', 'ft^2*h*R/Btu')
    runner.registerFinalCondition("The Final R-value of #{construction.name} is #{final_r_value_ip} (ft^2*h*R/Btu).")
    runner.registerValue('final_r_value_ip', final_r_value_ip.to_f, 'ft^2*h*R/Btu')
    true
  end # end the run method
end # end the measure

# this allows the measure to be used by the application
RValueOfInsulationForConstructionMultiplier.new.registerWithApplication
