

# TimeSeries Objective Function

## Description

Creates Objective Function from Timeseries Data.  The measure applies a Norm at each timestep between the difference of CSV metered data and SQL model data. A timeseries plot can also be created.  Possible outputs are 'cvrmse', 'nmbe', 'simdata' = sum of the simulated data, 'csvdata' = sum of metered data, 'diff' = P Norm between the metered and simulated data if Norm is 1 or 2, else its just the Difference.

## Arguments

**verbose_messages** will display all the runner.registerInfo statements for the metered value, simulated value and their difference at EVERY timestep. while this is useful for debugging the usage of the Measure, it has a MAJOR impact on performance and will slow the running of the measure.  Turn to False for production runs.  

**csv_name** is the file path, relative to the Measure at runtime, to the CSV data. If this run is taking place on an OS-Server or (OSAF) instance, where the project data is zipped up into an OSA.zip file and posted to the OS-Server Web node (in a directory called **calibration_data**), then relative path to the data would be: '../../../lib/calibration_data/electric_json.json'.  Notice the **lib** in the path name for the OSAF use case.

**csv_time_header** is the Header Value in the CSV file with metered data for the TIMESTAMP, ex: "timestamp"

**csv_var**, is the column name of the metered data, ex: "Electricity:Facility[J]"

**convert_data** is used to convert the units in the CSV from 'F to C', 'WH to J', 'CFM to m3/s', 'PSI to Pa' or **None**

The timestamp of the CSV data should follow a mm/dd/yyyy hh:mm:ss format with NO AM/PM

**year** (true) Is the Year in the csv data timestamp => mm/dd/yyyy or mm/dd

**seconds** (true) Is the Seconds in the csv data timestamp => hh:mm:ss or hh:mm

The model output variables/meters are listed in the eplusout.rdd and .mdd files.

The Measure argument **find_avail** (true)  will print out ALL the available RunPeriods (EnvPeriod), ReportingFrequencies, Variables and key values in the run.log file:

`[15:11:26.640379 INFO] environment_periods: ["Run Period 1"]`\
`[15:11:26.640418 INFO] available timeseries: ["Electricity:Facility", "NaturalGas:Facility", "Surface Inside Face Temperature", "Zone Outdoor Air Drybulb Temperature"]`\
`[15:11:26.640424 INFO] `\
`[15:11:26.640443 INFO] available EnvPeriod: Run Period 1, available ReportingFrequencies: ["Daily", "Hourly", "Zone Timestep"]`\
`[15:11:26.640454 INFO]   available ReportingFrequency: Daily, available variable names: ["Electricity:Facility", "NaturalGas:Facility"]`\
`[15:11:26.640463 INFO]     variable names: Electricity:Facility`\
`[15:11:26.640469 INFO]     available key value: [""]`\
`[15:11:26.640476 INFO]     variable names: NaturalGas:Facility`\
`[15:11:26.640481 INFO]     available key value: [""]`\
`[15:11:26.640493 INFO]   available ReportingFrequency: Hourly, available variable names: ["Electricity:Facility", "NaturalGas:Facility", "Surface Inside Face Temperature", "Zone Outdoor Air Drybulb Temperature"]`\
`[15:11:26.640499 INFO]     variable names: Electricity:Facility`\
`[15:11:26.640505 INFO]     available key value: [""]`\
`[15:11:26.640511 INFO]     variable names: NaturalGas:Facility`\
`[15:11:26.640516 INFO]     available key value: [""]`\
`[15:11:26.640526 INFO]     variable names: Surface Inside Face Temperature`\
`[15:11:26.640539 INFO]     available key value: ["SUB SURFACE 1", "SUB SURFACE 2", "SURFACE 1"]`\
`[15:11:26.640546 INFO]     variable names: Zone Outdoor Air Drybulb Temperature`\
`[15:11:26.640552 INFO]     available key value: ["THERMAL ZONE 1"]`\
`[15:11:26.640561 INFO]   available ReportingFrequency: Zone Timestep, available variable names: ["Electricity:Facility", "NaturalGas:Facility"]`\
`[15:11:26.640567 INFO]     variable names: Electricity:Facility`\
`[15:11:26.640573 INFO]     available key value: [""]`\
`[15:11:26.640579 INFO]     variable names: NaturalGas:Facility`\
`[15:11:26.640585 INFO]     available key value: [""]`\

* The name of the variable/timeseries to be compared is used in the **timeseries_name** measure argument.
* Some variables require a further **key_value** to narrow down the results to a specific object like a Surface or Zone.
* RunPeriods/EnvPeriod are set in the **environment_period** measure argument.
* ReportingFrequencies ["Daily", "Hourly", "Zone Timestep"] are set in the **reporting_frequency** measure argument.


## Measure Type
ReportingMeasure

## Taxonomy


## Arguments


### Path to CSV file for the metered data
Path to CSV file including file name.
**Name:** csv_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### CSV Time Header
CSV Time Header Value. Used to determine the timestamp column in the CSV file
**Name:** csv_time_header,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### CSV variable name
CSV variable name. Used to determine the variable column in the CSV file
**Name:** csv_var,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Convert Units
Convert Units in Metered Data
**Name:** convert_data,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### CSV variable display name
CSV variable display name. Not yet Implemented
**Name:** csv_var_dn,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Year in csv data timestamp
Is the Year in the csv data timestamp => mm:dd:yy or mm:dd (true/false)
**Name:** year,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Seconds in csv data timestamp
Is the Seconds in the csv data timestamp => hh:mm:ss or hh:mm (true/false)
**Name:** seconds,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### SQL key value
SQL key value for the SQL query to find the variable in the SQL file
**Name:** key_value,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### TimeSeries Name
TimeSeries Name for the SQL query to find the variable in the SQL file
**Name:** timeseries_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Reporting Frequency
Reporting Frequency for SQL Query
**Name:** reporting_frequency,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Environment Period
Environment Period for SQL query
**Name:** environment_period,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Norm of the difference of csv and sql
Norm of the difference of csv and sql. 1 is absolute value. 2 is euclidean distance. 3 is raw difference.
**Name:** norm,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Scale factor to apply to the difference
Scale factor to apply to the difference (1 is no scale)
**Name:** scale,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Find Available data in the SQL file
Will RegisterInfo all the 'EnvPeriod', 'ReportingFrequencies', 'VariableNames', 'KeyValues' in the SQL file.  Useful for debugging SQL issues.
**Name:** find_avail,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### algorithm_download
Make JSON data available for algorithm_download (true/false)
**Name:** algorithm_download,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### plot_flag timeseries data
Create plot of timeseries data (true/false)
**Name:** plot_flag,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Plot name
Name to include in reporting file name.
**Name:** plot_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### verbose_messages
verbose messages.  Useful for debugging but MAJOR Performance Hit.
**Name:** verbose_messages,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### warning_messages
Warn on missing data.
**Name:** warning_messages,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### add_first_zero_for_plots
Add a point of zero value to the plot at the beginning of the runperiod.
**Name:** add_first_zero_for_plots,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### add_last_zero_for_plots
Add a point of zero value to the plot at the end of the runperiod.
**Name:** add_last_zero_for_plots,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false





## Outputs












diff, simdata, csvdata, cvrmse, nmbe
