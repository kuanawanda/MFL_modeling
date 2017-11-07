function [edge, edge_std] = sampPosterior(posterior, numSamps)
    % convert posterior to sampling
    randArray = rand(numSamps,1);
    cumPost = cumsum(reshape(posterior,[],1));
    for i = 1:length(randArray)
        postIdx(i) = find(cumPost>randArray(i),1,'first');
        [edge(i), edge_std(i)] = ind2sub(size(posterior),postIdx(i));
    end
    
