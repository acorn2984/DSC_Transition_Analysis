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
    
    % Top plot - thermogram (now using subplot(2,1,1))
    subplot(2,1,1);
    plot(temp_heating, heat_flow_heating, 'b-', 'LineWidth', 2);
    xlabel('Temperature (°C)', 'FontSize', 12);
    ylabel('Heat Flow (W/g)', 'FontSize', 12);
    title('DSC Thermogram', 'FontSize', 14, 'FontWeight', 'bold');
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
    
    subplot(2,1,2);
    temp_smooth = smooth(temp_heating, 10);
    heat_flow_smooth = smooth(heat_flow_heating, 10);
    derivative = gradient(heat_flow_smooth) ./ gradient(temp_smooth);
    
    plot(temp_smooth, derivative, 'r-', 'LineWidth', 2);
    xlabel('Temperature (°C)', 'FontSize', 12);
    ylabel('d(Heat Flow)/dT (W/g/°C)', 'FontSize', 12);
    title('Derivative Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
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
        fprintf('  - Peak Type: Exothermic\n');
        fprintf('  - Method: Peak maximum detection\n');
    else
        fprintf('Crystallization Temperature: Not detected\n');
    end
    
    % Melting
    if ~isnan(transition_results.Tm_peak)
        fprintf('Melting Temperature:\n');
        fprintf('  - Onset (Tm_onset): %.2f°C\n', transition_results.Tm_onset);
        fprintf('  - Peak (Tm_peak): %.2f°C\n', transition_results.Tm_peak);
        fprintf('  - Peak Type: Endothermic\n');
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
    
    fields = {'Tg_onset', 'Tg_peak', 'Tg_delta_cp', 'Tg_method', 'Tg_type', ...
              'Tc_onset', 'Tc_peak', 'Tc_method', 'Tc_type', ...
              'Tm_onset', 'Tm_peak', 'Tm_method', 'Tm_type'};
    
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
                
                onset = calculate_onset_temperature(temp_smooth, heat_flow_smooth, tc_idx, 1);
                transition_results.Tc_onset = onset;
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
                
                onset = calculate_onset_temperature(temp_smooth, heat_flow_smooth, tm_idx, -1);
                transition_results.Tm_onset = onset;
            end
        catch
        end
    end
    
end

function onset_temp = calculate_onset_temperature(temperature, heat_flow, peak_idx, direction)
    
    onset_temp = NaN;
    
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
end

function create_comprehensive_results_table(results, heating_rate)
    
    % Create a figure for the table
    f = figure('Position', [100, 100, 800, 400], 'MenuBar', 'none', 'ToolBar', 'none');
    axis off;
    
    % Title
    uicontrol('Style', 'text', ...
              'String', 'DSC Thermal Analysis Results', ...
              'Position', [20, 350, 760, 40], ...
              'FontSize', 16, 'FontWeight', 'bold', ...
              'HorizontalAlignment', 'center');
    
    % Column headers
    headers = {'Transition', 'Onset', 'Peak', 'Type', 'Method'};
    for col = 1:length(headers)
        uicontrol('Style', 'text', ...
                  'String', headers{col}, ...
                  'Position', [20 + (col-1)*150, 310, 150, 30], ...
                  'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'center', ...
                  'BackgroundColor', [0.8 0.8 0.8]);
    end
    
    % Data rows
    row_height = 30;
    y_pos = 280;
    transitions = {};
    
    % Glass Transition
    if ~isnan(results.Tg_peak)
        transitions{end+1} = {'Glass Transition (Tg)', ...
                              sprintf('%.1f°C', results.Tg_onset), ...
                              sprintf('%.1f°C', results.Tg_peak), ...
                              results.Tg_type, results.Tg_method};
    end
    
    % Crystallization
    if ~isnan(results.Tc_peak)
        transitions{end+1} = {'Crystallization (Tc)', ...
                              sprintf('%.1f°C', results.Tc_onset), ...
                              sprintf('%.1f°C', results.Tc_peak), ...
                              results.Tc_type, results.Tc_method};
    end
    
    % Melting
    if ~isnan(results.Tm_peak)
        transitions{end+1} = {'Melting (Tm)', ...
                              sprintf('%.1f°C', results.Tm_onset), ...
                              sprintf('%.1f°C', results.Tm_peak), ...
                              results.Tm_type, results.Tm_method};
    end
    
    % Add transition rows
    for row = 1:length(transitions)
        for col = 1:length(transitions{row})
            bg_color = [1 1 1];
            if row == 1, bg_color = [0.9 0.9 1]; end % Light red for Tg
            if row == 2, bg_color = [0.9 1 0.9]; end % Light green for Tc
            if row == 3, bg_color = [1 0.9 0.9]; end % Light blue for Tm
            
            uicontrol('Style', 'text', ...
                      'String', transitions{row}{col}, ...
                      'Position', [20 + (col-1)*150, y_pos, 150, row_height], ...
                      'FontSize', 10, ...
                      'HorizontalAlignment', 'center', ...
                      'BackgroundColor', bg_color);
        end
        y_pos = y_pos - row_height;
        
        % Add empty row separator
        y_pos = y_pos - 10;
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