# DSC Transition Analysis

A comprehensive MATLAB tool for analyzing Differential Scanning Calorimetry (DSC) data to detect and characterise thermal transitions in polymers.

## Features

- **Automated Thermal Transition Detection**: Glass transition (Tg), crystallisation (Tc), and melting (Tm) temperatures
- **Adaptive Baseline Correction**: Intelligent spline-based baseline removal
- **Interactive Analysis**: User-guided temperature range selection for precise analysis
- **Multiple Polymer Types**: Optimized detection algorithms for amorphous, semi-crystalline, and crystalline polymers
- **Comprehensive Results**: Detailed transition parameters including onset temperatures, peak temperatures, and enthalpies
- **Visual Analysis**: Multi-panel plots showing thermogram, derivatives, and detected transitions
- **Export Capabilities**: Save results to formatted text files for documentation

## Installation

1. Clone this repository:
```bash
git clone https://github.com/acorn2984/DSC_Transition_Analysis.git
```

2. Navigate to the project directory:
```bash
cd DSC_Transition_Analysis
```

3. Open MATLAB and add the project folder to your path, or navigate to the folder in MATLAB's current directory.

## Requirements

- MATLAB R2016b or later
- Signal Processing Toolbox (recommended for enhanced smoothing functions)

## Usage

### Basic Usage

1. Launch MATLAB and run the main function:
```matlab
DSC_Analysis()
```

2. Follow the interactive prompts:
   - Enter experimental parameters (temperature range, heating rate)
   - Select polymer type for optimized analysis
   - Specify your DSC data file
   - Interactively select temperature ranges for transition analysis

### Input Data Format

The tool expects DSC data files with the following column structure:
- Column 1: Index/Sample number
- Column 2: Time (seconds)
- Column 3: Heat flow (W/g)
- Column 4: Sample temperature (°C)
- Column 5: Reference temperature (°C)

The file should have 3 header lines which will be automatically skipped.

### Example Workflow

```matlab
% Run the analysis
DSC_Analysis()

% Enter parameters when prompted:
% Starting temperature: -50
% Heating rate: 10
% Ending temperature: 300
% Polymer type: 2 (semi-crystalline)
% Data file: your_dsc_data.txt
```

## Output

The analysis provides:

### Visual Output
- **Main thermogram**: Original data with baseline correction and detected transitions
- **First derivative plot**: Shows rate of heat flow change for Tg detection
- **Second derivative plot**: Enhanced Tg detection using inflection point analysis
- **Results table**: Summary of all detected transitions with parameters

### Numerical Results
- **Glass Transition (Tg)**:
  - Onset temperature
  - Inflection point (primary Tg value)
- **Crystallisation (Tc)**:
  - Onset temperature
  - Peak temperature
- **Melting (Tm)**:
  - Onset temperature
  - Peak temperature

### File Export
Results can be saved to a formatted text file containing:
- Analysis parameters
- Detected transition temperatures and enthalpies
- Detection methods used
- Analysis summary and polymer classification

## Algorithm Details

### Baseline Correction
- **Adaptive Spline Fitting**: Automatically identifies stable baseline regions
- **Transition Region Exclusion**: Removes peak areas from baseline calculation
- **Robust Interpolation**: Uses spline or linear interpolation based on data density

### Transition Detection

#### Glass Transition (Tg)
- **Method**: ISO 11357 compliant second derivative minimum detection
- **Fallback**: Maximum first derivative change method
- **Parameters**: Onset, inflection point, peak

#### Crystallization/Melting Peaks
- **Method**: Adaptive peak detection with noise filtering
- **Baseline Integration**: Accurate enthalpy calculation using tangent baselines
- **Multiple Peak Handling**: Selects most significant peak in specified range

### Quality Assurance
- **Data Validation**: Checks for non-finite values and data consistency
- **Noise Filtering**: Adaptive thresholding based on signal characteristics
- **Method Reporting**: Documents detection algorithm used for each transition

## Supported Polymer Types

1. **Amorphous Polymers**: Optimized for Tg detection only
2. **Semi-crystalline Polymers**: Detects Tg, Tc, and Tm with appropriate temperature ranges
3. **Crystalline Polymers**: Focuses on melting transitions
4. **Unknown/Custom**: Analyzes full temperature range for all possible transitions

## Examples

### Example 1: Semi-crystalline Polymer (PET)
```
Expected results:
- Tg: ~80°C
- Tc: ~120-140°C (if cold crystallization occurs)
- Tm: ~250-260°C
```

### Example 2: Amorphous Polymer (PS)
```
Expected results:
- Tg: ~100°C
- No crystallization or melting peaks
```

## Troubleshooting

### Common Issues

**No transitions detected:**
- Check temperature range covers expected transition regions
- Verify data file format and column structure
- Increase sample mass or reduce heating rate
- Check for instrument calibration issues

**Noisy results:**
- Apply additional smoothing by modifying `smooth_factor` in the code
- Check for electromagnetic interference during measurement
- Verify sample preparation (avoid air bubbles, ensure good thermal contact)

**Incorrect transition assignments:**
- Manually adjust temperature ranges during interactive selection
- Consider polymer thermal history (annealing, processing conditions)
- Compare with literature values for similar polymers

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development Guidelines
- Follow MATLAB coding best practices
- Include comments for new functions
- Test with various polymer types and data formats
- Update documentation for new features

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 DSC Transition Analysis Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Citation

If you use this software in your research, please cite it as follows:

```bibtex
@software{dsc_transition_analysis_2024,
  title={DSC Transition Analysis},
  author={Anjali Malik},
  year={2024},
  url={https://github.com/acorn2984/DSC_Transition_Analysis},
  version={1.0},
  note={MATLAB software for differential scanning calorimetry data analysis}
}
```

## Acknowledgments

- Built following ISO standards for DSC analysis
- Inspired by polymer thermal analysis best practices
- Many thanks to Jai Gupta for being a supportive and insightful supervisor throughout my internship. I’ve greatly enjoyed learning about materials and polymers, and I’m truly grateful for the guidance and knowledge shared during this time.
- Thanks to the materials science community for feedback and testing

## Contact

For questions, suggestions, or collaboration opportunities, please open an issue on GitHub or contact the maintainers.

---

**Keywords**: DSC, Differential Scanning Calorimetry, Thermal Analysis, Polymers, Glass Transition, Melting Temperature, Crystallization, MATLAB, Materials Science
