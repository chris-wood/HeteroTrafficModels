% Simulation parameters
timeSteps = 100000; 
numNormals = 3;
numMedias = 3;
numberOfNodes = numNormals + numMedias;
pSuccess = 1.0; 
pArrive = 1.0;
pEnter = 0;
nMaxPackets = 1;
nInterarrival = 0;
Wmin = 2;
Wmax = 16;
physical_type = phys80211_type.B;
physical_speed = 1.0;
physical_payload = 8*1500;

desired_video_bps = 4 * 1000000; % 4MBits/second

verboseSetup = false;
verboseExecute = false;
verbosePrint = false;

throughputValues = zeros(1, numberOfNodes);
successValues = zeros(1, numberOfNodes);
failureValues = zeros(1, numberOfNodes);

for i = 1:numberOfNodes
    if (i==1)
        continue;
    end
    
    if (i <= numNormals) 
        numN = i;
        numM = 0;
    else 
        numN = numNormals;
        numM= i - numNormals;
    end
    
    fName = sprintf('./../results/%d_normal%d_media%d.sim', i, numN, numM);
    fprintf('\n------------\nrunning test: %s\n', fName);
    fid = fopen(fName, 'w');
    if (fid == -1)
        disp('Error: could not open the file for output.');
        exit;
    end
    
    simulator = create_simulation(verboseSetup, numN, numM, pSuccess, pArrive, pEnter, Wmin, Wmax, nMaxPackets, nInterarrival, desired_video_bps, physical_type, physical_payload, physical_speed);
    simulator.Steps(timeSteps, verboseExecute);
    simulator.PrintResults(verbosePrint);

    % write the simulation parameters and results for each node to the file
    fprintf(fid, '%d,%d,%f,%f,%f,%d,%d\n', timeSteps, i, pSuccess, pArrive, pEnter, Wmin, Wmax);
    fprintf(fid, '%d,%d,%d\n', simulator.CountSuccesses(), simulator.CountFailures(), simulator.CountWaits());
    
    % flush and cleanup
    fclose(fid);
    
    % Accumulate values
    throughputValues(1, i) = simulator.GetTransmit();
    successValues(1, i) = simulator.GetSuccess();
    failureValues(1, i) = simulator.GetFailures();
end

figureId = 1;
figure(figureId)
figureId = figureId + 1; 

x = zeros(1, numberOfNodes);
for i = 1:numberOfNodes
    x(1, i) = i;
end
plot(x, throughputValues, x, successValues, x, failureValues);

title(sprintf('Metrics for %d %d Nodes', numN, numM));
xlabel('Number of Nodes');
ylabel('Metric Value');

fileName = sprintf('./../results/fig-%d.fig', figureId);
saveas(gcf,['.', filesep, fileName], 'fig');  % gca?


