function test_writeBinFileMex_partial()
    % a simple test for writeBinFileMex
    fprintf('Testing "writeBinFileMex": \n')
    fname_test = 'testBinFile_partial.bin';
    fname_validation = 'testBinFile_partial_validation.bin';

    fprintf('Generating data\n')
    D = generateData(1024 * 512 * 32);
    D = reshape(D, [], 128);

    ncols_to_skip = 10;
    Dsel = D(:, ncols_to_skip + 1:end - ncols_to_skip);
    fprintf('Writing data to   "%s"... \n', fname_test)
    writeBinFileMex(fname_test, D, ncols_to_skip);
    fprintf('Writing data to   "%s"... \n', fname_validation)
    writeBinFile(fname_validation, Dsel);
    fprintf('Write test Passed!\n');

    pause(1)
    fprintf('Reading data from "%s"... ', fname_test)
    Dread = readBinFile(fname_test, size(Dsel), '*int16');
    Dread_validation = readBinFile(fname_validation, size(Dsel), '*int16');

    assert(nnz(Dread_validation - Dread) == 0, 'Test failed! Data written and read not equal.')
    assert(nnz(Dsel - Dread) == 0, 'Test failed! Data written and read not equal.')
    fprintf('Read test Passed!\n')

end

function data = generateData(n)
    fprintf('Generating data of size %i MB\n', round(n * 2/2^20))
    data = randi(1000, n, 1, 'int16');
end
