function statistical_postprocessing(MC_results)

% statistical_postprocessing.m
% Statistical analysis of Monte Carlo UQ results
fprintf('\n====================================================\n');
fprintf('STATISTICAL POSTPROCESSING\n');
fprintf('====================================================\n');

% Extract Monte Carlo outputs
Qp  = MC_results.Qp_mean_MC;
Cp  = MC_results.Cp_mean_MC;
SEC = MC_results.SEC_mean_MC;
Recovery = MC_results.Recovery_mean_MC;

% Remove NaN values
Qp  = Qp(~isnan(Qp));
Cp  = Cp(~isnan(Cp));
SEC = SEC(~isnan(SEC));
Recovery = Recovery(~isnan(Recovery));

% DESCRIPTIVE STATISTICS
fprintf('\n---------------- Qp Statistics ----------------\n');
fprintf('Mean          = %.4f m^3/h\n',mean(Qp));
fprintf('Std Dev       = %.4f\n',std(Qp));
fprintf('Min           = %.4f\n',min(Qp));
fprintf('Max           = %.4f\n',max(Qp));
fprintf('Coefficient of Variation = %.4f %%\n',...
        100*std(Qp)/mean(Qp));

fprintf('\n---------------- Cp Statistics ----------------\n');
fprintf('Mean          = %.4f ppm\n',mean(Cp));
fprintf('Std Dev       = %.4f\n',std(Cp));
fprintf('Min           = %.4f\n',min(Cp));
fprintf('Max           = %.4f\n',max(Cp));

fprintf('\n---------------- SEC Statistics ----------------\n');
fprintf('Mean          = %.4f kWh/m^3\n',mean(SEC));
fprintf('Std Dev       = %.4f\n',std(SEC));
fprintf('Min           = %.4f\n',min(SEC));
fprintf('Max           = %.4f\n',max(SEC));

fprintf('\n---------------- Recovery Statistics ----------------\n');
fprintf('Mean          = %.4f\n',mean(Recovery));
fprintf('Std Dev       = %.4f\n',std(Recovery));

% CONFIDENCE INTERVALS
CI_Qp  = prctile(Qp,[5 95]);
CI_Cp  = prctile(Cp,[5 95]);
CI_SEC = prctile(SEC,[5 95]);

fprintf('\n====================================================\n');
fprintf('95%% CONFIDENCE INTERVALS\n');
fprintf('====================================================\n');

fprintf('Qp   : %.4f  --  %.4f m^3/h\n',CI_Qp(1),CI_Qp(2));
fprintf('Cp   : %.4f  --  %.4f ppm\n',CI_Cp(1),CI_Cp(2));
fprintf('SEC  : %.4f  --  %.4f kWh/m^3\n',CI_SEC(1),CI_SEC(2));

% HISTOGRAMS
figure;
histogram(Qp,25);
xlabel('Mean Q_p (m^3/h)');
ylabel('Frequency');
title('Monte Carlo Distribution of Q_p');
grid on;

figure;
histogram(Cp,25);
xlabel('Mean C_p (ppm)');
ylabel('Frequency');
title('Monte Carlo Distribution of C_p');
grid on;

figure;
histogram(SEC,25);
xlabel('Mean SEC (kWh/m^3)');
ylabel('Frequency');
title('Monte Carlo Distribution of SEC');
grid on;

figure;
histogram(Recovery,25);
xlabel('Mean Recovery');
ylabel('Frequency');
title('Monte Carlo Distribution of Recovery');
grid on;

% CORRELATION ANALYSIS
fprintf('\n====================================================\n');
fprintf('DOMINANT UNCERTAINTY CONTRIBUTORS\n');
fprintf('====================================================\n');
idx = ~isnan(MC_results.Qp_mean_MC);
Qp = MC_results.Qp_mean_MC(idx);

R_sal = corr(MC_results.salinity_factor_MC(idx),Qp,'Rows','complete');
R_temp = corr(MC_results.temperature_shift_MC(idx),Qp,'Rows','complete');
R_irr = corr(MC_results.irradiance_factor_MC(idx),Qp,'Rows','complete');
R_kw = corr(MC_results.kw_factor_MC(idx),Qp,'Rows','complete');
R_Bs = corr(MC_results.Bs_factor_MC(idx),Qp,'Rows','complete');
R_foul = corr(MC_results.fouling_factor_MC(idx),Qp,'Rows','complete');

fprintf('\nCorrelation with Q_p:\n');

fprintf('Salinity factor        : %.4f\n',R_sal);
fprintf('Temperature shift      : %.4f\n',R_temp);
fprintf('Irradiance factor      : %.4f\n',R_irr);
fprintf('Membrane permeability  : %.4f\n',R_kw);
fprintf('Salt permeability      : %.4f\n',R_Bs);
fprintf('Fouling factor         : %.4f\n',R_foul);

% BAR CHART OF DOMINANT PHYSICS
figure;
bar(abs([R_sal R_temp R_irr R_kw R_Bs R_foul]));
set(gca,'XTickLabel',{'Salinity','Temperature','Irradiance',...
                      'k_w','B_s','Fouling'});
ylabel('|Correlation with Q_p|');
title('Dominant Parameters Affecting Permeate Production');
grid on;

fprintf('\n====================================================\n');
fprintf('Statistical postprocessing completed.\n');
fprintf('====================================================\n');

end