function [pStar,objStar,hess] = knitronlp(fnObj,x0,lb,ub,options,varargin)
[pStar,objStar,~,~,~,~,hess] = knitromatlab_mip(fnObj,x0,[],[],[],[],lb,ub,[],[],[],[],[],options,varargin{:});
