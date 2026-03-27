function memMB = estimateMemoryBuffer(vsxBuffer)
    memMB = class2byte(vsxBuffer.datatype) * vsxBuffer.rowsPerFrame * vsxBuffer.colsPerFrame * vsxBuffer.numFrames / 2^20;
end
