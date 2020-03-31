

###### (Automatically generated documentation)

# Heating Coils Gas Multiplier

## Description
This is a general purpose measure to calibrate Gas Heating Coils with a Multiplier.

## Modeler Description
It will be used for calibration of rated capacity and efficiency and parasitic loads. User can choose between a SINGLE coil or ALL the Coils.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Apply the Measure to a SINGLE Gas Heating Coil, ALL the Gas Heating Coils or NONE.

**Name:** coil,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Multiplier for coil Efficiency.
Multiplier for coil Efficiency.
**Name:** coil_efficiency_multiplier,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Multiplier for coil Capacity.
Multiplier for coil Capacity.
**Name:** coil_capacity_multiplier,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Multiplier for coil parasitic electric load.
Multiplier for coil parasitic electric load.
**Name:** coil_parasitic_electric_multiplier,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Multiplier for coil parasitic gas load.
Multiplier for coil parasitic gas load.
**Name:** coil_parasitic_gas_multiplier,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false




