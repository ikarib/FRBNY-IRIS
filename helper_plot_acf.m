function helper_plot_acf(xnv,xv,xm)

xm = xm(:);
xv = xv(:);
xnv = xnv(:);

[a,b] = hist(xnv,15);
bar(b,a,'barWidth',1,'faceColor',0.9*[1,1,1]);
hold('all');
height = max(a)*1.10;
stem(xv,height,'color','blue','lineWidth',2);
stem(xm,height,'color','red','lineWidth',2);
grid('on');

end