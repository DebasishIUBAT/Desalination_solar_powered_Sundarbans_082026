function MC_results = montecarlo_UQ(params,env)

% ========================================================================
% montecarlo_UQ.m
% Monte Carlo uncertainty quantification for transient RO system
% ========================================================================

fprintf('\n====================================================\n');
fprintf('RUNNING MONTE CARLO UNCERTAINTY QUANTIFICATION\n');
fprintf('====================================================\n');

%% =======================================================================
% RANDOM SEED FOR REPRODUCIBILITY
%% =======================================================================

rng(1)

%% =======================================================================
% Number of Monte Carlo realizations
%% =======================================================================

Ns = 500;
Nfailed = 0;

%% =======================================================================
% PREALLOCATION
%% =======================================================================

Qp_mean_MC = NaN(Ns,1);
Cp_mean_MC = NaN(Ns,1);
SEC_mean_MC = NaN(Ns,1);
Recovery_mean_MC = NaN(Ns,1);

%% -----------------------------------------------------------------------
% Store sampled parameters
%% -----------------------------------------------------------------------

salinity_factor_MC = zeros(Ns,1);
temperature_shift_MC = zeros(Ns,1);
irradiance_factor_MC = zeros(Ns,1);

kw_factor_MC = zeros(Ns,1);
Bs_factor_MC = zeros(Ns,1);

Am_factor_MC = zeros(Ns,1);

Qf_factor_MC = zeros(Ns,1);
Dh_factor_MC = zeros(Ns,1);
Sherwood_factor_MC = zeros(Ns,1);
msh_factor_MC = zeros(Ns,1);
DP_factor_MC = zeros(Ns,1);

motor_eff_factor_MC = zeros(Ns,1);
PVeff_factor_MC = zeros(Ns,1);
PVarea_factor_MC = zeros(Ns,1);

Pf_factor_MC = zeros(Ns,1);
pump_eff_factor_MC = zeros(Ns,1);

fouling_factor_MC = zeros(Ns,1);

%% =======================================================================
% Monte Carlo loop
%% =======================================================================

for s = 1:Ns

    fprintf('Monte Carlo realization = %d / %d\n',s,Ns);

    %% -------------------------------------------------------------------
    % Copy baseline
    %% -------------------------------------------------------------------

    params_MC = params;
    env_MC = env;

    %% ===================================================================
    % ENVIRONMENTAL UNCERTAINTY
    %% ===================================================================

    salinity_factor = 0.85 + 0.30*rand;
    temperature_shift = -4 + 8*rand;
    irradiance_factor = 0.75 + 0.50*rand;

    %% Salinity perturbation
    env_MC.salinity_ppt = env.salinity_ppt .* salinity_factor;

    %% Prevent unrealistically low salinity
    env_MC.salinity_ppt = max(env_MC.salinity_ppt,0.5);

    %% Temperature perturbation
    env_MC.temperature_C = env.temperature_C + temperature_shift;

    %% Irradiance perturbation
    env_MC.irradiance_Wm2 = env.irradiance_Wm2 .* irradiance_factor;

    %% Prevent unrealistically high irradiance
    env_MC.irradiance_Wm2 = min(env_MC.irradiance_Wm2,1200);

    %% ===================================================================
    % RECOMPUTE TEMPERATURE-DEPENDENT PROPERTIES
    %% ===================================================================

    T_ref = 298.15;
    D_ref = 1.6e-9;

    Ntime = length(env_MC.temperature_C);

    %% Preallocate
    env_MC.viscosity_Pas = zeros(Ntime,1);
    env_MC.density_kgm3 = zeros(Ntime,1);
    env_MC.D_salt_m2s = zeros(Ntime,1);

    for i = 1:Ntime

        T_K = env_MC.temperature_C(i) + 273.15;

        try

            %% Dynamic viscosity [Pa.s]
            env_MC.viscosity_Pas(i) = double(py.CoolProp.CoolProp.PropsSI( 'V','T',T_K,'P',101325,'Water'));

            %% Density [kg/m3]
            env_MC.density_kgm3(i) = double(py.CoolProp.CoolProp.PropsSI( 'D','T',T_K,'P',101325,'Water'));

        catch

            %% Fallback values
            env_MC.viscosity_Pas(i) = 0.001;
            env_MC.density_kgm3(i) = 1000;

        end

        %% Salt diffusivity
        env_MC.D_salt_m2s(i) = D_ref * (T_K/T_ref)^1.75;

    end

    %% ===================================================================
    % MEMBRANE UNCERTAINTY
    %% ===================================================================

    kw_factor = 0.70 + 0.60*rand;
    Bs_factor = 0.70 + 0.60*rand;
    Am_factor = 0.70 + 0.60*rand;

    params_MC.kw = params.kw * kw_factor;
    params_MC.Bs = params.Bs * Bs_factor;
    params_MC.Am_element = params.Am_element * Am_factor;

    
    %% ===================================================================
    % HYDRODYNAMIC UNCERTAINTY
    %% ===================================================================

    Qf_factor  = 0.70 + 0.60*rand;
    Dh_factor  = 0.70 + 0.60*rand;
    Csh_factor = 0.70 + 0.60*rand;
    msh_factor = 0.70 + 0.60*rand;
    DP_factor  = 0.70 + 0.60*rand;

    params_MC.Qf_module_m3h = params.Qf_module_m3h * Qf_factor;
    params_MC.spacer_hydraulic_diameter = params.spacer_hydraulic_diameter * Dh_factor;
    params_MC.C_sherwood = params.C_sherwood * Csh_factor;
    params_MC.m_sh = params.m_sh * msh_factor;
    params_MC.pressure_drop_multiplier = params.pressure_drop_multiplier * DP_factor;
    
    %% ===================================================================
    % ENERGY/PUMP UNCERTAINTY
    %% ===================================================================

    Pf_factor = 0.90 + 0.20*rand;
    pump_eff_factor = 0.95 + 0.10*rand;
    motor_eff_factor = 0.95 + 0.10*rand;
    PVeff_factor = 0.90 + 0.20*rand;
    PVarea_factor = 0.90 + 0.20*rand;
    params_MC.Pf_nominal_bar = params.Pf_nominal_bar * Pf_factor;
    params_MC.eta_pump = params.eta_pump * pump_eff_factor;
    params_MC.eta_motor = params.eta_motor * motor_eff_factor;
    params_MC.eta_PV = params.eta_PV * PVeff_factor;
    params_MC.PV_area = params.PV_area * PVarea_factor;
    
    %% ===================================================================
    % FOULING UNCERTAINTY
    %% ===================================================================

    fouling_factor = 0.05 + 0.25*rand;
    params_MC.kw = params_MC.kw * (1 - fouling_factor);
    params_MC.Bs = params_MC.Bs * (1 + 0.7*fouling_factor);

    %% ===================================================================
    % RUN TRANSIENT SOLVER
    %% ===================================================================

    results = transient_RO_driver_core(params_MC,env_MC);

    %% ===================================================================
    % REJECT FAILED REALIZATIONS
    %% ===================================================================

    if mean(results.Qp_all,'omitnan') < 0.01

        Nfailed = Nfailed + 1;
        continue

    end

    %% ===================================================================
    % STATISTICAL OUTPUTS
    %% ===================================================================

    Qp_mean_MC(s) = mean(results.Qp_all,'omitnan');
    Cp_mean_MC(s) = mean(results.Cp_all,'omitnan');
    SEC_mean_MC(s) = mean(results.SEC_all,'omitnan');
    Recovery_mean_MC(s) = mean(results.Recovery,'omitnan');

    %% ===================================================================
    % STORE SAMPLED VARIABLES
    %% ===================================================================

    salinity_factor_MC(s) = salinity_factor;
    temperature_shift_MC(s) = temperature_shift;
    irradiance_factor_MC(s) = irradiance_factor;

    kw_factor_MC(s) = kw_factor;
    Bs_factor_MC(s) = Bs_factor;

    Am_factor_MC(s) = Am_factor;

    Qf_factor_MC(s) = Qf_factor;
    Dh_factor_MC(s) = Dh_factor;
    Sherwood_factor_MC(s) = Csh_factor;
    msh_factor_MC(s) = msh_factor;
    DP_factor_MC(s) = DP_factor;
    
    motor_eff_factor_MC(s) = motor_eff_factor;
    PVeff_factor_MC(s) = PVeff_factor;
    PVarea_factor_MC(s) = PVarea_factor;

    Pf_factor_MC(s) = Pf_factor;
    pump_eff_factor_MC(s) = pump_eff_factor;

    fouling_factor_MC(s) = fouling_factor;

end

%% =======================================================================
% SAVE OUTPUT STRUCTURE
%% =======================================================================
MC_results.salinity_factor_MC=salinity_factor_MC;
MC_results.temperature_shift_MC=temperature_shift_MC;
MC_results.irradiance_factor_MC=irradiance_factor_MC;
MC_results.kw_factor_MC=kw_factor_MC;
MC_results.Bs_factor_MC=Bs_factor_MC;
MC_results.fouling_factor_MC=fouling_factor_MC;
MC_results.Qp_mean_MC = Qp_mean_MC;
MC_results.Cp_mean_MC = Cp_mean_MC;
MC_results.SEC_mean_MC = SEC_mean_MC;
MC_results.Recovery_mean_MC = Recovery_mean_MC;

MC_results.Am_factor_MC = Am_factor_MC;
MC_results.Qf_factor_MC = Qf_factor_MC;
MC_results.Dh_factor_MC = Dh_factor_MC;
MC_results.Sherwood_factor_MC = Sherwood_factor_MC;
MC_results.msh_factor_MC = msh_factor_MC;
MC_results.DP_factor_MC = DP_factor_MC;

MC_results.Pf_factor_MC = Pf_factor_MC;
MC_results.pump_eff_factor_MC = pump_eff_factor_MC;

MC_results.motor_eff_factor_MC = motor_eff_factor_MC;
MC_results.PVeff_factor_MC = PVeff_factor_MC;
MC_results.PVarea_factor_MC = PVarea_factor_MC;

%% =======================================================================
% EXPORT CSV
%% =======================================================================

T_MC = table(Qp_mean_MC,Cp_mean_MC,SEC_mean_MC,Recovery_mean_MC,...
    salinity_factor_MC,temperature_shift_MC,irradiance_factor_MC, ...
    kw_factor_MC,Bs_factor_MC,Am_factor_MC,...
    Qf_factor_MC,Dh_factor_MC,Sherwood_factor_MC,msh_factor_MC,DP_factor_MC,...
    Pf_factor_MC,pump_eff_factor_MC,motor_eff_factor_MC,PVeff_factor_MC,PVarea_factor_MC,...
    fouling_factor_MC,...
    'VariableNames',{'Qp_mean_MC','Cp_mean_MC','SEC_mean_MC','Recovery_mean_MC',...
    'SalinityFactor','TemperatureShift','IrradianceFactor',...
    'kwFactor','BsFactor','AmFactor',...
    'FeedFlowFactor','HydraulicDiameterFactor','SherwoodFactor','mShFactor','PressureDropFactor',...
    'PressureFactor','PumpEfficiencyFactor','MotorEfficiencyFactor','PVEfficiencyFactor','PVAreaFactor',...
    'FoulingFactor'});

writetable(T_MC,'MonteCarlo_UQ_results.csv');

fprintf('\n====================================================\n');
fprintf('Failed realizations = %d (%.2f%%)\n',Nfailed,100*Nfailed/Ns);
fprintf('Monte Carlo UQ completed successfully.\n');
fprintf('Results exported: MonteCarlo_UQ_results.csv\n');
fprintf('====================================================\n');

%% =======================================================================
% DIAGNOSTIC PLOTS
%% =======================================================================

figure;
scatter(salinity_factor_MC,Qp_mean_MC,40,'filled')
xlabel('Salinity scaling factor')
ylabel('Mean Q_p (m^3/h)')
title('Effect of Salinity Uncertainty on Q_p')
grid on

figure;
scatter(temperature_shift_MC,Qp_mean_MC,40,'filled')
xlabel('Temperature shift (^oC)')
ylabel('Mean Q_p (m^3/h)')
title('Effect of Temperature Uncertainty on Q_p')
grid on

figure;
scatter(irradiance_factor_MC,Qp_mean_MC,40,'filled')
xlabel('Irradiance scaling factor')
ylabel('Mean Q_p (m^3/h)')
title('Effect of Irradiance Uncertainty on Q_p')
grid on

Qp_valid = Qp_mean_MC(~isnan(Qp_mean_MC));
valid = ~isnan(Qp_mean_MC);

figure;
histogram(Qp_valid,25)
xlabel('Annual mean permeate production (m^3/h)')
ylabel('Frequency')
title('Monte Carlo Distribution of Annual Mean Q_p')
grid on

SEC_valid = SEC_mean_MC(~isnan(SEC_mean_MC));

figure;
histogram(SEC_valid,25)
xlabel('Annual mean SEC (kWh/m^3)')
ylabel('Frequency')
title('Monte Carlo Distribution of Annual Mean SEC')
grid on

figure;
scatter(Qf_factor_MC (valid),Qp_mean_MC (valid),40,'filled')
xlabel('Feed flow factor')
ylabel('Mean Q_p')
title('Effect of Feed Flow Uncertainty on Q_p')
grid on

figure;
scatter(Dh_factor_MC (valid),Qp_mean_MC (valid),40,'filled')
xlabel('Hydraulic diameter factor')
ylabel('Mean Q_p')
title('Effect of Spacer Hydraulic Diameter Uncertainty on Q_p')
grid on

figure;
scatter(Sherwood_factor_MC (valid),Qp_mean_MC (valid),40,'filled')
xlabel('Sherwood coefficient factor')
ylabel('Mean Q_p')
title('Effect of Mass Transfer Uncertainty on Q_p')
grid on

end