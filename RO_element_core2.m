function [Qp_elem_m3h, Cp_ppm, Pf_out_Pa, J_vol_m3m2s] = RO_element_core2(Pf_in_Pa, Qf_module_m3h, Xf_ppm, Am_elem, kw_local, Bs_local, ...
                                                        spacer_Dh, spacer_Lchar, viscosity_local, rho, D_salt_local, ...
                                                            C_sherwood, m_sh, n_sh, pressure_drop_multiplier, pi_coeff_Pa_per_ppm)
rho_local = rho;  % kg/m3

% convert module feed to m3/s
Qf_m3s = Qf_module_m3h / 3600;

% channel velocity estimate (per meter width approximation)
A_channel = spacer_Dh * 1.0;   % m2 per m width
V = Qf_m3s ./ A_channel;
V = max(V, 1e-9);

% dimensionless numbers
Re = max(1, (rho_local .* V .* spacer_Dh) ./ viscosity_local);
Sc = viscosity_local ./ (rho_local .* D_salt_local);

% Sherwood and mass transfer
Sh = C_sherwood .* (Re.^m_sh) .* (Sc.^n_sh);
km = (Sh * D_salt_local) ./ spacer_Dh;

% bulk concentration (kg/m3)
C_bulk_kgm3 = Xf_ppm * 0.001;

% osmotic at bulk (Pa)
pi_bulk_Pa = pi_coeff_Pa_per_ppm * Xf_ppm;

% initial guess for flux (mass basis kg/m2/s)
J_mass = kw_local * max(Pf_in_Pa - pi_bulk_Pa, 0);

tol   = 1e-8;
maxit = 200;
Cp_ppm = Xf_ppm;  % fallback

for iter = 1:maxit
    J_vol = J_mass / rho_local;
    if J_vol <= 0
        % fallback if no flux
        Js = Bs_local * C_bulk_kgm3;
        J_mass = eps;
    else
        % film concentration from balance (steady cp approximation)
        Cfilm_new = (km .* C_bulk_kgm3) ./ ((Bs_local ./ rho_local) + km);
        Js = Bs_local .* Cfilm_new;

        % osmotic at film (Pa) - note Cfilm_new is kg/m3 -> convert to ppm for pi coeff
        pi_film_Pa = pi_coeff_Pa_per_ppm * (Cfilm_new * 1000);

        % recompute flux (mass basis)
        J_mass_new = kw_local * max(Pf_in_Pa - pi_film_Pa, 0);

        if abs(J_mass_new - J_mass) / max(1, abs(J_mass)) < tol
            J_mass = J_mass_new;
            break;
        end

        % relaxation
        J_mass = 0.6 * J_mass + 0.4 * J_mass_new;
    end
end

% --- final flux and permeate ---
J_vol_final   = J_mass / rho_local;
Qp_elem_m3h   = J_vol_final * Am_elem * 3600;
J_vol_m3m2s   = J_vol_final;

% --- permeate concentration calculation ---
J_mass_water = rho_local * max(J_vol_final, eps);   % kg/m2/s
Cp_massfrac  = Js ./ J_mass_water;                 % kg salt / kg water
Cp_ppm_calc       = Cp_massfrac * 1e6;                  % ppm

% fallback if flux is too small
if J_vol_final > 1e-12
    Cp_kgm3 = Js ./ J_vol_final;    % [kg/m3]
    Cp_ppm  = Cp_kgm3 * 1000;     % ppm
else
    Cp_ppm = Xf_ppm;             % fallback
end

% Optional empirical correction (from your earlier code) - keep but comment or tune
% This was previously used to better match empirical target behavior. Keep if desired.
Cp_ppm = Cp_ppm/(222.7+861.93*exp(-0.001*Pf_in_Pa*1e-6)) + 30;

% pressure drop (Darcy-Weisbach-like)
f = (Re < 2300) .* (64 ./ Re) + (Re >= 2300) .* (0.3164 .* Re.^(-0.25));
dp_per_m = f .* (rho_local .* V.^2 ./ (2 .* spacer_Dh));
L_elem   = 1.0;
dp_elem  = dp_per_m * L_elem * pressure_drop_multiplier;
Pf_out_Pa = max(Pf_in_Pa - dp_elem, 0);

end
