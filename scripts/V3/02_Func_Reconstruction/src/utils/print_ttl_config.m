function print_ttl_config(config)
    % PRINT_TTL_CONFIG Display TTL channel assignments
    %
    %   print_ttl_config(config)
    
    fprintf('  Experiment: %s (%s)\n', config.experiment_id, config.date);
    if isfield(config, 'description')
        fprintf('  %s\n', config.description);
    end
    fprintf('\n→ TTL Channel Configuration:\n');
    
    ttl = config.ttl_channels;
    
    fprintf('  ✓ PDI frames:        Channel %d\n', ttl.pdi_frame);
    fprintf('  ✓ Experiment start:  Channel %d', ttl.experiment_start);
    if isfield(ttl, 'experiment_start_fallback')
        fprintf(' (fallback: %d)', ttl.experiment_start_fallback);
    end
    fprintf('\n');
    
    if isfield(ttl, 'shock')
        if length(ttl.shock) > 1
            fprintf('  ✓ Shock stim:        Channels %s\n', ...
                strjoin(arrayfun(@num2str, ttl.shock, 'UniformOutput', false), ', '));
        else
            fprintf('  ✓ Shock stim:        Channel %d\n', ttl.shock);
        end
    end
    
    if isfield(ttl, 'visual')
        fprintf('  ✓ Visual stim:       Channel %d\n', ttl.visual);
    end
    
    if isfield(ttl, 'auditory')
        fprintf('  ✓ Auditory stim:     Channel %d\n', ttl.auditory);
    end
end
