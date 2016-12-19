function helper_plot_xsf(freq,xv,xm)

xv = xv(:);
xm = xm(:);

plot(freq,real(xv),'color','blue','linewidth',1.5);
hold('all');
plot(freq,real(xm),'color','red','linewidth',1.5);
set(gca(),'xlim',[0,pi],'xLimMode','manual');
grid('on');

end