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
yline(intendedTime, 'k--')
% ylim([0 1.2*max(twrite)])

function data = generateData(n)
    fprintf('Generating data of size %i MB\n', (n / 2) / 2^20)
    data = randi(1000, n, 1, 'int16');
end
