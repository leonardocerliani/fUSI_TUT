function edgeIndices = detect_ttl_edges(ttlData, channel, edgeType)
    % DETECT_TTL_EDGES Detect edges in TTL channel
    %
    %   edgeIndices = detect_ttl_edges(ttlData, channel, edgeType)
    %
    %   Inputs:
    %       ttlData   - TTL timing matrix [time, channels...]
    %       channel   - Channel number to analyze
    %       edgeType  - 'rising', 'falling', or 'both'
    %
    %   Outputs:
    %       edgeIndices - Row indices where edges occur (not times!)
    
    % Get the specified channel
    signal = ttlData(:, channel);
    
    % Detect edges based on type
    switch edgeType
        case 'rising'
            % 0 → 1 transition
            edgeIndices = find(diff(signal) > 0);
            
        case 'falling'
            % 1 → 0 transition
            edgeIndices = find(diff(signal) < 0);
            
        case 'both'
            % Any transition
            edgeIndices = find(diff(signal) ~= 0);
            
        otherwise
            error('Unknown edge type: %s', edgeType);
    end
end
