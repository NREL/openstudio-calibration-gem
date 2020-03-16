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
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require 'json'
require 'time'

# start the measure
class AddMonthlyUtilityData < OpenStudio::Ruleset::ModelUserScript
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    'AddMonthlyUtilityData'
  end

  def year_month_day(str)
    result = nil
    if match_data = /(\d+)-(\d+)-(\d+)/.match(str)
      year = match_data[1].to_i
      month = match_data[2].to_i
      day = match_data[3].to_i
      result = [year, month, day]
    else
      puts "no match for '#{str}'"
    end
    result
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # make an electric json argument
    electric_json = OpenStudio::Ruleset::OSArgument.makeStringArgument('electric_json', true)
    electric_json.setDisplayName('Path to electric JSON')
    args << electric_json

    # make a gas json argument
    gas_json = OpenStudio::Ruleset::OSArgument.makeStringArgument('gas_json', true)
    gas_json.setDisplayName('Path to gas JSON')
    args << gas_json

    water_json = OpenStudio::Ruleset::OSArgument.makeStringArgument('water_json', false)
    water_json.setDisplayName('Path to water JSON')
    args << water_json

    # make a start date argument
    start_date = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date', true)
    start_date.setDisplayName('Start date')
    args << start_date

    # make an end date argument
    end_date = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date', true)
    end_date.setDisplayName('End date')
    args << end_date

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
    electric_json = runner.getStringArgumentValue('electric_json', user_arguments)
    gas_json = runner.getStringArgumentValue('gas_json', user_arguments)
    water_json = runner.getOptionalStringArgumentValue('water_json', user_arguments)
    start_date = runner.getStringArgumentValue('start_date', user_arguments)
    end_date = runner.getStringArgumentValue('end_date', user_arguments)

    # set start date
    if date = year_month_day(start_date)

      start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(date[1]), date[2], date[0])

      # actual year of start date
      yearDescription = model.getYearDescription
      yearDescription.setCalendarYear(date[0])

      runPeriod = model.getRunPeriod
      runPeriod.setBeginMonth(date[1])
      runPeriod.setBeginDayOfMonth(date[2])
    else
      runner.registerError("Unknown start date '#{start_date}'")
      raise "Unknown start date '#{start_date}'"
      return false
    end

    # set end date
    if date = year_month_day(end_date)

      end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(date[1]), date[2], date[0])

      runPeriod = model.getRunPeriod
      runPeriod.setEndMonth(date[1])
      runPeriod.setEndDayOfMonth(date[2])
    else
      runner.registerError("Unknown end date '#{end_date}'")
      raise "Unknown end date '#{end_date}'"
      return false
    end

    # remove all utility bills
    model.getUtilityBills.each(&:remove)
    runner.registerInfo("electric_json is #{electric_json}")
    electric_json_path = File.expand_path(electric_json.to_s, __FILE__)
    runner.registerInfo("electric_json_path is #{electric_json_path}")
    temp = File.read(electric_json_path)
    electric_data = JSON.parse(temp)
    unless electric_data.nil?

      utilityBill = OpenStudio::Model::UtilityBill.new('Electricity'.to_FuelType, model)
      utilityBill.setName('Electric Bill')
      utilityBill.setConsumptionUnit('kWh')
      utilityBill.setPeakDemandUnit('kW')

      electric_data['data'].each do |period|
        from_date = period['from'] ? Time.iso8601(period['from']).strftime('%Y%m%dT%H%M%S') : nil
        to_date = period['to'] ? Time.iso8601(period['to']).strftime('%Y%m%dT%H%M%S') : nil

        if from_date.nil? || to_date.nil?
          runner.registerError("Unknown date format in period '#{period}'")
          raise "Unknown date format in period '#{period}'"
          return false
        end

        period_start_date = OpenStudio::DateTime.fromISO8601(from_date).get.date
        # period_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(from_date[1]), from_date[2], from_date[0])
        period_end_date = OpenStudio::DateTime.fromISO8601(to_date).get.date - OpenStudio::Time.new(1.0)
        # period_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(to_date[1]), to_date[2], to_date[0])

        if (period_start_date < start_date) || (period_end_date > end_date)
          runner.registerInfo("skipping period #{period_start_date} to #{period_end_date}")
          next
        end

        if period['tot_kwh'].nil?
          runner.registerError("Billing period missing tot_kwh '#{period}'")
          return false
        end
        tot_kwh = period['tot_kwh'].to_f

        peak_kw = nil
        peak_kw = period['peak_kw'].to_f unless period['peak_kw'].nil?

        runner.registerInfo("electric period #{period}")
        runner.registerInfo("electric period_start_date: #{period_start_date}, period_end_date: #{period_end_date}, tot_kwh: #{tot_kwh}, peak_kw: #{peak_kw}")

        bp = utilityBill.addBillingPeriod
        bp.setStartDate(period_start_date)
        bp.setEndDate(period_end_date)
        bp.setConsumption(tot_kwh)
        bp.setPeakDemand(peak_kw) if peak_kw
      end
    end
    runner.registerInfo("gas_json is #{gas_json}")
    gas_json_path = File.expand_path(gas_json.to_s, __FILE__)
    runner.registerInfo("gas_json_path is #{gas_json_path}")
    temp = File.read(gas_json_path)
    gas_data = JSON.parse(temp)
    unless gas_data.nil?

      utilityBill = OpenStudio::Model::UtilityBill.new('Gas'.to_FuelType, model)
      utilityBill.setName('Gas Bill')
      utilityBill.setConsumptionUnit('therms')

      gas_data['data'].each do |period|
        from_date = period['from'] ? Time.iso8601(period['from']).strftime('%Y%m%dT%H%M%S') : nil
        to_date = period['to'] ? Time.iso8601(period['to']).strftime('%Y%m%dT%H%M%S') : nil

        if from_date.nil? || to_date.nil?
          runner.registerError("Unknown date format in period '#{period}'")
          raise "Unknown date format in period '#{period}'"
          return false
        end

        period_start_date = OpenStudio::DateTime.fromISO8601(from_date).get.date
        # period_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(from_date[1]), from_date[2], from_date[0])
        period_end_date = OpenStudio::DateTime.fromISO8601(to_date).get.date - OpenStudio::Time.new(1.0)
        # period_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(to_date[1]), to_date[2], to_date[0])

        if (period_start_date < start_date) || (period_end_date > end_date)
          runner.registerInfo("skipping period #{period_start_date} to #{period_end_date}")
          next
        end

        if period['tot_therms'].nil?
          runner.registerError("Billing period missing tot_therms '#{period}'")
          return false
        end
        tot_therms = period['tot_therms'].to_f

        runner.registerInfo("gas period: #{period}")
        runner.registerInfo("gas period_start_date: #{period_start_date}, period_end_date: #{period_end_date}, tot_therms: #{tot_therms}")

        bp = utilityBill.addBillingPeriod
        bp.setStartDate(period_start_date)
        bp.setEndDate(period_end_date)
        bp.setConsumption(tot_therms)
      end
    end

    # water bills
    if water_json.is_initialized

      runner.registerInfo("water_json is #{water_json}")
      water_json_path = File.expand_path(water_json.to_s, __FILE__)
      runner.registerInfo("water_json_path is #{water_json_path}")
      temp = File.read(water_json_path)
      water_data = JSON.parse(temp)

      if water_data

        utilityBill = OpenStudio::Model::UtilityBill.new('Water'.to_FuelType, model)
        utilityBill.setName('Water Bill')
        utilityBill.setConsumptionUnit('gal')
        # utilityBill.setPeakDemandUnit("kW")

        water_data['data'].each do |period|
          from_date = period['from'] ? Time.iso8601(period['from']).strftime('%Y%m%dT%H%M%S') : nil
          to_date = period['to'] ? Time.iso8601(period['to']).strftime('%Y%m%dT%H%M%S') : nil

          if from_date.nil? || to_date.nil?
            runner.registerError("Unknown date format in period '#{period}'")
            raise "Unknown date format in period '#{period}'"
            return false
          end

          period_start_date = OpenStudio::DateTime.fromISO8601(from_date).get.date
          # period_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(from_date[1]), from_date[2], from_date[0])
          period_end_date = OpenStudio::DateTime.fromISO8601(to_date).get.date - OpenStudio::Time.new(1.0)
          # period_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(to_date[1]), to_date[2], to_date[0])

          if (period_start_date < start_date) || (period_end_date > end_date)
            runner.registerInfo("skipping period #{period_start_date} to #{period_end_date}")
            next
          end

          if period['tot_gal'].nil?
            runner.registerError("Billing period missing tot_gal '#{period}'")
            return false
          end
          tot_gal = period['tot_gal'].to_f

          tot_cost = nil
          tot_cost = period['tot_cost'].to_f if period['tot_cost']

          runner.registerInfo("water period #{period}")
          runner.registerInfo("water period_start_date: #{period_start_date}, period_end_date: #{period_end_date}")

          bp = utilityBill.addBillingPeriod
          bp.setStartDate(period_start_date)
          bp.setEndDate(period_end_date)
          bp.setConsumption(tot_gal)
        end
      end
    end

    # reporting final condition of model
    runner.registerFinalCondition('Utility bill data has been added to the model.')

    true
  end
end

# this allows the measure to be use by the application
AddMonthlyUtilityData.new.registerWithApplication
