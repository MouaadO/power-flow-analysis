function count = countMatches(A, B)
    % Convert matrices to unique sets
    uniqueA = unique(A);
    uniqueB = unique(B);
    
    % Find common elements
    commonElements = intersect(uniqueA, uniqueB);
    
    % Count the number of common elements
    count = length(commonElements);
end

