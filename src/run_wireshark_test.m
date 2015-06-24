nBins = 100;
binnedWeb = load_wireshark_trace('./../Wireshark Web Browsing - web_browsing.csv', nBins);
binnedVid = load_wireshark_trace('./../Wireshark Youtube - streaming_video.csv', nBins);
time = 1:nBins-1;

figure
plot(time, binnedWeb, 'r', time, binnedVid, 'b');
title('web (red) vs. video (blue)');
