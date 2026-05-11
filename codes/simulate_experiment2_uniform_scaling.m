function simulate_experiment2_uniform_scaling()
clc; clear; close all;
set(groot, 'defaultTextInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');

%% ============================================================
% Experiment 2:
% Uniform scaling under the same system and CLF-QP setting as Experiment 1
%
% - same nonlinear system
% - same ZOH + ode45 simulation
% - same soft CLF-QP
% - fixed sigma = 2
% - effectively no input saturation
%
% Fig.1 : x1(t) for q = 1,4,8
% Fig.2 : u_infty versus q for q = 1,...,8
%% ============================================================

%% Simulation settings
T  = 5.0;
dt = 0.005;
t  = 0:dt:T;
N  = numel(t);

% Fixed prescribed decay
sigma = 1.0;

% Effectively remove input saturation
theta = 1e6;

% Slack penalty
q_slack = 10000.0;

% q used for x1(t) trajectories
q_plot_list = [1, 4, 8];

% q used for u_infty-vs-q curve
q_full_list = 1:8;

% Initial conditions: x(0) = [x10; 0]
x10_list = [2.0, 1.5, 1.0, 0.5];

% Nominal model parameters (same as Experiment 1)
k1 = 1.0;
k2 = 0.8;
k3 = 0.5;

% Relative threshold kept only for consistency / optional diagnostics
eps_LgV = 1e-2;

%% ============================================================
% Disturbance / uncertainty module
%% ============================================================
cfg.use_disturbance = false;
cfg.use_uncertainty = false;

cfg.dist.a1 = 0.0;
cfg.dist.w1 = 2.0;
cfg.dist.a2 = 0.0;
cfg.dist.w2 = 0.5;

cfg.unc.a1 = 0.0;
cfg.unc.a2 = 0.0;
cfg.unc.a3 = 0.0;

%% ============================================================
% Plot style module
%% ============================================================
plt.c_black  = [0 0 0];
plt.c_blue   = [0 0 1];
plt.c_red    = [1 0 0];
plt.c_purple = [0.5 0 0.5];

% same q -> same color
plt.q_color_map = containers.Map( ...
    {'1','2','3','4','5','6','7','8'}, ...
    {plt.c_black, plt.c_black, plt.c_black, ...
     plt.c_blue, plt.c_blue, plt.c_blue, plt.c_red, plt.c_red});

% for q=1,4,8 explicitly
plt.q_colors_plot = {plt.c_black, plt.c_blue, plt.c_red};

% different initial conditions -> different line styles
plt.ic_styles = {'-', '--', '-.', ':'};

% u_infty plot: different initial conditions -> different colors
plt.ic_curve_colors = {plt.c_black, plt.c_blue, plt.c_red, plt.c_purple};
plt.ic_markers = {'o','s','d','^'};

plt.lw_main   = 2.5;
plt.ms_marker = 8;
plt.fs_label  = 20;
plt.fs_tick   = 16;
plt.fs_legend = 16;
plt.ax_lw     = 2;

plt.fig_pos1  = [100 100 980 720];
plt.fig_pos2  = [150 150 820 560];

%% ============================================================
% Run q for trajectory plot: q = 1,4,8
%% ============================================================
nq_plot = numel(q_plot_list);
nIC     = numel(x10_list);

res_plot = cell(nq_plot, nIC);

for iq = 1:nq_plot
    q = q_plot_list(iq);

    for ic = 1:nIC
        x0 = [x10_list(ic); 0];

        res_plot{iq, ic} = run_case_uniform_scaling_zoh_ode45( ...
            x0, t, theta, sigma, q_slack, ...
            k1, k2, k3, cfg, q, eps_LgV);
    end
end

%% ============================================================
% Run q for u_infty plot: q = 1,...,8
%% ============================================================
nq_full = numel(q_full_list);
u_inf_mat = zeros(nIC, nq_full);

for iq = 1:nq_full
    q = q_full_list(iq);

    for ic = 1:nIC
        x0 = [x10_list(ic); 0];

        res_tmp = run_case_uniform_scaling_zoh_ode45( ...
            x0, t, theta, sigma, q_slack, ...
            k1, k2, k3, cfg, q, eps_LgV);

        u_inf_mat(ic, iq) = max(abs(res_tmp.u));
    end
end

%% ============================================================
% Figure 1: x1(t), q = 1,4,8 only
%% ============================================================
figure('Name','Experiment 2: x1(t)', ...
    'Color','w','Position',plt.fig_pos1);

ax1 = axes; hold(ax1, 'on');

legend_entries = {};

for iq = 1:nq_plot
    q = q_plot_list(iq);

    for ic = 1:nIC
        plot(t, res_plot{iq, ic}.x(1,:), ...
            'Color', plt.q_colors_plot{iq}, ...
            'LineStyle', plt.ic_styles{ic}, ...
            'LineWidth', plt.lw_main);

        legend_entries{end+1} = sprintf('$q=%g,\\; x_1(0)=%.1f$', q, x10_list(ic)); 
    end
end

grid on;
xlabel('$t\;(\mathrm{s})$', 'FontSize', plt.fs_label, 'Interpreter', 'latex');
ylabel('$x_1(t)$', 'FontSize', plt.fs_label, 'Interpreter', 'latex');
%title('(a) Prioritized-state trajectories under uniform scaling', 'Interpr
% eter', 'latex');

ax1.LineWidth = plt.ax_lw;
ax1.Box = 'on';
ax1.FontSize = plt.fs_tick;
ax1.TickLabelInterpreter = 'latex';

lgd1 = legend(legend_entries, ...
    'Location', 'north', ...
    'Interpreter', 'latex','NumColumns', 2);
lgd1.FontSize = plt.fs_legend;

%% ============================================================
% Figure 2: u_infty vs q, q = 1,...,8
%% ============================================================
figure('Name','Experiment 2: u_infty vs q', ...
    'Color','w','Position',plt.fig_pos2);

ax2 = axes; hold(ax2, 'on');

for ic = 1:nIC
    plot(q_full_list, u_inf_mat(ic,:), ...
        'Color', plt.ic_curve_colors{ic}, ...
        'Marker', plt.ic_markers{ic}, ...
        'LineStyle', '-', ...
        'LineWidth', plt.lw_main, ...
        'MarkerSize', plt.ms_marker);
end

grid on;
xlabel('$q$', 'FontSize', plt.fs_label, 'Interpreter', 'latex');
xlim([1,8])
ylabel('$u_\infty := \max_t |u(t)|$', 'FontSize', plt.fs_label, 'Interpreter', 'latex');
%title('(b) Peak input versus uniform scaling parameter', 'Interpreter', 'latex');

ax2.LineWidth = plt.ax_lw;
ax2.Box = 'on';
ax2.FontSize = plt.fs_tick;
ax2.TickLabelInterpreter = 'latex';

lgd2 = legend( ...
    arrayfun(@(x10) sprintf('$x_1(0)=%.1f~~$', x10), x10_list, 'UniformOutput', false), ...
    'Location', 'northeast', ...
    'Interpreter', 'latex');
lgd2.FontSize = plt.fs_legend;

%% ============================================================
% Print summary
%% ============================================================
fprintf('\n========== Experiment 2 summary ==========\n');
fprintf('disturbance on  : %d\n', cfg.use_disturbance);
fprintf('uncertainty on  : %d\n', cfg.use_uncertainty);
fprintf('fixed sigma     : %.2f\n', sigma);
fprintf('theta           : %.2e (effectively unconstrained)\n\n', theta);

fprintf('Peak input u_infty matrix:\n');
fprintf('  rows: x1(0) = [2.0, 1.5, 1.0, 0.5]\n');
fprintf('  cols: q = [1,2,3,4,5,6,7,8]\n\n');
disp(u_inf_mat);

end

%% ============================================================
function res = run_case_uniform_scaling_zoh_ode45(x0, t, theta, sigma, q_slack, ...
    k1, k2, k3, cfg, q, eps_LgV)

N = numel(t);

x       = zeros(2, N);
u       = zeros(1, N);
slack   = zeros(1, N);
Vhist   = zeros(1, N);
LfVhist = zeros(1, N);
LgVhist = zeros(1, N);

x(:,1) = x0;

for k = 1:N-1
    xk = x(:,k);

    [uk, deltak, Vk, LfVk, LgVk] = clf_qp_controller_uniform_scaling( ...
        xk, theta, sigma, q_slack, k1, k2, k3, q);

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

[~, ~, Vhist(end), LfVhist(end), LgVhist(end)] = clf_qp_controller_uniform_scaling( ...
    x(:,end), theta, sigma, q_slack, k1, k2, k3, q);

LgV_max = max(abs(LgVhist));
th_LgV  = eps_LgV * LgV_max;

res.x = x;
res.u = u;
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
function [u_opt, delta_opt, V, LfV, LgV] = clf_qp_controller_uniform_scaling( ...
    x, theta, sigma, q_slack, k1, k2, k3, q)

x1 = x(1);
x2 = x(2);

% Same BS-CLF structure as Experiment 1, but uniformly scaled q
z2 = x2 + q*x1;

V = 0.5*x1^2 + 0.5*z2^2;

x1dot_nom = x2;
z2dot_nom_no_u = -k1*x1 - k2*x2 - k3*x1^3 + q*x2;

LgV = z2;
LfV = x1*x1dot_nom + z2*z2dot_nom_no_u;

% Same soft CLF-QP structure as Experiment 1
H = diag([1.0, q_slack]);
f = [0; 0];

A = [ LgV, -1;
      1,    0;
     -1,    0;
      0,   -1];
b = [ -sigma*V - LfV;
       theta;
       theta;
       0];

opts = optimoptions('quadprog', 'Display', 'off', 'ConstraintTolerance', 1e-8);
sol = quadprog(H, f, A, b, [], [], [], [], [], opts);

u_opt     = sol(1);
delta_opt = sol(2);
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