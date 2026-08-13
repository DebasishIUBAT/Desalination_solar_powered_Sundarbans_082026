function sens_mem = sensitivity_membrane(params,env)

variation = [-0.3 0 0.3];

sens_mem.kw = run_sensitivity_NSC(params,env,'kw',variation,'membrane');

sens_mem.Bs = run_sensitivity_NSC(params,env,'Bs',variation,'membrane');

sens_mem.Am_element = run_sensitivity_NSC(params,env,'Am_element',variation,'membrane');

T = table( {'kw';'Bs';'Am_element'},...
[sens_mem.kw.NSC_Qp; sens_mem.Bs.NSC_Qp; sens_mem.Am_element.NSC_Qp],...
[sens_mem.kw.NSC_Cp; sens_mem.Bs.NSC_Cp; sens_mem.Am_element.NSC_Cp],...
[sens_mem.kw.NSC_SEC; sens_mem.Bs.NSC_SEC; sens_mem.Am_element.NSC_SEC],...
[sens_mem.kw.NSC_Recovery; sens_mem.Bs.NSC_Recovery; sens_mem.Am_element.NSC_Recovery],...
'VariableNames',...
{'Parameter','NSC_Qp','NSC_Cp','NSC_SEC','NSC_Recovery'});

writetable(T,'Membrane_Sensitivity.csv');

end