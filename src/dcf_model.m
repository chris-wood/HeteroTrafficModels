% FHSS physical model in 802.11 standard
p = 0.25;
Wmin = 2;
Wmax = 4; %1024;
m = log2(Wmax / Wmin);
packetMax = 2;
% -> W = (2 4)

%%%% Transition matrix generation
%[pi, dims] = dcf_matrix(p, m, Wmin);
[piFail, dimsFail, dcfFail] = dcf_matrix_oo(1.0, m, Wmin, 1);
[pi, dims, dcf] = dcf_matrix_oo(p, m, Wmin, 1);

sim = dcf_simulator_oo(dcf, dcfFail, 1);
sim.Setup();
sim.Steps(10000);

successes = sim.CountSuccesses()
failures = sim.CountFailures()
waits = sim.CountWaits()

dims
pi

[groundProbability] = dcf_ground_state(p, Wmin, m);

%%%% Metrics computation
% Note: all time parameters must have the same units
E_p = 5; % TODO: depends on type of traffic
T_s = 10; % TODO: depends on E_p
T_c = 10; % TODO: depends on E_p
n = 2; % number of nodes -- make this a parameter
sigma = 5; % TODO

% 1. Throughput
[tau] = dcf_tau(p, Wmin, m)
P_tr = (1 - (1 - tau)^n)
P_s = (n * tau * (1 - tau)^(n - 1)) / (1 - (1 - tau)^n)
[S] = dcf_throughput( P_s, P_tr, E_p, sigma, T_s, T_c );

S

% 2. Packet loss probability
