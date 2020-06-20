% plot TFD
variable = 'TFD';
T2 = [T T1];
byAnimal = varfun(@mean,T2,'InputVariables',variable,'GroupingVariables',{'Group','Animal','Placement'});
ncol=width(byAnimal);
byGroup = varfun(@mean,PSDbyAnimal,'InputVariables',ncol,'GroupingVariables',{'Group','Placement'});
