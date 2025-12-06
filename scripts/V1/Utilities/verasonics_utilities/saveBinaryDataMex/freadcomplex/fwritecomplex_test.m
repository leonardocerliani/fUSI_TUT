% Test file for fwritecomplex( ) function.  Version 1.1
function fwritecomplex_test
disp(' ');
disp('-----------------------------------------------------------------');
disp('-----------------------------------------------------------------');
disp('fwritecomplex test function Version 1.1');
disp('-----------------------------------------------------------------');
disp('-----------------------------------------------------------------');
disp(' ');
% Compile if necessary and print version
fwritecomplex('version');
fprintf('fwritecomplex mex function Version %s\n',fwritecomplex('version'));
fail = 0;
fail = fail + test_class('double');
fail = fail + test_class('single');
fail = fail + test_class('int8');
fail = fail + test_class('uint8');
fail = fail + test_class('int16');
fail = fail + test_class('uint16');
fail = fail + test_class('int32');
fail = fail + test_class('uint32');
fail = fail + test_class('int64');
fail = fail + test_class('uint64');
disp(' ');
disp('-----------------------------------------------------------------');
disp('-----------------------------------------------------------------');
disp(' ');
if( fail )
    fprintf('Number of FAILED tests = %d\n',fail);
else
    disp('All tests PASSED!');
end
disp(' ');
end

function fail = test_class(classname)
disp(' ');
disp('-----------------------------------------------------------------');
disp(['Testing ' classname]);
disp('-----------------------------------------------------------------');
disp(' ');
fail = 0;

% create test file
fname = 'fwritecomplex_test.dat';
fid = fopen(fname,'wb');
xcomplex = cast(reshape(complex((1:2:16),(2:2:16)),2,4),classname);
disp('Original variable');
disp(xcomplex);
disp(' ');
fwritecomplex(fid,xcomplex,classname);
fclose(fid);

% read as column
fid = fopen(fname,'rb');
y = freadcomplex(fid,['*' classname]);
fclose(fid);
disp('Read as column:');
disp(y);
if( isequal(y,xcomplex(:)) )
    disp(['PASS ' classname ' column']);
else
    disp(['FAIL ' classname ' column ***']);
    fail = fail + 1;
end

% read as halve first dimension
dim = [1 8];
fid = fopen(fname,'rb');
y = freadcomplex(fid,dim,['*' classname]);
fclose(fid);
disp(' ')
disp('Read as halve first dimension:');
disp(y);
if( isequal(y,reshape(xcomplex,dim)) )
    disp(['PASS ' classname ' halve first dimension']);
else
    disp(['FAIL ' classname ' halve first dimension ***']);
    fail = fail + 1;
end

% read as halve second dimension
dim = [4 2];
fid = fopen(fname,'rb');
y = freadcomplex(fid,dim,['*' classname]);
fclose(fid);
disp(' ')
disp('Read as halve second dimension:');
disp(y);
if( isequal(y,reshape(xcomplex,dim)) )
    disp(['PASS ' classname ' halve second dimension']);
else
    disp(['FAIL ' classname ' halve second dimension ***']);
    fail = fail + 1;
end

% read as inf dimension
dim = inf;
fid = fopen(fname,'rb');
y = freadcomplex(fid,dim,['*' classname]);
fclose(fid);
disp(' ')
disp('Read as inf dimension:');
disp(y);
if( isequal(y,xcomplex(:)) )
    disp(['PASS ' classname ' inf dimension']);
else
    disp(['FAIL ' classname ' inf dimension ***']);
    fail = fail + 1;
end

% read as inf second dimension
dim = [2 inf];
fid = fopen(fname,'rb');
y = freadcomplex(fid,dim,['*' classname]);
fclose(fid);
disp(' ')
disp('Read as inf second dimension:');
disp(y);
if( isequal(y,reshape(xcomplex,2,[])) )
    disp(['PASS ' classname ' inf second dimension']);
else
    disp(['FAIL ' classname ' inf second dimension ***']);
    fail = fail + 1;
end

end
