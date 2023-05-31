function [x,z] = calcSenorsPos(targetTruthPos,measureTargets)
    x = 0;
    z = 0;
    numTargets = size(targetTruthPos,1)
    for idx = 1:numTargets
        x = x + (targetTruthPos(idx,1) - measureTargets(idx,1))
        z = z + (targetTruthPos(idx,2) - measureTargets(idx,2))
    end
    x = x/numTargets;
    z = z/numTargets;
end

