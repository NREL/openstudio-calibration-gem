# OpenStudio Calibration Measures 

Calibration measures used by OpenStudio. This contains general use calibration measures. Some measures here may also be suitable for energy efficiency or model articulation. Similarly, some measures in other measure gem repos may also be suitable for calibration usage.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openstudio-calibration-measures'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install 'openstudio-calibration-measures'

## Usage

To be filled out later.

# Releasing

* Update CHANGELOG.md
* Run `rake rubocop:auto_correct`
* Update version in `/lib/openstudio/calibration_measures/version.rb`
* Create PR to master, after tests and reviews complete, then merge
* Locally - from the master branch, run `rake release`
* On GitHub, go to the releases page and update the latest release tag. Name it "Version x.y.z" and copy the CHANGELOG entry into the description box.

