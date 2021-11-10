# OpenStudio Calibration Measures 

Calibration measures used by OpenStudio. This contains general use calibration measures. Some measures here may also be suitable for energy efficiency or model articulation. Similarly, some measures in other measure gem repos may also be suitable for calibration usage.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openstudio-calibration'

require 'openstudio-calibration'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install 'openstudio-calibration'

# Compatibility Matrix

|OpenStudio Calibration Gem|OpenStudio|Ruby|
|:--------------:|:----------:|:--------:|
| 0.5.0  | 3.3      | 2.7    |
| 0.4.0 - 0.4.2  | 3.2      | 2.7    |
| 0.3.0 - 0.3.1  | 3.1      | 2.5    |
| 0.2.0   | 3.0      | 2.5    |
| 0.1.4 and below | 2.9 and below      | 2.2.4    |

# Contributing 

Please review the [OpenStudio Contribution Policy](https://openstudio.net/openstudio-contribution-policy) if you would like to contribute code to this gem.


# Releasing

* Update CHANGELOG.md
* Run `rake rubocop:auto_correct`
* Update version in `/lib/openstudio/calibration_measures/version.rb`
* Create PR to master, after tests and reviews complete, then merge
* Locally - from the master branch, run `rake release`
* On GitHub, go to the releases page and update the latest release tag. Name it "Version x.y.z" and copy the CHANGELOG entry into the description box.

