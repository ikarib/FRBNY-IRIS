% BGG elasticities of the spread

function zeta_spx = zeta_sp(sigma,Fom,sprd,x)
    z = norminv(Fom);
    G = normcdf(z-sigma);
    omega = exp(sigma*(z-sigma/2));
    Gamma = omega*(1-Fom)+G;
    dGdomega = normpdf(z)/sigma;
    dGammadomega = 1-Fom;
    dg = dGdomega/dGammadomega;
    mu = (1-1/sprd)/(dg*(1-Gamma)+G);
    GammamuG = Gamma-mu*G;
    nk = 1-sprd*GammamuG;
    
    % elasticities wrt omegabar
    zetabomega = mu*nk*(z/sigma-dg)/(1/dg-mu);
    zetazomega = omega*dGdomega*(1/dg-mu)/GammamuG;
    zeta_bw_zw = zetabomega/zetazomega;
    
    switch x
        case 1
            % elasticity of the spread w.r.t. leverage
            zeta_spx = -zeta_bw_zw/(1-zeta_bw_zw)*nk/(1-nk);
        case 2
            dGammadsigma = -normpdf(z-sigma);
            dGdsigma = z*dGammadsigma/sigma;
            d2Gammadomegadsigma = dGdomega*(z-sigma);
            d2Gdomegadsigma = -dGdomega*(1-z*(z-sigma))/sigma;
            GammamuGprime = dGammadomega-mu*dGdomega;

            % elasticities wrt sigw
            zeta_bsigw = sigma*(((1-mu*dGdsigma/dGammadsigma)/...
                (1-mu*dGdomega/dGammadomega)-1)*dGammadsigma*sprd+...
                mu*nk*(dGdomega*d2Gammadomegadsigma-dGammadomega*d2Gdomegadsigma)/GammamuGprime^2)/...
                ((1-Gamma)*sprd+dGammadomega/GammamuGprime*(1-nk));
            zeta_zsigw = sigma*(dGammadsigma-mu*dGdsigma)/GammamuG;
            zeta_spx = (zeta_bw_zw*zeta_zsigw-zeta_bsigw)/(1-zeta_bw_zw);
        case 3
            GammamuGprime = dGammadomega-mu*dGdomega;
            % elasticities wrt mue
            zeta_bmue = -mu*(nk*dGammadomega*dGdomega/GammamuGprime+dGammadomega*G*sprd)/...
                ((1-Gamma)*GammamuGprime*sprd+dGammadomega*(1-nk));
            zeta_zmue = -mu*G/GammamuG;
            zeta_spx = (zeta_bw_zw*zeta_zmue-zeta_bmue)/(1-zeta_bw_zw);
    end
end
