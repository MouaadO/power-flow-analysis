function rank = findRank(vec, num)
    [~, sortedIdx] = sort(vec, 'ascend'); % Sort the vector in ascending order
    rank = find(vec(sortedIdx) == num);   % Find the index of the number in the sorted vector
end


