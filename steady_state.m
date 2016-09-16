function m=steady_state(m,bgg)
% this file has been copied from DSGE-2015-Apr\initialization\getpara00_990.m

% get parameters from the model
var={'gam','alp','ups','bet','sigmac','del','Bigphi','gstar','nu_l','h','muwstar','sprd'};
if bgg; var=[var,'Fom','zeta_spb','gammstar','pistar']; end
for v=var
    eval([v{1} '=m.' v{1} ';'])
end

zstar = log(gam+1)+(alp/(1-alp))*log(ups); 

rstar = (1/bet)*exp(sigmac*zstar);

% Rstarn = 100*(rstar*pistar-1);

rkstar = sprd*rstar*ups - (1-del);%NOTE: includes "sprd*"

wstar = (alp^(alp)*(1-alp)^(1-alp)*rkstar^(-alp)/Bigphi)^(1/(1-alp));

% Lstar = 1;
Lstar = (wstar/muwstar/((1-gstar)*(alp/(1-alp)*wstar/rkstar)^alp/Bigphi-...
    (1-(1-del)/ups*exp(-zstar))*ups*exp(zstar)*alp/(1-alp)*wstar/rkstar)/(1-h*exp(-zstar)))^(1/(1+nu_l));

kstar = (alp/(1-alp))*wstar*Lstar/rkstar;

kbarstar = kstar*(gam+1)*ups^(1/(1-alp));

istar = kbarstar*( 1-((1-del)/((gam+1)*ups^(1/(1-alp)))) );

ystar = (kstar^alp)*(Lstar^(1-alp))/Bigphi;
if ystar <= 0

    disp([alp,  bet, kstar,Lstar])
    dm([ystar,Lstar,kstar,Bigphi])

end
cstar = (1-gstar)*ystar - istar;

% wl_c = (wstar*Lstar/cstar)/muwstar;

% assign steady states to model parameters
if ~bgg
    ss={'rkstar','cstar','istar','kstar','kbarstar','Lstar','ystar'};
    m=assign(m,ss,eval(['[' strjoin(ss) ']']));
    return;
end

%FINANCIAL FRICTIONS ADDITIONS
% solve for sigmaomegastar and zomegastar
zwstar = norminv(Fom);
sigwstar = fzero(@(sigma)zetaspbfcn(zwstar,sigma,sprd)-zeta_spb,0.5);
% zetaspbfcn(zwstar,sigwstar,sprd)-zeta_spb % check solution

% evaluate omegabarstar
omegabarstar = omegafcn(zwstar,sigwstar);

% evaluate all BGG function elasticities
Gstar = Gfcn(zwstar,sigwstar);
Gammastar = Gammafcn(zwstar,sigwstar);
dGdomegastar = dGdomegafcn(zwstar,sigwstar);
d2Gdomega2star = d2Gdomega2fcn(zwstar,sigwstar);
dGammadomegastar = dGammadomegafcn(zwstar);
d2Gammadomega2star = d2Gammadomega2fcn(zwstar,sigwstar);
dGdsigmastar = dGdsigmafcn(zwstar,sigwstar);
d2Gdomegadsigmastar = d2Gdomegadsigmafcn(zwstar,sigwstar);
dGammadsigmastar = dGammadsigmafcn(zwstar,sigwstar);
d2Gammadomegadsigmastar = d2Gammadomegadsigmafcn(zwstar,sigwstar);

% evaluate mu, nk, and Rhostar
muestar = mufcn(zwstar,sigwstar,sprd);
nkstar = nkfcn(zwstar,sigwstar,sprd);
Rhostar = 1/nkstar-1;

% evaluate wekstar and vkstar
betbar=bet*exp((1-sigmac)*zstar);
wekstar = (1-gammstar/betbar)*nkstar...
    -gammstar/betbar*(sprd*(1-muestar*Gstar)-1);
vkstar = (nkstar-wekstar)/gammstar;

% evaluate nstar and vstar
nstar = nkstar*kbarstar; % why kstar???
vstar = vkstar*kbarstar; % why kstar???

% a couple of combinations
GammamuG = Gammastar-muestar*Gstar;
GammamuGprime = dGammadomegastar-muestar*dGdomegastar;

% elasticities wrt omegabar
zeta_bw = zetabomegafcn(zwstar,sigwstar,sprd);
zeta_zw = zetazomegafcn(zwstar,sigwstar,sprd);
zeta_bw_zw = zeta_bw/zeta_zw;

% elasticities wrt sigw
zeta_bsigw = sigwstar*(((1-muestar*dGdsigmastar/dGammadsigmastar)/...
    (1-muestar*dGdomegastar/dGammadomegastar)-1)*dGammadsigmastar*sprd+...
    muestar*nkstar*(dGdomegastar*d2Gammadomegadsigmastar-dGammadomegastar*d2Gdomegadsigmastar)/...
    GammamuGprime^2)/...
    ((1-Gammastar)*sprd+dGammadomegastar/GammamuGprime*(1-nkstar));
zeta_zsigw = sigwstar*(dGammadsigmastar-muestar*dGdsigmastar)/GammamuG;
zeta_spsigw = (zeta_bw_zw*zeta_zsigw-zeta_bsigw)/(1-zeta_bw_zw);

% elasticities wrt mue
zeta_bmue = -muestar*(nkstar*dGammadomegastar*dGdomegastar/GammamuGprime+dGammadomegastar*Gstar*sprd)/...
    ((1-Gammastar)*GammamuGprime*sprd+dGammadomegastar*(1-nkstar));
zeta_zmue = -muestar*Gstar/GammamuG;
zeta_spmue = (zeta_bw_zw*zeta_zmue-zeta_bmue)/(1-zeta_bw_zw);

% some ratios/elasticities
Rkstar = sprd*pistar*rstar; % (rkstar+1-delta)/ups*pistar;
zeta_Gw = dGdomegastar/Gstar*omegabarstar;
zeta_Gsigw = dGdsigmastar/Gstar*sigwstar;

% elasticities for the net worth evolution
zeta_nRk = gammstar*Rkstar/pistar/exp(zstar)*(1+Rhostar)*(1-muestar*Gstar*(1-zeta_Gw/zeta_zw));
zeta_nR = gammstar/betbar*(1+Rhostar)*(1-nkstar+muestar*Gstar*sprd*zeta_Gw/zeta_zw);
zeta_nqk = gammstar*Rkstar/pistar/exp(zstar)*(1+Rhostar)*(1-muestar*Gstar*(1+zeta_Gw/zeta_zw/Rhostar))...
    -gammstar/betbar*(1+Rhostar);
zeta_nn = gammstar/betbar+gammstar*Rkstar/pistar/exp(zstar)*(1+Rhostar)*muestar*Gstar*zeta_Gw/zeta_zw/Rhostar;
zeta_nmue = gammstar*Rkstar/pistar/exp(zstar)*(1+Rhostar)*muestar*Gstar*(1-zeta_Gw*zeta_zmue/zeta_zw);
zeta_nsigw = gammstar*Rkstar/pistar/exp(zstar)*(1+Rhostar)*muestar*Gstar*(zeta_Gsigw-zeta_Gw/zeta_zw*zeta_zsigw);

% assign steady states to model parameters
ss={'rkstar','cstar','istar','kstar','kbarstar','Lstar','ystar','vstar','nstar','zeta_spsigw','zeta_spmue','Rhostar','vkstar','nkstar','zeta_zmue','zeta_zsigw','zeta_zw','Gstar','muestar','zeta_Gsigw','zeta_Gw','zeta_nRk','zeta_nR','zeta_nsigw','zeta_nmue','zeta_nqk','zeta_nn'};
m=assign(m,ss,eval(['[' strjoin(ss) ']']));
end

function f=zetaspbfcn(z,sigma,sprd)
zetaratio = zetabomegafcn(z,sigma,sprd)/zetazomegafcn(z,sigma,sprd);
nk = nkfcn(z,sigma,sprd);
f = -zetaratio/(1-zetaratio)*nk/(1-nk);
end

function f=zetabomegafcn(z,sigma,sprd)
nk = nkfcn(z,sigma,sprd);
mustar = mufcn(z,sigma,sprd);
omegastar = omegafcn(z,sigma);
Gammastar = Gammafcn(z,sigma);
Gstar = Gfcn(z,sigma);
dGammadomegastar = dGammadomegafcn(z);
dGdomegastar = dGdomegafcn(z,sigma);
d2Gammadomega2star = d2Gammadomega2fcn(z,sigma);
d2Gdomega2star = d2Gdomega2fcn(z,sigma);
f = omegastar*mustar*nk*(d2Gammadomega2star*dGdomegastar-d2Gdomega2star*dGammadomegastar)/...
    (dGammadomegastar-mustar*dGdomegastar)^2/sprd/...
    (1-Gammastar+dGammadomegastar*(Gammastar-mustar*Gstar)/(dGammadomegastar-mustar*dGdomegastar));
end

function f=zetazomegafcn(z,sigma,sprd)
mustar = mufcn(z,sigma,sprd);
f = omegafcn(z,sigma)*(dGammadomegafcn(z)-mustar*dGdomegafcn(z,sigma))/...
    (Gammafcn(z,sigma)-mustar*Gfcn(z,sigma));
end

function f=nkfcn(z,sigma,sprd)
f = 1-(Gammafcn(z,sigma)-mufcn(z,sigma,sprd)*Gfcn(z,sigma))*sprd;
end

function f=mufcn(z,sigma,sprd)
f = (1-1/sprd)/(dGdomegafcn(z,sigma)/dGammadomegafcn(z)*(1-Gammafcn(z,sigma))+Gfcn(z,sigma));
end

function f=omegafcn(z,sigma)
f = exp(sigma*z-1/2*sigma^2);
end

function f=Gfcn(z,sigma)
f = normcdf(z-sigma);
end

function f=Gammafcn(z,sigma)
f = omegafcn(z,sigma)*(1-normcdf(z))+normcdf(z-sigma);
end

function f=dGdomegafcn(z,sigma)
f=normpdf(z)/sigma;
end

function f=d2Gdomega2fcn(z,sigma)
f = -z*normpdf(z)/omegafcn(z,sigma)/sigma^2;
end

function f=dGammadomegafcn(z)
f = 1-normcdf(z);
end

function f=d2Gammadomega2fcn(z,sigma)
f = -normpdf(z)/omegafcn(z,sigma)/sigma;
end

function f=dGdsigmafcn(z,sigma)
f = -z*normpdf(z-sigma)/sigma;
end

function f=d2Gdomegadsigmafcn(z,sigma)
f = -normpdf(z)*(1-z*(z-sigma))/sigma^2;
end

function f=dGammadsigmafcn(z,sigma)
f = -normpdf(z-sigma);
end

function f=d2Gammadomegadsigmafcn(z,sigma)
f = (z/sigma-1)*normpdf(z);
end
