run_set_path

nVidNodes = 1;
nDataNodes = 0;

% Load in a real video file to test against
vu = video_util();
vu.nFrames = 150;
vu.prep();

slotsPerVPacket = 50;
qualityThresholdMicrosec = 50000; % 50 miliseconds

% Shared params
simName = 'mp4-interference';
simParams = dcf_simulation_params();
simParams.pSingleSuccess = 1.0;
simParams.pMultiSuccess = 1.0; % For this trace, we're not simulating failures so everything succeeds
simParams.physical_type = phys80211_type.B;

wMin = 8;
wMax = 16;

% Video node stuff
% Grab values from our actual loaded file
timesteps = slotsPerVPacket * vu.nPacketsSrcC; % how many packets we'll need for our video (assume pretty good conditions)

% File node stuff
nSizeTypes = 1;
nInterarrivalTypes = 1;
fileBigness = 4.0;
fileWaityness = 2.0;

vidParams = traffic_video_stream(1, wMin, wMax, vu.bpsSrcC, [], []);
dataParams = traffic_file_downloads(1, wMin, wMax, nSizeTypes, nInterarrivalTypes, fileBigness, fileWaityness);

nSims = nVidNodes + nDataNodes;
nSim = 1;
simType = zeros(1, nSims);
simResults = cell(1, nSims);

for i=1:nVidNodes
    fprintf('\n==============\nSimulating video node %d of %d\n', i, nVidNodes);
    sim = setup_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, qualityThresholdMicrosec, 1, 0 );
    sim.cleanCache = true;
    sim.Run(false);
    
    simType(nSim) = 20;
    simResults{nSim} = sim.simResults;
    nSim = nSim + 1;
end

for i=1:nDataNodes
    fprintf('\n==============\nSimulating data node %d of %d\n', i, nDataNodes);
    sim = setup_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, qualityThresholdMicrosec, 0, 1 );
    sim.cleanCache = true;
    sim.Run(false);
    
    simType(nSim) = 10;
    simResults{nSim} = sim.simResults;
    nSim = nSim + 1;
end

fprintf('Dumping out history to file\n');
bytesPerPacket = simParams.physical_payload / 8;
deltaTime = phys80211.TransactionTime(simParams.physical_type, simParams.physical_payload, simParams.physical_speed);
time = 0;


% Col 1: 'Simulation #'
% Col 2: 'Node Type (10=web, 20=generic video, 21=iframe, 22=pframe, 23=bframe)'
% Col 2: 'Packet Index'
% Col 3: 'Time (microseconds)'
% Col 4: 'Packet Size (bytes)'
csvFilename = './../results/trace.csv';
clear csvData;

csvRow = 1;
for i=1:nSims
    % Assume we're just doing simulations with a single node by iteslf
    results = simResults{i};
    packetHistories = results{1}.nodePacketHistory;    
    packetHistory = packetHistories{1};
    sentPackets = find(packetHistory ~= 0);
    
    if (simType(i)==10) % type (web=10, video=20's)
        types = 10 * ones(1, size(sentPackets,2));
    else
        types = results{1}.nodeSecHistory{1}.stateTypeHistory( sentPackets );
        types( types==21 ) = 20;
        types( types==31 ) = 30;
        types( types==41 ) = 40;
    end
    
    dataRow = 1;
    for j=sentPackets
        time = deltaTime * j;
        packetSize = bytesPerPacket * packetHistory(j);
        
        csvData(csvRow, 1) = int32(i); % simulation #
        csvData(csvRow, 2) = int32(types(dataRow)); % IFrame(20,21) BFrame(30,31) PFrame(40,41)
        csvData(csvRow, 3) = int32(j); % packet index
        csvData(csvRow, 4) = time; % time (microseconds)
        csvData(csvRow, 5) = int32(packetSize); % packetsize (bytes)
        
        csvRow = csvRow + 1;
        dataRow = dataRow + 1;
    end
end

csvwrite(csvFilename, csvData);
