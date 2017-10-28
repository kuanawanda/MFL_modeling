function posterior = update_posterior(prior, edges, edges_std, X)

% posterior = likelihood * prior
for i = 1:length(edges)
    for j = 1:length(edges_std)
        posterior(i,j) = normpdf(X,edges(i),edges_std(j)) * prior(i,j);
    end
end

posterior = posterior/sum(posterior(:));