function DSC_Analysis()
    % DSC Data Analysis for Glass Transition, Crystallization, and Melting
    % This function reads DSC data and automatically calculates thermal transitions
    
    % Read the DSC data file
    filename = 'Universal DARK - 1.txt'; % Change this to your full data file
    
    % Read the data (skip header lines)
    data = readtable(filename, 'HeaderLines', 3);
    
    % Extract columns
    time = data{:, 2};        % Time [s]
    heat_flow = data{:, 3};   % Heat Flow [Wg^-1]
    temp_sample = data{:, 4}; % Sample Temperature [°C]
    temp_ref = data{:, 5};    % Reference Temperature [°C]
    
    % Use sample temperature for analysis
    temperature = temp_sample;
    
    % Create figure
    figure('Position', [100, 100, 1200, 800]);
    
    % Plot the DSC curve
    subplot(2,1,1);
    plot(temperature, heat_flow, 'b-', 'LineWidth', 1.5);
    xlabel('Temperature (°C)');
    ylabel('Heat Flow (W/g)');
    title('DSC Thermogram - Universal DARK Sample');
    grid on;
    hold on;
    
    % Analyze thermal transitions
    [Tg, Tc, Tm] = analyze_thermal_transitions(temperature, heat_flow);
    
    % Plot markers for transitions
    if ~isnan(Tg)
        plot(Tg, interp1(temperature, heat_flow, Tg), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
        text(Tg, interp1(temperature, heat_flow, Tg), sprintf('  Tg = %.1f°C', Tg), ...
             'VerticalAlignment', 'bottom', 'FontSize', 10, 'Color', 'red', 'FontWeight', 'bold');
    end
    
    if ~isnan(Tc)
        plot(Tc, interp1(temperature, heat_flow, Tc), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
        text(Tc, interp1(temperature, heat_flow, Tc), sprintf('  Tc = %.1f°C', Tc), ...
             'VerticalAlignment', 'top', 'FontSize', 10, 'Color', 'green', 'FontWeight', 'bold');
    end
    
    if ~isnan(Tm)
        plot(Tm, interp1(temperature, heat_flow, Tm), 'mo', 'MarkerSize', 10, 'MarkerFaceColor', 'm');
        text(Tm, interp1(temperature, heat_flow, Tm), sprintf('  Tm = %.1f°C', Tm), ...
             'VerticalAlignment', 'bottom', 'FontSize', 10, 'Color', 'magenta', 'FontWeight', 'bold');
    end
    
    % Add legend
    legend('DSC Curve', 'Glass Transition (Tg)', 'Crystallization (Tc)', 'Melting (Tm)', 'Location', 'best');
    
    % Plot derivative for better peak identification
    subplot(2,1,2);
    temp_smooth = smooth(temperature, 5);
    heat_flow_smooth = smooth(heat_flow, 5);
    derivative = gradient(heat_flow_smooth) ./ gradient(temp_smooth);
    
    plot(temp_smooth, derivative, 'r-', 'LineWidth', 1);
    xlabel('Temperature (°C)');
    ylabel('d(Heat Flow)/dT (W/g/°C)');
    title('Derivative of Heat Flow - Peak Detection');
    grid on;
    
    % Display results
    fprintf('\n=== DSC Analysis Results ===\n');
    fprintf('Glass Transition Temperature (Tg): %.2f°C\n', Tg);
    fprintf('Crystallization Temperature (Tc): %.2f°C\n', Tc);
    fprintf('Melting Temperature (Tm): %.2f°C\n', Tm);
    fprintf('============================\n');
    
end

function [Tg, Tc, Tm] = analyze_thermal_transitions(temperature, heat_flow)
    % Analyze thermal transitions using ISO 11357 approach for Tg
    
    % Initialize outputs
    Tg = NaN; Tc = NaN; Tm = NaN;
    
    % Smooth the data for better analysis
    temp_smooth = smooth(temperature, 10);
    heat_flow_smooth = smooth(heat_flow, 10);
    
    % Calculate first derivative
    dHF_dT = gradient(heat_flow_smooth) ./ gradient(temp_smooth);
    
    % Calculate second derivative
    d2HF_dT2 = gradient(dHF_dT) ./ gradient(temp_smooth);
    
    % 1. Glass Transition Temperature (Tg) - ISO 11357 method
    % Look for the inflection point in the baseline shift region
    % Typically occurs at lower temperatures (30-100°C for many polymers)
    
    tg_range = find(temp_smooth >= 30 & temp_smooth <= 120);
    if ~isempty(tg_range)
        % Find maximum in second derivative (inflection point)
        [~, max_idx] = max(d2HF_dT2(tg_range));
        if ~isempty(max_idx)
            Tg = temp_smooth(tg_range(max_idx));
        end
    end
    
    % 2. Crystallization Temperature (Tc)
    % Look for exothermic peak (negative heat flow minimum)
    % Typically occurs at intermediate temperatures
    
    tc_range = find(temp_smooth >= 100 & temp_smooth <= 180);
    if ~isempty(tc_range)
        [min_val, min_idx] = min(heat_flow_smooth(tc_range));
        if min_val < -0.1 % Threshold for significant exothermic peak
            Tc = temp_smooth(tc_range(min_idx));
        end
    end
    
    % 3. Melting Temperature (Tm)
    % Look for endothermic peak (positive heat flow maximum)
    % Typically occurs at higher temperatures
    
    tm_range = find(temp_smooth >= 150 & temp_smooth <= 250);
    if ~isempty(tm_range)
        [max_val, max_idx] = max(heat_flow_smooth(tm_range));
        if max_val > 0.05 % Threshold for significant endothermic peak
            Tm = temp_smooth(tm_range(max_idx));
        end
    end
    
    % Alternative method using peak detection
    if isnan(Tc) || isnan(Tm)
        % Use findpeaks for more robust peak detection
        [pks_pos, locs_pos] = findpeaks(heat_flow_smooth, 'MinPeakHeight', 0.05, 'MinPeakDistance', 50);
        [pks_neg, locs_neg] = findpeaks(-heat_flow_smooth, 'MinPeakHeight', 0.05, 'MinPeakDistance', 50);
        
        % Find crystallization (exothermic peak)
        if ~isempty(locs_neg) && isnan(Tc)
            neg_temps = temp_smooth(locs_neg);
            tc_candidates = neg_temps(neg_temps >= 100 & neg_temps <= 180);
            if ~isempty(tc_candidates)
                Tc = tc_candidates(1);
            end
        end
        
        % Find melting (endothermic peak)
        if ~isempty(locs_pos) && isnan(Tm)
            pos_temps = temp_smooth(locs_pos);
            tm_candidates = pos_temps(pos_temps >= 150 & pos_temps <= 250);
            if ~isempty(tm_candidates)
                Tm = tm_candidates(1);
            end
        end
    end
    
    % Spline integration approach for enthalpy calculations
    calculate_enthalpies(temperature, heat_flow, Tg, Tc, Tm);
end

function calculate_enthalpies(temperature, heat_flow, Tg, Tc, Tm)
    % Calculate enthalpies using spline integration (similar to STARE)
    
    fprintf('\n=== Enthalpy Calculations ===\n');
    
    % Glass transition enthalpy (step height)
    if ~isnan(Tg)
        tg_range = find(abs(temperature - Tg) <= 10);
        if length(tg_range) > 10
            baseline_before = mean(heat_flow(tg_range(1:5)));
            baseline_after = mean(heat_flow(tg_range(end-4:end)));
            delta_cp = baseline_after - baseline_before;
            fprintf('Glass Transition Step Height (ΔCp): %.4f W/g/°C\n', delta_cp);
        end
    end
    
    % Crystallization enthalpy
    if ~isnan(Tc)
        tc_range = find(abs(temperature - Tc) <= 20);
        if length(tc_range) > 10
            % Create baseline
            baseline_temp = temperature(tc_range([1, end]));
            baseline_hf = heat_flow(tc_range([1, end]));
            baseline_interp = interp1(baseline_temp, baseline_hf, temperature(tc_range));
            
            % Calculate area under curve
            peak_area = trapz(temperature(tc_range), heat_flow(tc_range) - baseline_interp');
            fprintf('Crystallization Enthalpy (ΔHc): %.2f J/g\n', peak_area);
        end
    end
    
    % Melting enthalpy
    if ~isnan(Tm)
        tm_range = find(abs(temperature - Tm) <= 25);
        if length(tm_range) > 10
            % Create baseline
            baseline_temp = temperature(tm_range([1, end]));
            baseline_hf = heat_flow(tm_range([1, end]));
            baseline_interp = interp1(baseline_temp, baseline_hf, temperature(tm_range));
            
            % Calculate area under curve
            peak_area = trapz(temperature(tm_range), heat_flow(tm_range) - baseline_interp');
            fprintf('Melting Enthalpy (ΔHm): %.2f J/g\n', peak_area);
        end
    end
    
    fprintf('=============================\n');
end

% Usage Instructions:
% 1. Save this code as 'DSC_Analysis.m'
% 2. Make sure your DSC data file is in the same directory
% 3. Update the filename variable if needed
% 4. Run the function: DSC_Analysis()

% Note: The code assumes the data format matches your provided sample
% If your full dataset has different column arrangements, adjust the data extraction section accordingly