# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
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

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class ElectricBaseboardEfficiencyAndCapacity < OpenStudio::Ruleset::ModelUserScript
  # human readable name
  def name
    'Electric Baseboard Efficiency And Capacity'
  end

  # human readable description
  def description
    'Electric Baseboard Efficiency And Capacity'
  end

  # human readable description of modeling approach
  def modeler_description
    'Electric Baseboard Efficiency And Capacity'
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # efficiency
    base_eff = OpenStudio::Ruleset::OSArgument.makeDoubleArgument('base_eff', true)
    base_eff.setDisplayName('efficiency')
    base_eff.setDefaultValue(1.0)
    args << base_eff

    # capacity
    nom_cap = OpenStudio::Ruleset::OSArgument.makeDoubleArgument('nom_cap', true)
    nom_cap.setDisplayName('Nominal Capacity (W)')
    nom_cap.setDefaultValue(1500)
    args << nom_cap

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
    base_eff = runner.getDoubleArgumentValue('base_eff', user_arguments)
    nom_cap = runner.getDoubleArgumentValue('nom_cap', user_arguments)

    model.getZoneHVACBaseboardConvectiveElectrics.each do |zone|
      # base_eff = OpenStudio::Double.new(base_eff)
      # nom_cap = OpenStudio::OptionalDouble.new(nom_cap)
      zone.setEfficiency(base_eff)
      zone.setNominalCapacity(nom_cap)
      runner.registerInfo("Changing the base_eff to #{zone.getEfficiency} ")
      runner.registerInfo("Changing the nominal capacity to #{zone.getNominalCapacity} ")
    end

    true
  end
end

# register the measure to be used by the application
ElectricBaseboardEfficiencyAndCapacity.new.registerWithApplication
