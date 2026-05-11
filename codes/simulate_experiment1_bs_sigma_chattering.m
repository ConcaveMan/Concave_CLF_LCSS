function simulate_experiment1_bs_sigma_chattering()
clc; clear; close all;
set(groot, 'defaultTextInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');

%% ============================================================
% Experiment 1:
% Fixed BS-CLF, compare sigma_H = 2 and 6
% Mark near-weak-channel region:
%   |L_gV| <= 0.01 * max_t |L_gV|
% Also compare with optimal-decay CLF-QP using sigma_H = max sigma
%
% Plant simulation: ZOH + ode45
%% ============================================================

%% Simulation settings
T  = 2.0;
dt = 0.005;
t  = 0:dt:T;
N  = numel(t);

x0 = [2.0; 0.0];

% Input bound
theta = 3.0;

% Fixed-sigma slack penalty
q_slack = 10000.0;

% Optimal-decay penalty on rho
q_rho = 1000.0;

% Decay rates to compare
sigma_list = [2, 6];

% Nominal model parameters
k1 = 1.0;
k2 = 0.5;
k3 = 0.2;

% Backstepping CLF parameter
q1 = 1.0;

% Relative threshold for near-zero L_gV
eps_LgV = 1e-2;

%% ============================================================
% Disturbance / uncertainty module
%% ============================================================
cfg.use_disturbance = false;
cfg.use_uncertainty = false;

% disturbance parameters
cfg.dist.a1 = 0.0;
cfg.dist.w1 = 2.0;
cfg.dist.a2 = 0.0;
cfg.dist.w2 = 0.5;

% uncertainty parameters
cfg.unc.a1 = 0.0;
cfg.unc.a2 = 0.0;
cfg.unc.a3 = 0.0;

%% ============================================================
% Plot style module
%% ============================================================
plt.c_black = [0 0 0];
plt.c_blue  = [0 0 1];
plt.c_red   = [1 0 0];

plt.lw_main   = 2.5;
plt.lw_marker = 1.0;
plt.ms_marker = 4;

plt.fs_label  = 20;
plt.fs_tick   = 16;
plt.fs_legend = 16;
plt.ax_lw     = 2;

plt.fig_pos   = [100 100 980 720];

% legend positions (inside figure)
plt.leg1_loc = 'northeast';
plt.leg2_loc = 'northeast';

%% ============================================================
% Run all sigma cases
%% ============================================================
ns = numel(sigma_list);
res_fix = cell(1, ns);
res_opt = cell(1, ns);

for i = 1:ns
    sigma_H = sigma_list(i);

    res_fix{i} = run_case_bs_sigma_zoh_ode45( ...
        x0, t, theta, sigma_H, q_slack, ...
        k1, k2, k3, cfg, q1, eps_LgV);

    res_opt{i} = run_case_bs_opt_decay_zoh_ode45( ...
        x0, t, theta, sigma_H, q_rho, q_slack, ...
        k1, k2, k3, cfg, q1, eps_LgV);
end

sigma_max = max(sigma_list);
idx_max   = find(sigma_list == sigma_max, 1);




%% ============================================================
% Final publication-style figure: 2 x 1
% (a) LgV(t) + V(t)
% (b) u(t) with weak-channel markers
%% ============================================================
figure('Name','Experiment 1 final figure', ...
    'Color','w','Position',plt.fig_pos);

%% ---------- (a) LgV(t) + V(t) ----------
ax1 = subplot(2,1,1);

yyaxis left; hold on;
plot(t, res_fix{1}.LgV, '-', 'Color', plt.c_black, 'LineWidth', plt.lw_main);
plot(t, res_fix{2}.LgV, '-', 'Color', plt.c_blue,  'LineWidth', plt.lw_main);
plot(t, res_opt{idx_max}.LgV, '-', 'Color', plt.c_red, 'LineWidth', 0.6*plt.lw_main);
ylabel('$L_gV$', 'FontSize', plt.fs_label, 'Interpreter', 'latex');

yyaxis right; hold on;
plot(t, res_fix{1}.V, '--', 'Color', plt.c_black, 'LineWidth', plt.lw_main);
plot(t, res_fix{2}.V, '--', 'Color', plt.c_blue,  'LineWidth', plt.lw_main);
plot(t, res_opt{idx_max}.V, '--', 'Color', plt.c_red, 'LineWidth', 0.6*plt.lw_main);
ylabel('$V$', 'FontSize', plt.fs_label, 'Interpreter', 'latex');

grid on;
xlabel('$t\;(\mathrm{s})$', 'FontSize', plt.fs_label, 'Interpreter', 'latex');
title('(a) Input channel and Lyapunov function', 'Interpreter', 'latex');

lgd1 = legend( ...
    '$L_gV$: fixed $\sigma=2$', ...
    '$L_gV$: fixed $\sigma=6$', ...
    '$L_gV$: optimal-decay $~~$', ...
    '$V$: fixed $\sigma=2$', ...
    '$V$: fixed $\sigma=6$', ...
    '$V$: optimal-decay $~$', ...
    'Location','eastoutside', ...
    'Interpreter', 'latex');
lgd1.FontSize = plt.fs_legend;

ax1.LineWidth = plt.ax_lw;
ax1.Box = 'on';
ax1.FontSize = plt.fs_tick;
ax1.TickLabelInterpreter = 'latex';

%% ---------- (b) u(t) with weak-channel markers ----------
ax2 = subplot(2,1,2); hold on;

% fixed sigma = 2
plot(t, res_fix{1}.u, '-', 'Color', plt.c_black, 'LineWidth', plt.lw_main);
idx = res_fix{1}.near_zero_idx;
plot(t(idx), res_fix{1}.u(idx), 'o', ...
    'Color', plt.c_black, ...
    'MarkerSize', plt.ms_marker, ...
    'LineWidth', plt.lw_marker);

% fixed sigma = 6
plot(t, res_fix{2}.u, '-', 'Color', plt.c_blue, 'LineWidth', plt.lw_main);
idx = res_fix{2}.near_zero_idx;
plot(t(idx), res_fix{2}.u(idx), 'o', ...
    'Color', plt.c_blue, ...
    'MarkerSize', plt.ms_marker, ...
    'LineWidth', plt.lw_marker);

% optimal-decay sigma_H = 6
plot(t, res_opt{idx_max}.u, '-', 'Color', plt.c_red, 'LineWidth', 0.6*plt.lw_main);
idx = res_opt{idx_max}.near_zero_idx;
plot(t(idx), res_opt{idx_max}.u(idx), 'o', ...
    'Color', plt.c_red, ...
    'MarkerSize', plt.ms_marker, ...
    'LineWidth', plt.lw_marker);

grid on;
xlabel('$t\;(\mathrm{s})$', 'FontSize', plt.fs_label, 'Interpreter', 'latex');
ylabel('$u$', 'FontSize', plt.fs_label, 'Interpreter', 'latex');
title('(b) Control input with weak-channel markers', 'Interpreter', 'latex');

lgd2 = legend( ...
    'fixed $\sigma=2$', ...
    'fixed $\sigma=2$ markers$~~$', ...
    'fixed $\sigma=6$', ...
    'fixed $\sigma=6$ markers', ...
    'optimal-decay ', ...
    'optimal-decay markers$~~$', ...
    'Location', 'eastoutside', ...
    'Interpreter', 'latex');
lgd2.FontSize = plt.fs_legend;

ax2.LineWidth = plt.ax_lw;
ax2.Box = 'on';
ax2.FontSize = plt.fs_tick;
ax2.TickLabelInterpreter = 'latex';
%% ============================================================
% Print summary
%% ============================================================
fprintf('\n========== Experiment 1 summary ==========\n');
fprintf('disturbance on  : %d\n', cfg.use_disturbance);
fprintf('uncertainty on  : %d\n', cfg.use_uncertainty);

for i = 1:ns
    fprintf('\n---- fixed-sigma: sigma_H = %.2f ----\n', sigma_list(i));
    print_metrics_sigma(res_fix{i}, dt, sigma_list(i), eps_LgV);
end

fprintf('\n---- optimal-decay: sigma_H = %.2f ----\n', sigma_max);
print_metrics_sigma(res_opt{idx_max}, dt, sigma_max, eps_LgV);

end

%% ============================================================
function res = run_case_bs_sigma_zoh_ode45(x0, t, theta, sigma_H, q_slack, ...
    k1, k2, k3, cfg, q1, eps_LgV)

N = numel(t);

x       = zeros(2, N);
u       = zeros(1, N);
slack   = zeros(1, N);
rhohist = ones(1, N);
Vhist   = zeros(1, N);
LfVhist = zeros(1, N);
LgVhist = zeros(1, N);

x(:,1) = x0;

for k = 1:N-1
    xk = x(:,k);

    [uk, deltak, Vk, LfVk, LgVk] = clf_qp_controller_bs( ...
        xk, theta, sigma_H, q_slack, k1, k2, k3, q1);

    tk  = t(k);
    tk1 = t(k+1);

    dyn = @(tt, xx) plant_dynamics(xx, uk, tt, k1, k2, k3, cfg);
    [~, xseg] = ode45(dyn, [tk tk1], xk);
    x(:,k+1) = xseg(end, :)';

    u(k)       = uk;
    slack(k)   = deltak;
    Vhist(k)   = Vk;
    LfVhist(k) = LfVk;
    LgVhist(k) = LgVk;
end

u(end)       = u(end-1);
slack(end)   = slack(end-1);
rhohist(end) = rhohist(end-1);

[~, ~, Vhist(end), LfVhist(end), LgVhist(end)] = clf_qp_controller_bs( ...
    x(:,end), theta, sigma_H, q_slack, k1, k2, k3, q1);

LgV_max = max(abs(LgVhist));
th_LgV  = eps_LgV * LgV_max;

res.x = x;
res.u = u;
res.rho = rhohist;
res.slack = slack;
res.V = Vhist;
res.LfV = LfVhist;
res.LgV = LgVhist;
res.LgV_max = LgV_max;
res.th_LgV  = th_LgV;
res.near_zero_idx = abs(LgVhist) <= th_LgV;
end

%% ============================================================
function res = run_case_bs_opt_decay_zoh_ode45(x0, t, theta, sigma_H, q_rho, q_slack, ...
    k1, k2, k3, cfg, q1, eps_LgV)

N = numel(t);

x       = zeros(2, N);
u       = zeros(1, N);
rhohist = zeros(1, N);
slack   = zeros(1, N);
Vhist   = zeros(1, N);
LfVhist = zeros(1, N);
LgVhist = zeros(1, N);

x(:,1) = x0;

for k = 1:N-1
    xk = x(:,k);

    [uk, rhok, deltak, Vk, LfVk, LgVk] = clf_qp_optimal_decay_bs( ...
        xk, theta, sigma_H, q_rho, q_slack, k1, k2, k3, q1);

    tk  = t(k);
    tk1 = t(k+1);

    dyn = @(tt, xx) plant_dynamics(xx, uk, tt, k1, k2, k3, cfg);
    [~, xseg] = ode45(dyn, [tk tk1], xk);
    x(:,k+1) = xseg(end, :)';

    u(k)       = uk;
    rhohist(k) = rhok;
    slack(k)   = deltak;
    Vhist(k)   = Vk;
    LfVhist(k) = LfVk;
    LgVhist(k) = LgVk;
end

u(end)       = u(end-1);
rhohist(end) = rhohist(end-1);
slack(end)   = slack(end-1);

[~, ~, ~, Vhist(end), LfVhist(end), LgVhist(end)] = clf_qp_optimal_decay_bs( ...
    x(:,end), theta, sigma_H, q_rho, q_slack, k1, k2, k3, q1);

LgV_max = max(abs(LgVhist));
th_LgV  = eps_LgV * LgV_max;

res.x = x;
res.u = u;
res.rho = rhohist;
res.slack = slack;
res.V = Vhist;
res.LfV = LfVhist;
res.LgV = LgVhist;
res.LgV_max = LgV_max;
res.th_LgV  = th_LgV;
res.near_zero_idx = abs(LgVhist) <= th_LgV;
end

%% ============================================================
function dx = plant_dynamics(x, u, t, k1, k2, k3, cfg)
x1 = x(1);
x2 = x(2);

d = disturbance_module(t, cfg);
Delta = uncertainty_module(x, cfg);

dx = [x2;
     -k1*x1 - k2*x2 - k3*x1^3 + Delta + d + u];
end

%% ============================================================
function [u_opt, delta_opt, V, LfV, LgV] = clf_qp_controller_bs( ...
    x, theta, sigma_H, q_slack, k1, k2, k3, q1)

x1 = x(1);
x2 = x(2);

z2 = x2 + q1*x1;

V = 0.5*x1^2 + 0.5*z2^2;

x1dot_nom = x2;
z2dot_nom_no_u = -k1*x1 - k2*x2 - k3*x1^3 + q1*x2;

LgV = z2;
LfV = x1*x1dot_nom + z2*z2dot_nom_no_u;

H = diag([1.0, q_slack]);
f = [0; 0];

A = [ LgV, -1;
      1,    0;
     -1,    0;
      0,   -1];
b = [ -sigma_H*V - LfV;
       theta;
       theta;
       0];

opts = optimoptions('quadprog', 'Display', 'off', 'ConstraintTolerance', 1e-8);
sol = quadprog(H, f, A, b, [], [], [], [], [], opts);

u_opt     = sol(1);
delta_opt = sol(2);
end

%% ============================================================
function [u_opt, rho_opt, delta_opt, V, LfV, LgV] = clf_qp_optimal_decay_bs( ...
    x, theta, sigma_H, q_rho, q_slack, k1, k2, k3, q1)

x1 = x(1);
x2 = x(2);

z2 = x2 + q1*x1;

V = 0.5*x1^2 + 0.5*z2^2;

x1dot_nom = x2;
z2dot_nom_no_u = -k1*x1 - k2*x2 - k3*x1^3 + q1*x2;

LgV = z2;
LfV = x1*x1dot_nom + z2*z2dot_nom_no_u;

H = diag([1, q_rho, q_slack]);
f = [0; -q_rho; 0];

A = [ LgV,  sigma_H*V, -1;
       1,   0,          0;
      -1,   0,          0;
       0,   1,          0;
       0,  -1,          0;
       0,   0,         -1];
b = [ -LfV;
       theta;
       theta;
       1;
       0;
       0];

opts = optimoptions('quadprog', 'Display', 'off', 'ConstraintTolerance', 1e-8);
z = quadprog(H, f, A, b, [], [], [], [], [], opts);

u_opt     = z(1);
rho_opt   = z(2);
delta_opt = z(3);
end

%% ============================================================
function d = disturbance_module(t, cfg)
if ~cfg.use_disturbance
    d = 0.0;
    return;
end

d = cfg.dist.a1*sin(cfg.dist.w1*t) + cfg.dist.a2*cos(cfg.dist.w2*t);
end

%% ============================================================
function Delta = uncertainty_module(x, cfg)
if ~cfg.use_uncertainty
    Delta = 0.0;
    return;
end

x1 = x(1);
x2 = x(2);
Delta = cfg.unc.a1*x1 + cfg.unc.a2*x1^3 + cfg.unc.a3*x2;
end

%% ============================================================
function print_metrics_sigma(res, dt, sigma_H, eps_LgV)

u  = res.u;
sl = res.slack;
idx = res.near_zero_idx;

J_u_total = trapz(abs(u)) * dt;
J_slack   = trapz(sl) * dt;
u_peak    = max(abs(u));

if any(idx)
    t_chatter   = sum(idx) * dt;
    tv_u_near   = sum(abs(diff(u(idx))));
    peak_u_near = max(abs(u(idx)));
else
    t_chatter   = 0;
    tv_u_near   = 0;
    peak_u_near = 0;
end

fprintf('\n sigma_H = %.2f\n', sigma_H);
fprintf('   max |LgV|                    : %.6f\n', res.LgV_max);
fprintf('   near-zero threshold          : %.6f (= %.4g * max|LgV|)\n', ...
    res.th_LgV, eps_LgV);
fprintf('   Peak |u|                     : %.4f\n', u_peak);
fprintf('   Integral |u| dt              : %.4f\n', J_u_total);
fprintf('   Integral slack dt            : %.4f\n', J_slack);
fprintf('   Time with |LgV| <= th        : %.4f s\n', t_chatter);
fprintf('   TV(u) in near-zero region    : %.4f\n', tv_u_near);
fprintf('   Peak |u| in near-zero region : %.4f\n', peak_u_near);
end