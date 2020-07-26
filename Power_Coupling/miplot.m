load Tables.mat
close all

coup = 3;
coup_type=couptype{coup};
idx = find(upper(coup_type)==coup_type);
idx = idx(2);
variable = eval([coup_type '.Properties.VariableNames{3}']);
newfolder =[folder coup_type '\'];
mkdir(newfolder)

for count = unique(T.Epoch)'
    j=find(T.Epoch==count);
    
    if length(j)==2
        j = [j(2) j(1)];
    end
    
    figure('Position',[20 20 620 920],'PaperOrientation','rotated');
    
    for pos = [1 2]
        i=j(pos);
        
        if strcmp(T.Placement(i),'CtxD')
            pos = 2;
        end        
        
        bins = eval([coup_type '.(3).bins(i,:)']);
        prob = eval([coup_type '.(3).prob(i,:)']);
        step = eval([coup_type '.(3).step(i,:)']);
        mi_value=eval([coup_type '.(3).MI(i,:)']);
        misurr_value = 1;
        threshold = 1;
        %%
        subplot(2,2,pos)
        bar([bins bins+bins(end)+step],[prob flip(prob)],1,'k')
        xticks([min(bins) (2*max(bins))/2 2*max(bins)])
        xticklabels({'min','max','min'})
        xlabel([variable(1:find(variable=='_')-1) ' ' lower(coup_type(1:idx-1)) ' range'])
        ylabel({['Median ' lower(variable(find(variable=='_')+1:end)) ' ' lower(coup_type(idx:end))]; '(normalized)'})
        ylim([0 0.10])
        box off
        title(T.Placement(i))
        
        %%
        subplot(2,2,pos+2)
        bar([1 2],[mi_value misurr_value],1,'k')
        xticklabels({'MI','MI_{sur}'})
        % yline(threshold,'r--')
        % ylim([0 0.10])
        title([coup_type ' MI = ' sprintf('%0.5f',mi_value)])
        
        if length(j)==1
            break
        end        
    end
    suptitle(join([T.Animal(i) ' - epoch ' T.Epoch(i)]))
    saveas(figure(1),[newfolder lower(variable) num2str(T.Epoch(i)) '.pdf'])
    close
end
%%
% switch ct
%     case 'PhaPha'
%     case 'PhaAmp'
%     case 'PhaFreq'
%     case 'AmpAmp'
%     case 'AmpFreq'
%     case 'FreqFreq'
% end
% rowfun(@(x,y) bar(x,y,1,'k'),a);
