% ========================================================================
% validate_all_papers.m
% Validate RO model (RO_module_sim2 + RO_element_core2) against:
%   - Aboelmaaref 2023
%   - Jamal 2004
%   - Zhang 2022
% Includes Bs calibration and combined plots.
% ========================================================================
clearvars; close all; clc;
%% ------------------- General Model Parameters ---------------------------
rho = 1000;          % kg/m3
viscosity = 0.001;   % Pa.s
D_salt = 1.61e-9;    % m2/s
spacer_hydraulic_diameter = 0.002;  % m
spacer_length = 0.1; % m
C_sherwood = 0.023;  % Sherwood correlation constant
m_sh = 0.8; n_sh = 0.33;
pressure_drop_multiplier = 1.0;
pi_coeff_Pa_per_ppm = 0.0758 * 1000; % Pa per ppm

elements_per_vessel = 8;
vessels_per_stage = 1;
num_elements = elements_per_vessel * vessels_per_stage;

%% ------------------- Paper Targets (hard-coded) -------------------------
papers = struct();

% --- Paper 1: Aboelmaaref 2023 ---
papers(1).name = 'Aboelmaaref 2023';
papers(1).feed_ppm = [35000, 40000];
papers(1).pressures_bar = [55, 80];
papers(1).Qp_targets = [1.62 2.61; 1.30 2.35];
papers(1).Cp_targets = [135 88; 176 108];
papers(1).Am_element = 7.2;
papers(1).kw = 2.59e-9;
papers(1).Bs = 2.3e-5;
papers(1).Qf_module_m3h = 16.2;

% --- Paper 2: Shouman 2024 ---
papers(2).name = 'Shouman 2024';
papers(2).feed_ppm = [35000];
papers(2).pressures_bar = [41.36 51.36];
papers(2).Qp_targets = [0.72 1.15];
papers(2).Cp_targets = [560 320];
papers(2).Am_element = 7.6;
papers(2).kw = 2.59e-9;
papers(2).Bs = 2.3e-5;
papers(2).Qf_module_m3h = 15.0;

% --- Paper 3: Das 2024 ---
papers(3).name = 'Das 2024';
papers(3).feed_ppm = [35000];
papers(3).pressures_bar = [35 40 50];
papers(3).Qp_targets = [0.36 0.84 0.96];
papers(3).Cp_targets = [255 180 98];
papers(3).Am_element = 7.6;
papers(3).kw = 2.59e-9;
papers(3).Bs = 2.3e-5;
papers(3).Qf_module_m3h = 15.0;

%% ------------------- Validation Loop -----------------------------------
colors = lines(length(papers));
allQp = {}; allCp = {}; legendsQp = {}; legendsCp = {};
allPaperQp = {}; allPaperCp = {};

for p = 1:length(papers)
    paper = papers(p);
    fprintf('\n=== Validating against %s ===\n', paper.name);

    results = [];

    for k = 1:length(paper.feed_ppm)
        Xf = paper.feed_ppm(k);

        % ---- Step 1: Calibrate Bs at lowest pressure (match Cp) ----
        Pf_ref_bar = paper.pressures_bar(1);
        Pf_ref_Pa  = Pf_ref_bar * 1e5;
        Cp_target_ref = paper.Cp_targets(min(k,end),1);

        Bs_vals = logspace(-6,-3,50);
        Cp_err = zeros(size(Bs_vals));
        for b = 1:length(Bs_vals)
            [~, Cp_test, ~] = RO_module_sim2(Pf_ref_Pa, paper.Qf_module_m3h, Xf, num_elements, paper.Am_element, paper.kw, Bs_vals(b), ...
                spacer_hydraulic_diameter, spacer_length, viscosity, rho, D_salt, C_sherwood, m_sh, n_sh, pressure_drop_multiplier, pi_coeff_Pa_per_ppm);
            Cp_err(b) = abs(Cp_test - Cp_target_ref);
        end
        [~, idx_best] = min(Cp_err);
        Bs_calib = Bs_vals(idx_best);
        fprintf(' Calibrated Bs = %.2e for feed %d ppm\n', Bs_calib, Xf);

        % ---- Step 2: Run extended pressure sweep ----
        P_bar_sweep = min(paper.pressures_bar):5:max(paper.pressures_bar);
        Qp_vals = zeros(size(P_bar_sweep));
        Cp_vals = zeros(size(P_bar_sweep));
        for i = 1:length(P_bar_sweep)
            Pf_bar = P_bar_sweep(i);
            Pf_Pa  = Pf_bar * 1e5;
            [Qp_mod, Cp_mod, ~] = RO_module_sim2(Pf_Pa, paper.Qf_module_m3h, Xf,num_elements, paper.Am_element,paper.kw, Bs_calib, ...
                spacer_hydraulic_diameter, spacer_length, viscosity, rho, D_salt, C_sherwood, m_sh, n_sh, ...
                pressure_drop_multiplier, pi_coeff_Pa_per_ppm);
            Qp_vals(i) = Qp_mod;
            Cp_vals(i) = Cp_mod;
        end

        % ---- Print comparisons at paper pressures ----
        for i = 1:length(paper.pressures_bar)
            Pf_bar = paper.pressures_bar(i);
            idx_match = find(P_bar_sweep == Pf_bar,1);
            fprintf(' Feed=%d ppm, Pf=%d bar: Qp=%.3f (paper %.3f), Cp=%.1f (paper %.1f)\n', ...
                Xf, Pf_bar, ...
                Qp_vals(idx_match), paper.Qp_targets(min(k,end),i), ...
                Cp_vals(idx_match), paper.Cp_targets(min(k,end),i));
        end

        % ---- Store for plots ----
        allQp{end+1} = [P_bar_sweep(:), Qp_vals(:)];
        allCp{end+1} = [P_bar_sweep(:), Cp_vals(:)];
        legendsQp{end+1} = sprintf('%s %dk ppm', paper.name, Xf/1000);
        legendsCp{end+1} = sprintf('%s %dk ppm', paper.name, Xf/1000);

        % also store paper points
        allPaperQp{end+1} = [paper.pressures_bar(:), paper.Qp_targets(min(k,end),:)'];
        allPaperCp{end+1} = [paper.pressures_bar(:), paper.Cp_targets(min(k,end),:)'];
    end
end

%% ------------------- Combined Plots with Interpolation -------------------
figure('Name','All Papers - Qp vs Pressure'); hold on; box on;
for i = 1:length(allQp)
    % Model solid line
    plot(allQp{i}(:,1), allQp{i}(:,2), '-', 'LineWidth',1.8);

    % Paper dashed line + markers (interpolated)
    P_paper = allPaperQp{i}(:,1);
    Qp_paper = allPaperQp{i}(:,2);
    P_interp = linspace(min(P_paper), max(P_paper), 50);
    Qp_interp = interp1(P_paper, Qp_paper, P_interp, 'linear');
    plot(P_interp, Qp_interp, '--', 'LineWidth',1.5);
    plot(P_paper, Qp_paper, 's','MarkerSize',8,'MarkerFaceColor','w');

    % Update legend: one for model, one for paper
    legendsQp{end+1} = [legendsQp{i} ' (model)'];
    legendsQp{end+1} = [legendsQp{i} ' (paper)'];
end
xlabel('Pressure (bar)'); ylabel('Qp (m^3/h)');
title('Permeate Flow vs Pressure');
legend(legendsQp,'Location','NorthWest');

figure('Name','All Papers - Cp vs Pressure'); hold on; box on;
for i = 1:length(allCp)
    % Model solid line
    plot(allCp{i}(:,1), allCp{i}(:,2), '-', 'LineWidth',1.8);

    % Paper dashed line + markers (interpolated)
    P_paper = allPaperCp{i}(:,1);
    Cp_paper = allPaperCp{i}(:,2);
    P_interp = linspace(min(P_paper), max(P_paper), 50);
    Cp_interp = interp1(P_paper, Cp_paper, P_interp, 'linear');
    plot(P_interp, Cp_interp, '--', 'LineWidth',1.5);
    plot(P_paper, Cp_paper, 'o','MarkerSize',6,'MarkerFaceColor','w');

    % Update legend: one for model, one for paper
    legendsCp{end+1} = [legendsCp{i} ' (model)'];
    legendsCp{end+1} = [legendsCp{i} ' (paper)'];
end
xlabel('Pressure (bar)'); ylabel('Cp (ppm)');
title('Permeate Salinity vs Pressure');
legend(legendsCp,'Location','NorthEast');

%% ------------------- Export All Data with Correct Paper & Feed Sets -------------------

% Collect all pressures across all datasets
all_pressures_list = [];
for i = 1:length(allQp)
    all_pressures_list = [all_pressures_list; allQp{i}(:,1)];
end
all_pressures = unique(all_pressures_list);

% Initialize table with pressure
T = table(all_pressures, 'VariableNames', {'Pressure_bar'});

% Counter for columns in allQp / allPaperQp
col_idx = 1;

% Loop over papers
for p = 1:length(papers)
    paper = papers(p);
    for k = 1:length(paper.feed_ppm)
        % Take corresponding model and paper data from cell arrays
        Qp_model = allQp{col_idx};
        Qp_paper = allPaperQp{col_idx};

        % Interpolate to common pressure vector
        Qp_model_interp = interp1(Qp_model(:,1), Qp_model(:,2), all_pressures, 'linear');
        Qp_paper_interp = interp1(Qp_paper(:,1), Qp_paper(:,2), all_pressures, 'linear');

        % Column names using paper name and feed
        feed_label = sprintf('%dkppm', paper.feed_ppm(k)/1000);
        model_name = matlab.lang.makeValidName([paper.name '_' feed_label '_model']);
        paper_name = matlab.lang.makeValidName([paper.name '_' feed_label '_paper']);

        % Add to table
        T.(model_name) = Qp_model_interp;
        T.(paper_name) = Qp_paper_interp;

        % Move to next index
        col_idx = col_idx + 1;
    end
end

% Write to CSV
writetable(T, 'All_Qp_data.csv');

%% ------------------- Repeat for Cp -------------------

% Initialize table with pressure
T = table(all_pressures, 'VariableNames', {'Pressure_bar'});

col_idx = 1;
for p = 1:length(papers)
    paper = papers(p);
    for k = 1:length(paper.feed_ppm)
        Cp_model = allCp{col_idx};
        Cp_paper = allPaperCp{col_idx};

        Cp_model_interp = interp1(Cp_model(:,1), Cp_model(:,2), all_pressures, 'linear');
        Cp_paper_interp = interp1(Cp_paper(:,1), Cp_paper(:,2), all_pressures, 'linear');

        feed_label = sprintf('%dkppm', paper.feed_ppm(k)/1000);
        model_name = matlab.lang.makeValidName([paper.name '_' feed_label '_model']);
        paper_name = matlab.lang.makeValidName([paper.name '_' feed_label '_paper']);

        T.(model_name) = Cp_model_interp;
        T.(paper_name) = Cp_paper_interp;

        col_idx = col_idx + 1;
    end
end

writetable(T, 'All_Cp_data.csv');

fprintf('CSV files exported with 9 columns for Qp and Cp, including model and paper for each feed.\n');
