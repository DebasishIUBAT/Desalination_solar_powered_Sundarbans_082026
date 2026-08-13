function [Qp_module_m3h, Cp_module_ppm, Pf_out_Pa] = RO_module_sim2(Pf_feed_Pa, Qf_module_m3h, Xf_ppm, num_elements_in_module, ...
    Am_elem, kw_local, Bs_local, spacer_Dh, spacer_Lchar, visc_local, rho_local, D_salt_local, ...
    C_sherwood, m_sh, n_sh, pressure_drop_multiplier, pi_coeff_Pa_per_ppm)

% Assemble module of elements in series. Calls RO_element_core1 iteratively.

Pf_local   = Pf_feed_Pa;
Qf_local   = Qf_module_m3h;
Xf_local   = Xf_ppm;

Qp_total     = 0;
Cp_weighted  = 0;

for e = 1:num_elements_in_module
     [Qp_elem_m3h, Cp_ppm_elem, Pf_local_out, ~] = RO_element_core2(Pf_local, Qf_local, Xf_local, Am_elem, kw_local, Bs_local, ...
         spacer_Dh, spacer_Lchar, visc_local, rho_local, D_salt_local, C_sherwood, m_sh, n_sh, pressure_drop_multiplier, pi_coeff_Pa_per_ppm);

    % update module sums
    Qp_total    = Qp_total + Qp_elem_m3h;
    Cp_weighted = Cp_weighted + Cp_ppm_elem * Qp_elem_m3h;

    % mass balance for next element
    Qf_next = Qf_local - Qp_elem_m3h;
    if Qf_next <= 0
        Xf_next = Xf_local;
    else
        Xf_next = (Qf_local*Xf_local - Qp_elem_m3h*Cp_ppm_elem) / Qf_next;
    end

    % prepare for next loop
    Qf_local   = Qf_next;
    Xf_local   = Xf_next;
    Pf_local   = Pf_local_out;
end

% finalize outputs
if Qp_total > 0
    Cp_module_ppm = Cp_weighted / Qp_total;
else
    Cp_module_ppm = Xf_ppm;
end
Qp_module_m3h = Qp_total;
Pf_out_Pa     = Pf_local;

end
