function longest = longestArray(varargin)
%LONGESTARRAY   Return the array (of N inputs) with the most elements.
[~,i] = max(cellfun(@numel, varargin)); 
longest = varargin{i};
end
