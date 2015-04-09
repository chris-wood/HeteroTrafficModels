function [ simulator ] = create_simulation( bVerbose, numNormals, numMedias, pSuccess, pArrive, pEnter, Wmin, Wmax, nMaxPackets, nInterarrival )

% Precompute variables for the DCF model
m = log2(Wmax / Wmin);
W = zeros(1,m+1);
for i = 1:(m+1)
    W(1,i) = (2^(i-1)) * Wmin;
end

% Populate the nodes in the simulator
dcf_model = dcf_markov_model();
dcf_model.m = m;
dcf_model.wMin = Wmin;
dcf_model.nPkt = nMaxPackets;
dcf_model.nInterarrival = nInterarrival;
dcf_model.pEnterInterarrival = pEnter;
dcf_model.pRawArrive = pArrive;

simulator = dcf_simulator_oo(pSuccess, 0.0);

for i = 1:numNormals
    nodeName = sprintf('node%d', i);
    simulator.add_plain_node(nodeName, dcf_model);
end

% modify dcf matrix for media settings
bps = 4 * 1000000; % 4MBits/second
payloadSize = 1500*8;
    
% We always have fixed packetsize of 1 payload
dcf_model.bFixedPacketchain = true;
dcf_model.nPkt = 1;

% We want to estimate the desired video BPS
dcf_model.pEnterInterarrival = 1.0;
dcf_model.bFixedInterarrivalChain = true;
dcf_model.CalculateInterarrival(phys80211_type.B, bps, payloadSize);

for i = 1:numMedias
	video_model = mpeg4_frame_model();
	video_model.gopAnchorFrameDistance = 3;
	video_model.gopFullFrameDistance = 12;
    video_model.bps = bps; % 4MBits/second
    video_model.payloadSize = payloadSize;
    
    nodeName = sprintf('media-node%d', i);
    simulator.add_multivideo_model(nodeName, dcf_model, video_model);
end

simulator.Setup(bVerbose);

end