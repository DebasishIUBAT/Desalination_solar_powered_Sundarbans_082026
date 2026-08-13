function create_sensitivity_summary(sens_env,sens_mem,sens_hyd,sens_energy,sens_foul)

% ========================================================================
% Create unified sensitivity table
% ========================================================================
Parameter = {};
Category = {};

S_Qp = [];
S_Cp = [];
S_SEC = [];
S_Recovery = [];

%% Environmental
env_pars = {'salinity','temperature','irradiance'};

for i = 1:length(env_pars)

    p = env_pars{i};

    Parameter{end+1,1} = p;
    Category{end+1,1} = 'Environmental';

    S_Qp(end+1,1) = sens_env.(p).NSC_Qp;
    S_Cp(end+1,1) = sens_env.(p).NSC_Cp;
    S_SEC(end+1,1) = sens_env.(p).NSC_SEC;
    S_Recovery(end+1,1) = sens_env.(p).NSC_Recovery;

end

%% Membrane
mem_pars = {'kw','Bs','Am_element'};

for i = 1:length(mem_pars)

    p = mem_pars{i};

    Parameter{end+1,1} = p;
    Category{end+1,1} = 'Membrane';

    S_Qp(end+1,1) = sens_mem.(p).NSC_Qp;
    S_Cp(end+1,1) = sens_mem.(p).NSC_Cp;
    S_SEC(end+1,1) = sens_mem.(p).NSC_SEC;
    S_Recovery(end+1,1) = sens_mem.(p).NSC_Recovery;

end

%% Hydrodynamic
hyd_pars = {'Qf_module_m3h', 'spacer_hydraulic_diameter','C_sherwood','m_sh','pressure_drop_multiplier'};

for i = 1:length(hyd_pars)

    p = hyd_pars{i};

    Parameter{end+1,1} = p;
    Category{end+1,1} = 'Hydrodynamic';

    S_Qp(end+1,1) = sens_hyd.(p).NSC_Qp;
    S_Cp(end+1,1) = sens_hyd.(p).NSC_Cp;
    S_SEC(end+1,1) = sens_hyd.(p).NSC_SEC;
    S_Recovery(end+1,1) = sens_hyd.(p).NSC_Recovery;

end

%% Energy
energy_pars = {'Pf_nominal_bar','eta_pump','eta_motor','eta_PV','PV_area'};

for i = 1:length(energy_pars)

    p = energy_pars{i};

    Parameter{end+1,1} = p;
    Category{end+1,1} = 'Energy';

    S_Qp(end+1,1) = sens_energy.(p).NSC_Qp;
    S_Cp(end+1,1) = sens_energy.(p).NSC_Cp;
    S_SEC(end+1,1) = sens_energy.(p).NSC_SEC;
    S_Recovery(end+1,1) = sens_energy.(p).NSC_Recovery;

end

%% Fouling
%foul_pars = {'fouling_factor','kw','Bs'};
foul_pars = {'fouling_factor'};

for i = 1:length(foul_pars)

    p = foul_pars{i};

    Parameter{end+1,1} = p;
    Category{end+1,1} = 'Fouling';

    S_Qp(end+1,1) = sens_foul.(p).NSC_Qp;
    S_Cp(end+1,1) = sens_foul.(p).NSC_Cp;
    S_SEC(end+1,1) = sens_foul.(p).NSC_SEC;
    S_Recovery(end+1,1) = sens_foul.(p).NSC_Recovery;

end

%% Export

T = table(Category,Parameter,S_Qp,S_Cp,S_SEC,S_Recovery);

writetable(T,'Sensitivity_Summary.csv');

fprintf('\nUnified sensitivity table exported:\n');
fprintf('Sensitivity_Summary.csv\n');

end