function findPolicyDPForSingleValueFunction(transitionMatrix,...
    utilityFunction,wealthVector,gamma, wageVector,rf,numYears)

numGridPoints=length(wealthVector);
mu=0.05; % This is the average return of the risky asset
sigma=0.3; % This is the standard deviation of the return of the risky asset
% I find the quantiles of the standard normal distribution
epsChosen=norminv([0.05 0.2 0.4 0.5 0.6 0.8 0.95]);
% I use the quantiles to estimate the rates of return waited, in order to
% apply them into the objective function
ratesReturn=exp((mu-(sigma^2)/2)+sigma*epsChosen(:))-1;
ratesReturn=ratesReturn';
% The weight that must be given to every rate estimated
qVect=[0.05 0.2 0.4 0.5 0.4 0.2 0.05];
numRates=length(ratesReturn);
policyToApply=zeros(numGridPoints,numYears,3,2);

% The index of the last year is 'numYears+1' and NOT 'numYears', because
% the Matlab numeration starts from 1 and NOT from 0, so all the years are
% rescaled of a factor '+1'
valueFunctions=zeros(numGridPoints,numYears+1,3);

% I find the value functions for the final time 'numYears' and doing this I
% can fill the last column of the value functions matrix
for k=1:numGridPoints
    valueFunctions(k,numYears+1,1)=utilityFunction(wealthVector(k));
    valueFunctions(k,numYears+1,2)=utilityFunction(wealthVector(k));
    valueFunctions(k,numYears+1,3)=utilityFunction(wealthVector(k));
end

% I find the spline having as the indipendent variable the 'wealthVector' 
% vector and as a dependent variable the 'valueFunctions' vector
splineList(numYears+1,1)=spline(wealthVector(:),valueFunctions(:,numYears+1,1));
splineList(numYears+1,2)=spline(wealthVector(:),valueFunctions(:,numYears+1,2));
splineList(numYears+1,3)=spline(wealthVector(:),valueFunctions(:,numYears+1,3));


for t=numYears:-1:5
% This loop is made for every working condition
for i=1:3
    % This loop is made on all the grid points
    for k=1:numGridPoints

        % I initialize the external sum to 0 and I increase it after
        % having applied all the return rates
        externalSum=@(x) 0;
        for l=1:numRates
            % I initialize the internal sum to 0 and I increase it
            % after having applied all the working conditions
            internalSum=@(x) 0;
            for j=1:3
                % x(1) is the variable C_t
                % x(2) is the variable alpha_t
                wealthlj=@(x) wageVector(j)+(wealthVector(k)-x(1))*(1+rf+x(2)*(ratesReturn(l)-rf)); %W_t^{lj}
                valSpl=@(x) ppval(splineList(t+1,j),wealthlj([x(1) x(2)])); %v_{t,j}(W_t^{lj})
                internalSum=@(x) internalSum([x(1) x(2)])+transitionMatrix(i,j)*valSpl([x(1) x(2)]);
            end
            externalSum=@(x) externalSum([x(1) x(2)])+internalSum([x(1) x(2)])*qVect(l);
        end

        % I find the objective function after the simulation on all the
        % working conditions and all the rates of return
        objFunc=@(x) -(utilityFunction(x(1))+gamma*externalSum([x(1) x(2)]));

        if k>1
            % After the first grid point I can use as the initial
            % values the optimal values found in the previous step
            options=optimoptions('fmincon','Display','off');
            optimalSolutions=fmincon(objFunc,[policyToApply(k-1,t,i,1),policyToApply(k-1,t,i,2)],...
                [],[],[],[],[0,0],[wealthVector(k),1],[],options);
        else
            % I find 2 random initial values to give to 'fmincon'
            initialValues=zeros(2,1);
            initialValues(1)=100*rand(1);
            initialValues(2)=rand(1);
            options=optimoptions('fmincon','Display','off');
            optimalSolutions=fmincon(objFunc,initialValues,[],[],[],[],[0,0],[wealthVector(k),1],[],options);
        end
        % I save the 2 optimal values and I save the value of the
        % objective function into the value functions matrix (with the
        % negative sign because with 'fmincon' I find the minimum but I
        % want the maximum)
        policyToApply(k,t,i,:)=optimalSolutions;
        valueFunctions(k,t,i)=-objFunc(optimalSolutions);
    end
    % After the loop on all the grid points I have the values to
    % estimate the spline of the value function of time t
    splineList(t,i)=spline(wealthVector(:),valueFunctions(:,t,i));
end
end

figure('Position',[0 0 1080 1080])
plot(wealthVector,valueFunctions(:,5,1),'xb','LineWidth',2,'MarkerSize',9)
% leg=legend('$$I_{c,u}$$','$$I_{c,w}$$','$$I_{w,u}$$');
% set(leg,'Interpreter','latex')
% set(leg,'Fontsize',20)
xlabel('wealth (euro)','Interpreter','latex','Fontsize',35)
ylabel('value function','Interpreter','latex','Fontsize',30)
title('Andamento dei valori di value function al variare della ricchezza','Interpreter','latex','Fontsize',40)
ax=gca;
ax.LineWidth=2;
ax.FontSize=21;
ax.TitleFontSizeMultiplier=1;
saveas(gcf, 'valueFunctionT5.png');

end