run_set_path

% Load in a real video file to test against
vu = video_util();
vu.setup();
vu.nFrames = 800; % a bit over 30 seconds
vu.prep();

doVideoMangle = false;
slotsPerVPacket = 5;
qualityThresholdMicrosec = 50000; % 50 miliseconds

% max number of nodes in system
nVidnodes = 2;
nDatanodes = 0;

% Shared params
simName = 'mp4-interference';
simParams = dcf_simulation_params();
simParams.pSingleSuccess = [0.60, 0.80, 1.0];
simParams.physical_type = phys80211_type.B;

% Video node stuff
% Grab values from our actual loaded file
timesteps = slotsPerVPacket * vu.nPacketsSrcC; % how many packets we'll need for our video (assume pretty good conditions)

% File node stuff
nSizeTypes = 1;
nInterarrivalTypes = 1;
fileBigness = 1.0;
fileWaityness = 1.0;
wMin = 8;
wMax = 16;

vidParams = traffic_video_stream(1, wMin, wMax, vu.bpsSrcC, [], []);
dataParams = traffic_file_downloads(1, wMin, wMax, nSizeTypes, nInterarrivalTypes, fileBigness, fileWaityness);

nSimulations = max(nDatanodes, 1) * max(nVidnodes, 1);
results = cell( 1, nSimulations );
[results{1}, plotColors] = run_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, doVideoMangle, qualityThresholdMicrosec, max(0,nDatanodes), 1 );
nVariations = size(results{1,1}, 2);
nNodes = zeros(1, nSimulations);
labels = cell(1, nVariations);

overThresholdCount = zeros( nSimulations, nVariations );
overThresholdTime = zeros( nSimulations, nVariations );
transferCount = zeros( nSimulations, nVariations, timesteps );

allMangledPsnr = cell(nSimulations, nVariations);
allMangledSnr = cell(nSimulations, nVariations);
allMangledSSIM = cell(nSimulations, nVariations);

meanMangledPsnr = zeros(nSimulations, nVariations);
meanMangledSnr = zeros(nSimulations, nVariations);
medMangledPsnr = zeros(nSimulations, nVariations);
medMangledSnr = zeros(nSimulations, nVariations);
medMangledSSIM = zeros(nSimulations, nVariations);

r = results{1};
for i=1:nVariations
    labels{i} = r{i}.label;
end

% TEMP OVERRIDE
labels{1} = 'pSuccess=0.2';
labels{2} = 'pSuccess=0.6';
labels{3} = 'pSuccess=1.0';

simIndex = 1;
if (nDatanodes > 0)
    for vi=1:nVidnodes
        for di=1:nDatanodes
            nNodes(simIndex) = vi + di;
            [results{simIndex}, ~] = run_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, doVideoMangle, qualityThresholdMicrosec, di, vi );
            simIndex = simIndex + 1;
        end
    end
else
    for vi=1:nVidnodes
        nNodes(simIndex) = vi;
        [results{simIndex}, ~] = run_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, doVideoMangle, qualityThresholdMicrosec, 0, vi );
        simIndex = simIndex + 1;
    end
end

for i=1:nSimulations
    allResults = results{i};
    
    for j=1:nVariations
        variationResults = allResults{j};
        
        overThresholdCount(i, j) = variationResults.nodeSlowWaitCount(1);
        overThresholdTime(i, j) = variationResults.nodeSlowWaitQuality(1);
        transferCount(i, j, :) = variationResults.nodeTxHistory{1};

%         badPacketIndices = variationResults.nodeSlowWaitIndices{1};
%         [allMangledPsnr{i, j}, allMangledSnr{i, j}] = vu.testMangle(badPacketIndices, 'sC', 'dC');

        allMangledPsnr{i, j} = variationResults.allMangledPsnr;
        allMangledSnr{i, j} = variationResults.allMangledSnr;
        allMangledSSIM{i, j} = variationResults.allMangledSSIM;
                 
        cleanPsnr = allMangledPsnr{i, j}( isfinite(allMangledPsnr{i, j}) );
        cleanSnr = allMangledSnr{i, j}( isfinite(allMangledSnr{i, j}) );
        cleanSSIM = allMangledSSIM{i, j}( isfinite(allMangledSSIM{i, j}) );
         
        meanMangledPsnr(i, j) = mean(cleanPsnr);
        meanMangledSnr(i, j) = mean(cleanSnr);
        medMangledPsnr(i, j) = median(cleanPsnr);
        medMangledSnr(i, j) = median(cleanSnr);
        medMangledSSIM(i, j) = median(cleanSSIM);
    end
end

fprintf('Timesteps = %d\n', timesteps);

channelBps = phys80211.EffectiveMaxDatarate(simParams.physical_type, simParams.physical_payload, simParams.physical_speed, 1);
dataBps = (fileBigness/fileWaityness) * (channelBps/wMin);
fprintf('%s Channel Speed: %.2fMbps\n', phys80211.Name(simParams.physical_type), (channelBps/1000000));
fprintf('Desired Video Speed: %.2fMbps\n', (vu.bpsSrcC/1000000));
fprintf('Desired Data Speed: %.2fMbps\n', (dataBps/1000000));

% Late packets
nPlots = 1;
plot_rundata( nPlots, [2 1], 1, 'Time spent waiting over threshold (lower better)', ...
    'Time (microseconds)', labels, plotColors, nVariations, nSimulations, overThresholdTime );
plot_rundata( nPlots, [2 1], 2, 'Packets waiting over threshold (lower better)', ...
    'Packet Count', labels, plotColors, nVariations, nSimulations, overThresholdCount );
savefig( sprintf('./../results/figures/VN%d Late Packets.fig', nVidnodes) );
    
% Data transfer
nPlots = 1 + nPlots;

if (doVideoMangle)
    % PSNR
    nPlots = 1 + nPlots;
    plot_rundata( nPlots, [2 1], 1, 'Mean PSNR with dropped packets (lower better)', ...
        'PSNR', labels, plotColors, nVariations, nSimulations, meanMangledPsnr);
    plot_rundata( nPlots, [2 1], 2, 'Median PSNR with dropped packets (lower better)', ...
        'PSNR', labels, plotColors, nVariations, nSimulations, medMangledPsnr);
    savefig( sprintf('./../results/figures/VN%d PSNR.fig', nVidnodes) );

    % SNR
    nPlots = 1 + nPlots;
    plot_rundata( nPlots, [2 1], 1, 'Mean SNR with dropped packets (lower better)', ...
        'SNR', labels, plotColors, nVariations, nSimulations, meanMangledSnr );
    plot_rundata( nPlots, [2 1], 1, 'Median SNR with dropped packets (lower better)', ...
        'SNR', labels, plotColors, nVariations, nSimulations, medMangledSnr );
    savefig( sprintf('./../results/figures/VN%d SNR.fig', nVidnodes) );

    % SSIM
    nPlots = 1 + nPlots;
    plot_rundata( nPlots, 'Median SSIM Similarity with dropped packets(lower better)', ...
        'SNR', labels, plotColors, nVariations, nSimulations, medMangledSSIM );
    savefig( sprintf('./../results/figures/VN%d SSIM.fig', nVidnodes) );
end
