% ========================================================================
% transient_RO_driver.m
% Uses validated RO model under transient environmental conditions
% ========================================================================
clearvars; close all; clc;
%% ---------------- TIME SETTINGS ----------------------------------------
dt_hr = 1;                    % hourly simulation
Ndays = 365;
Nt = Ndays * 24;
time_hr = (1:Nt)';

%% ---------------- ENVIRONMENTAL INPUTS ---------------------------------
env = generate_environmental_inputs(Nt);

% Safety check
%% -----------------------------------------------------------------------
fprintf('\n');
fprintf('Environmental data loaded:\n');
fprintf('Salinity size     = %d\n',length(env.salinity_ppt));
fprintf('Temperature size  = %d\n',length(env.temperature_C));
fprintf('Irradiance size   = %d\n',length(env.irradiance_Wm2));

%% ---------------- PV + PUMP SETTINGS -----------------------------------
eta_pump = 0.8;
eta_motor = 0.9;
eta_PV = 0.20;
PV_area = 150;     % m2

%% ---------------- RO PARAMETERS ----------------------------------------
Pf_nominal_bar = 40;
Qf_module_m3h = 16.2;
elements_per_vessel = 8;
vessels_per_stage = 1;
num_elements = elements_per_vessel * vessels_per_stage;
Am_element = 7.2;
kw = 2.59e-9;
Bs = 2.3e-5;

spacer_hydraulic_diameter = 0.002;
spacer_length = 0.1;
C_sherwood = 0.023;
m_sh = 0.8;
n_sh = 0.33;
pressure_drop_multiplier = 1.0;
pi_coeff_Pa_per_ppm = 0.0758 * 1000;

%% ---------------- PREALLOCATE OUTPUT ARRAYS ----------------------------------------
Qp_all = zeros(Nt,1);
Cp_all = zeros(Nt,1);
Pf_out_all = zeros(Nt,1);
Pf_all_bar = zeros(Nt,1);
PowerPump_kW = zeros(Nt,1);
Recovery = zeros(Nt,1);
SEC_all = zeros(Nt,1);
T_ref = 25;
alpha_kw = 0.025;
beta_Bs = 0.03;
fouling_factor = 0.15;

%% ---------------- MAIN TRANSIENT LOOP ----------------------------------
fprintf('\nRunning transient simulation...\n');
for t = 1:Nt

    % ------------------------------------------------------------
    % Environmental conditions
    % ------------------------------------------------------------
    Xf_ppm = env.salinity_ppt(t) * 1000;
    T_C = env.temperature_C(t);
    G = env.irradiance_Wm2(t);
    viscosity = env.viscosity_Pas(t);
    rho = env.density_kgm3(t);
    D_salt = env.D_salt_m2s(t);

    kw_T = kw * exp(alpha_kw * (T_C - T_ref));
    Bs_T = Bs * exp(beta_Bs * (T_C - T_ref));

    % Fouling correction
    kw_T = kw_T * (1 - fouling_factor);
    Bs_T = Bs_T * (1 + 0.5*fouling_factor);

    % Solar power available
    PV_power_W = env.PV_power_W(t);

    % Pressure adjusted by available solar power
    solar_fraction = PV_power_W / max(env.PV_power_W);
   %Pf_bar = 5 + (Pf_nominal_bar - 5) * solar_fraction^0.5;
    Pf_bar = Pf_nominal_bar * solar_fraction^0.5;
    Pf_bar = max(Pf_bar,5);

    %% Lower pressure limit
    if PV_power_W < 0.05 * max(env.PV_power_W)
        Pf_bar = 0;
    end
    Pf_Pa = Pf_bar * 1e5;

    if Pf_bar <= 0
        Qp_all(t) = 0;
        Cp_all(t) = NaN;
        SEC_all(t) = NaN;
        Pf_all_bar(t) = 0;
        continue
    end

    pi_est_bar = 0.75 * env.salinity_ppt(t);

    if Pf_bar <= pi_est_bar
        Qp_all(t) = 0;
        Cp_all(t) = NaN;
        SEC_all(t) = NaN;
        Pf_all_bar(t) = Pf_bar;  
        continue
    end

    % Run validated RO model
    [Qp_mod, Cp_mod, Pf_out] = RO_module_sim2(Pf_Pa, Qf_module_m3h, Xf_ppm, num_elements,Am_element,...
                                    kw_T, Bs_T, spacer_hydraulic_diameter,spacer_length,viscosity,rho,D_salt, C_sherwood,...
                                    m_sh,n_sh, pressure_drop_multiplier,pi_coeff_Pa_per_ppm);

    % ------------------------------------------------------------
    % Store outputs
    % ------------------------------------------------------------
    Qp_all(t) = Qp_mod;
    Cp_all(t) = Cp_mod;
    Pf_out_all(t) = Pf_out;
    Pf_all_bar(t) = Pf_bar;

    % ------------------------------------------------------------
    % SEC estimate
    % ------------------------------------------------------------
    Qf_m3s = Qf_module_m3h / 3600;
    PowerPump_kW(t) = (Pf_Pa * Qf_m3s) / (eta_pump * eta_motor) / 1000;
    Recovery(t) = min(Qp_mod / Qf_module_m3h,0.85);

    A_total = num_elements * Am_element;
    J_LMH = Qp_mod * 1000 / A_total;

    if J_LMH < 2
    
        SEC_all(t) = NaN;
        Qp_all(t) = 0;
        Cp_all(t) = NaN;
        Recovery(t) = 0;
        continue
    end

        Qp_all(t) = Qp_mod;
        Cp_all(t) = Cp_mod;
        Pf_all_bar(t) = Pf_bar;
        SEC_all(t) = PowerPump_kW(t) / max(Qp_mod,1e-6); 
end

fprintf('Transient simulation completed.\n');
%% =======================================================================
% RESULTS PLOTS
%% =======================================================================
figure;
plot(time_hr,Qp_all,'LineWidth',1.5)
xlabel('Hour')
ylabel('Q_p (m^3/h)')
title('Transient Permeate Production')
grid on

figure;
plot(time_hr,Cp_all,'LineWidth',1.5)
xlabel('Hour')
ylabel('C_p (ppm)')
title('Transient Permeate Salinity')

figure;
plot(time_hr,Pf_all_bar,'LineWidth',1.5)
xlabel('Hour')
ylabel('Feed Pressure (bar)')
title('Transient RO Pressure')
grid on

figure;
plot(time_hr,PowerPump_kW,'LineWidth',1.2)
xlabel('Hour')
ylabel('Pump Power (kW)')
title('Pump Power Requirement')
grid on

figure;
plot(time_hr,SEC_all,'LineWidth',1.5)
xlabel('Hour')
ylabel('SEC (kWh/m^3)')
title('Specific Energy Consumption')

%% =======================================================================
% EXPORT RESULTS
%% =======================================================================

T_results = table(time_hr,env.salinity_ppt,env.temperature_C,env.irradiance_Wm2,...
                Pf_all_bar,Pf_out_all, Qp_all,Cp_all,Recovery,PowerPump_kW,SEC_all,...
            'VariableNames',{'Hour','Salinity_ppt','Temperature_C','Irradiance_Wm2',...
            'Pressure_bar','Pressure_out','Qp_m3h','Cp_ppm','Recovery','PumpPower_kW','SEC'});

writetable(T_results,'transient_RO_results.csv');

fprintf('\nResults exported successfully.\n');