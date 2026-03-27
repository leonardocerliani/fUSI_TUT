function saveBinaryDataMex(varargin)

    if nargin > 1
        for k = 1:nargin
            saveBinaryDataMex(varargin{k});
        end
        return;
    else
        CMD = varargin{1};
    end

    switch CMD
        case 'compile'
            compileStr = 'mex COMPFLAGS="$COMPFLAGS /openmp /DSAFE_MODE=1 /MTd" -R2018a -Iinclude src/*.cpp -output writeBinFileMex';
            runCompileCommand(compileStr);
        case 'compile2'
            compileStr = 'mex COMPFLAGS="$COMPFLAGS /openmp /DSAFE_MODE=1" -R2018a -Iinclude src/*.cpp -output writeBinFileMex';
            runCompileCommand(compileStr);

        case 'test'
            fprintf('Testing "writeBinFileMex": \n')
            fname = 'testBinFile22.bin';
            fprintf('Generating data\n')
            M = 1000; N = M;
            D = generateData(5e7);
            whossort
            fprintf('Writing data to "%s"... ', fname)
            writeBinFileMex(fname, D);
            pause(2)
            fprintf('Write test Passed!\nReading data from "%s"... ', fname)
            Dread = readBinFile(fname, size(D), '*int16');
            assert(nnz(D - Dread) == 0, 'Test failed! Data written and read not equal.')
            fprintf('Read test Passed!\n')

        case 'testsimple'
            fprintf('Testing "writeBinFileMex": \n')
            fname = 'testBinFile44.bin';
            fprintf('Generating data\n')
            D = int16(magic(5));
            D = repmat(D, 2, 1);
            writeBinFileMex(fname, D, 1);
            pause(1);
            Dsmall = D(:, 2:5 - 1)
            Dread = readBinFile(fname, size(Dsmall), '*int16')

        case 'time'
            % Mimicking this scenario:
            % BLOCK INFO
            %   Total number of blocks   :   40
            %   Rec time per block       :   0.50 s
            %   Time per block           :   0.50 s
            %   Frames/block             :   500
            %   Total Acquisition time   :   20.00 s
            %   Num channels saving      :   128
            %   Block Size               :   1312.5 MB
            %   Write speed required     :   2625.0 MB/s
            %   Total Disk space req.    :   52.5 GB
            D = zeros(1312, 512 * 1024, 'int16');
            D = reshape(D, [], 128);
            sizeD = size(D);
            whossort

            % create buffers to simulate buffers
            Dbuf = {D; D; D; D};
            nbuf = numel(Dbuf);
            for k = 1:nbuf
                Dbuf{k}([1 end]) = k;
            end

            % fname = @(k) sprintf('z_test%02i.bin', k);
            delete('E:\\RICK_DATA_TEST\\*.bin')
            fname = @(k) sprintf('E:\\RICK_DATA_TEST\\z_test%02i.bin', k);
            niter = 5;

            A = D;
            dinfo = whos('D');
            sizeBlockMB = dinfo.bytes / 2^20;
            intendedTime = 0.5;
            bnum = @(k) mod(k - 1, nbuf) + 1;

            t1 = tic;
            for k = 1:niter
                fprintf('Writing iteration %02i\n', k);
                %A([1 end]) = k;
                tic
                writeBinFileMex(fname(k), Dbuf{bnum(k)});
                twrite(k) = toc;
                Dbuf{bnum(k + 1)}(2) = k;
                fprintf('INFO writing mex took %.5f s\n', twrite(k));
                wtime = intendedTime - twrite(k);
                if wtime > 0
                    fprintf('Write start took %.5f s. -- Pausing %.5f s\n', twrite(k), wtime)
                    pause(wtime);
                end
            end
            T = toc(t1);
            fprintf('written %.2f MB in %.3f s\n', niter * sizeBlockMB, T);
            fprintf('avg write speed: %.2f MB/s\n', niter * sizeBlockMB / T);

            clear A D Dbuf
            save time_data.mat

            figure(99); clf;
            plot(twrite)
            yline(intendedTime)

        case 'clean'
            curDir = cd;
            cd(fileparts(mfilename('fullpath'))); % whole path without extension
            fprintf('Cleaning: \n')
            delete('*.bin');
            delete('*.mexw64');
            fprintf('Done \n')

        otherwise
            fprintf('Unknown command, to compile do \n\t>>saveBinaryDataMex compile\nTo test do\n\t>>saveBinaryDataMex test');
    end
end

function data = generateData(n)
    fprintf('Generating data of size %i MB\n', (n / 2) / 2^20)
    data = randi(1000, n, 1, 'int16');
end

function runCompileCommand(compileStr)
    curDir = cd;
    cd(fileparts(mfilename('fullpath'))); % whole path without extension
    fprintf('Compiling: \n')
    try
        disp(compileStr)
        eval(compileStr);
    catch ME
        cd(curDir);
        rethrow(ME);
    end
end
