# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# start the measure
class HardSizeHVAC < OpenStudio::Measure::ModelMeasure
  require 'openstudio-standards'

  # human readable name
  def name
    'Hard Size HVAC'
  end

  # human readable description
  def description
    'Run a simulation to autosize HVAC equipment and then apply these autosized values back to the model.'
  end

  # human readable description of modeling approach
  def modeler_description
    'Run a simulation to autosize HVAC equipment and then apply these autosized values back to the model.'
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # Make the standard applier
    standard = Standard.build('90.1-2004') # template choice doesn't matter

    # Perform a sizing run (2.5.1 and later)
    sizing_run_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/SR1').to_s
    runner.registerInfo("Performing sizing run at #{sizing_run_path}.")
    if standard.model_run_sizing_run(model, sizing_run_path) == false
      return false
    end

    # Hard sizing every object in the model.
    model.applySizingValues

    # Log the openstudio-standards messages to the runner
    log_messages_to_runner(runner, false)

    true
  end
end

# register the measure to be used by the application
HardSizeHVAC.new.registerWithApplication
