function sigw=solve_sigw(zeta_spb,Fom,sprd)
for i=1:size(zeta_spb,1)
    sigw(i) = fzero(@(sigma) zeta_spb(i)-zeta_sp(sigma,Fom(i),sprd(i),1),0.5,optimset('Display','off')); %#ok<AGROW>
end