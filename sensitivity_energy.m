function sens_energy = sensitivity_energy(params,env)

variation = [-0.3 0 0.3];

plist = {'Pf_nominal_bar','eta_pump','eta_motor','eta_PV','PV_area'};

for i = 1:length(plist)

    sens_energy.(plist{i}) = run_sensitivity_NSC(params,env,plist{i},variation,'energy');

end

    %% ============================================================
% Export CSV
%% ============================================================

Parameter = { 'Pf_nominal_bar'; 'eta_pump'; 'eta_motor'; 'eta_PV'; 'PV_area'};
NSC_Qp = [sens_energy.Pf_nominal_bar.NSC_Qp; sens_energy.eta_pump.NSC_Qp; sens_energy.eta_motor.NSC_Qp; sens_energy.eta_PV.NSC_Qp; sens_energy.PV_area.NSC_Qp];
NSC_Cp = [ sens_energy.Pf_nominal_bar.NSC_Cp; sens_energy.eta_pump.NSC_Cp; sens_energy.eta_motor.NSC_Cp; sens_energy.eta_PV.NSC_Cp; sens_energy.PV_area.NSC_Cp];
NSC_SEC = [ sens_energy.Pf_nominal_bar.NSC_SEC; sens_energy.eta_pump.NSC_SEC; sens_energy.eta_motor.NSC_SEC; sens_energy.eta_PV.NSC_SEC; sens_energy.PV_area.NSC_SEC];
NSC_Recovery = [ sens_energy.Pf_nominal_bar.NSC_Recovery; sens_energy.eta_pump.NSC_Recovery; sens_energy.eta_motor.NSC_Recovery; sens_energy.eta_PV.NSC_Recovery;sens_energy.PV_area.NSC_Recovery];

T = table( Parameter,NSC_Qp,NSC_Cp,NSC_SEC,NSC_Recovery);

writetable(T,'Energy_Sensitivity.csv');

fprintf('\nEnergy_Sensitivity.csv exported.\n');
end