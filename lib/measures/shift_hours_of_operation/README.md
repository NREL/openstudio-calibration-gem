

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


### New space name
This name will be used as the name of the new space.
**Name:** space_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false




