function [ nodegen ] = traffic_web_browsing(nNodes, wMin, wMax, nSizeTypes, nInterarrivalTypes, nEnterInterarrivalTypes, fileBigness, fileWaityness)
%TRAFFIC_WEB_BROWSING Create nodegen to simulate browsing webpages
    nodegen = nodegen_data_nodes();
    nodegen.name = 'file download';
    
    % user entered params
    if (~isempty(nNodes))
        nodegen.nGenerators = nNodes;
    end
    
    if (~isempty(wMin))
        nodegen.wMin = wMin;
    end
    
    if (~isempty(wMax))
        nodegen.wMax = wMax;
    end
    
    % 2nd level params to be used later
    if (isempty(fileBigness))
        fileBigness = 1.0;
    end
    
    if (isempty(fileWaityness))
        fileWaityness = 1.0;
    end
    
    if (isempty(nSizeTypes))
        nSizeTypes = 3;
    end
    
    if (isempty(nInterarrivalTypes))
        nInterarrivalTypes = 3;
    end
    
    if (isempty(nEnterInterarrivalTypes))
        nEnterInterarrivalTypes = 3;
    end
    
    % There is always a packet in the buffer
    nodegen.pArrive = 1.0;
    
    nodegen.pEnter = 1:nEnterInterarrivalTypes / nEnterInterarrivalTypes;
    nodegen.nMaxPackets = ceil( fileBigness * 1:nSizeTypes );
    nodegen.nInterarrival = ceil( fileWaityness * 5 * 1:nInterarrivalTypes );
end
