% plot TFD

for i=1:height(T1)
    x = T1.lfp(i,:);
    [~,freq,t,TFD{i}]=spectrogram(x,func(2).winlength,func(2).winoverlap,func(2).freq(func(2).freq<=150),srate);
end



B = T1;
C = table2struct([T1 table(TFD','VariableNames',{'TFD'})]);

animals = unique(T1.Animal)';
groups = unique(T1.Group)';

j=1;
for i = animals
  idx = find(strcmp(B.Animal,i));
  byAnimal(j).Animal = i;
  byAnimal(j).Group = B.Group(idx(1));
  byAnimal(j).TFD = mean(cat(3,C(idx).TFD),3); 
  j=j+1;
end

j=1;
for i = groups
  byGroup(j).group = i;
  byGroup(j).TFD = mean(cat(3,C(B.Group==i).TFD),3);
  subplot(2,2,j)
  imagesc(t,func(2).freq(func(2).idx{f}),byGroup(j).TFD(func(2).idx{f},:)); axis xy
  title(j);
  colorbar; caxis([1 6]*10^-7)
  j=j+1;
end

i = [4.7 5 5.7 6 6.5 7.2];
figure(2)
count=1;
for f = 1:length(F)
    for j = groups
          subplot(6,4,count)
          imagesc(t,func(2).freq(func(2).idx{f}),byGroup(j).TFD(func(2).idx{f},:)); axis xy
%           title(j);
          colorbar; caxis([1 10].*(10^-i(f)))
          count=count+1;
    end
end
% byAnimal = varfun(@mean,B,'InputVariables',variable,'GroupingVariables',{'Group','Animal','Placement'});
% byGroup = varfun(@mean,B,'InputVariables',variable,'GroupingVariables',grouping);


%% Coherence
T2 = TCoh;
grouping = 'Group';
variable = 'Cxy';
B = sortrows(T2,grouping);
byAnimal = varfun(@mean,B,'InputVariables',variable,'GroupingVariables',{'Group','Animal'});
byGroup = varfun(@mean,byAnimal,'InputVariables',['mean_' variable],'GroupingVariables',grouping);

plot(func(1).freq,byGroup.mean_mean_Cxy)
xlim([0 150])
ylim([0 1])
xlabel('Frequency (Hz)')
ylabel('Coherence') %embora seja coerência ao quadrado, o que ressalta a 
% diferença entre as coerencias calculadas
set(gcf,'color','w')
box off

% fitglme(tbl,formula)
