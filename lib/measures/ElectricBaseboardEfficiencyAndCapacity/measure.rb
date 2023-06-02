# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class ElectricBaseboardEfficiencyAndCapacity < OpenStudio::Measure::ModelMeasure
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
    args = OpenStudio::Measure::OSArgumentVector.new

    # efficiency
    base_eff = OpenStudio::Measure::OSArgument.makeDoubleArgument('base_eff', true)
    base_eff.setDisplayName('efficiency')
    base_eff.setDefaultValue(1.0)
    args << base_eff

    # capacity
    nom_cap = OpenStudio::Measure::OSArgument.makeDoubleArgument('nom_cap', true)
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
