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
    
    figure('Position', [100, 100, 1400, 900]);
    
    subplot(2,2,[1,2]);
    plot(temp_heating, heat_flow_heating, 'b-', 'LineWidth', 2);
    xlabel('Temperature (°C)', 'FontSize', 12);
    ylabel('Heat Flow (W/g)', 'FontSize', 12);
    title('DSC Thermogram - Heating Stage Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    hold on;
    
    [transition_results] = analyze_thermal_transitions(temp_heating, heat_flow_heating, heating_rate);
    
    marker_size = 12;
    
    % Glass Transition (Tg)
    if ~isnan(transition_results.Tg_peak)
        plot(transition_results.Tg_peak, interp1(temp_heating, heat_flow_heating, transition_results.Tg_peak), 'ro', ...
             'MarkerSize', marker_size, 'MarkerFaceColor', 'r', 'LineWidth', 2);
        text(transition_results.Tg_peak, interp1(temp_heating, heat_flow_heating, transition_results.Tg_peak) + 0.02, ...
             sprintf('Tg = %.1f°C', transition_results.Tg_peak), 'VerticalAlignment', 'bottom', ...
             'FontSize', 11, 'Color', 'red', 'FontWeight', 'bold', 'BackgroundColor', 'white');
    end
    
    % Crystallization (Tc)
    if ~isnan(transition_results.Tc_peak)
        plot(transition_results.Tc_peak, interp1(temp_heating, heat_flow_heating, transition_results.Tc_peak), 'go', ...
             'MarkerSize', marker_size, 'MarkerFaceColor', 'g', 'LineWidth', 2);
        text(transition_results.Tc_peak, interp1(temp_heating, heat_flow_heating, transition_results.Tc_peak) + 0.02, ...
             sprintf('Tc = %.1f°C', transition_results.Tc_peak), 'VerticalAlignment', 'bottom', ...
             'FontSize', 11, 'Color', 'green', 'FontWeight', 'bold', 'BackgroundColor', 'white');
    end
    
    % Melting (Tm)
    if ~isnan(transition_results.Tm_peak)
        plot(transition_results.Tm_peak, interp1(temp_heating, heat_flow_heating, transition_results.Tm_peak), 'mo', ...
             'MarkerSize', marker_size, 'MarkerFaceColor', 'm', 'LineWidth', 2);
        text(transition_results.Tm_peak, interp1(temp_heating, heat_flow_heating, transition_results.Tm_peak) - 0.02, ...
             sprintf('Tm = %.1f°C', transition_results.Tm_peak), 'VerticalAlignment', 'top', ...
             'FontSize', 11, 'Color', 'magenta', 'FontWeight', 'bold', 'BackgroundColor', 'white');
    end
    
    param_text = sprintf('Heating Rate: %.1f°C/min\nTemp Range: %.1f - %.1f°C\nDuration: %.1f min', ...
                        heating_rate, start_temp, end_temp, heating_duration);
    text(0.02, 0.98, param_text, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
         'FontSize', 10, 'BackgroundColor', 'yellow', 'EdgeColor', 'black');
    
    subplot(2,2,3);
    temp_smooth = smooth(temp_heating, 10);
    heat_flow_smooth = smooth(heat_flow_heating, 10);
    derivative = gradient(heat_flow_smooth) ./ gradient(temp_smooth);
    
    plot(temp_smooth, derivative, 'r-', 'LineWidth', 1.5);
    xlabel('Temperature (°C)', 'FontSize', 11);
    ylabel('d(Heat Flow)/dT (W/g/°C)', 'FontSize', 11);
    title('Derivative Analysis', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
    
    subplot(2,2,4);
    axis off;
    
    create_comprehensive_results_table(transition_results, heating_rate);
    
    fprintf('\n=== DETAILED DSC ANALYSIS RESULTS ===\n');
    fprintf('Sample: Universal DARK\n');
    fprintf('Heating Rate: %.1f°C/min\n', heating_rate);
    fprintf('Analysis Range: %.1f - %.1f°C\n', min(temp_heating), max(temp_heating));
    fprintf('======================================\n');
    
    % Glass Transition
    if ~isnan(transition_results.Tg_peak)
        fprintf('Glass Transition Temperature:\n');
        fprintf('  - Onset (Tg_onset): %.2f°C\n', transition_results.Tg_onset);
        fprintf('  - Peak (Tg_peak): %.2f°C\n', transition_results.Tg_peak);
        fprintf('  - Heat Capacity Change (ΔCp): %.4f W/g/°C\n', transition_results.Tg_delta_cp);
        fprintf('  - Integral: %.2f J/g\n', transition_results.Tg_integral);
        fprintf('  - Method: ISO 11357 (inflection point)\n');
        fprintf('  - Peak Type: Step change\n');
    else
        fprintf('Glass Transition Temperature: Not detected\n');
    end
    
    % Crystallization
    if ~isnan(transition_results.Tc_peak)
        fprintf('Crystallization Temperature:\n');
        fprintf('  - Onset (Tc_onset): %.2f°C\n', transition_results.Tc_onset);
        fprintf('  - Peak (Tc_peak): %.2f°C\n', transition_results.Tc_peak);
        fprintf('  - Crystallization Enthalpy (ΔHc): %.2f J/g\n', transition_results.Tc_enthalpy);
        fprintf('  - Integral: %.2f J/g\n', transition_results.Tc_integral);
        fprintf('  - Peak Type: Endothermic\n');
        fprintf('  - Method: Peak maximum detection\n');
    else
        fprintf('Crystallization Temperature: Not detected\n');
    end
    
    % Melting
    if ~isnan(transition_results.Tm_peak)
        fprintf('Melting Temperature:\n');
        fprintf('  - Onset (Tm_onset): %.2f°C\n', transition_results.Tm_onset);
        fprintf('  - Peak (Tm_peak): %.2f°C\n', transition_results.Tm_peak);
        fprintf('  - Melting Enthalpy (ΔHm): %.2f J/g\n', transition_results.Tm_enthalpy);
        fprintf('  - Integral: %.2f J/g\n', transition_results.Tm_integral);
        fprintf('  - Peak Type: Exothermic\n');
        fprintf('  - Method: Peak minimum detection\n');
    else
        fprintf('Melting Temperature: Not detected\n');
    end
    
    fprintf('======================================\n');
    
    save_option = input('\nSave results to file? (y/n): ', 's');
    if strcmpi(save_option, 'y')
        save_comprehensive_results(transition_results, heating_rate, filename);
    end
    
end

function transition_results = analyze_thermal_transitions(temperature, heat_flow, heating_rate)
    
    transition_results = struct();
    
    fields = {'Tg_onset', 'Tg_peak', 'Tg_delta_cp', 'Tg_integral', 'Tg_method', 'Tg_type', ...
              'Tc_onset', 'Tc_peak', 'Tc_enthalpy', 'Tc_integral', 'Tc_method', 'Tc_type', ...
              'Tm_onset', 'Tm_peak', 'Tm_enthalpy', 'Tm_integral', 'Tm_method', 'Tm_type'};
    
    for i = 1:length(fields)
        if contains(fields{i}, 'method') || contains(fields{i}, 'type')
            transition_results.(fields{i}) = '';
        else
            transition_results.(fields{i}) = NaN;
        end
    end
    
    temp_smooth = smooth(temperature, 15);
    heat_flow_smooth = smooth(heat_flow, 15);
    
    dHF_dT = gradient(heat_flow_smooth) ./ gradient(temp_smooth);
    d2HF_dT2 = gradient(dHF_dT) ./ gradient(temp_smooth);
    
    % 1. Glass Transition Temperature (Tg)
    tg_range = find(temp_smooth >= 40 & temp_smooth <= 120);
    if ~isempty(tg_range)
        [~, max_idx] = max(d2HF_dT2(tg_range));
        if ~isempty(max_idx)
            tg_idx = tg_range(max_idx);
            transition_results.Tg_peak = temp_smooth(tg_idx);
            transition_results.Tg_method = 'ISO 11357 (inflection point)';
            transition_results.Tg_type = 'Step change';
            
            if tg_idx > 30 && tg_idx < length(temp_smooth) - 30
                baseline_before_range = max(1, tg_idx-40):tg_idx-20;
                baseline_after_range = tg_idx+20:min(length(temp_smooth), tg_idx+40);
                
 
                baseline_before = mean(heat_flow_smooth(baseline_before_range));
                baseline_after = mean(heat_flow_smooth(baseline_after_range));
                
                transition_range = tg_idx-15:tg_idx+15;
                [~, steep_idx] = max(abs(dHF_dT(transition_range)));
                steep_global_idx = transition_range(steep_idx);
                
                tangent_slope = dHF_dT(steep_global_idx);
                tangent_intercept = heat_flow_smooth(steep_global_idx) - tangent_slope * temp_smooth(steep_global_idx);
                
                onset_temp = (baseline_before - tangent_intercept) / tangent_slope;
                
                if onset_temp > temp_smooth(1) && onset_temp < transition_results.Tg_peak
                    transition_results.Tg_onset = onset_temp;
                else
                    deviation_threshold = 0.5 * std(heat_flow_smooth(baseline_before_range));
                    for j = baseline_before_range(end):tg_idx
                        if abs(heat_flow_smooth(j) - baseline_before) > deviation_threshold
                            transition_results.Tg_onset = temp_smooth(j);
                            break;
                        end
                    end
                end
                
                transition_results.Tg_delta_cp = baseline_after - baseline_before;
                
                integration_range = find(temp_smooth >= transition_results.Tg_onset & temp_smooth <= transition_results.Tg_peak + 10);
                if ~isempty(integration_range)
                    baseline_integration = linspace(baseline_before, baseline_after, length(integration_range));
                    corrected_hf = heat_flow_smooth(integration_range) - baseline_integration';
                    
                    dt = mean(diff(temp_smooth(integration_range))) / (heating_rate/60);
                    transition_results.Tg_integral = trapz(corrected_hf) * dt * (heating_rate/60);
                end
            end
        end
    end
    
    % 2. Crystallization Temperature (Tc)
    tc_range = find(temp_smooth >= 70 & temp_smooth <= 120);
    if ~isempty(tc_range)
        hf_range_data = heat_flow_smooth(tc_range);
        data_std = std(hf_range_data);
        data_mean = mean(hf_range_data);
        
        min_peak_height = data_mean + 1.5 * data_std;
        
        try
            [pks_pos, locs_pos] = findpeaks(hf_range_data, ...
                                           'MinPeakHeight', min_peak_height, 'MinPeakDistance', 20);
            if ~isempty(locs_pos)
                [~, max_peak_idx] = max(pks_pos);
                tc_idx = tc_range(locs_pos(max_peak_idx));
                transition_results.Tc_peak = temp_smooth(tc_idx);
                transition_results.Tc_method = 'Peak maximum detection';
                transition_results.Tc_type = 'Endothermic';
                
                [onset, enthalpy, integral] = calculate_improved_transition_parameters(...
                    temp_smooth, heat_flow_smooth, tc_idx, 1, heating_rate);
                transition_results.Tc_onset = onset;
                transition_results.Tc_enthalpy = abs(enthalpy);
                transition_results.Tc_integral = integral;
            end
        catch
        end
    end
    
    % 3. Melting Temperature (Tm)
    tm_range = find(temp_smooth >= 150 & temp_smooth <= 200);
    if ~isempty(tm_range)
        hf_range_data = heat_flow_smooth(tm_range);
        neg_hf_data = -hf_range_data;
        neg_data_std = std(neg_hf_data);
        neg_data_mean = mean(neg_hf_data);
        
        min_peak_height = neg_data_mean + 1.5 * neg_data_std;
        
        try
            [pks_neg, locs_neg] = findpeaks(neg_hf_data, ...
                                           'MinPeakHeight', min_peak_height, 'MinPeakDistance', 20);
            if ~isempty(locs_neg)
                [~, max_peak_idx] = max(pks_neg);
                tm_idx = tm_range(locs_neg(max_peak_idx));
                transition_results.Tm_peak = temp_smooth(tm_idx);
                transition_results.Tm_method = 'Peak minimum detection';
                transition_results.Tm_type = 'Exothermic';
                
                [onset, enthalpy, integral] = calculate_improved_transition_parameters(...
                    temp_smooth, heat_flow_smooth, tm_idx, -1, heating_rate);
                transition_results.Tm_onset = onset;
                transition_results.Tm_enthalpy = abs(enthalpy);
                transition_results.Tm_integral = integral;
            end
        catch
        end
    end
    
end

function [onset_temp, enthalpy, integral] = calculate_improved_transition_parameters(temperature, heat_flow, peak_idx, direction, heating_rate)
    
    onset_temp = NaN;
    enthalpy = NaN;
    integral = NaN;
    
    if peak_idx < 50 || peak_idx > length(temperature) - 50
        return;
    end
    
    range_width = 60; % ±60 data points around peak
    start_idx = max(1, peak_idx - range_width);
    end_idx = min(length(temperature), peak_idx + range_width);
    
    temp_region = temperature(start_idx:end_idx);
    hf_region = heat_flow(start_idx:end_idx);
    
    baseline_before_range = 1:round(length(temp_region)*0.25);
    baseline_after_range = round(length(temp_region)*0.75):length(temp_region);
    
    baseline_before = mean(hf_region(baseline_before_range));
    baseline_after = mean(hf_region(baseline_after_range));

    baseline = linspace(baseline_before, baseline_after, length(hf_region));

    corrected_hf = hf_region - baseline';
    
    if direction == 1 % endothermic
        [~, steep_idx] = max(gradient(corrected_hf));
    else % exothermic
        [~, steep_idx] = min(gradient(corrected_hf));
    end
    
    if steep_idx > 5 && steep_idx < length(corrected_hf) - 5
        tangent_slope = gradient(corrected_hf(steep_idx-2:steep_idx+2));
        tangent_slope = mean(tangent_slope);
        
        onset_offset = -corrected_hf(steep_idx) / tangent_slope;
        onset_temp_idx = steep_idx + onset_offset;
        
        if onset_temp_idx > 1 && onset_temp_idx <= length(temp_region)
            onset_temp = interp1(1:length(temp_region), temp_region, onset_temp_idx);
        end
    end
    
    if isnan(onset_temp)
        threshold = 0.1 * max(abs(corrected_hf));
        if direction == 1 % endothermic
            onset_candidates = find(corrected_hf > threshold);
        else % exothermic
            onset_candidates = find(corrected_hf < -threshold);
        end
        
        if ~isempty(onset_candidates)
            onset_temp = temp_region(onset_candidates(1));
        else
            onset_temp = temp_region(steep_idx) - 5;
        end
    end

    integral_raw = trapz(temp_region, corrected_hf);

    conversion_factor = 60 / heating_rate;
    
    integral = integral_raw * conversion_factor;
    enthalpy = abs(integral);
    
    if direction == -1
        integral = -integral;
    end
    
end

function create_comprehensive_results_table(results, heating_rate)
    
    title('DSC Analysis Results', 'FontSize', 14, 'FontWeight', 'bold');
    
    row_labels = {};
    onset_temps = {};
    peak_temps = {};
    enthalpies = {};
    methods = {};
    
    row = 1;
    
    % Glass Transition
    if ~isnan(results.Tg_peak)
        row_labels{row} = 'Glass Transition (Tg)';
        onset_temps{row} = sprintf('%.1f°C', results.Tg_onset);
        peak_temps{row} = sprintf('%.1f°C', results.Tg_peak);
        enthalpies{row} = sprintf('ΔCp: %.3f W/g/°C', results.Tg_delta_cp);
        methods{row} = sprintf('%s | %s', results.Tg_type, results.Tg_method);
        row = row + 1;
    end
    
    % Crystallization
    if ~isnan(results.Tc_peak)
        row_labels{row} = 'Crystallization (Tc)';
        onset_temps{row} = sprintf('%.1f°C', results.Tc_onset);
        peak_temps{row} = sprintf('%.1f°C', results.Tc_peak);
        enthalpies{row} = sprintf('ΔH: %.1f J/g', results.Tc_enthalpy);
        methods{row} = sprintf('%s | %s', results.Tc_type, results.Tc_method);
        row = row + 1;
    end
    
    % Melting
    if ~isnan(results.Tm_peak)
        row_labels{row} = 'Melting (Tm)';
        onset_temps{row} = sprintf('%.1f°C', results.Tm_onset);
        peak_temps{row} = sprintf('%.1f°C', results.Tm_peak);
        enthalpies{row} = sprintf('ΔH: %.1f J/g', results.Tm_enthalpy);
        methods{row} = sprintf('%s | %s', results.Tm_type, results.Tm_method);
        row = row + 1;
    end
    
    row_labels{row} = 'Heating Rate';
    onset_temps{row} = '';
    peak_temps{row} = sprintf('%.1f°C/min', heating_rate);
    enthalpies{row} = '';
    methods{row} = '';
    
    if ~isempty(row_labels)
        y_positions = linspace(0.85, 0.05, length(row_labels));
        
        text(0.02, 0.95, 'Transition', 'FontWeight', 'bold', 'FontSize', 10);
        text(0.25, 0.95, 'Onset', 'FontWeight', 'bold', 'FontSize', 10);
        text(0.38, 0.95, 'Peak', 'FontWeight', 'bold', 'FontSize', 10);
        text(0.50, 0.95, 'Enthalpy', 'FontWeight', 'bold', 'FontSize', 10);
        text(0.68, 0.95, 'Type | Method', 'FontWeight', 'bold', 'FontSize', 10);
        
        for i = 1:length(row_labels)
            text(0.02, y_positions(i), row_labels{i}, 'FontSize', 9);
            text(0.25, y_positions(i), onset_temps{i}, 'FontSize', 9, 'FontWeight', 'bold');
            text(0.38, y_positions(i), peak_temps{i}, 'FontSize', 9, 'FontWeight', 'bold');
            text(0.50, y_positions(i), enthalpies{i}, 'FontSize', 9);
            text(0.68, y_positions(i), methods{i}, 'FontSize', 8);
        end
        
        line([0.02, 0.98], [0.90, 0.90], 'Color', 'black', 'LineWidth', 1);
        
    else
        text(0.5, 0.5, 'No thermal transitions detected', 'HorizontalAlignment', 'center', ...
             'FontSize', 12, 'Color', 'red');
    end
end

function save_comprehensive_results(results, heating_rate, filename)
    
    [~, base_name, ~] = fileparts(filename);
    output_filename = sprintf('%s_DSC_Results_Complete.txt', base_name);
    
    fid = fopen(output_filename, 'w');
    
    fprintf(fid, '=== COMPREHENSIVE DSC ANALYSIS RESULTS ===\n');
    fprintf(fid, 'Analysis Date: %s\n', datestr(now));
    fprintf(fid, 'Original Data File: %s\n', filename);
    fprintf(fid, 'Heating Rate: %.1f°C/min\n\n', heating_rate);
    
    fprintf(fid, 'THERMAL TRANSITIONS (Corrected Peak Assignments):\n');
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
        fprintf(fid, 'Crystallization (Endothermic Peak):\n');
        fprintf(fid, '  Onset Temperature: %.2f°C\n', results.Tc_onset);
        fprintf(fid, '  Peak Temperature: %.2f°C\n', results.Tc_peak);
        fprintf(fid, '  Enthalpy (ΔHc): %.2f J/g\n', results.Tc_enthalpy);
        fprintf(fid, '  Integral: %.2f J/g\n\n', results.Tc_integral);
    end
    
    % Melting
    if ~isnan(results.Tm_peak)
        fprintf(fid, 'Melting (Exothermic Peak):\n');
        fprintf(fid, '  Onset Temperature: %.2f°C\n', results.Tm_onset);
        fprintf(fid, '  Peak Temperature: %.2f°C\n', results.Tm_peak);
        fprintf(fid, '  Enthalpy (ΔHm): %.2f J/g\n', results.Tm_enthalpy);
        fprintf(fid, '  Integral: %.2f J/g\n\n', results.Tm_integral);
    end
    
    fprintf(fid, 'Note: Peak assignments have been corrected:\n');
    fprintf(fid, '- Crystallization: Endothermic peak (upward)\n');
    fprintf(fid, '- Melting: Exothermic peak (downward)\n');
    fprintf(fid, '\nAnalysis completed using corrected DSC analysis script.\n');
    
    fclose(fid);
    
    fprintf('Comprehensive results saved to: %s\n', output_filename);
end