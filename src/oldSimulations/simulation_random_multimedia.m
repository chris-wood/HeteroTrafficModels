timeSteps = 10000; 
Wmin = 2;
Wmax = 16;
pSuccess = 1.0;
physical_type = phys80211_type.B;
physical_payload = 8*1500;
physical_speed = 1.0;

% Precompute variables for the DCF model
[m, W] = dcf_markov_model.CalculateDimensions(Wmin, Wmax);

[pArrive1, pEnter1, nPackets1, nInterarrival1] = create_random_parameters();
[bps] = create_multimedia_parameters();

[t1, numArrive1] = size(pArrive1);
[t2, numEnter1] = size(pEnter1);
[t3, numPackets1] = size(nPackets1);
[t4, numInterarrival1] = size(nInterarrival1);
[t5, numBps] = size(bps);

throughput1 = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numBps);
success1 = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numBps);
failure1 = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numBps);

throughput2 = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numBps);
success2 = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numBps);
failure2 = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numBps);

allthroughput = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numBps);
allsuccess = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numBps);
allfailure = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numBps);

% Cover all combinations
for i1 = 1:numArrive1
    for i2 = 1:numEnter1
        for i3 = 1:numPackets1
            for i4 = 1:numInterarrival1

                for b = 1:numBps
                    simulator = dcf_simulator(pSuccess, 1.0, physical_type, physical_payload, physical_speed);

                    randomNode = add_random_node(simulator, m, Wmin, 1, pArrive1(i1), pEnter1(i2), nPackets1(i3), nInterarrival1(i4));
                    webNode = add_multimedia_node(simulator, m, Wmin, 2, bps(b));

                    fName = sprintf('./../results/simulation_random_multimedia-%d_%d_%d_%d_%d_%d.sim', pArrive1(i1), pEnter1(i2), nPackets1(i3), nInterarrival1(i4), bps(b), payload(p));
                    fprintf('\n------------\nrunning test: %s\n', fName);
                    fid = fopen(fName, 'w');
                    if (fid == -1)
                        disp('Error: could not open the file for output.');
                        exit;
                    end

                    simulator.Setup(true);
                    simulator.Steps(timeSteps, true);
                    simulator.PrintResults(true);

                    fprintf(fid, '%d,%d,%d\n', timeSteps, Wmin, Wmax);
                    fprintf(fid, '%d,%d,%d\n', simulator.GetNode(1).CountSuccesses(), simulator.GetNode(1).CountFailures(), simulator.GetNode(1).CountWaits());
                    fprintf(fid, '%d,%d,%d\n', simulator.GetNode(2).CountSuccesses(), simulator.GetNode(2).CountFailures(), simulator.GetNode(2).CountWaits());
                    fprintf(fid, '%d,%d,%d\n', simulator.CountSuccesses(), simulator.CountFailures(), simulator.CountWaits());

                    throughput1(i1, i2, i3, i4, b) = simulator.GetNode(1).GetTransmit(timeSteps);
                    success1(i1, i2, i3, i4, b) = simulator.GetNode(1).GetSuccess();
                    failure1(i1, i2, i3, i4, b) = simulator.GetNode(1).GetFailures();

                    throughput2(i1, i2, i3, i4, b) = simulator.GetNode(2).GetTransmit(timeSteps);
                    success2(i1, i2, i3, i4, b) = simulator.GetNode(2).GetSuccess();
                    failure2(i1, i2, i3, i4, b) = simulator.GetNode(2).GetFailures();

                    allthroughput(i1, i2, i3, i4, b) = simulator.GetTransmit();
                    allsuccess(i1, i2, i3, i4, b) = simulator.GetSuccess();
                    allfailure(i1, i2, i3, i4, b) = simulator.GetFailures();
                end
            end
        end
    end
end

% Plot variance in each parameter
figureId = 1;
for i1 = 1:numArrive1
    for i2 = 1:numEnter1
        for i3 = 1:numPackets1
            for i4 = 1:numInterarrival1
                
                % Payload variation
                if numPayload > 1
                for b = 1:numBps
                    figure(figureId)
                    figureId = figureId + 1; 

                    x = payload;
                    throughputValues1 = zeros(1, numPayload);
                    throughputValues2 = zeros(1, numPayload);
                    averageThroughputValues = zeros(1, numPayload);
                    for p = 1:numPayload
                        throughputValues1(1, p) = throughput1(i1, i2, i3, i4, b, p);
                        throughputValues2(1, p) = throughput2(i1, i2, i3, i4, b, p);
                        averageThroughputValues(1, p) = allthroughput(i1, i2, i3, i4, b, p);
                    end

                    plot(x, throughputValues1, x, throughputValues2, x, averageThroughputValues);

                    title(sprintf('Payload Size Variance'));
                    xlabel('Payload Size (bits)');
                    ylabel('Throughput');
                    legend('random throughput', 'multimedia throughput', 'average throughput');

                    fileName = sprintf('./../results/fig-simulation_random_multimedia-payload-%d_%d_%d_%d_%d.fig', pArrive1(i1), pEnter1(i2), nPackets1(i3), nInterarrival1(i4), bps(b));
                    saveas(gcf,['.', filesep, fileName], 'fig');  % gca?
                end
                end
                
                % bps variation
                if numBps > 1
                for p = 1:numPayload
                    figure(figureId)
                    figureId = figureId + 1; 

                    x = bps;
                    throughputValues1 = zeros(1, numBps);
                    throughputValues2 = zeros(1, numBps);
                    averageThroughputValues = zeros(1, numBps);
                    for b = 1:numBps
                        throughputValues1(1, b) = throughput1(i1, i2, i3, i4, b, p);
                        throughputValues2(1, b) = throughput2(i1, i2, i3, i4, b, p);
                        averageThroughputValues(1, b) = allthroughput(i1, i2, i3, i4, b, p);
                    end

                    plot(x, throughputValues1, x, throughputValues2, x, averageThroughputValues);

                    title(sprintf('BPS Variance'));
                    xlabel('BPS (bits / second)');
                    ylabel('Throughput');
                    legend('random throughput', 'multimedia throughput', 'average throughput');

                    fileName = sprintf('./../results/fig-simulation_random_multimedia-bps-%d_%d_%d_%d_%d.fig', pArrive1(i1), pEnter1(i2), nPackets1(i3), nInterarrival1(i4), payload(p));
                    saveas(gcf,['.', filesep, fileName], 'fig');  % gca?
                end
                end
            end
        end
    end
end
