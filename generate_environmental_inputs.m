function env = generate_environmental_inputs(Nt)

env.time_hr = (1:Nt)';
sal = readtable('salinity_hourly_8760.csv');

% Ensure compatible size
Nsal = min(Nt,height(sal));

% Main salinity input (deterministic)
env.salinity_ppt = sal.SalinityMean_ppt(1:Nsal);

% Optional stochastic/UQ salinity
if any(strcmp(sal.Properties.VariableNames,'SalinityRandom_ppt'))

    env.salinity_random_ppt = sal.SalinityRandom_ppt(1:Nsal);

else
    env.salinity_random_ppt = env.salinity_ppt;
end

% Equivalent day
if any(strcmp(sal.Properties.VariableNames,'EquivalentDay'))
    env.day_equivalent = sal.EquivalentDay(1:Nsal);
else
    env.day_equivalent = linspace(1,365,Nsal)';
end

% 3. LOAD METEOROLOGICAL DATA
fprintf('Downloading meteorological data...\n');
meteo = download_openmeteo_data();

% Convert to column vectors
temperature_raw = meteo.temperature(:);
irradiance_raw = meteo.irradiance(:);

% Synchronize sizes
% Nmeteo = min([Nt,length(temperature_raw),length(irradiance_raw),Nsal]);
Nmeteo = Nt;

%% -----------------------------------------------------------------------
% Final synchronized vectors
%% -----------------------------------------------------------------------
env.time_hr = env.time_hr(1:Nmeteo);
env.day_equivalent = env.day_equivalent(1:Nmeteo);
env.salinity_ppt = env.salinity_ppt(1:Nmeteo);
env.salinity_random_ppt = env.salinity_random_ppt(1:Nmeteo);

% Temperature
if length(temperature_raw) ~= Nmeteo

    t_old = linspace(1,Nmeteo,length(temperature_raw));
    t_new = (1:Nmeteo)';
    env.temperature_C = interp1(t_old,temperature_raw,t_new,'pchip');
else
    env.temperature_C = temperature_raw(1:Nmeteo);
end

% Irradiance
if length(irradiance_raw) ~= Nmeteo
    t_old = linspace(1,Nmeteo,length(irradiance_raw));
    t_new = (1:Nmeteo)';
    env.irradiance_Wm2 = interp1(t_old,irradiance_raw,t_new,'pchip');
else
    env.irradiance_Wm2 = irradiance_raw(1:Nmeteo);
end

% 4. TEMPERATURE-DEPENDENT WATER PROPERTIES
fprintf('Computing temperature-dependent properties...\n');
env.viscosity_Pas = zeros(Nmeteo,1);
env.density_kgm3 = zeros(Nmeteo,1);
env.D_salt_m2s = zeros(Nmeteo,1);
D_ref = 1.61e-9;

% Check CoolProp availability
useCoolProp = true;
try
    py.importlib.import_module('CoolProp');
catch
    warning('CoolProp not detected. Using fallback constants.');
    useCoolProp = false;
end

for i = 1:Nmeteo

    T_K = env.temperature_C(i) + 273.15;

    if useCoolProp

        try
            %% Dynamic viscosity [Pa.s]
            env.viscosity_Pas(i) = double(py.CoolProp.CoolProp.PropsSI('V','T',T_K,'P',101325,'Water'));
             %% Density [kg/m3]
            env.density_kgm3(i) = double(py.CoolProp.CoolProp.PropsSI('D','T',T_K,'P',101325,'Water'));
            env.D_salt_m2s(i) = D_ref * (T_K / T_ref)^1.75;

        catch
            %% Fallback if CoolProp fails
            env.viscosity_Pas(i) = 0.001;
            env.density_kgm3(i) = 1000;
            env.D_salt_m2s(i)=1.61e-9;
        end
    else
            %% Constant fallback properties
            env.viscosity_Pas(i) = 0.001;
            env.density_kgm3(i) = 1000;
            env.D_salt_m2s(i)=1.61e-9;
    end
end

% 5. SIMPLE PV POWER MODEL
fprintf('Computing PV power...\n');
%% -----------------------------------------------------------------------
% User-defined PV parameters
%% -----------------------------------------------------------------------
PV_area_m2 = 100;
PV_efficiency = 0.18;

%% -----------------------------------------------------------------------
% Instantaneous PV power
%% -----------------------------------------------------------------------
env.PV_power_W = PV_area_m2 .*PV_efficiency .*env.irradiance_Wm2;

%% =======================================================================
% 6. OPTIONAL STOCHASTIC IRRADIANCE
%% =======================================================================
rng(1)
irr_noise = 0.05 * randn(size(env.irradiance_Wm2));
env.irradiance_random_Wm2 = max(0,env.irradiance_Wm2 .* (1 + irr_noise));

%% =======================================================================
% 7. OPTIONAL STOCHASTIC TEMPERATURE
%% =======================================================================
temp_noise = 0.02 * randn(size(env.temperature_C));
env.temperature_random_C = env.temperature_C .* (1 + temp_noise);

%% =======================================================================
% 8. QUALITY CHECK PLOTS
%% =======================================================================
fprintf('Generating diagnostic plots...\n');
%% -----------------------------------------------------------------------
% Salinity
%% -----------------------------------------------------------------------
figure;
plot(env.time_hr,env.salinity_ppt,'LineWidth',1.2)
xlabel('Hour')
ylabel('Salinity (ppt)')
title('Hourly Salinity Input')
grid on

%% -----------------------------------------------------------------------
% Temperature
%% -----------------------------------------------------------------------
figure;
plot(env.time_hr,env.temperature_C,'LineWidth',1.2)
xlabel('Hour')
ylabel('Temperature (^oC)')
title('Hourly Temperature')
grid on

%% -----------------------------------------------------------------------
% Irradiance
%% -----------------------------------------------------------------------
figure;
plot(env.time_hr,env.irradiance_Wm2,'LineWidth',1.2)
xlabel('Hour')
ylabel('Irradiance (W/m^2)')
title('Hourly Solar Irradiance')
grid on

%% -----------------------------------------------------------------------
% PV power
%% -----------------------------------------------------------------------
figure;
plot(env.time_hr,env.PV_power_W,'LineWidth',1.2)
xlabel('Hour')
ylabel('PV Power (W)')
title('Estimated PV Power')
grid on

% 9. EXPORT SYNCHRONIZED ENVIRONMENTAL DATA
fprintf('Exporting environmental dataset...\n');
T_export = table(env.time_hr,env.day_equivalent,env.salinity_ppt,env.salinity_random_ppt,...
                env.temperature_C,env.temperature_random_C,env.irradiance_Wm2,env.irradiance_random_Wm2,...
                env.viscosity_Pas,env.density_kgm3,env.PV_power_W,...
           'VariableNames',{'Hour','EquivalentDay','Salinity_ppt','SalinityRandom_ppt',...
                            'Temperature_C','TemperatureRandom_C','Irradiance_Wm2','IrradianceRandom_Wm2',...
                            'Viscosity_Pas','Density_kgm3','PVPower_W'});

    writetable(T_export,'environmental_inputs_8760.csv');
      % COMPLETION MESSAGE
    fprintf('\n'); 
    fprintf('====================================================\n');
    fprintf('Environmental inputs generated successfully.\n');
    fprintf('Total synchronized time steps = %d\n',Nmeteo);
    fprintf('Output file: environmental_inputs_8760.csv\n');
    fprintf('====================================================\n');
end