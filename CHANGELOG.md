# OpenStudio Calibration Measures Gem

## Version 0.11.1
* Update dependencies for 3.9

## Version 0.11.0
* Support for OpenStudio 3.9 (upgrade to standards gem 0.7.0, extension gem 0.8.1)

## Version 0.10.0
* Support for OpenStudio 3.8 (upgrade to standards gem 0.6.0, extension gem 0.8.0)
* Support Ruby 3.2.2

## Version 0.9.0
* Updating dependencies and licenses for OpenStudio 3.7 (upgrade to standards gem 0.5.0, extension gem 0.7.0)
* Fixed [#54]( https://github.com/NREL/openstudio-calibration-gem/issues/54 ), OS API changes break some measures

## Version 0.8.0
* Fixed [#52]( https://github.com/NREL/openstudio-calibration-gem/pull/52 ), Specify date format in AddMonthlyUtilityData
* Fixed [#55]( https://github.com/NREL/openstudio-calibration-gem/pull/55 ), Api change
* Updating dependencies and licenses for OpenStudio 3.6 (upgrade to standards gem 0.4.0, extension gem 0.6.1)

## Version 0.7.0
* Support for OpenStudio 3.5 (upgrade to standards gem 0.3.0, extension gem 0.6.0)

## Version 0.6.0
* Support for OpenStudio 3.4 (upgrade to standards gem 0.2.16, no extension gem upgrade)

## Version 0.5.1
* Fixed [#24]( https://github.com/NREL/openstudio-calibration-gem/pull/24 ), HardSizeHvac: undefined method `runSizingRun'
* Fixed [#42]( https://github.com/NREL/openstudio-calibration-gem/pull/42 ), Update reporting measures in repo to pass in model = nil
* Fixed [#43]( https://github.com/NREL/openstudio-calibration-gem/pull/43 ), Check all measures in this repo for multiple tags

## Version 0.5.0
* Support for OpenStudio 3.3 (upgrade to extension gem 0.5.1 and standards gem 0.2.15)
- Fixed [#35]( https://github.com/NREL/openstudio-calibration-gem/pull/35 ), adding compatibility matrix and contribution policy
- Fixed [#38]( https://github.com/NREL/openstudio-calibration-gem/pull/38 ), Add hoo var method argment to change hours of operation measure

## Version 0.4.0

* Support Ruby ~> 2.7
* Support for OpenStudio 3.2 (upgrade to extension gem 0.4.2 and standards gem 0.2.13)
* Fixed [#11]( https://github.com/NREL/openstudio-calibration-gem/issues/11 ), Error in Exterior Wall Thermal Percent Change , getSolarAbsorptance
* add shift_hours_of_operation measure using parametric schedules from standards gem
* added inspect_and_edit_parametric_schedules measure to inspect and edit parametric schedule including profile formulas

## Version 0.3.1

* Bump openstudio-extension-gem version to 0.3.2 to support updated workflow-gem

## Version 0.3.0

* There project was misnamed. Moved to be called `openstudio-calibration`.
* Support for OpenStudio 3.1
    * Update OpenStudio Standards to 0.2.12
    * Update OpenStudio Extension gem to 0.3.1

## Version 0.2.0

* Note that this version was never released to RubyGems
* Support for OpenStudio 3.0
    * Upgrade Bundler to 2.1.x
    * Restrict to Ruby ~> 2.5.0   
    * Removed simplecov forked dependency 
* Upgraded openstudio-extension to 0.2.3
    * Updated measure tester to 0.2.0 (removes need for github gem in downstream projects)
* Upgraded openstudio-standards to 0.2.11
* Exclude measure tests from being released with the gem (reduces the size of the installed gem significantly)

## Version 0.1.3

* Require as openstudio-calibration-measures (not openstudio-calibration)

## Version 0.1.2

* Initial release of the calibration measures gem.
* Supports OpenStudio 2.9.x series.

## Version 0.1.1 (yanked)
## Version 0.1.0 (yanked)

