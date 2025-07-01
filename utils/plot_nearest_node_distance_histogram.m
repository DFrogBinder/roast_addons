function plot_nearest_node_distance_histogram(nodes1, nodes2, title_text, varargin)
%PLOT_NEAREST_NODE_DISTANCE_HISTOGRAM
%   For each node in nodes1 (Nx3), finds the closest node in nodes2 (M×3)
%   and plots a histogram of those distances.
%
%   Usage:
%     plot_nearest_node_distance_histogram(nodes1, nodes2, 'My Title')
%     plot_nearest_node_distance_histogram(nodes1, nodes2, 'Title', ...
%           'NumBins', 100);
%
%   Inputs:
%     nodes1    - N×3 array of coordinates from mesh1
%     nodes2    - M×3 array of coordinates from mesh2
%     title_text- string for the histogram title
%   Optional name/value pairs:
%     'NumBins' - number of bins (default 50)

    % Parse optional arguments
    p = inputParser;
    addParameter(p, 'NumBins', 50);
    parse(p, varargin{:});
    numBins = p.Results.NumBins;

    % Remove any NaN rows in either set
    nodes1 = nodes1(~any(isnan(nodes1),2), :);
    nodes2 = nodes2(~any(isnan(nodes2),2), :);

    % Use knnsearch (works even for large N via KD-tree)
    % stats toolbox required; if unavailable, use pdist2 and min().
    try
        % knnsearch returns indices and distances
        [~, dists] = knnsearch(nodes2, nodes1, 'K', 1);
        fprintf('Nodes >1 mm: %d (%.1f%%)\n', sum(dists>1), 100*sum(dists>1)/numel(dists));
    catch
        % Fallback: full pairwise then minimum
        D = pdist2(nodes1, nodes2);
        dists = min(D, [], 2);
    end
    
    % Print some stats
    fprintf('Nodes at zero: %d\n', sum(dists == 0));
    fprintf('Mean: %g, Median: %g, Max: %g\n', mean(dists), median(dists), max(dists));

    % Plot histogram
    figure;
    histogram(dists, numBins, ...
              'EdgeColor','none', ...
              'FaceColor',[0.2 0.4 0.6]);
    xlabel('Distance to nearest node in mesh2');
    ylabel('Number of nodes');
    title(title_text);
    grid on;


end
