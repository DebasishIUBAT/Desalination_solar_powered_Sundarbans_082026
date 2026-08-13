clearvars; close all; clc;

% Environmental data
env = generate_environmental_inputs(8760);

% Baseline parameters
params.Qf_module_m3h = 16.2;
params.kw = 2.59e-9;
params.Bs = 2.3e-5;
params.Am_element = 7.2;
params.num_elements = 8;

params.spacer_hydraulic_diameter = 0.002;
params.spacer_length = 0.1;
params.C_sherwood = 0.023;
params.m_sh = 0.8;
params.n_sh = 0.33;
params.pressure_drop_multiplier = 1.0;

params.Pf_nominal_bar = 40;
params.pi_coeff_Pa_per_ppm = 0.0758*1000;
params.eta_pump = 0.8;
params.eta_motor = 0.9;
params.eta_PV = 0.20;
params.PV_area = 150;

params.alpha_kw = 0.025;
params.beta_Bs = 0.03;
params.fouling_factor = 0.15;

% Run category-wise sensitivity analysis
fprintf('\nRunning sensitivity analyses...\n');
sens_env = sensitivity_environmental(params,env);
sens_mem = sensitivity_membrane(params,env);
sens_hyd = sensitivity_hydrodynamic(params,env);
sens_energy = sensitivity_energy(params,env);
sens_foul = sensitivity_fouling(params,env);

% Unified sensitivity summary
create_sensitivity_summary(sens_env,sens_mem,sens_hyd,sens_energy,sens_foul);

% Plot comparison
plot_sensitivity_results(sens_env,sens_mem,sens_hyd,sens_energy,sens_foul);

fprintf('\nSensitivity analysis completed.\n');

%% Monte Carlo uncertainty quantification
MC_results = montecarlo_UQ(params,env);

%% Statistical postprocessing
statistical_postprocessing(MC_results);