classdef video_util < handle
    %VIDEO_UTIL Stuff to handle load/save of videos
    
    properties
        % http://www.h264info.com/clips.html
        DEFAULT_INPUT_FOLDER = 'C:\Users\rawkuts\Downloads\';
        DEFAULT_OUTPUT_FOLDER = './../results/cache/video/';
        DEFAULT_FILE = 'serenity_480p_trailer.mp4';
        DEFAULT_START_FRAME = 150;
        DEFAULT_NFRAMES = 1000;
        DEFAULT_PACKETSIZE = 1316;
    end
    
    properties
        fNameOrig;
        fNameSrcU;
        fNameSrcC;
        fNameDstC;
        frameStart;
        nFrames;
        nBytesPerPacket;
        resDst;
    end
    
    properties
        nBytesSrcC;
        nPacketsSrcC;
        fpsSrcC;
        bpsSrcC;
        durationSrcC;
    end
    
    methods (Static)
        function exe = ffmpeg_exe()
            %exe = 'E:\Downloads\ffmpeg-20150414-git-013498b-win64-static\bin\ffmpeg.exe';
            exe = 'C:\Users\rawkuts\Downloads\ffmpeg-20150605-git-7be0f48-win64-static\bin';
        end
        
        function exe = xvid_encode()
            exe = 'C:\Users\rawkuts\Downloads\xvidcore\build\win32\bin\xvid_encraw.exe';
        end
        
        function exe = xvid_decode()
            exe = 'C:\Users\rawkuts\Downloads\xvidcore\build\win32\bin\xvid_decraw.exe';
        end
        
        function [fNameOrig, fNameSrcU, fNameSrcC, fNameDstC] = subFilenames(folderIn, folderOut, fNameIn, frameStart, nFrames)
            fNameOrig = fullfile(folderIn, fNameIn);
            
            subsection = ['.' num2str(frameStart) '-' num2str(frameStart+nFrames-1)];
            fNameSrcU = fullfile(folderOut, ['src_u_' fNameIn subsection '.avi']);
            fNameSrcC = fullfile(folderOut, ['src_c_' fNameIn subsection '.mp4']);
            fNameDstC = fullfile(folderOut, ['dst_c_' fNameIn subsection '.mp4']);
            
            [~, ~, ~] = mkdir(folderOut);
        end
        
        % Take input video and extract subset of frames and reencode
        function extractFrames(fNameIn, fNameOut, encoding, frameStart, nFrames)
            % Read in the video file to memory
            fprintf('reading video: %s [%d-%d]\n', fNameIn, frameStart, frameStart+nFrames-1);
            [vidData, ~, ~] = video_util.reader(fNameIn, frameStart, nFrames);
            
            % Write the video file back out
            fprintf('writing video: %s (%s)\n', fNameOut, encoding);
            video_util.writer(vidData, VideoWriter(fNameOut, encoding));
        end
        
        % Prep input data by creating compressed and uncompressed src data
        function prepInput(fNameOrig, fNameSrcU, fNameSrcC, frameStart, nFrames)
            assert( exist(fNameOrig, 'file') == 2 );
            
            if (exist(fNameSrcU, 'file') ~= 2)
                fprintf('Generating uncompressed version of %s\n', fNameOrig);
                video_util.extractFrames(fNameOrig, fNameSrcU, 'Uncompressed AVI', frameStart, nFrames);
            else
                fprintf('Uncompressed version of %s already exists, skipping\n', fNameOrig);
            end
            
            % Compress from the uncompressed source
            if (exist(fNameSrcC, 'file') ~= 2)
                fprintf('Generating compressed version of %s\n', fNameSrcU);
                video_util.extractFrames(fNameSrcU, fNameSrcC, 'MPEG-4', 1, nFrames);
            else
                fprintf('Compressed version of %s already exists, skipping\n', fNameSrcU);
            end
        end
        
        % Mangle frames listed in badFrames
        % Input and output will be MPEG4 compressed data streams
        function mangle(fNameSrcC, fNameDstC, ~, badPackets, packetsize)
            copyfile(fNameSrcC, fNameDstC, 'f');
            
            % Overwrite packets with zeros
            data = zeros(1, this.nBytesPerPacket);
            
            % Open the destination as a byte stream
            dstFile = fopen(fNameDstC, 'r+');
            
            for badPkt = badPackets
                % Override each bad packet with 0's
                offset = (badPkt-1)*packetsize;
                fseek(dstFile, offset, 'bof');
                fwrite(dstFile, data, 'uint8');
            end
            
            fclose(dstFile);
        end
        
        function [peaksnr, snr] = psnr_pics(srcPrefix, dstPrefix, nFrames)
            peaksnr = zeros(1, nFrames);
            snr = zeros(1, nFrames);
            for i=1:nFrames
                src = imread( sprintf('%s_%08d.png', srcPrefix, i) );
                dst = imread( sprintf('%s_%08d.png', dstPrefix, i) );
                [peaksnr(i), snr(i)] = psnr(dst, src);
            end
        end
        
        function [peaksnr, snr] = psnr_vids(vidDataSrc, vidDataDst, nFrames)
            peaksnr = zeros(1, nFrames);
            snr = zeros(1, nFrames);
            for i=1:nFrames
                src = vidDataSrc(i).cdata;
                dst = vidDataDst(i).cdata;
                [peaksnr(i), snr(i)] = psnr(dst, src, 255);
            end
        end
        
        function vid_to_pics(srcFile, outputPrefix)
            exe = sprintf('%s -i %s -r 30 %s_%%08d.png', video_util.ffmpeg_exe(), srcFile, outputPrefix);
            fprintf(' Running command: %s\n', exe);
            system(exe);
        end
        
        % Test the difference between two video files
        function [peaksnr, snr] = test_diff(fNameSrc, fNameDst, nFrames)
            fprintf('Calculating PSNR of %s...\n', fNameDst);
            
            % Dump temp files into a folder so we can delete it after
            baseDir = fullfile(tempdir(), 'snr');
            srcPrefix = fullfile(baseDir, 'src');
            dstPrefix = fullfile(baseDir, 'dst');
            mkdir(baseDir);
            
            %[vidDataSrc, vidHeightSrc, vidWidthSrc] = video_util.reader(fNameSrc, 1, nFrames);
            %[vidDataDst, vidHeightDst, vidWidthDst] = video_util.reader(fNameDst, 1, nFrames);
            %[peaksnr, snr] = video_util.psnr(vidDataSrc, vidDataDst, nFrames);
            
            % Convert video files to frames of PNG for comparision
            % We don't use built in matlab video reader because it crashes
            % when it encounters bad frames
            video_util.vid_to_pics(fNameSrc, srcPrefix);
            video_util.vid_to_pics(fNameDst, dstPrefix);
            
            [peaksnr, snr] = video_util.psnr_pics(srcPrefix, dstPrefix, nFrames);
            
            % clean up our temp files
            rmdir(baseDir, 's');
        end
        
        function [vidData, height, width] = reader(fName, frameStart, nFramesOut)
            vidObj = VideoReader(fName);
            
            frames = vidObj.NumberOfFrames;
            assert(frameStart >= 1);
            assert((frameStart + nFramesOut - 1) <= frames);
            
            width = vidObj.Width;
            height = vidObj.Height;
            
            % array for raw rgb data (colormap ignored)
            vidData(1:nFramesOut) = struct('cdata', zeros(height, width, 3, 'uint8'), 'colormap', []);
            for i = 1:nFramesOut
                % dump frame data into our local struct
                vidData(i).cdata = vidObj.read(frameStart + i - 1);
            end
        end
        
        function writer(vidData, vidObj)
            frames = size(vidData, 2);
            open(vidObj);
            
            % Dump frame data into video
            for k = 1:frames
                vidObj.writeVideo(vidData(k).cdata);
            end
            
            close(vidObj);
        end
    end
    
    methods
        function obj = video_util()
            obj = obj@handle();
        end
        
        function setup(this)
            this.frameStart = this.DEFAULT_START_FRAME;
            this.nFrames = this.DEFAULT_NFRAMES;
            this.nBytesPerPacket = this.DEFAULT_PACKETSIZE;
        end
        
        function prep(this)
            [this.fNameOrig, this.fNameSrcU, this.fNameSrcC, this.fNameDstC] = video_util.subFilenames(this.DEFAULT_INPUT_FOLDER, this.DEFAULT_OUTPUT_FOLDER, this.DEFAULT_FILE, this.frameStart, this.nFrames);
            video_util.prepInput(this.fNameOrig, this.fNameSrcU, this.fNameSrcC, this.frameStart, this.nFrames);
            
            fileInfoSrcC = dir(this.fNameSrcC);
            this.nBytesSrcC = fileInfoSrcC.bytes;
            this.nPacketsSrcC = ceil( this.nBytesSrcC / this.nBytesPerPacket );
            
            vidObj = VideoReader(this.fNameSrcC);
            this.fpsSrcC = vidObj.FrameRate;
            this.durationSrcC = vidObj.Duration;
            this.bpsSrcC = (this.nBytesSrcC * 8) / this.durationSrcC;
        end
        
        function filename = getFile(this, type)
            switch(type)
                case 'sU'
                    filename = this.fNameSrcU;
                case 'sC'
                    filename = this.fNameSrcC;
                case 'dU'
                    filename = this.fNameDstU;
                case 'dC'
                    filename = this.fNameDstC;
            end
        end
        
        function [psnr, snr] = testMangle(this, badPackets, srcType, dstType)
            video_util.mangle(this.fNameSrc, this.fNameDstC, this.nFrames, badPackets, this.nBytesPerPacket);
            [psnr, snr] = video_util.test_diff( this.getFile(srcType), this.getFile(dstType), this.nFrames);
        end
        
        function test(this)
            this.setup();
            this.prep();
            
            badPackets = 100:100;
            [psnrCtoMC1, snrCtoMC1] = this.testMangle(badPackets, 'sC', 'dC');
            
            badPackets = 101:101;
            [psnrCtoMC2, snrCtoMC2] = this.testMangle(badPackets, 'sC', 'dC');
            
            badPackets = 102:102;
            [psnrCtoMC3, snrCtoMC3] = this.testMangle(badPackets, 'sC', 'dC');
            
            badPackets = 100:100;
            [psnrCtoMC4, snrCtoMC4] = this.testMangle(badPackets, 'sC', 'dC');
            
            figure
            fprintf('Plotting...');
            
            % Peak SNR Plot
            subplot(2,1,1);
            hold on;
            plot(psnrCtoMC1, 'r');
            plot(psnrCtoMC2, 'g');
            plot(psnrCtoMC3, 'b');
            plot(psnrCtoMC4, 'c');
            %plot(psnrUtoC, 'r');
            %plot(psnrUtoMC, 'b');
            %plot(psnrCtoMC, 'c');
            hold off;
            xlabel('Frame');
            ylabel('Peak SNR');
            %legend('from uncompressed to compressed', 'from uncompressed to mangled', 'from compressed to mangled');
            legend('1', '2', '3', '4');
            
            subplot(2,1,2);
            hold on;
            plot(snrCtoMC1, 'r');
            plot(snrCtoMC2, 'g');
            plot(snrCtoMC3, 'b');
            plot(snrCtoMC4, 'c');
            %plot(snrUtoC, 'r');
            %plot(snrUtoMC, 'b');
            %plot(snrCtoMC, 'c');
            hold off;
            xlabel('Frame');
            ylabel('SNR');
            %legend('from uncompressed to compressed', 'from uncompressed to mangled', 'from compressed to mangled');
            legend('1', '2', '3', '4');

            fprintf('\nDone!\n');
        end
    end
end
