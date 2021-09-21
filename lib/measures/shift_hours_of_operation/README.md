

###### (Automatically generated documentation)

# Shift Hours of Operation

## Description
This measure will infer the hours of operation for the building and then will shift the start of the hours of operation and change the duration of the hours of operation. In an alternate workflow you can directly pass in target start and duration rather than a shift and delta. Inputs can vary for weekday, Saturday, and Sunday. if a day does not have any hours of operation to start with increasing hours of operation may not have any impact as the auto generated data may not know what to do during operating hours. Future version may be able to borrow a profile formula but would probably require additional user arguments.

## Modeler Description
This will only impact schedule rulesets. It will use methods in openstudio-standards to infer hours of operation, develop a parametric formula for all of the ruleset schedules, alter the hours of operation inputs to that formula and then re-apply the schedules. Input is expose to set ramp frequency of the resulting schedules. If inputs are such that no changes are requested, bypass the measure with NA so that it will not be parameterized. An advanced option for this measure would be bool to use hours of operation from OSM schedule ruleset hours of operation instead of inferring from standards. This should allow different parts of the building to have different hours of operation in the seed model.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Shift the weekday start of hours of operation.
Use decimal hours so an 1 hour and 15 minute shift would be 1.25. Positive value moves the hour of operation later
**Name:** hoo_start_weekday,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false




### Extend the weekday of hours of operation.
Use decimal hours so an 1 hour and 15 minute would be 1.25. Positive value makes the hour of operation longer.
**Name:** hoo_dur_weekday,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false




### Shift the saturday start of hours of operation.
Use decimal hours so an 1 hour and 15 minute shift would be 1.25. Positive value moves the hour of operation later
**Name:** hoo_start_saturday,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false




### Extend the saturday of hours of operation.
Use decimal hours so an 1 hour and 15 minute would be 1.25. Positive value makes the hour of operation longer.
**Name:** hoo_dur_saturday,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false




### Shift the sunday start of hours of operation.
Use decimal hours so an 1 hour and 15 minute shift would be 1.25. Positive value moves the hour of operation later
**Name:** hoo_start_sunday,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false




### Extend the sunday of hours of operation.
Use decimal hours so an 1 hour and 15 minute would be 1.25. Positive value makes the hour of operation longer.
**Name:** hoo_dur_sunday,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false




### Hours of operation values treated as deltas
When this is true the hours of operation start and duration represent a delta from the original model values. When switched to false they represent absolute values.
**Name:** delta_values,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




### Dynamically generate parametric schedules from current ruleset schedules.
When this is true the parametric schedule formulas and hours of operation will be generated from the existing model schedules. When false it expects the model already has parametric formulas stored.
**Name:** infer_parametric_schedules,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




### Fraction of Daily Occupancy Range.
This determine what fraction of occupancy be considered operating conditions. This fraction is normalized to expanded to range seen over the full year and does not necessary equal fraction of design occupancy. This value should be between 0 and 1.0 and is only used if dynamically generated parametric schedules are used.
**Name:** fraction_of_daily_occ_range,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false




### Use model hours of operation as target
The default behavior is for this to be false. This can not be used unless Dynamically generate parametric schedules from current ruleset schedules is set to false and if the schedules in the model already have parametric profiles. When changed to true all of the hours of operation start and duration values will be ignored as the bool to treat those values as relative or absolute. Instead the hours of operation schedules for the model will be used.
**Name:** target_hoo_from_model,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false







