%% load_mesh_coarse.m
% [V, F] = load_mesh_coarse(mesh_mat_file)
%   Loads a ROAST “mesh_coarse.mat” and returns:
%     V: #vertices×3 array of node coordinates
%     F: #faces×3 array of vertex‐indices per triangle
function [V, F] = load_mesh_coarse(mesh_mat_file)
  S = gmshread(mesh_mat_file);
  if isfield(S,'nodes') && isfield(S,'faces')
    V = S.nodes;
    F = S.faces;
  else
    error('mesh_coarse.mat must contain fields nodes and faces.');
  end
end
