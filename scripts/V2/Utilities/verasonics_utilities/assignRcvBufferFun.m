function assignRcvBufferFun(RcvData)
    % input: RcvData
    fprintf('Assignin Rcv Buffer\n')
    assignin('base', 'RcvDataB', RcvData);
end
