function plot_node_distance_histogram(nodes, title_text,varargin)
%PLOT_NODE_DISTANCE_HISTOGRAM Plots histogram of distances between random node pairs in a mesh
%
%   Usage:
%     plot_node_distance_histogram(nodes)
%     plot_node_distance_histogram(nodes, 'NumBins', 100, 'MaxPairs', 1e6)
%
%   Inputs:
%     nodes    - Nx3 matrix of mesh node coordinates
%     NumBins  - (optional) histogram bins (default: 50)
%     MaxPairs - (optional) max node pairs to sample (default: 1e6)

    % Parse optional arguments
    p = inputParser;
    addParameter(p, 'NumBins', 50);
    addParameter(p, 'MaxPairs', 1e6);
    parse(p, varargin{:});
    numBins = p.Results.NumBins;
    maxPairs = p.Results.MaxPairs;

    % Filter out NaN rows
    nodes = nodes(~any(isnan(nodes), 2), :);
    N = size(nodes, 1);

    % Sample random node pairs
    maxPairs = min(maxPairs, N^2); % Safety cap
    idx1 = randi(N, maxPairs, 1);
    idx2 = randi(N, maxPairs, 1);

    % Avoid self-pairs
    mask = idx1 ~= idx2;
    idx1 = idx1(mask);
    idx2 = idx2(mask);

    % Compute distances
    diff = nodes(idx1, :) - nodes(idx2, :);
    distances = sqrt(sum(diff.^2, 2));

    % Plot histogram
    figure;
    histogram(distances, numBins, 'EdgeColor', 'none', 'FaceColor', [0.2 0.4 0.6]);
    xlabel('Distance between nodes');
    ylabel('Frequency');
    title(title_text);
    grid on;
end
