

###### (Automatically generated documentation)

# Shift Hours of Operation

## Description
This measure will infer the hours of operation for the building and then will shift the start of the hours of operation and change the duration of the hours of operation. In an alternate workflow you can directly pass in target start and duration rather than a shift and delta. Inputs can vary for weekday, Saturday, and Sunday. 

## Modeler Description
This will only impact schedule rulesets. It will impact the default profile, rules, and summer and winter design days. It will use methods in openstudio-standards to infer hours of operation, develop a parametric formula for all of the ruleset schedules, alter the hours of operation inputs to that formula and then re-apply the schedules. Input is expose to set ramp frequency of the resulting schedules. If inputs are such that no changes are requested, bypass the measure with NA so that it will not be parameterized. An advanced option for this measure would be bool to use hours of operation from OSM schedule ruleset hours of operation instead of inferring from standards. This should allow different parts of the building to have different hours of operation in the seed model.

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

### Use model hours of operation as target
The default behavior is for this to be false. When changed to true all of the hours of operation start and duration values will be ignored as the bool to treat those values as relative or absolue. Instead the hours of operation schedules for the model will be used.
**Name:** target_hoo_from_model,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Use parametric schedule formaulas already stored in the model.
When this is true the parametric schedule formulas will be generated from the existing model schedules. When false it expects the model already has parametric formulas stored.
**Name:** infer_parametric_schedules,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




