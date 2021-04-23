


![Apply Measures Now Dialog](./docs/apply_measures_now.png?raw=true)
*Each parametric schedule will have a series of arguments including one or more profile, and optionally a ceiling and floor value which can be used in the profile formulas.*

Additional documentation will follow at a later date.

###### (Automatically generated documentation below)

# Inspect and Edit Parametric Schedules

## Description
This model will create arguments out of additional property inputs for parametric schedules in the model. You can use this just to inspect, or you can alter the inputs. It will not make parametric inputs for schedules that are not already setup as parametric. If you want to generate parametric schedules you can first run the Shift Hours of Operation Schedule with default 0 argument values for change in hours of operation.

## Modeler Description
This can be used in apply measure now, or can be used in a parametric workflow to load in any custom user profiles or floor/ceiling values.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Apply Parametric Schedules to the Model
When this is true the parametric schedules will be regenerated based on modified formulas, ceiling and floor values, and current horus of operation for building.
**Name:** apply_parametric_sch,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false







