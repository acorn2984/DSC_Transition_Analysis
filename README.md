# DSC Analysis MATLAB Script

A comprehensive MATLAB script for analyzing Differential Scanning Calorimetry (DSC) data with automatic thermal transition detection and ISO standard compliance.

## Overview

This script provides automated analysis of DSC thermograms, detecting and quantifying thermal transitions including:
- **Glass Transition Temperature (Tg)** - Following ISO 11357 standard - Step change inflection point detection
- **Crystallization Temperature (Tc)** - Following ISO 11357 standard - Exothermic peak detection
- **Melting Temperature (Tm)** - Following ISO 11357 standard - Endothermic peak detection

## Features

### 📊 Analysis Capabilities
- **Automatic baseline correction** using spline fitting
- **Multi-method transition detection** with ISO standard compliance
- **Comprehensive derivative analysis** (1st and 2nd derivatives)
- **Quantitative results** including onset temperatures, and peak temperatures
- **Visual results presentation** with annotated plots

### 🔧 Technical Features
- Interactive parameter input with validation
- Robust error handling for file reading
- Flexible data format support
- Comprehensive results export
- Professional visualization with multiple plot types

## Requirements

- MATLAB R2016b or later
- Signal Processing Toolbox (for `smooth` function)
- Statistics and Machine Learning Toolbox (optional, for enhanced analysis)

## Installation

1. Download the `DSC_Analysis.m` file
2. Place it in your MATLAB working directory
3. Ensure your DSC data files are accessible

## Usage

### Basic Usage

```matlab
DSC_Analysis()
```

### Input Parameters

When you run the script, you'll be prompted to enter:

1. **Starting temperature (°C)** - Initial temperature of your DSC run
2. **Heating rate (°C/min)** - Rate of temperature increase
3. **Ending temperature (°C)** - Final temperature of the heating stage
4. **Data filename** - Path to your DSC data file

### Data File Format

The script expects a tab-delimited text file with the following structure:
- **Header lines**: First 3 lines (automatically skipped)
- **Column 1**: Sample identifier (not used)
- **Column 2**: Time (seconds)
- **Column 3**: Heat flow (W/g)
- **Column 4**: Sample temperature (°C)
- **Column 5**: Reference temperature (°C)

Example data format:
```
# DSC Data File
# Sample: Universal DARK
# Date: 2024-01-15
Sample_1    0.00    0.1234    25.0    25.0
Sample_1    1.00    0.1245    25.1    25.1
Sample_1    2.00    0.1256    25.2    25.2
...
```

## Output

### Visual Results

The script generates a comprehensive 3-panel plot:

1. **Top Panel**: DSC thermogram with:
   - Original heat flow data
   - Spline baseline correction
   - Baseline-corrected data
   - Annotated transition temperatures

2. **Middle Panel**: First derivative analysis
   - Shows rate of heat flow change
   - Highlights glass transition inflection point

3. **Bottom Panel**: Second derivative analysis
   - Enhanced glass transition detection
   - Noise reduction through smoothing

### Quantitative Results

#### Glass Transition (Tg)
- **Inflection Point**: Primary value following ISO 11357
- **Onset Temperature**: Extrapolated baseline method
- **Peak Temperature**: Maximum derivative point

#### Crystallization (Tc)
- **Onset Temperature**: Deviation from baseline
- **Peak Temperature**: Maximum exothermic point

#### Melting (Tm)
- **Onset Temperature**: Deviation from baseline
- **Peak Temperature**: Maximum endothermic point

### Results Table

An interactive table displays all detected transitions with:
- Transition type and temperatures
- Analysis method used
- Color-coded results for easy interpretation

## Analysis Methods

### Glass Transition Detection
- **Standard**: ISO 11357 compliance
- **Method**: Minimum point in second derivative within 40-80°C range
- **Validation**: Cross-referenced with first derivative analysis
- **Baseline**: Spline-corrected data

### Crystallization Detection
- **Standard**: ISO 11357 compliance
- **Method**: Baseline-corrected exothermic peak detection
- **Range**: 70-140°C (customizable)
- **Validation**: Minimum peak height and distance filtering
- **Integration**: Trapezoidal rule with baseline subtraction

### Melting Detection
- **Standard**: ISO 11357 compliance
- **Method**: Baseline-corrected endothermic peak detection
- **Range**: 140-200°C (customizable)
- **Validation**: Minimum peak height and distance filtering
- **Integration**: Trapezoidal rule with baseline subtraction

## Customization

### Temperature Ranges
Modify the analysis ranges in the `analyze_thermal_transitions_iso` function:

```matlab
% Glass transition range
tg_range = find(temp_smooth >= 40 & temp_smooth <= 80);

% Crystallization range
tc_range = find(temp_smooth >= 70 & temp_smooth <= 140);

% Melting range
tm_range = find(temp_smooth >= 140 & temp_smooth <= 200);
```

### Detection Sensitivity
Adjust peak detection parameters:

```matlab
% Minimum peak height
'MinPeakHeight', 0.01

% Minimum peak distance
'MinPeakDistance', 20
```

## Troubleshooting

### Common Issues

1. **File Reading Errors**
   - Ensure file path is correct
   - Check file format matches expected structure
   - Verify file permissions

2. **No Transitions Detected**
   - Check temperature ranges match your sample
   - Adjust detection sensitivity parameters
   - Verify baseline correction is appropriate

3. **Noisy Results**
   - Increase smoothing parameters
   - Check data quality
   - Verify heating rate is appropriate

### Error Messages

- `Error reading file`: Check file format and path
- `Calculated heating duration exceeds available data`: Verify time/temperature parameters
- `Too few baseline points`: Data may be too noisy or short

## File Output

### Results File
Optional text file export containing:
- Analysis parameters
- Detected transition temperatures
- Quantitative results
- Analysis methods used
- Timestamp and original filename

### Naming Convention
Results saved as: `[original_filename]_DSC_Results.txt`

## Validation

The script has been validated against:
- ISO 11357 standard for glass transition temperature, crystallisation temperature, and melting temperature
- Commercial DSC software results
- Known reference materials

## Contributing

Contributions are welcome! Please consider:
- Adding support for additional file formats
- Implementing new analysis methods
- Improving detection algorithms
- Adding unit tests

## License

This script is provided as-is for research and educational purposes. Please cite appropriately if used in publications.

## Support

For issues, questions, or suggestions:
1. Check the troubleshooting section
2. Review the customization options
3. Open an issue on GitHub with:
   - MATLAB version
   - Sample data (if possible)
   - Error messages
   - Expected vs. actual results

## Version History

- **v1.0**: Initial release with basic DSC analysis
- **v1.1**: Shows the dsc graph plotted over temperature
- **v1.2**: More user friendly, Improved onset temperature calculations, Improved results display
- **v1.3**: Results looks better and provide key information needed
- **v1.4**: Glass Transition Temperature Analysis is now correct as per ISO 11357 standards, Readability of the plots and tables has improved

---

*This script is designed for thermal analysis research and should be validated against known standards for your specific applications.*
