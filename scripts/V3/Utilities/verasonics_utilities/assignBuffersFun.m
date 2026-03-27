function assignBuffersFun(varargin)
    % input: IQData ot IData and QData
    fprintf('Assignin IQ Buffer\n')
    if numel(varargin) > 1
        IQData = varargin{1} + 1i * varargin{2};
    else
        IQData = varargin{1};
    end
    assignin('base', 'IQDataB', IQData);
end
