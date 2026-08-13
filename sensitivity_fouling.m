function sens_foul = sensitivity_fouling(params,env)

variation = [-0.3 0 0.3];

sens_foul.fouling_factor = run_sensitivity_NSC(params,env,'fouling_factor',variation,'fouling');
% sens_foul.kw = run_sensitivity_NSC(params,env,'kw',variation);
% sens_foul.Bs = run_sensitivity_NSC(params,env,'Bs',variation);

T = table( sens_foul.fouling_factor.NSC_Qp,...
           sens_foul.fouling_factor.NSC_Cp,...
           sens_foul.fouling_factor.NSC_SEC,...
           sens_foul.fouling_factor.NSC_Recovery,...
'VariableNames',{'NSC_Qp','NSC_Cp','NSC_SEC','NSC_Recovery'});

writetable(T,'Fouling_Sensitivity.csv');

end