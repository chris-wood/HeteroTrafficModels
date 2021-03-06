classdef simulation_run_results < handle
    %SIMULATION_RUN_RESULTS Plottable results from a simulation run
    properties
        variation;
        nSteps;
        label;
        
        simSuccessCount;
        simFailureCount;
        simWaitCount;
        simInvalidCount;
        
        nNodes;
        nodeSuccessCount;
        nodeFailureCount;
        nodeWaitCount;
        nodeInvalidCount;
        
        nodeDcfHistory;
        nodeSecHistory;
        nodeWaitHistory;
        nodeTxHistory;
        nodePacketHistory;
        
        nodeSlowWaitQuality;
        nodeSlowWaitCount;
        nodeSlowWaitIndices;
        
        allMangledPsnr;
        allMangledSnr;
        allMangledSSIM;
    end
    
    methods
        function obj = simulation_run_results()
            obj = obj@handle();
        end
        
        function PrepData(this, microsecPerTick, qualityThresholdMicrosec)
            this.nodeWaitHistory = cell(1, this.nNodes);
            this.nodeSlowWaitQuality = zeros(1, this.nNodes);
            this.nodeSlowWaitCount = zeros(1, this.nNodes);
            this.nodeTxHistory = cell(1, this.nNodes);
            this.nodePacketHistory = cell(1, this.nNodes);
            this.nodeSlowWaitIndices = cell(1, this.nNodes);
            
            for i=1:this.nNodes
                history = this.nodeDcfHistory{i};
                this.nodeWaitHistory{i} = microsecPerTick * history.packetWaitHistory(1:history.currentPacketIndex);
                this.nodeSlowWaitIndices{i} = find( this.nodeWaitHistory{i} >= qualityThresholdMicrosec );
                this.nodeSlowWaitCount(i) = size(this.nodeSlowWaitIndices{i}, 2);
                this.nodeSlowWaitQuality(i) = sum( this.nodeWaitHistory{i}(this.nodeSlowWaitIndices{i}) );
                
                endTransmit = find(history.stateTypeHistory == dcf_state_type.Transmit);
                packetChains = history.stateTypeHistory == dcf_state_type.PacketSize;
                
                this.nodeTxHistory{i} = zeros(1, size(history.stateTypeHistory, 2));
                this.nodePacketHistory{i} = zeros(1, size(history.stateTypeHistory, 2));
                for j=endTransmit
                    packetSize = 1;
                    k = j-1;
                    while( k > 0 && packetChains(k)~=0)
                        this.nodeTxHistory{i}(k) = 1;
                        packetSize = packetSize + 1;
                        k = k - 1;
                    end
                    
                    this.nodeTxHistory{i}(j) = 1;
                    this.nodePacketHistory{i}(j-packetSize+1) = packetSize;
                end
            end
            
            this.label = sprintf('Var %d', this.variation);
        end
    end
end
