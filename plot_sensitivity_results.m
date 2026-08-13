function plot_sensitivity_results(sens_env,sens_mem,sens_hyd,sens_energy,sens_foul)

% ========================================================================
% Unified Sensitivity Visualization
% Uses normalized sensitivity coefficients
% ========================================================================

close all

%% =======================================================================
% CATEGORY-WISE PLOTS
%% =======================================================================

%% 1. Environmental

figure

env_Qp = [ sens_env.salinity.NSC_Qp sens_env.temperature.NSC_Qp sens_env.irradiance.NSC_Qp ];
bar(env_Qp)

xticklabels({'Salinity','Temperature','Irradiance'})
ylabel('Normalized sensitivity coefficient')
title('Environmental Sensitivity on Q_p')
grid on

%% 2. Membrane

figure

mem_Qp = [ ...
sens_mem.kw.NSC_Qp ...
sens_mem.Bs.NSC_Qp ...
sens_mem.Am_element.NSC_Qp ];

bar(mem_Qp)

xticklabels({'k_w','B_s','A_m'})
ylabel('Normalized sensitivity coefficient')
title('Membrane Sensitivity on Q_p')
grid on

%% 3. Hydrodynamic

figure

hyd_Qp = [ ...
sens_hyd.Qf_module_m3h.NSC_Qp ...
sens_hyd.spacer_hydraulic_diameter.NSC_Qp ...
sens_hyd.C_sherwood.NSC_Qp ...
sens_hyd.m_sh.NSC_Qp ...
sens_hyd.pressure_drop_multiplier.NSC_Qp ];

bar(hyd_Qp)

xticklabels({'Feed flow','Spacer D_h',...
             'C_{Sh}','m_{Sh}','Pressure drop'})

ylabel('Normalized sensitivity coefficient')
title('Hydrodynamic Sensitivity on Q_p')
grid on

%% 4. Energy

figure

energy_Qp = [ sens_energy.Pf_nominal_bar.NSC_Qp sens_energy.eta_pump.NSC_Qp sens_energy.eta_motor.NSC_Qp sens_energy.eta_PV.NSC_Qp sens_energy.PV_area.NSC_Qp ];

bar(energy_Qp)
xticklabels({'Pressure','Pump \eta','Motor \eta','PV \eta','PV Area'})
ylabel('Normalized sensitivity coefficient')
title('Energy/PV Sensitivity on Q_p')
grid on

%% 5. Fouling
figure
%foul_Qp = [ sens_foul.fouling_factor.NSC_Qp sens_foul.kw.NSC_Qp sens_foul.Bs.NSC_Qp ];
foul_Qp = [ sens_foul.fouling_factor.NSC_Qp];
bar(foul_Qp)
xticklabels({'Fouling'})
ylabel('Normalized sensitivity coefficient')
title('Fouling Sensitivity on Q_p')
grid on

%% =======================================================================
% GLOBAL PARAMETER RANKING
%% =======================================================================

param_names = {...
'Salinity','Temperature','Irradiance',...
'k_w','B_s','A_m',...
'Feed flow','Spacer D_h','C_{Sh}','m_{Sh}','Pressure drop',...
'Pressure','Pump eff.','Motor eff.','PV eff.','PV area',...
'Fouling'};

%% -----------------------------------------------------------------------
% Qp
%% -----------------------------------------------------------------------

Qp_all = [...
sens_env.salinity.NSC_Qp;
sens_env.temperature.NSC_Qp;
sens_env.irradiance.NSC_Qp;
sens_mem.kw.NSC_Qp;
sens_mem.Bs.NSC_Qp;
sens_mem.Am_element.NSC_Qp;
sens_hyd.Qf_module_m3h.NSC_Qp;
sens_hyd.spacer_hydraulic_diameter.NSC_Qp;
sens_hyd.C_sherwood.NSC_Qp;
sens_hyd.m_sh.NSC_Qp;
sens_hyd.pressure_drop_multiplier.NSC_Qp;
sens_energy.Pf_nominal_bar.NSC_Qp;
sens_energy.eta_pump.NSC_Qp;
sens_energy.eta_motor.NSC_Qp;
sens_energy.eta_PV.NSC_Qp;
sens_energy.PV_area.NSC_Qp;
sens_foul.fouling_factor.NSC_Qp];

[~,idx] = sort(abs(Qp_all),'descend');

figure
bar(Qp_all(idx))
xticklabels(param_names(idx))
xtickangle(45)
ylabel('Normalized sensitivity coefficient')
title('Global Parameter Ranking for Q_p')
grid on

%% -----------------------------------------------------------------------
% SEC
%% -----------------------------------------------------------------------

SEC_all = [...
sens_env.salinity.NSC_SEC;
sens_env.temperature.NSC_SEC;
sens_env.irradiance.NSC_SEC;
sens_mem.kw.NSC_SEC;
sens_mem.Bs.NSC_SEC;
sens_mem.Am_element.NSC_SEC;
sens_hyd.Qf_module_m3h.NSC_SEC;
sens_hyd.spacer_hydraulic_diameter.NSC_SEC;
sens_hyd.C_sherwood.NSC_SEC;
sens_hyd.m_sh.NSC_SEC;
sens_hyd.pressure_drop_multiplier.NSC_SEC;
sens_energy.Pf_nominal_bar.NSC_SEC;
sens_energy.eta_pump.NSC_SEC;
sens_energy.eta_motor.NSC_SEC;
sens_energy.eta_PV.NSC_SEC;
sens_energy.PV_area.NSC_SEC;
sens_foul.fouling_factor.NSC_SEC];

[~,idx] = sort(abs(SEC_all),'descend');

figure
bar(SEC_all(idx))
xticklabels(param_names(idx))
xtickangle(45)
ylabel('Normalized sensitivity coefficient')
title('Global Parameter Ranking for SEC')
grid on

%% -----------------------------------------------------------------------
% Recovery
%% -----------------------------------------------------------------------

REC_all = [...
sens_env.salinity.NSC_Recovery;
sens_env.temperature.NSC_Recovery;
sens_env.irradiance.NSC_Recovery;
sens_mem.kw.NSC_Recovery;
sens_mem.Bs.NSC_Recovery;
sens_mem.Am_element.NSC_Recovery;
sens_hyd.Qf_module_m3h.NSC_Recovery;
sens_hyd.spacer_hydraulic_diameter.NSC_Recovery;
sens_hyd.C_sherwood.NSC_Recovery;
sens_hyd.m_sh.NSC_Recovery;
sens_hyd.pressure_drop_multiplier.NSC_Recovery;
sens_energy.Pf_nominal_bar.NSC_Recovery;
sens_energy.eta_pump.NSC_Recovery;
sens_energy.eta_motor.NSC_Recovery;
sens_energy.eta_PV.NSC_Recovery;
sens_energy.PV_area.NSC_Recovery;
sens_foul.fouling_factor.NSC_Recovery];

[~,idx] = sort(abs(REC_all),'descend');

figure
bar(REC_all(idx))
xticklabels(param_names(idx))
xtickangle(45)
ylabel('Normalized sensitivity coefficient')
title('Global Parameter Ranking for Recovery')
grid on

SensitivityMatrix = [Qp_all SEC_all REC_all];
figure
bar(SensitivityMatrix,'grouped')
xticklabels(param_names)
xtickangle(45)
ylabel('Normalized sensitivity coefficient')
legend({'Q_p','SEC','Recovery'},...
       'Location','best')
title('Global Sensitivity Comparison of All Parameters')

grid on

% Create a table with parameter names and the three sensitivity vectors
sensitivityTable = table(param_names', Qp_all, SEC_all, REC_all, ...
    'VariableNames', {'Parameter', 'Q_p', 'SEC', 'Recovery'});

% Write to CSV
writetable(sensitivityTable, 'sensitivity_matrix_all.csv');
end