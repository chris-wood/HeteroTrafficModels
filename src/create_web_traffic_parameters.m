function [ pArrive, pEnter, nMaxPackets, nInterarrival ] = create_web_traffic_parameters(  )

pArrive = [1.0];
pEnter = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
nMaxPackets = [1, 5, 10, 20, 50];
nInterarrival = [1, 5, 10, 20, 50];

end
