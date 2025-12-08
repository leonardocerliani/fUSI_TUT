function copyBuffersFun()
    fprintf('Copying Buffers\n')
    Control = evalin('base', 'Control');
    Control(1).Command = 'copyBuffers';
    assignin('base', 'Control', Control);
    % runAcq(Control);
end
