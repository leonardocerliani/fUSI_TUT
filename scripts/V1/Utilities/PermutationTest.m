function pValue = PermutationTest(data1, data2, numPermutations)
% PERMUTATIONTEST Performs a two-sided permutation test to compare the
% means of two independent samples, data1 and data2.
%
%   pValue = permutationTest(data1, data2, numPermutations)
%
% Inputs:
%   data1           - Vector of sample 1 observations (e.g., correlation coefficients)
%   data2           - Vector of sample 2 observations
%   numPermutations - Number of permutations to perform (e.g., 10,000)
%
% Outputs:
%   pValue          - The two-sided p-value of the test
%
% Example:
%   >> groupA = [0.21, 0.35, 0.42, 0.50, 0.29];
%   >> groupB = [0.10, 0.12, 0.05, 0.18, 0.09];
%   >> p = permutationTest(groupA, groupB, 10000);

    if nargin < 3
        numPermutations = 10000; % default number of permutations
    end

    % Combine all data and compute the observed difference in means
    allData = [data1(:); data2(:)];
    n1 = numel(data1);
    n2 = numel(data2);

    obsDiff = mean(data1) - mean(data2);

    % Preallocate an array to hold permutation-based differences
    permDiffs = zeros(numPermutations, 1);

    for i = 1:numPermutations
        % Randomly permute the combined data
        permIndices = randperm(numel(allData));
        shuffled = allData(permIndices);

        % Split shuffled data into two new groups
        permGroup1 = shuffled(1:n1);
        permGroup2 = shuffled(n1+1 : n1+n2);

        % Compute difference in means for this permutation
        permDiffs(i) = mean(permGroup1) - mean(permGroup2);
    end

    % Compute two-sided p-value:
    % The proportion of permuted differences whose absolute value
    % is greater than or equal to the observed difference
    pValue = mean(abs(permDiffs) >= abs(obsDiff));
end
