# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2022, Alliance for Sustainable Energy, LLC.
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
class ExteriorWallThermalPropertiesPercentChange < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    'Exterior Wall Thermal Percent Change'
  end

  # human readable description
  def description
    'Change exterior walls by altering the thermal resistance, density, and solar absorptance of the wall constructions by a Percent Change'
  end

  # human readable description of modeling approach
  def modeler_description
    'Change exterior walls by altering the thermal resistance, density, and solar absorptance of the wall constructions by a Percent Change'
  end

  # short def to make numbers pretty (converts 4125001.25641 to 4,125,001.26 or 4,125,001). The definition be called through this measure
  def neat_numbers(number, roundto = 2) # round to 0 or 2)
    number = if roundto == 2
               format '%.2f', number
             else
               number.round
             end
    # regex to add commas
    number.to_s.reverse.gsub(/([0-9]{3}(?=([0-9])))/, '\\1,').reverse
  end # end def neat_numbers

  # helper to make it easier to do unit conversions on the fly
  def unit_helper(number, from_unit_string, to_unit_string)
    OpenStudio.convert(OpenStudio::Quantity.new(number, OpenStudio.createUnit(from_unit_string).get), OpenStudio.createUnit(to_unit_string).get).get.value
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument insulation R-value
    r_value_perc_change = OpenStudio::Measure::OSArgument.makeDoubleArgument('r_value_perc_change', true)
    r_value_perc_change.setDisplayName('Exterior wall total R-value Percentage Change')
    r_value_perc_change.setDefaultValue(0)
    args << r_value_perc_change

    solar_abs_perc_change = OpenStudio::Measure::OSArgument.makeDoubleArgument('solar_abs_perc_change', true)
    solar_abs_perc_change.setDisplayName('Exterior wall solar absorptance Percentage Change')
    solar_abs_perc_change.setDefaultValue(0)
    args << solar_abs_perc_change

    thermal_mass_perc_change = OpenStudio::Measure::OSArgument.makeDoubleArgument('thermal_mass_perc_change', true)
    thermal_mass_perc_change.setDisplayName('Exterior wall thermal mass Percentage Change')
    thermal_mass_perc_change.setDefaultValue(0)
    args << thermal_mass_perc_change

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
    r_value_perc_change = runner.getDoubleArgumentValue('r_value_perc_change', user_arguments)
    solar_abs_perc_change = runner.getDoubleArgumentValue('solar_abs_perc_change', user_arguments)
    thermal_mass_perc_change = runner.getDoubleArgumentValue('thermal_mass_perc_change', user_arguments)

    # create an array of exterior surfaces and construction types
    surfaces = model.getSurfaces
    exterior_surfaces = []
    exterior_surface_constructions = []
    surfaces.each do |surface|
      next unless surface.outsideBoundaryCondition == 'Outdoors' && surface.surfaceType == 'Wall'
      exterior_surfaces << surface
      exterior_surface_const = surface.construction.get
      # only add construction if it hasn't been added yet
      unless exterior_surface_constructions.include?(exterior_surface_const)
        exterior_surface_constructions << exterior_surface_const.to_Construction.get
      end
    end

    # nothing will be done if there are no exterior surfaces
    if exterior_surfaces.empty?
      runner.registerAsNotApplicable('Model does not have any exterior walls.')
      return true
    end

    # get initial number of surfaces having each construction type
    initial_condition_string = 'Initial number of surfaces of each construction type: '
    exterior_surface_construction_numbers = []
    exterior_surface_constructions.each_with_index do |construction, index|
      exterior_surface_construction_numbers[index] = 0
      initial_condition_string << "'#{construction.name}': "
      exterior_surfaces.each do |surface|
        exterior_surface_construction_numbers[index] += 1 if surface.construction.get.handle.to_s == construction.handle.to_s
      end
      initial_condition_string << "#{exterior_surface_construction_numbers[index]}, "
    end

    runner.registerInitialCondition(initial_condition_string)

    # get initial sets of construction layers and desired values
    initial_layers = []
    initial_r_val = []
    initial_sol_abs = []
    initial_thm_mass = []
    initial_r_val_d = []
    initial_sol_abs_d = []
    initial_thm_mass_d = []
    exterior_surface_constructions.each_with_index do |_construction, con_index|
      initial_layers[con_index] = exterior_surface_constructions[con_index].layers
      initial_sol_abs[con_index] = initial_layers[con_index][0].to_StandardOpaqueMaterial.get.solarAbsorptance
      initial_r_val[con_index] = []
      initial_thm_mass[con_index] = []
      initial_sol_abs_d[con_index] = neat_numbers(initial_layers[con_index][0].to_StandardOpaqueMaterial.get.solarAbsorptance)
      initial_r_val_d[con_index] = []
      initial_thm_mass_d[con_index] = []
      initial_layers[con_index].each_with_index do |layer, lay_index|
        initial_r_val[con_index][lay_index] = initial_layers[con_index][lay_index].to_OpaqueMaterial.get.thermalResistance
        initial_thm_mass[con_index][lay_index] = initial_layers[con_index][lay_index].to_StandardOpaqueMaterial.get.density if layer.to_StandardOpaqueMaterial.is_initialized
        initial_r_val_d[con_index][lay_index] = neat_numbers(initial_layers[con_index][lay_index].to_OpaqueMaterial.get.thermalResistance) if layer.to_OpaqueMaterial.is_initialized
        initial_thm_mass_d[con_index][lay_index] = neat_numbers(initial_layers[con_index][lay_index].to_StandardOpaqueMaterial.get.density) if layer.to_StandardOpaqueMaterial.is_initialized
      end
    end
    initial_r_val_units = 'm^2*K/W'
    initial_thm_mass_units = 'kg/m3'

    # calculate desired values for each construction and layer
    desired_r_val = []
    desired_sol_abs = []
    desired_thm_mass = []
    initial_r_val.each_index do |index1|
      desired_r_val[index1] = []
      initial_r_val[index1].each_index do |index2|
        desired_r_val[index1][index2] = initial_r_val[index1][index2] + initial_r_val[index1][index2] * r_value_perc_change * 0.01 if initial_r_val[index1][index2]
      end
    end
    initial_sol_abs.each_index do |index1|
      next unless initial_sol_abs[index1]
      desired_sol_abs[index1] = initial_sol_abs[index1] + initial_sol_abs[index1] * solar_abs_perc_change * 0.01
      if desired_sol_abs[index1] > 1
        desired_sol_abs[index1] = 1
        runner.registerWarning("Initial solar absorptance of '#{initial_layers[index1][0].name}' was #{initial_sol_abs[index1]}. A Percent Change of #{solar_abs_perc_change} results in a number greater than 1, which is outside the allowed range. The value is instead being set to #{desired_sol_abs[index1]}")
      elsif desired_sol_abs[index1] < 0
        desired_sol_abs[index1] = 0
        runner.registerWarning("Initial solar absorptance of '#{initial_layers[index1][0].name}' was #{initial_sol_abs[index1]}. A Percent Change of #{solar_abs_perc_change} results in a number less than 0, which is outside the allowed range. The value is instead being set to #{desired_sol_abs[index1]}")
      end
    end
    initial_thm_mass.each_index do |index1|
      desired_thm_mass[index1] = []
      initial_thm_mass[index1].each_index do |index2|
        desired_thm_mass[index1][index2] = initial_thm_mass[index1][index2] + initial_thm_mass[index1][index2] * thermal_mass_perc_change * 0.01 if initial_thm_mass[index1][index2]
      end
    end

    # initalize final values arrays
    final_construction = []
    final_r_val = []
    final_sol_abs = []
    final_thm_mass = []
    final_r_val_d = []
    final_sol_abs_d = []
    final_thm_mass_d = []
    initial_r_val.each_with_index { |_, index| final_r_val[index] = [] }
    initial_thm_mass.each_with_index { |_, index| final_thm_mass[index] = [] }
    initial_r_val_d.each_with_index { |_, index| final_r_val_d[index] = [] }
    initial_thm_mass_d.each_with_index { |_, index| final_thm_mass_d[index] = [] }

    # replace exterior surface wall constructions
    exterior_surface_constructions.each_with_index do |construction, con_index|
      # create and name new construction
      new_construction = construction.clone
      new_construction = new_construction.to_Construction.get
      new_construction.setName("#{construction.name} (R #{r_value_perc_change.round(1)} Solar #{solar_abs_perc_change.round(1)} Therm #{thermal_mass_perc_change.round(1)} Percent Change)")
      # replace layers in new construction
      new_construction.layers.each_with_index do |layer, lay_index|
        new_layer = layer.clone
        new_layer = new_layer.to_Material.get
        # update thermal properties for the layer based on desired arrays
        new_layer.to_StandardOpaqueMaterial.get.setSolarAbsorptance(desired_sol_abs[con_index]) if lay_index == 0 && layer.to_StandardOpaqueMaterial.is_initialized # only apply to outer surface
        new_layer.to_OpaqueMaterial.get.setThermalResistance(desired_r_val[con_index][lay_index]) if layer.to_OpaqueMaterial.is_initialized
        new_layer.to_StandardOpaqueMaterial.get.setDensity(desired_thm_mass[con_index][lay_index]) if layer.to_StandardOpaqueMaterial.is_initialized && desired_thm_mass[con_index][lay_index] != 0
        new_layer.setName("#{layer.name} (R #{r_value_perc_change.round(1)} Solar #{solar_abs_perc_change.round(1)} Therm #{thermal_mass_perc_change.round(1)} Percent Change)")
        new_construction.setLayer(lay_index, new_layer)
        # calculate properties of new layer and output nice names
        final_r_val[con_index][lay_index] = new_construction.layers[lay_index].to_OpaqueMaterial.get.thermalResistance if layer.to_OpaqueMaterial.is_initialized
        final_sol_abs[con_index] = new_construction.layers[lay_index].to_StandardOpaqueMaterial.get.solarAbsorptance if lay_index == 0 && layer.to_StandardOpaqueMaterial.is_initialized
        final_thm_mass[con_index][lay_index] = new_construction.layers[lay_index].to_StandardOpaqueMaterial.get.density if layer.to_StandardOpaqueMaterial.is_initialized
        final_r_val_d[con_index][lay_index] = neat_numbers(final_r_val[con_index][lay_index])
        final_sol_abs_d[con_index] = neat_numbers(final_sol_abs[con_index]) if lay_index == 0 && layer.to_StandardOpaqueMaterial.is_initialized
        final_thm_mass_d[con_index][lay_index] = neat_numbers(final_thm_mass[con_index][lay_index]) if layer.to_StandardOpaqueMaterial.is_initialized
        runner.registerInfo("Updated material '#{layer.name}' in construction '#{new_construction.name}' to '#{new_layer.name}' as follows:")
        final_r_val[con_index][lay_index] ? runner.registerInfo("R-Value updated from #{initial_r_val_d[con_index][lay_index]} to #{final_r_val_d[con_index][lay_index]} (#{((final_r_val[con_index][lay_index] - initial_r_val[con_index][lay_index]) / initial_r_val[con_index][lay_index] * 100).round(2)} percent change)") : runner.registerInfo("R-Value was #{initial_r_val_d[con_index][lay_index]} and now is nil_value")
        final_thm_mass[con_index][lay_index] ? runner.registerInfo("Thermal Mass updated from #{initial_thm_mass_d[con_index][lay_index]} to #{final_thm_mass_d[con_index][lay_index]} (#{((final_thm_mass[con_index][lay_index] - initial_thm_mass[con_index][lay_index]) / initial_thm_mass[con_index][lay_index] * 100).round(2)} percent change)") : runner.registerInfo("Thermal Mass was #{initial_thm_mass[con_index][lay_index]} and now is nil_value")
        if lay_index == 0
          final_sol_abs[con_index] ? runner.registerInfo("Solar Absorptance updated from #{initial_sol_abs_d[con_index]} to #{final_sol_abs_d[con_index]} (#{((final_sol_abs[con_index] - initial_sol_abs[con_index]) / initial_sol_abs[con_index] * 100).round(2)} percent change)") : runner.registerInfo("Solar Absorptance was #{initial_sol_abs[con_index][lay_index]} and now is nil_value")
        end
      end
      final_construction[con_index] = new_construction
      # update surfaces with construction = construction to new_construction
      exterior_surfaces.each do |surface|
        surface.setConstruction(new_construction) if surface.construction.get.handle.to_s == construction.handle.to_s
      end
      runner.registerInfo("Using New Construction #{new_construction.name}")
    end

    # report desired condition
    runner.registerFinalCondition("Applied R #{r_value_perc_change.round(1)} Solar #{solar_abs_perc_change.round(1)} Therm #{thermal_mass_perc_change.round(1)} Percent change")

    true
  end # end the run method
end # end the measure

# this allows the measure to be used by the application
ExteriorWallThermalPropertiesPercentChange.new.registerWithApplication
