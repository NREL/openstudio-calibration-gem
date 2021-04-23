# OpenStudio Calibration Measures Gem

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

