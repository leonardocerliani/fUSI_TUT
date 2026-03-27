function remapped = remap_glm_results(glm_estimate, bmask)
% REMAP_GLM_RESULTS - Remap GLM results to spatial format
%
% Simple wrapper that remaps all numeric GLM outputs using remap_betas()
%
% Inputs:
%   glm_estimate - struct from glm() with fields in [* × V] format
%   bmask - [ny × nz] brain mask (logical or numeric)
%
% Outputs:
%   remapped - struct with all numeric fields remapped to [* × ny × nz]
%
% Example:
%   glm_estimate = glm('M1', Y, M1_predictors, M1_labels);
%   all_results.M1 = remap_glm_results(glm_estimate, data.bmask);
%
% See also: glm, remap_betas

%% List of fields that need spatial remapping
% Note: 'res' (residuals) commented out to save memory - uncomment if needed
fields_to_remap = {'betas', 'R2', 'eta2', 'Z', 'p'}; %, 'res'};

%% Remap each field using remap_betas
remapped = struct();
for i = 1:length(fields_to_remap)
    field = fields_to_remap{i};
    if isfield(glm_estimate, field)
        remapped.(field) = remap_betas(glm_estimate.(field), bmask);
    end
end

%% Copy non-numeric fields as-is
remapped.predictor_labels = glm_estimate.predictor_labels;
remapped.model_name = glm_estimate.model_name;

end
