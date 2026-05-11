function simulate_experiment3_comparisons()
clc; clear; close all;
set(groot, 'defaultTextInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');

%% ============================================================
% Experiment 3:
% Compare baseline, high-gain baseline, and shaped CLF-QP
% under input saturation, uncertainty, and disturbance
%
% Controllers:
%   1) baseline q = 2
%   2) high-gain baseline q = 4
%   3) high-gain baseline q = 6
%   4) shaped CLF based on q = 2
%
% Disturbance is activated at t = 4 s
% Plant simulation: ZOH + ode45
%
% Metrics:
%   - average settle error ||x|| on [0,4]
%   - average settle error |x1| on [0,4]
%   - settling time of x1 on [0,4]
%   - average disturbance error ||x|| on [4,12]
%   - maximum |x1(t)| on [4,12]
%   - peak |u|
%   - integral u^2
%   - max slack
%   - average slack
%
% Relative to baseline q=2:
%   - settling time change (%)
%   - robustness change (%)   using max |x1(t)| on [4,12]
%   - energy change (%)       using integral u^2
%% ============================================================

%% Simulation settings
T  = 12.0;
dt = 0.005;
t  = 0:dt:T;
N  = numel(t); %#ok<NASGU>

x0 = [1.5; 0.0];

sigma   = 3;
theta   = 6.0;
q_slack = 10000.0;

% Nominal model parameters
k1 = 1.0;
k2 = 0.8;
k3 = 0.5;

% Controller parameters
q_base   = 2.0;
q_high_1 = 4.0;
q_high_2 = 6.0;

% shaped CLF parameters
shape.q_base = 2.0;
shape.kmin   = 0.9;
shape.kmax   = 3.5;

% choose desired initial shaping level: s(V1(0)) = r
shape.r = 1.0;

V10 = 0.5 * x0(1)^2;

if ~(shape.kmin < shape.r && shape.r < shape.kmax)
    error('Require kmin < r < kmax.');
end

% s(V) = (kmin*V + kmax*ell)/(V + ell)
shape.ell = V10 * (shape.r - shape.kmin) / (shape.kmax - shape.r);

eps_LgV = 1e-2;

%% ============================================================
% Disturbance / uncertainty module
%% ============================================================
cfg.use_disturbance = true;
cfg.use_uncertainty = false;
cfg.t_activate      = 4.0;

cfg.dist.a1 = 1.5;
cfg.dist.w1 = 2.0;

cfg.unc.a1 = 0.2;
cfg.unc.a2 = 0.15;
cfg.unc.a3 = 0.1;

%% ============================================================
% Plot style
%% ============================================================
plt.c_black  = [0 0 0];
plt.c_blue   = [0 0 1];
plt.c_red    = [1 0 0];
plt.c_purple = [0.5 0 0.5];

plt.lw_main   = 2.5;
plt.fs_label  = 20;
plt.fs_tick   = 16;
plt.fs_legend = 14;
plt.ax_lw     = 2;

plt.fig_pos   = [100 100 1150 760];

%% ============================================================
% Run controllers
%% ============================================================
res_base = run_case_controller( ...
    'baseline', x0, t, theta, sigma, q_slack, ...
    k1, k2, k3, cfg, q_base, shape, eps_LgV);

res_high4 = run_case_controller( ...
    'baseline', x0, t, theta, sigma, q_slack, ...
    k1, k2, k3, cfg, q_high_1, shape, eps_LgV);

res_high6 = run_case_controller( ...
    'baseline', x0, t, theta, sigma, q_slack, ...
    k1, k2, k3, cfg, q_high_2, shape, eps_LgV);

res_shaped = run_case_controller( ...
    'shaped', x0, t, theta, sigma, q_slack, ...
    k1, k2, k3, cfg, shape.q_base, shape, eps_LgV);

%% ============================================================
% Collect metrics
%% ============================================================
m_base   = collect_metrics_case(res_base,   t);
m_high4  = collect_metrics_case(res_high4,  t);
m_high6  = collect_metrics_case(res_high6,  t);
m_shaped = collect_metrics_case(res_shaped, t);

%% ============================================================
% Figure layout:
% Row 1: x1(t) spans two columns
% Row 2: u(t) and slack(t) side by side
%% ============================================================
figure('Color','w','Position',plt.fig_pos);

x1_scale = abs(x0(1));
ctrl_labels = {'Baseline $q=2$', 'High $q=4$', 'High $q=6$', 'Shaped CLF'};

tl = tiledlayout(2,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

%% ============================================================
% Subplot 1: x1(t), first row full width
%% ============================================================
ax1 = nexttile(tl, 1, [1 2]);
hold(ax1, 'on');

h = gobjects(1,4);

h(1) = plot(ax1, t, res_base.x(1,:)/x1_scale, ...
    '-', 'Color', plt.c_black, 'LineWidth', plt.lw_main);

h(2) = plot(ax1, t, res_high4.x(1,:)/x1_scale, ...
    '-', 'Color', plt.c_blue, 'LineWidth', plt.lw_main);

h(3) = plot(ax1, t, res_high6.x(1,:)/x1_scale, ...
    '-', 'Color', plt.c_red, 'LineWidth', plt.lw_main);

h(4) = plot(ax1, t, res_shaped.x(1,:)/x1_scale, ...
    '-', 'Color', plt.c_purple, 'LineWidth', plt.lw_main);

xline(ax1, cfg.t_activate, '--k', 'LineWidth', 1.5);

grid(ax1, 'on');
xlabel(ax1, '$t\;(\mathrm{s})$', ...
    'FontSize', plt.fs_label, ...
    'Interpreter', 'latex');
ylabel(ax1, '$x_1/x_1(0)$', ...
    'FontSize', plt.fs_label, ...
    'Interpreter', 'latex');

ax1.LineWidth = plt.ax_lw;
ax1.Box = 'on';
ax1.FontSize = plt.fs_tick;
ax1.TickLabelInterpreter = 'latex';

% One common legend at the top
lgd = legend(ax1, h, ctrl_labels, ...
    'Orientation', 'horizontal', ...
    'NumColumns', 4, ...
    'Location', 'northoutside', ...
    'Interpreter', 'latex');

lgd.FontSize = plt.fs_legend;
lgd.Box = 'on';

try
    lgd.Layout.Tile = 'north';
catch
    % For older MATLAB versions
end

% Zoom box on main axis
zoom_x1 = 1.5;
zoom_x2 = 9.0;
zoom_y1 = -0.05;
zoom_y2 =  0.05;

rectangle(ax1, ...
    'Position', [zoom_x1, zoom_y1, zoom_x2-zoom_x1, zoom_y2-zoom_y1], ...
    'EdgeColor', [0.2 0.2 0.2], ...
    'LineStyle', '--', ...
    'LineWidth', 1.5);

text(ax1, 6.15, 0.035, 'Zoom', ...
    'FontSize', 12, ...
    'Interpreter', 'latex');

% Inset zoom
axes('Position',[0.30 0.72 0.44 0.12]);
box on; hold on;

plot(t, res_base.x(1,:)/x1_scale, ...
    '-', 'Color', plt.c_black, 'LineWidth', 2);

plot(t, res_high4.x(1,:)/x1_scale, ...
    '-', 'Color', plt.c_blue, 'LineWidth', 2);

plot(t, res_high6.x(1,:)/x1_scale, ...
    '-', 'Color', plt.c_red, 'LineWidth', 2);

plot(t, res_shaped.x(1,:)/x1_scale, ...
    '-', 'Color', plt.c_purple, 'LineWidth', 2);

xlim([1.5 9]);
ylim([-0.1 0.1]);
set(gca, 'FontSize', 12, 'LineWidth', 1.5);
set(gca, 'TickLabelInterpreter', 'latex');

%% ============================================================
% Subplot 2: u(t), second row left
%% ============================================================
ax2 = nexttile(tl, 3);
hold(ax2, 'on');

plot(ax2, t, res_base.u, ...
    '-', 'Color', plt.c_black, 'LineWidth', plt.lw_main);

plot(ax2, t, res_high4.u, ...
    '-', 'Color', plt.c_blue, 'LineWidth', plt.lw_main);

plot(ax2, t, res_high6.u, ...
    '-', 'Color', plt.c_red, 'LineWidth', plt.lw_main);

plot(ax2, t, res_shaped.u, ...
    '-', 'Color', plt.c_purple, 'LineWidth', plt.lw_main);

xline(ax2, cfg.t_activate, '--k', 'LineWidth', 1.5);
yline(ax2, theta, '--k', 'LineWidth', 1.0);
yline(ax2, -theta, '--k', 'LineWidth', 1.0);

grid(ax2, 'on');
xlabel(ax2, '$t\;(\mathrm{s})$', ...
    'FontSize', plt.fs_label, ...
    'Interpreter', 'latex');
ylabel(ax2, '$u$', ...
    'FontSize', plt.fs_label, ...
    'Interpreter', 'latex');
xlim([0,12]);

ax2.LineWidth = plt.ax_lw;
ax2.Box = 'on';
ax2.FontSize = plt.fs_tick;
ax2.TickLabelInterpreter = 'latex';

%% ============================================================
% Subplot 3: slack(t), second row right
%% ============================================================
ax3 = nexttile(tl, 4);
hold(ax3, 'on');

plot(ax3, t, res_base.slack, ...
    '-', 'Color', plt.c_black, 'LineWidth', plt.lw_main);

plot(ax3, t, res_high4.slack, ...
    '-', 'Color', plt.c_blue, 'LineWidth', plt.lw_main);

plot(ax3, t, res_high6.slack, ...
    '-', 'Color', plt.c_red, 'LineWidth', plt.lw_main);

plot(ax3, t, res_shaped.slack, ...
    '-', 'Color', plt.c_purple, 'LineWidth', plt.lw_main);

xline(ax3, cfg.t_activate, '--k', 'LineWidth', 1.5);

grid(ax3, 'on');
xlabel(ax3, '$t\;(\mathrm{s})$', ...
    'FontSize', plt.fs_label, ...
    'Interpreter', 'latex');
ylabel(ax3, '$\delta$', ...
    'FontSize', plt.fs_label, ...
    'Interpreter', 'latex');
xlim([0,12]);
ax3.LineWidth = plt.ax_lw;
ax3.Box = 'on';
ax3.FontSize = plt.fs_tick;
ax3.TickLabelInterpreter = 'latex';

%% ============================================================
% Print summary
%% ============================================================
fprintf('\n========== Experiment 3 summary ==========\n');
fprintf('disturbance on   : %d\n', cfg.use_disturbance);
fprintf('uncertainty on   : %d\n', cfg.use_uncertainty);
fprintf('activation time  : %.2f s\n', cfg.t_activate);
fprintf('sigma            : %.2f\n', sigma);
fprintf('theta            : %.2f\n', theta);
fprintf('shape ell        : %.6f\n', shape.ell);
fprintf('check s(V1(0))   : %.6f\n\n', shaping_factor(V10, shape.kmin, shape.kmax, shape.ell));

print_metrics_case('Baseline q=2',  m_base);
print_metrics_case('High q=4',      m_high4);
print_metrics_case('High q=6',      m_high6);
print_metrics_case('Shaped CLF',    m_shaped);

fprintf('\n========== Relative change w.r.t. baseline q=2 ==========\n');
print_relative_metrics('High q=4',   m_high4,  m_base);
print_relative_metrics('High q=6',   m_high6,  m_base);
print_relative_metrics('Shaped CLF', m_shaped, m_base);

end

%% ============================================================
function res = run_case_controller(mode, x0, t, theta, sigma, q_slack, ...
    k1, k2, k3, cfg, q, shape, eps_LgV)

N = numel(t);

x           = zeros(2, N);
u           = zeros(1, N);
slack       = zeros(1, N);
Vhist       = zeros(1, N);
LfVhist     = zeros(1, N);
LgVhist     = zeros(1, N);
s1hist      = ones(1, N);
qeffhist    = zeros(1, N);
qeffdothist = zeros(1, N);

x(:,1) = x0;

for k = 1:N-1
    xk = x(:,k);

    [uk, deltak, Vk, LfVk, LgVk, s1k, qeffk, qeffdotk] = clf_qp_controller( ...
        mode, xk, theta, sigma, q_slack, k1, k2, k3, q, shape);

    tk  = t(k);
    tk1 = t(k+1);

    dyn = @(tt, xx) plant_dynamics(xx, uk, tt, k1, k2, k3, cfg);
    [~, xseg] = ode45(dyn, [tk tk1], xk);
    x(:,k+1) = xseg(end, :)';

    u(k)           = uk;
    slack(k)       = deltak;
    Vhist(k)       = Vk;
    LfVhist(k)     = LfVk;
    LgVhist(k)     = LgVk;
    s1hist(k)      = s1k;
    qeffhist(k)    = qeffk;
    qeffdothist(k) = qeffdotk;
end

u(end)           = u(end-1);
slack(end)       = slack(end-1);
s1hist(end)      = s1hist(end-1);
qeffhist(end)    = qeffhist(end-1);
qeffdothist(end) = qeffdothist(end-1);

[~, ~, Vhist(end), LfVhist(end), LgVhist(end), s1hist(end), qeffhist(end), qeffdothist(end)] = clf_qp_controller( ...
    mode, x(:,end), theta, sigma, q_slack, k1, k2, k3, q, shape);

LgV_max = max(abs(LgVhist));
th_LgV  = eps_LgV * LgV_max;

res.x = x;
res.u = u;
res.slack = slack;
res.V = Vhist;
res.LfV = LfVhist;
res.LgV = LgVhist;
res.s1 = s1hist;
res.qeff = qeffhist;
res.qeff_dot = qeffdothist;
res.LgV_max = LgV_max;
res.th_LgV  = th_LgV;
res.near_zero_idx = abs(LgVhist) <= th_LgV;
end

%% ============================================================
function dx = plant_dynamics(x, u, t, k1, k2, k3, cfg)
x1 = x(1);
x2 = x(2);

d = disturbance_module(t, cfg);
Delta = uncertainty_module(x, t, cfg);

dx = [x2;
     -k1*x1 - k2*x2 - k3*x1^3 + Delta + d + u];
end

%% ============================================================
function [u_opt, delta_opt, V, LfV, LgV, s1, qeff, qeff_dot] = clf_qp_controller( ...
    mode, x, theta, sigma, q_slack, k1, k2, k3, q, shape)

x1 = x(1);
x2 = x(2);

switch lower(mode)
    case 'baseline'
        s1 = 1.0;
        qeff = q;
        qeff_dot = 0.0;

    case 'shaped'
        V1 = 0.5*x1^2;
        s1 = shaping_factor(V1, shape.kmin, shape.kmax, shape.ell);
        ds1 = shaping_factor_derivative(V1, shape.kmin, shape.kmax, shape.ell);
        qeff = s1 * q;
        qeff_dot = q * ds1 * x1 * x2;

    otherwise
        error('Unknown controller mode.');
end

z2 = x2 + qeff*x1;

V = 0.5*x1^2 + 0.5*z2^2;

x1dot_nom = x2;
z2dot_nom_no_u = -k1*x1 - k2*x2 - k3*x1^3 + qeff_dot*x1 + qeff*x2;

LgV = z2;
LfV = x1*x1dot_nom + z2*z2dot_nom_no_u;

H = diag([1.0, q_slack]);
f = [0; 0];

A = [ LgV, -1 ];
b = [ -sigma*V - LfV ];

lb = [-theta; 0];
ub = [ theta; inf ];

opts = optimoptions('quadprog', ...
    'Display', 'off', ...
    'ConstraintTolerance', 1e-10);

sol = quadprog(H, f, A, b, [], [], lb, ub, [], opts);

u_opt     = min(max(sol(1), -theta), theta);
delta_opt = max(sol(2), 0);
end

%% ============================================================
function s = shaping_factor(v, kmin, kmax, ell)
s = (kmin*v + kmax*ell) / (v + ell);
end

%% ============================================================
function ds = shaping_factor_derivative(v, kmin, kmax, ell)
ds = -((kmax - kmin) * ell) / (v + ell)^2;
end

%% ============================================================
function d = disturbance_module(t, cfg)
if ~cfg.use_disturbance || t < cfg.t_activate
    d = 0.0;
    return;
end

d = cfg.dist.a1 * sin(cfg.dist.w1 * t);
end

%% ============================================================
function Delta = uncertainty_module(x, t, cfg)
if ~cfg.use_uncertainty || t < cfg.t_activate
    Delta = 0.0;
    return;
end

x1 = x(1);
x2 = x(2);
Delta = cfg.unc.a1*x1 + cfg.unc.a2*x1^3 + cfg.unc.a3*x2;
end

%% ============================================================
function m = collect_metrics_case(res, t)
x1    = res.x(1,:);
xnorm = vecnorm(res.x, 2, 1);
uabs  = abs(res.u);
u2    = res.u.^2;
sl    = res.slack;

idx_settle = (t >= 0) & (t <= 4);
idx_dist   = (t >= 4) & (t <= 12);

t_settle = t(idx_settle);
t_dist   = t(idx_dist);

x1_settle = x1(idx_settle);
x1_dist   = x1(idx_dist);

xnorm_settle = xnorm(idx_settle);
xnorm_dist   = xnorm(idx_dist);

m.avg_settle_err = trapz(t_settle, xnorm_settle) / (t_settle(end) - t_settle(1));
m.avg_settle_x1  = trapz(t_settle, abs(x1_settle)) / (t_settle(end) - t_settle(1));
m.avg_dist_err   = trapz(t_dist, xnorm_dist) / (t_dist(end) - t_dist(1));

x1_tol = 0.01 * abs(x1(1));
m.settling_time_x1 = NaN;

for k = 1:length(t_settle)
    if all(abs(x1_settle(k:end)) <= x1_tol)
        m.settling_time_x1 = t_settle(k);
        break;
    end
end

m.max_dist_x1 = max(abs(x1_dist));
m.peak_u      = max(uabs);
m.int_u2      = trapz(t, u2);
m.max_slack   = max(sl);
m.avg_slack   = trapz(t, sl) / (t(end) - t(1));
end

%% ============================================================
function r = relative_metrics(m, mbase)
pct = @(a,b) 100*(a-b)/b;

if isnan(m.settling_time_x1) || isnan(mbase.settling_time_x1)
    r.st_pct = NaN;
else
    r.st_pct = pct(m.settling_time_x1, mbase.settling_time_x1);
end

r.rob_pct    = pct(m.max_dist_x1, mbase.max_dist_x1);
r.energy_pct = pct(m.int_u2, mbase.int_u2);
r.peaku_pct  = pct(m.peak_u, mbase.peak_u);
end

%% ============================================================
function print_metrics_case(name, m)

fprintf('%s\n', name);
fprintf('  Avg. settle error ||x||  [0,4] : %.6f\n', m.avg_settle_err);
fprintf('  Avg. settle error |x1|   [0,4] : %.6f\n', m.avg_settle_x1);

if isnan(m.settling_time_x1)
    fprintf('  Settling time (x1)       [0,4] : not reached\n');
else
    fprintf('  Settling time (x1)       [0,4] : %.6f\n', m.settling_time_x1);
end

fprintf('  Avg. disturbance error   [4,12]: %.6f\n', m.avg_dist_err);
fprintf('  Max |x1(t)|              [4,12]: %.6f\n', m.max_dist_x1);
fprintf('  Peak |u|                       : %.6f\n', m.peak_u);
fprintf('  Integral u^2                   : %.6f\n', m.int_u2);
fprintf('  Max slack                      : %.6f\n', m.max_slack);
fprintf('  Avg. slack                     : %.6f\n\n', m.avg_slack);
end

%% ============================================================
function print_relative_metrics(name, m, mbase)
r = relative_metrics(m, mbase);

fprintf('%s\n', name);

if isnan(r.st_pct)
    fprintf('  Settling time change          : N/A\n');
else
    fprintf('  Settling time change          : %+8.2f %%\n', r.st_pct);
end

fprintf('  Robustness change (max |x1|)  : %+8.2f %%\n', r.rob_pct);
fprintf('  Energy change (int u^2)       : %+8.2f %%\n', r.energy_pct);
fprintf('  Peak |u| change               : %+8.2f %%\n', r.peaku_pct);

fprintf('\n');
end