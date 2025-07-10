function DSC_Analysis()
    
    clc;
    
    fprintf('=== DSC Analysis Parameters ===\n');
    fprintf('Please enter the following parameters for your DSC experiment:\n\n');
    
    start_temp = input('Starting temperature (°C): ');
    while isempty(start_temp) || ~isnumeric(start_temp)
        start_temp = input('Please enter a valid starting temperature (°C): ');
    end
    
    heating_rate = input('Heating rate (°C/min): ');
    while isempty(heating_rate) || ~isnumeric(heating_rate) || heating_rate <= 0
        heating_rate = input('Please enter a valid heating rate (°C/min): ');
    end
    
    end_temp = input('Ending temperature of first dynamic stage (°C): ');
    while isempty(end_temp) || ~isnumeric(end_temp) || end_temp <= start_temp
        end_temp = input('Please enter a valid ending temperature (°C) higher than starting temp: ');
    end
    
    temp_range = end_temp - start_temp;
    heating_duration = temp_range / heating_rate;
    heating_duration_sec = heating_duration * 60;
    
    fprintf('\n=== Calculated Parameters ===\n');
    fprintf('Temperature range: %.1f°C\n', temp_range);
    fprintf('Heating duration: %.1f minutes (%.0f seconds)\n', heating_duration, heating_duration_sec);
    
    filename = input('\nEnter DSC data filename (with extension): ', 's');
    if isempty(filename)
        filename = 'Universal DARK - 1.txt';
    end
    
    try
        data = readtable(filename, 'HeaderLines', 3);
        
        time = data{:, 2};
        heat_flow = data{:, 3};
        temp_sample = data{:, 4};
        temp_ref = data{:, 5};
        
    catch ME
        fprintf('Error reading file: %s\n', ME.message);
        fprintf('Please check the filename and format.\n');
        return;
    end
    
    heating_indices = find(time <= heating_duration_sec);
    
    if isempty(heating_indices)
        fprintf('Warning: Calculated heating duration exceeds available data.\n');
        fprintf('Using all available data points.\n');
        heating_indices = 1:length(time);
    end
    
    time_heating = time(heating_indices);
    heat_flow_heating = heat_flow(heating_indices);
    temp_heating = temp_sample(heating_indices);
    
    fprintf('Data points in heating stage: %d\n', length(heating_indices));
    fprintf('Actual temperature range in data: %.1f°C to %.1f°C\n', ...
            min(temp_heating), max(temp_heating));
    
    figure('Position', [100, 100, 1400, 1200]);
    
    % Top plot - thermogram with baseline correction
    subplot(3,1,1);
    
    % Calculate spline baseline for the entire dataset
    baseline_spline = calculate_spline_baseline(temp_heating, heat_flow_heating);
    heat_flow_corrected = heat_flow_heating - baseline_spline;
    
    % Plot original data
    plot(temp_heating, heat_flow_heating, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Original');
    hold on;
    
    % Plot baseline
    plot(temp_heating, baseline_spline, 'k--', 'LineWidth', 1, 'DisplayName', 'Spline Baseline');
    
    % Plot baseline-corrected data
    plot(temp_heating, heat_flow_corrected, 'r-', 'LineWidth', 2, 'DisplayName', 'Baseline Corrected');
    
    xlabel('Temperature (°C)', 'FontSize', 12);
    ylabel('Heat Flow (W/g)', 'FontSize', 12);
    title('DSC Thermogram', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('show', 'Location', 'best');
    
    % Analyze thermal transitions using baseline-corrected data
    [transition_results] = analyze_thermal_transitions_iso(temp_heating, heat_flow_heating, heat_flow_corrected, heating_rate);
    
    marker_size = 12;
    
    % Glass Transition (Tg) - Plot inflection point, not peak
    if ~isnan(transition_results.Tg_inflection)
        plot(transition_results.Tg_inflection, interp1(temp_heating, heat_flow_heating, transition_results.Tg_inflection), 'ro', ...
             'MarkerSize', marker_size, 'MarkerFaceColor', 'r', 'LineWidth', 2, 'DisplayName', 'Tg');
        text(transition_results.Tg_inflection - 13, interp1(temp_heating, heat_flow_heating, transition_results.Tg_inflection) - 0.1, ...
             sprintf('Tg = %.1f°C', transition_results.Tg_inflection), 'VerticalAlignment', 'bottom', ...
             'FontSize', 11, 'Color', 'red', 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.7]);
    end
    
    % Crystallization (Tc) - Plot peak from baseline-corrected data
    if ~isnan(transition_results.Tc_peak)
        plot(transition_results.Tc_peak, interp1(temp_heating, heat_flow_heating, transition_results.Tc_peak), 'go', ...
             'MarkerSize', marker_size, 'MarkerFaceColor', 'g', 'LineWidth', 2, 'DisplayName', 'Tc');
        text(transition_results.Tc_peak, interp1(temp_heating, heat_flow_heating, transition_results.Tc_peak) + 0.1, ...
             sprintf('Tc = %.1f°C', transition_results.Tc_peak), 'VerticalAlignment', 'bottom', ...
             'FontSize', 11, 'Color', 'green', 'FontWeight', 'bold', 'BackgroundColor', 'white');
    end
    
    % Melting (Tm) - Plot peak from baseline-corrected data
    if ~isnan(transition_results.Tm_peak)
        plot(transition_results.Tm_peak, interp1(temp_heating, heat_flow_heating, transition_results.Tm_peak), 'mo', ...
             'MarkerSize', marker_size, 'MarkerFaceColor', 'm', 'LineWidth', 2, 'DisplayName', 'Tm');
        text(transition_results.Tm_peak + 5, interp1(temp_heating, heat_flow_heating, transition_results.Tm_peak) + 0.1, ...
             sprintf('Tm = %.1f°C', transition_results.Tm_peak), 'VerticalAlignment', 'top', ...
             'FontSize', 11, 'Color', 'magenta', 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.7]);
    end
    
    param_text = sprintf('Heating Rate: %.1f°C/min\nTemp Range: %.1f - %.1f°C\nDuration: %.1f min', ...
                        heating_rate, start_temp, end_temp, heating_duration);
    text(0.02, 0.98, param_text, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
         'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black');
    
    % Middle plot - first derivative analysis
    subplot(3,1,2);
    temp_smooth = smooth(temp_heating, 10);
    heat_flow_smooth = smooth(heat_flow_corrected, 10);
    derivative = gradient(heat_flow_smooth) ./ gradient(temp_smooth);
    
    plot(temp_smooth, derivative, 'r-', 'LineWidth', 2);
    hold on;
    
    % Mark inflection point on derivative plot
    if ~isnan(transition_results.Tg_inflection)
        deriv_at_inflection = interp1(temp_smooth, derivative, transition_results.Tg_inflection);
        plot(transition_results.Tg_inflection, deriv_at_inflection, 'ro', ...
             'MarkerSize', 10, 'MarkerFaceColor', 'r', 'LineWidth', 2);
        text(transition_results.Tg_inflection - 8, deriv_at_inflection, ...
             sprintf('Tg = %.1f°C', transition_results.Tg_inflection), ...
             'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
             'FontSize', 10, 'Color', 'red', 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.7]);
    end
    
    xlabel('Temperature (°C)', 'FontSize', 12);
    ylabel('d(Heat Flow)/dT (W/g/°C)', 'FontSize', 12);
    title('First Derivative Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % Bottom plot - second derivative analysis
    subplot(3,1,3);
    second_derivative = gradient(derivative) ./ gradient(temp_smooth);
    
    plot(temp_smooth, second_derivative, 'b-', 'LineWidth', 2);
    hold on;
    
    % Mark glass transition point on second derivative plot
    if ~isnan(transition_results.Tg_inflection)
        second_deriv_at_inflection = interp1(temp_smooth, second_derivative, transition_results.Tg_inflection);
        plot(transition_results.Tg_inflection, second_deriv_at_inflection, 'ro', ...
             'MarkerSize', 10, 'MarkerFaceColor', 'r', 'LineWidth', 2);
        text(transition_results.Tg_inflection - 0.1, second_deriv_at_inflection - max(second_derivative)*0.4, ...
             sprintf('Tg = %.1f°C', transition_results.Tg_inflection), ...
             'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
             'FontSize', 10, 'Color', 'red', 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.7]);
    end
    
    xlabel('Temperature (°C)', 'FontSize', 12);
    ylabel('d^2(Heat Flow)/dT^2 (W/g/°C^2)', 'FontSize', 12);
    title('Second Derivative Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    create_comprehensive_results_table(transition_results, heating_rate);
    
    fprintf('\n=== DETAILED DSC ANALYSIS RESULTS (ISO Standard) ===\n');
    fprintf('Sample: Universal DARK\n');
    fprintf('Heating Rate: %.1f°C/min\n', heating_rate);
    fprintf('Analysis Range: %.1f - %.1f°C\n', min(temp_heating), max(temp_heating));
    fprintf('Baseline Method: Spline fitting\n');
    fprintf('======================================\n');
    
    % Glass Transition
    if ~isnan(transition_results.Tg_inflection)
        fprintf('Glass Transition Temperature (ISO 11357):\n');
        fprintf('  - Inflection Point (Tg): %.2f°C [PRIMARY VALUE]\n', transition_results.Tg_inflection);
        fprintf('  - Onset (Tg_onset): %.2f°C\n', transition_results.Tg_onset);
        fprintf('  - Peak (Tg_peak): %.2f°C\n', transition_results.Tg_peak);
        fprintf('  - Heat Capacity Change (ΔCp): %.4f W/g/°C\n', transition_results.Tg_delta_cp);
        fprintf('  - Method: ISO 11357 (inflection point of first dip)\n');
        fprintf('  - Baseline: Spline corrected\n');
    else
        fprintf('Glass Transition Temperature: Not detected\n');
    end
    
    % Crystallization
    if ~isnan(transition_results.Tc_peak)
        fprintf('Crystallization Temperature:\n');
        fprintf('  - Onset (Tc_onset): %.2f°C\n', transition_results.Tc_onset);
        fprintf('  - Peak (Tc_peak): %.2f°C\n', transition_results.Tc_peak);
        fprintf('  - Integral (ΔH): %.2f J/g\n', transition_results.Tc_integral);
        fprintf('  - Peak Type: Exothermic\n');
        fprintf('  - Method: Baseline-corrected peak detection\n');
    else
        fprintf('Crystallization Temperature: Not detected\n');
    end
    
    % Melting
    if ~isnan(transition_results.Tm_peak)
        fprintf('Melting Temperature:\n');
        fprintf('  - Onset (Tm_onset): %.2f°C\n', transition_results.Tm_onset);
        fprintf('  - Peak (Tm_peak): %.2f°C\n', transition_results.Tm_peak);
        fprintf('  - Integral (ΔH): %.2f J/g\n', transition_results.Tm_integral);
        fprintf('  - Peak Type: Endothermic\n');
        fprintf('  - Method: Baseline-corrected peak detection\n');
    else
        fprintf('Melting Temperature: Not detected\n');
    end
    
    fprintf('======================================\n');
    
    save_option = input('\nSave results to file? (y/n): ', 's');
    if strcmpi(save_option, 'y')
        save_comprehensive_results(transition_results, heating_rate, filename);
    end
    
end

function baseline_spline = calculate_spline_baseline(temperature, heat_flow)
    % Calculate spline baseline similar to DSC STARE software
    
    % Identify baseline regions (exclude transition zones)
    n_points = length(temperature);
    baseline_mask = true(n_points, 1);
    
    % Smooth data for baseline detection
    temp_smooth = smooth(temperature, 20);
    hf_smooth = smooth(heat_flow, 20);
    
    % Calculate derivative to find transition regions
    dhf_dt = gradient(hf_smooth) ./ gradient(temp_smooth);
    dhf_dt_smooth = smooth(dhf_dt, 10);
    
    % Mark regions with high derivative activity as transitions
    derivative_threshold = 0.5 * std(dhf_dt_smooth);
    transition_mask = abs(dhf_dt_smooth) > derivative_threshold;
    
    % Expand transition regions
    expansion_width = 50; % points to expand around transitions
    for i = 1:length(transition_mask)
        if transition_mask(i)
            start_idx = max(1, i - expansion_width);
            end_idx = min(length(transition_mask), i + expansion_width);
            baseline_mask(start_idx:end_idx) = false;
        end
    end
    
    % Ensure we have enough baseline points
    if sum(baseline_mask) < 20
        % If too few baseline points, use end regions
        baseline_mask = false(n_points, 1);
        baseline_mask(1:round(n_points*0.15)) = true;
        baseline_mask(round(n_points*0.85):end) = true;
    end
    
    % Fit spline to baseline regions
    baseline_temps = temp_smooth(baseline_mask);
    baseline_hf = hf_smooth(baseline_mask);
    
    % Create spline baseline
    try
        baseline_spline = interp1(baseline_temps, baseline_hf, temp_smooth, 'spline', 'extrap');
    catch
        % Fallback to linear baseline if spline fails
        baseline_spline = interp1(baseline_temps, baseline_hf, temp_smooth, 'linear', 'extrap');
    end
    
    % Smooth the baseline
    baseline_spline = smooth(baseline_spline, 10);
end

function transition_results = analyze_thermal_transitions_iso(temperature, heat_flow_original, heat_flow_corrected, heating_rate)
    
    transition_results = struct();
    
    % Initialize all fields
    fields = {'Tg_onset', 'Tg_peak', 'Tg_inflection', 'Tg_delta_cp', 'Tg_method', 'Tg_type', ...
              'Tc_onset', 'Tc_peak', 'Tc_integral', 'Tc_method', 'Tc_type', ...
              'Tm_onset', 'Tm_peak', 'Tm_integral', 'Tm_method', 'Tm_type'};
    
    for i = 1:length(fields)
        if contains(fields{i}, 'method') || contains(fields{i}, 'type')
            transition_results.(fields{i}) = '';
        else
            transition_results.(fields{i}) = NaN;
        end
    end
    
    % Smooth data for analysis
    temp_smooth = smooth(temperature, 15);
    hf_corrected_smooth = smooth(heat_flow_corrected, 15);
    
    % Calculate derivatives
    dHF_dT = gradient(hf_corrected_smooth) ./ gradient(temp_smooth);
    d2HF_dT2 = gradient(dHF_dT) ./ gradient(temp_smooth);
    
    % 1. Glass Transition Temperature (Tg) - ISO 11357 Standard
    % Look for the minimum point in second derivative between 40-80°C
    tg_range = find(temp_smooth >= 40 & temp_smooth <= 80);
    if ~isempty(tg_range)
        % Find the minimum point in second derivative (most negative value)
        [~, min_idx] = min(d2HF_dT2(tg_range));
        if ~isempty(min_idx)
            tg_min_idx = tg_range(min_idx);
            transition_results.Tg_inflection = temp_smooth(tg_min_idx);
            transition_results.Tg_method = 'ISO 11357 (min in 2nd deriv 40-80°C)';
            transition_results.Tg_type = 'Step change';
            
            % Calculate onset using tangent method
            if tg_min_idx > 30 && tg_min_idx < length(temp_smooth) - 30
                % Define baseline regions
                baseline_before_range = max(1, tg_min_idx-50):tg_min_idx-20;
                baseline_after_range = tg_min_idx+20:min(length(temp_smooth), tg_min_idx+50);
                
                baseline_before = mean(hf_corrected_smooth(baseline_before_range));
                baseline_after = mean(hf_corrected_smooth(baseline_after_range));
                
                % Calculate ΔCp
                transition_results.Tg_delta_cp = (baseline_after - baseline_before) / heating_rate;
                
                % Find steepest point around minimum
                steep_range = max(1, tg_min_idx-10):min(length(temp_smooth), tg_min_idx+10);
                [~, steep_rel_idx] = max(abs(dHF_dT(steep_range)));
                steep_idx = steep_range(steep_rel_idx);
                
                % Calculate onset using tangent method
                tangent_slope = dHF_dT(steep_idx);
                tangent_intercept = hf_corrected_smooth(steep_idx) - tangent_slope * temp_smooth(steep_idx);
                onset_temp = (baseline_before - tangent_intercept) / tangent_slope;
                
                if onset_temp > temp_smooth(1) && onset_temp < transition_results.Tg_inflection
                    transition_results.Tg_onset = onset_temp;
                else
                    transition_results.Tg_onset = transition_results.Tg_inflection - 5;
                end
                
                % Find peak (maximum rate of change)
                [~, peak_rel_idx] = max(dHF_dT(tg_range));
                peak_idx = tg_range(peak_rel_idx);
                transition_results.Tg_peak = temp_smooth(peak_idx);
            end
        end
    end
    
    % 2. Crystallization Temperature (Tc) - Exothermic Peak
    tc_range = find(temp_smooth >= 70 & temp_smooth <= 140);
    if ~isempty(tc_range)
        hf_range_data = hf_corrected_smooth(tc_range);
        
        % Find exothermic peaks (positive values in corrected data)
        [pks, locs] = findpeaks(hf_range_data, 'MinPeakHeight', 0.01, 'MinPeakDistance', 20);
        
        if ~isempty(pks)
            [~, max_peak_idx] = max(pks);
            tc_idx = tc_range(locs(max_peak_idx));
            transition_results.Tc_peak = temp_smooth(tc_idx);
            transition_results.Tc_method = 'Baseline-corrected peak detection';
            transition_results.Tc_type = 'Exothermic';
            
            % Calculate onset and integral
            [onset, integral] = calculate_onset_and_integral(temp_smooth, hf_corrected_smooth, tc_idx, heating_rate, 1);
            transition_results.Tc_onset = onset;
            transition_results.Tc_integral = integral;
        end
    end
    
    % 3. Melting Temperature (Tm) - Endothermic Peak
    tm_range = find(temp_smooth >= 140 & temp_smooth <= 200);
    if ~isempty(tm_range)
        hf_range_data = hf_corrected_smooth(tm_range);
        
        % Find endothermic peaks (negative values in corrected data)
        [pks, locs] = findpeaks(-hf_range_data, 'MinPeakHeight', 0.01, 'MinPeakDistance', 20);
        
        if ~isempty(pks)
            [~, max_peak_idx] = max(pks);
            tm_idx = tm_range(locs(max_peak_idx));
            transition_results.Tm_peak = temp_smooth(tm_idx);
            transition_results.Tm_method = 'Baseline-corrected peak detection';
            transition_results.Tm_type = 'Endothermic';
            
            % Calculate onset and integral
            [onset, integral] = calculate_onset_and_integral(temp_smooth, hf_corrected_smooth, tm_idx, heating_rate, -1);
            transition_results.Tm_onset = onset;
            transition_results.Tm_integral = integral;
        end
    end
end

function [onset_temp, integral_value] = calculate_onset_and_integral(temperature, heat_flow, peak_idx, heating_rate, direction)
    
    onset_temp = NaN;
    integral_value = NaN;
    
    if peak_idx < 50 || peak_idx > length(temperature) - 50
        return;
    end
    
    % Define integration region around peak
    range_width = 100; % ±100 data points around peak
    start_idx = max(1, peak_idx - range_width);
    end_idx = min(length(temperature), peak_idx + range_width);
    
    temp_region = temperature(start_idx:end_idx);
    hf_region = heat_flow(start_idx:end_idx);
    
    % Find onset using extrapolated baseline method
    baseline_before_range = 1:round(length(temp_region)*0.2);
    baseline_after_range = round(length(temp_region)*0.8):length(temp_region);
    
    baseline_before = mean(hf_region(baseline_before_range));
    baseline_after = mean(hf_region(baseline_after_range));
    
    % Create linear baseline
    baseline = linspace(baseline_before, baseline_after, length(hf_region));
    
    % Find onset where signal deviates from baseline
    deviation_threshold = 0.02; % Adjust as needed
    
    if direction == 1 % exothermic
        deviation_points = find(hf_region > baseline' + deviation_threshold);
    else % endothermic
        deviation_points = find(hf_region < baseline' - deviation_threshold);
    end
    
    if ~isempty(deviation_points)
        onset_temp = temp_region(deviation_points(1));
        
        % Calculate integral (area under curve)
        peak_relative_idx = peak_idx - start_idx + 1;
        
        if direction == 1 % exothermic
            integration_range = deviation_points(1):min(length(temp_region), peak_relative_idx + 50);
        else % endothermic
            integration_range = deviation_points(1):min(length(temp_region), peak_relative_idx + 50);
        end
        
        if length(integration_range) > 5
            temp_int = temp_region(integration_range);
            hf_int = hf_region(integration_range);
            baseline_int = baseline(integration_range);
            
            % Calculate area using trapezoidal rule
            area = trapz(temp_int, abs(hf_int - baseline_int'));
            
            % Convert to J/g (assuming heating rate in °C/min)
            integral_value = area * 60 / heating_rate; % Convert to J/g
        end
    else
        onset_temp = temperature(peak_idx) - 10; % Fallback
    end
end

function create_comprehensive_results_table(results, heating_rate)
    
    % Create a figure for the table
    f = figure('Position', [100, 100, 1200, 400], 'MenuBar', 'none', 'ToolBar', 'none');
    axis off;
    
    % Title
    uicontrol('Style', 'text', ...
              'String', 'DSC Thermal Analysis Results', ...
              'Position', [20, 350, 1160, 40], ...
              'FontSize', 16, 'FontWeight', 'bold', ...
              'HorizontalAlignment', 'center');
    
    % Column headers
    headers = {'Transition', 'Onset (°C)', 'Peak (°C)', 'Inflection (°C)', 'Type', 'Method'};
    col_widths = [150, 100, 100, 100, 150, 200];
    x_pos = 20;
    
    for col = 1:length(headers)
        uicontrol('Style', 'text', ...
                  'String', headers{col}, ...
                  'Position', [x_pos, 300, col_widths(col), 30], ...
                  'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'center', ...
                  'BackgroundColor', [0.8 0.8 0.8]);
        x_pos = x_pos + col_widths(col);
    end
    
    % Data rows
    row_height = 30;
    y_pos = 270;
    transitions = {};
    
    % Glass Transition
    if ~isnan(results.Tg_inflection)
        onset_str = sprintf('%.1f', results.Tg_onset);
        peak_str = sprintf('%.1f', results.Tg_peak);
        inflection_str = sprintf('%.1f', results.Tg_inflection);
        
        transitions{end+1} = {'Tg', onset_str, peak_str, inflection_str, 'Step Change', 'ISO 11357'};
    end
    
    % Crystallization
    if ~isnan(results.Tc_peak)
        onset_str = sprintf('%.1f', results.Tc_onset);
        peak_str = sprintf('%.1f', results.Tc_peak);
        inflection_str = '-';
        
        transitions{end+1} = {'Tc', onset_str, peak_str, inflection_str, 'Exothermic', 'Peak maxima'};
    end
    
    % Melting
    if ~isnan(results.Tm_peak)
        onset_str = sprintf('%.1f', results.Tm_onset);
        peak_str = sprintf('%.1f', results.Tm_peak);
        inflection_str = '-';
        
        transitions{end+1} = {'Tm', onset_str, peak_str, inflection_str, 'Endothermic', 'Peak minima'};
    end
    
    % Add transition rows
    for row = 1:length(transitions)
        x_pos = 20;
        for col = 1:length(transitions{row})
            bg_color = [1 1 1];
            if row == 1, bg_color = [1 0.9 0.9]; end % Light red for Tg
            if row == 2, bg_color = [0.9 1 0.9]; end % Light green for Tc
            if row == 3, bg_color = [0.9 0.9 1]; end % Light blue for Tm
            
            % Highlight inflection point for glass transition
            if row == 1 && col == 4
                bg_color = [1 0.8 0.8]; % Darker red for Tg inflection
            end
            
            uicontrol('Style', 'text', ...
                      'String', transitions{row}{col}, ...
                      'Position', [x_pos, y_pos, col_widths(col), row_height], ...
                      'FontSize', 10, ...
                      'HorizontalAlignment', 'center', ...
                      'BackgroundColor', bg_color);
            x_pos = x_pos + col_widths(col);
        end
        y_pos = y_pos - row_height;
    end
end

function save_comprehensive_results(results, heating_rate, filename)
    
    [~, base_name, ~] = fileparts(filename);
    output_filename = sprintf('%s_DSC_Results.txt', base_name);
    
    fid = fopen(output_filename, 'w');
    
    fprintf(fid, '=== DSC ANALYSIS RESULTS ===\n');
    fprintf(fid, 'Analysis Date: %s\n', datestr(now));
    fprintf(fid, 'Original Data File: %s\n', filename);
    fprintf(fid, 'Heating Rate: %.1f°C/min\n\n', heating_rate);
    
    fprintf(fid, 'THERMAL TRANSITIONS:\n');
    fprintf(fid, '================================================\n');
    
    % Glass Transition
    if ~isnan(results.Tg_peak)
        fprintf(fid, 'Glass Transition:\n');
        fprintf(fid, '  Onset Temperature: %.2f°C\n', results.Tg_onset);
        fprintf(fid, '  Peak Temperature: %.2f°C\n', results.Tg_peak);
        fprintf(fid, '  Heat Capacity Change (ΔCp): %.4f W/g/°C\n\n', results.Tg_delta_cp);
    end
    
    % Crystallization
    if ~isnan(results.Tc_peak)
        fprintf(fid, 'Crystallization (Exothermic Peak):\n');
        fprintf(fid, '  Onset Temperature: %.2f°C\n', results.Tc_onset);
        fprintf(fid, '  Peak Temperature: %.2f°C\n\n', results.Tc_peak);
    end
    
    % Melting
    if ~isnan(results.Tm_peak)
        fprintf(fid, 'Melting (Endothermic Peak):\n');
        fprintf(fid, '  Onset Temperature: %.2f°C\n', results.Tm_onset);
        fprintf(fid, '  Peak Temperature: %.2f°C\n\n', results.Tm_peak);
    end
    
    fprintf(fid, 'Analysis completed using DSC analysis script.\n');
    
    fclose(fid);
    
    fprintf('Results saved to: %s\n', output_filename);
end