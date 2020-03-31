

###### (Automatically generated documentation)

# Maalka Formatted Monthly JSON Utility Data

## Description
Maalka Formatted Monthly JSON Utility Data

## Modeler Description
Add Maalka Formatted Monthly JSON Utility Data to OSM as a UtilityBill Object

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Path to JSON Data.
Path to JSON Data. resources is default directory name of uploaded files in the server.
**Name:** json,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Variable name
Name of the Utility Bill Object.  For Calibration Report use Electric Bill or Gas Bill
**Name:** variable_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Maalka Fuel Type in JSON
Maalka Fuel Type in JSON
**Name:** maalka_fuel_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### OpenStudio Fuel Type
OpenStudio Fuel Type
**Name:** fuel_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### OpenStudio Consumption Unit
OpenStudio Consumption Unit (usually kWh or therms)
**Name:** consumption_unit,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Maalka data key name in JSON
Maalka data key name in JSON (tot_kwh or tot_therms)
**Name:** data_key_name,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start date
Start date format %Y%m%dT%H%M%S with Hour Min Sec optional
**Name:** start_date,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End date
End date format %Y%m%dT%H%M%S with Hour Min Sec optional
**Name:** end_date,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### remove all existing Utility Bill data objects from model
remove all existing Utility Bill data objects from model
**Name:** remove_existing_data,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set RunPeriod Object in model to use start and end dates
Set RunPeriod Object in model to use start and end dates.  Only needed once if multiple copies of measure being used.
**Name:** set_runperiod,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




