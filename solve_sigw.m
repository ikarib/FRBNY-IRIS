function sigw=solve_sigw(zeta_spb,Fom,sprd)
sigw = fzero(@(sigma) zeta_spb-zeta_sp(sigma,Fom,sprd,1),0.5,optimset('Display','off'));
dbstack