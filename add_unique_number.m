function vec = add_unique_number(vec, target)
    if ~ismember(target, vec)
        vec = [vec, target];
    end
end