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
class FansPercentChange < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    'Fans Percent Change'
  end

  # human readable description
  def description
    'This is a general purpose measure to calibrate Fans with a Percent Change.'
  end

  # human readable description of modeling approach
  def modeler_description
    'It will be used for calibration maximum flow rate, efficiency, pressure rise and motor efficiency. User can choose between a SINGLE Fan or ALL the Fans.'
  end

  def change_name(object, max_flowrate_perc_change, fan_efficiency_perc_change, pressure_rise_perc_change, motor_efficiency_perc_change)
    nameString = object.name.get.to_s
    if max_flowrate_perc_change != 0.0
      nameString += " #{max_flowrate_perc_change.round(2)}percng flow"
    end
    if pressure_rise_perc_change != 0.0
      nameString += " #{pressure_rise_perc_change.round(2)}percng press"
    end
    if fan_efficiency_perc_change != 0.0
      nameString += " #{fan_efficiency_perc_change.round(2)}percng fanEff"
    end
    if motor_efficiency_perc_change != 0.0
      nameString += " #{motor_efficiency_perc_change.round(2)}percng motorEff"
    end
    object.setName(nameString)
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
        unless component.to_FanConstantVolume.empty?
          show_loop = true
          loop_handles << component.handle.to_s
          loop_display_names << component.name.to_s
        end
        unless component.to_FanVariableVolume.empty?
          show_loop = true
          loop_handles << component.handle.to_s
          loop_display_names << component.name.to_s
        end
        next if component.to_FanOnOff.empty?
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
    loop_display_names << '*All Fans*'
    loop_handles << '0'
    loop_display_names << '*None*'

    # make a choice argument for space type
    fan_arg = OpenStudio::Measure::OSArgument.makeChoiceArgument('fan', loop_handles, loop_display_names)
    fan_arg.setDisplayName('Apply the Measure to a SINGLE Fan, ALL the Fans or NONE.')
    fan_arg.setDefaultValue('*All Fans*') # if no space type is chosen this will run on the entire building
    args << fan_arg

    # max_flowrate_perc_change
    max_flowrate_perc_change = OpenStudio::Measure::OSArgument.makeDoubleArgument('max_flowrate_perc_change', true)
    max_flowrate_perc_change.setDisplayName('Percent Change for Maximum FlowRate.')
    max_flowrate_perc_change.setDescription('Percent Change for Maximum FlowRate.')
    max_flowrate_perc_change.setDefaultValue(0.0)
    max_flowrate_perc_change.setMinValue(0.0)
    args << max_flowrate_perc_change

    # fan_efficiency_perc_change
    fan_efficiency_perc_change = OpenStudio::Measure::OSArgument.makeDoubleArgument('fan_efficiency_perc_change', true)
    fan_efficiency_perc_change.setDisplayName('Percent Change for Fan Efficiency.')
    fan_efficiency_perc_change.setDescription('Percent Change for Fan Efficiency.')
    fan_efficiency_perc_change.setDefaultValue(0.0)
    args << fan_efficiency_perc_change

    # pressure_rise_perc_change
    pressure_rise_perc_change = OpenStudio::Measure::OSArgument.makeDoubleArgument('pressure_rise_perc_change', true)
    pressure_rise_perc_change.setDisplayName('Percent Change for Pressure Rise.')
    pressure_rise_perc_change.setDescription('Percent Change for Pressure Rise.')
    pressure_rise_perc_change.setDefaultValue(0.0)
    args << pressure_rise_perc_change

    # motor_efficiency_perc_change
    motor_efficiency_perc_change = OpenStudio::Measure::OSArgument.makeDoubleArgument('motor_efficiency_perc_change', true)
    motor_efficiency_perc_change.setDisplayName('Percent Change for Motor Efficiency.')
    motor_efficiency_perc_change.setDescription('Percent Change for Motor Efficiency.')
    motor_efficiency_perc_change.setDefaultValue(0.0)
    args << motor_efficiency_perc_change

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
    fan_object = runner.getOptionalWorkspaceObjectChoiceValue('fan', user_arguments, model)
    fan_handle = runner.getStringArgumentValue('fan', user_arguments)
    pressure_rise_perc_change = runner.getDoubleArgumentValue('pressure_rise_perc_change', user_arguments)
    motor_efficiency_perc_change = runner.getDoubleArgumentValue('motor_efficiency_perc_change', user_arguments)
    max_flowrate_perc_change = runner.getDoubleArgumentValue('max_flowrate_perc_change', user_arguments)
    fan_efficiency_perc_change = runner.getDoubleArgumentValue('fan_efficiency_perc_change', user_arguments)

    # find objects to change
    fans = []
    building = model.getBuilding
    building_handle = building.handle.to_s
    runner.registerInfo("fan_handle: #{fan_handle}")
    # setup fans
    if fan_handle == building_handle
      # Use ALL Fans
      runner.registerInfo('Applying change to ALL Fans')
      loops = model.getAirLoopHVACs
      # loop through air loops
      loops.each do |loop|
        supply_components = loop.supplyComponents
        # find fans on loops
        supply_components.each do |supply_component|
          if !supply_component.to_FanConstantVolume.empty?
            fans << supply_component.to_FanConstantVolume.get
          elsif !supply_component.to_FanVariableVolume.empty?
            fans << supply_component.to_FanVariableVolume.get
          elsif !supply_component.to_FanOnOff.empty?
            fans << supply_component.to_FanOnOff.get
          end
        end
      end
    elsif fan_handle == 0.to_s
      # Fans set to NONE so do nothing
      runner.registerInfo('Applying change to NONE Fans')
    elsif !fan_handle.empty?
      # Single Fan handle found, check if object is good
      if !fan_object.get.to_FanConstantVolume.empty?
        runner.registerInfo("Applying change to #{fan_object.get.name} Fan")
        fans << fan_object.get.to_FanConstantVolume.get
      elsif !fan_object.get.to_FanVariableVolume.empty?
        runner.registerInfo("Applying change to #{fan_object.get.name} Fan")
        fans << fan_object.get.to_FanVariableVolume.get
      elsif !fan_object.get.to_FanOnOff.empty?
        runner.registerInfo("Applying change to #{fan_object.get.name} Fan")
        fans << fan_object.get.to_FanOnOff.get
      else
        runner.registerError("Fan with handle #{fan_handle} could not be found.")
      end
    else
      runner.registerError('Fan handle is empty.')
      return false
    end

    # report initial condition of model
    runner.registerInitialCondition("Fans to change: #{fans.size}")
    runner.registerInfo("Fans to change: #{fans.size}")
    altered_fans = []
    altered_maxflow = []
    altered_pressurerise = []
    altered_fanefficiency = []
    altered_motorefficiency = []
    # loop through fans
    fans.each do |fan|
      altered_fan = false
      # modify max flowrate
      if max_flowrate_perc_change != 0.0
        if fan.maximumFlowRate.is_initialized
          runner.registerInfo("Applying #{max_flowrate_perc_change} Percent Change to #{fan.name.get}.")
          fan.setMaximumFlowRate(fan.maximumFlowRate + fan.maximumFlowRate * max_flowrate_perc_change * 0.01)
          altered_maxflow << fan.handle.to_s
          altered_fan = true
        end
      end

      # modify fan_efficiency_perc_change
      if fan_efficiency_perc_change != 0.0
        runner.registerInfo("Applying #{fan_efficiency_perc_change} Percent Change to #{fan.name.get}.")
        fan.setFanEfficiency(fan.fanEfficiency + fan.fanEfficiency * fan_efficiency_perc_change * 0.01)
        altered_fanefficiency << fan.handle.to_s
        altered_fan = true
      end

      # pressure_rise_perc_change
      if pressure_rise_perc_change != 0.0
        runner.registerInfo("Applying #{pressure_rise_perc_change} Percent Change to #{fan.name.get}.")
        fan.setPressureRise(fan.pressureRise + fan.pressureRise * pressure_rise_perc_change * 0.01)
        altered_pressurerise << fan.handle.to_s
        altered_fan = true
      end

      # motor_efficiency_perc_change
      if motor_efficiency_perc_change != 0.0
        runner.registerInfo("Applying #{motor_efficiency_perc_change} Percent Change to #{fan.name.get}.")
        fan.setMotorEfficiency(fan.motorEfficiency + fan.motorEfficiency * motor_efficiency_perc_change * 0.01)
        altered_motorefficiency << fan.handle.to_s
        altered_fan = true
      end

      next unless altered_fan
      altered_fans << fan.handle.to_s
      change_name(fan, max_flowrate_perc_change, fan_efficiency_perc_change, pressure_rise_perc_change, motor_efficiency_perc_change)
      runner.registerInfo("Fan name changed to: #{fan.name.get}")
    end # end fan loop

    # na if nothing in model to look at
    if altered_fans.empty?
      runner.registerAsNotApplicable('No Fans were altered in the model')
      return true
    end

    # report final condition of model
    runner.registerFinalCondition("#{altered_fans.size} fans objects were altered.")

    true
  end
end

# register the measure to be used by the application
FansPercentChange.new.registerWithApplication
