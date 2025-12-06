function data_all = dataLoader(Pm, BFConfig, type_str)
    data_all = dataLoaderAppend(Pm, BFConfig, type_str);
end

function data_all = dataLoaderSeparate(Pm, BFConfig, type_str)
    % PDI = dataLoader(Pm, BFConfig, 'PDI');
    % IQ = dataLoader(Pm, BFConfig, 'IQ');

    % f = sprintf('fUS_block_%s_%s_float.bin', type_str,'%03i');
    f = sprintf('fUS_block_%s_float.bin', type_str);
    fn = @(i) sprintf(f, i);
    switch type_str
        case 'PDI'
            s = [BFConfig.Nz, BFConfig.Nx];
            c = 0;
            data_all = zeros(BFConfig.Nz, BFConfig.Nx, Pm.numBlocks);
            for k = 1:Pm.numBlocks
                p = fullfile(Pm.data_path_save, fn(k));
                data = readBinFile(p, s, '*float', c, 0);
                data_all(:, :, k) = data;
            end
        case 'IQ'
            s = [BFConfig.Nz, BFConfig.Nx, BFConfig.NFrames];
            c = 1;
            data_all = zeros(BFConfig.Nz, BFConfig.Nx, BFConfig.NFrames, Pm.numBlocks);
            for k = 1:Pm.numBlocks
                p = fullfile(Pm.data_path_save, fn(k));
                data = readBinFile(p, s, '*float', c, 0);
                data_all(:, :, :, k) = data;
            end
    end

end

function data_all = dataLoaderAppend(Pm, BFConfig, type_str)
    % PDI = dataLoader(Pm, BFConfig, 'PDI');
    % IQ = dataLoader(Pm, BFConfig, 'IQ');

    % f = sprintf('fUS_block_%s_%s_float.bin', type_str,'%03i');
    f = sprintf('fUS_block_%s_float.bin', type_str);
    switch type_str
        case 'PDI'
            s = [BFConfig.Nz, BFConfig.Nx, Pm.numBlocks];
            c = 0;
            p = fullfile(Pm.data_path_save, f);
            [data_all, succes] = readBinFile(p, s, '*float', c, 0);

        case 'IQ'
            s = [BFConfig.Nz, BFConfig.Nx, BFConfig.NFrames, Pm.numBlocks];
            c = 1;
            p = fullfile(Pm.data_path_save, f);
            [data_all, succes] = readBinFile(p, s, '*float', c, 0);
    end

end
