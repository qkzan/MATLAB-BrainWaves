%% plot power by animal and placement with group mean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T4 = [T T1];
variable = 'PSDdB';
PSDbyAnimal = varfun(@mean,T4,'InputVariables',variable,'GroupingVariables',{'Group','Animal','Placement'});
ncol=width(PSDbyAnimal);
PSDbyGroup = varfun(@mean,PSDbyAnimal,'InputVariables',ncol,'GroupingVariables',{'Group','Placement'});
PSDstd = varfun(@std,PSDbyAnimal,'InputVariables',ncol','GroupingVariables',{'Group'});

close all
Place={'CtxE','CtxD'};
figure('Position',[0 0 800 500],'PaperOrientation','rotated')
figure('Position',[0 0 800 500],'PaperOrientation','rotated')
for i = 1:height(PSDbyAnimal)
    if strcmp(PSDbyAnimal.Placement(i),Place{1})
        figure(1);fig=1;
    else
        figure(2);fig=2;
    end
    switch PSDbyAnimal.Group(i)
        case 1
            ax(fig,1)=subplot(2,2,1); box off; hold on
        case 2
            ax(fig,2)=subplot(2,2,2); box off; hold on
        case 3
            ax(fig,3)=subplot(2,2,3); box off; hold on
        case 4
            ax(fig,4)=subplot(2,2,4); box off; hold on
    end
    plot(func(1).freq,PSDbyAnimal.mean_PSDdB(i,:))
end
for f = 1:size(F,1)
    for fig=1:2
        figure(fig)
        name = [F{f,2} ' ' Place{fig}];
        suptitle(name)
        cases{3} = strcmp(PSDbyAnimal.Placement,Place{fig});
        for i = 1:4
            cases{1} = PSDbyAnimal.Group==i & strcmp(PSDbyAnimal.Placement,Place{fig});
            cases{2} = PSDbyGroup.Group==i & strcmp(PSDbyGroup.Placement,Place{fig});
            plot(ax(fig,i),func(1).freq,PSDbyGroup.mean_mean_PSDdB(cases{2},:),'k')
            legend(ax(fig,i),PSDbyAnimal.Animal(cases{1})'); legend(ax(fig,i),'boxoff');
            xlabel(ax(fig,i),'Frequency (Hz)')
            ylabel(ax(fig,i),'Power (dB)')
            xlim(ax(fig,i),[F{f}(1:2)])
            ylim(ax(fig,i),[min(min(PSDbyAnimal.mean_PSDdB(:,func(1).idx{f}))) max(max(PSDbyAnimal.mean_PSDdB(:,func(1).idx{f})))])
        end
%         pause(1)
        saveas(figure(fig),[folder '\' name 'Power.pdf'])
    end
end

%% plot power by group
T2 = [T T1];
PSDbyAnimal = varfun(@mean,T2,'InputVariables',variable,'GroupingVariables',{'Group','Animal'});
ncol=width(PSDbyAnimal);
PSDbyGroup = varfun(@mean,PSDbyAnimal,'InputVariables',ncol,'GroupingVariables',{'Group'});
PSDstd = varfun(@std,PSDbyAnimal,'InputVariables',ncol','GroupingVariables',{'Group'});

close all
figure('Position',[20 20 620 920],'PaperOrientation','rotated');
for f = 1:size(F,1)
        a=subplot(3,2,f);
        idx = func(1).idx{f};
        x = func(1).freq';
        hold on
        for i = 1:height(PSDbyGroup)
            y = PSDbyGroup.mean_mean_PSDdB(i,:);
            sd = PSDstd.std_mean_PSDdB(i,:);
            patch('XData',[x fliplr(x)],'YData',[y-sd fliplr(y+sd)],'FaceColor',co(i,:),'FaceAlpha',0.2,'LineStyle','none')
        end
        plot(x,PSDbyGroup.mean_mean_PSDdB);
        hold off
        box off
        xlabel('Frequency (Hz)')
        ylabel({F{f,2} ;['Power (dB)']})
        xlim(F{f}(1:2))
           
        if f==4 || f==6
            a.XTick = (F{f}(1):(F{f}(2)-F{f}(1))/4:F{f}(2));
        end
        Y2 = max(max(PSDbyGroup.mean_mean_PSDdB(:,idx)+PSDstd.std_mean_PSDdB(:,idx)));
        Y1 = min(min(PSDbyGroup.mean_mean_PSDdB(:,idx)-PSDstd.std_mean_PSDdB(:,idx)))-1;
        a.YLim = [Y1 Y2];
        range = Y2-Y1;
        x=3;
        step = round(range/x,2);
        limit = Y1 + x*step+1;
        a.YLim = [Y1 limit];
        a.YTick = (Y1:step:limit);
        ytickformat('%.1f')
%         pause(1)
end
saveas(figure(1),[folder 'Power.pdf'])


%% um plot por animal com seus trechos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all;
fig=1;
ax(fig)=figure;
for i =149:height(T1)
    x = T2.PSD(i,:);
    if strcmp(T2.Animal(i),T2.Animal(i-1))
        hold on
        powerplot(func(1).freq,x,[0 100],[0 0.0001])
        legend = T2.Epoch(i);
    else
        ax(fig).Name = join([T2.Animal(i-1) T2.Placement(i-1)],' ');
        title = ax(fig).Name;
        hold off
        fig = fig+1;
        ax(fig)=figure;
        powerplot(func(1).freq,x,[0 100],[0 0.0001])
    end
end
ax(fig).Name = join([T2.Animal(i-1) T2.Placement(i-1)],' ');
title = ax(fig).Name;