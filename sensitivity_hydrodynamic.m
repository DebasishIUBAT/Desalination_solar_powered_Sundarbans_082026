function sens_hyd = sensitivity_hydrodynamic(params,env)

variation = [-0.3 0 0.3];

plist = {'Qf_module_m3h','spacer_hydraulic_diameter','C_sherwood','m_sh','pressure_drop_multiplier'};

for i = 1:length(plist)

    sens_hyd.(plist{i}) = run_sensitivity_NSC(params,env,plist{i},variation,'hydrodynamic');

end
%% ============================================================
% Export CSV
%% ============================================================

    Parameter = { 'Qf_module_m3h'; 'spacer_hydraulic_diameter'; 'C_sherwood'; 'm_sh'; 'pressure_drop_multiplier'};
    
    NSC_Qp = [sens_hyd.Qf_module_m3h.NSC_Qp; sens_hyd.spacer_hydraulic_diameter.NSC_Qp; sens_hyd.C_sherwood.NSC_Qp; sens_hyd.m_sh.NSC_Qp; sens_hyd.pressure_drop_multiplier.NSC_Qp];
    NSC_Cp = [sens_hyd.Qf_module_m3h.NSC_Cp; sens_hyd.spacer_hydraulic_diameter.NSC_Cp; sens_hyd.C_sherwood.NSC_Cp; sens_hyd.m_sh.NSC_Cp; sens_hyd.pressure_drop_multiplier.NSC_Cp];
    NSC_SEC = [sens_hyd.Qf_module_m3h.NSC_SEC;sens_hyd.spacer_hydraulic_diameter.NSC_SEC; sens_hyd.C_sherwood.NSC_SEC; sens_hyd.m_sh.NSC_SEC; sens_hyd.pressure_drop_multiplier.NSC_SEC];
    NSC_Recovery = [sens_hyd.Qf_module_m3h.NSC_Recovery; sens_hyd.spacer_hydraulic_diameter.NSC_Recovery; sens_hyd.C_sherwood.NSC_Recovery; sens_hyd.m_sh.NSC_Recovery; sens_hyd.pressure_drop_multiplier.NSC_Recovery];
    
    T = table( Parameter,NSC_Qp,NSC_Cp,NSC_SEC,NSC_Recovery);
    writetable(T,'Hydrodynamic_Sensitivity.csv');
    fprintf('\nHydrodynamic_Sensitivity.csv exported.\n');
end