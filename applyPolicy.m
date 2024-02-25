function [optimalValues,objectiveValue,wealthAtTime,lambdaAtTime,objValAtTime,ratesAtTime] = applyPolicy(splineList...
    ,utilityFunction,numYears,transitionMatrix,wageVector,rf,gamma)

objectiveValue=0;
optimalValues=zeros(numYears+1,2);
mu=0.05; % The expected value of the return of the risky asset
sigma=0.3; % The standard deviation of the return of the risky asset
% I use again the rates of return found thanks to the aid of a normal
% distribution. I use them to solve the optimization problem
epsChosen=norminv([0.05 0.2 0.4 0.5 0.6 0.8 0.95]);
ratesReturn=exp(mu-(sigma^2)/2+sigma*epsChosen(:))-1;
ratesReturn=ratesReturn';
ratesAtTime=zeros(numYears+1,1); %the first cell is 0 because the first rate is at time t=1 (for Matlab t=2)
qVect=[0.05 0.2 0.4 0.5 0.4 0.2 0.05];
numRates=length(ratesReturn);
% I save all the wealth after every time instant and all the lambda (so all
% the working conditions during the years of the simulation)
wealthAtTime=zeros(numYears+1,1);
lambdaAtTime=zeros(numYears+1,1);
wealthAtTime(1)=wageVector(1)*rand(1); % it means the initial time t=0, it is random between 0 and 250
lambdaAtTime(1)=randi([1 3]); % it means the initial time t=0, it is random between 1,2 and 3
objValAtTime=zeros(numYears+1,1); % I save all the objective values found

% I use this matrix to find a random number between 0 and 1 and to choose,
% knowing the working condition, which will be the next one
cumulativeTransitionMatrix=zeros(3);
for i=1:3
    for j=1:3
        cumulativeTransitionMatrix(i,j)=sum(transitionMatrix(i,1:j));
    end
end

% I find the optimal values of C and alpha at time 0 (so for Matlab t=1)
externalSum=@(x) 0;
for l=1:numRates
    internalSum=@(x) 0;
    for j=1:3
        wealthlj=@(x) wageVector(j)+(wealthAtTime(1)-x(1))*(1+rf+x(2)*(ratesReturn(l)-rf));
        valSpl=@(x) ppval(splineList(2,j),wealthlj([x(1) x(2)]));
        internalSum=@(x) internalSum([x(1) x(2)])+transitionMatrix(lambdaAtTime(1),j)*valSpl([x(1) x(2)]);
    end
    externalSum=@(x) externalSum([x(1) x(2)])+internalSum([x(1) x(2)])*qVect(l);
end

objFunc = @(x) -(utilityFunction(x(1))+gamma*externalSum([x(1) x(2)]));
options=optimoptions('fmincon','Display','off');
solutionsFound=fmincon(objFunc,[100,100],[],[],[],[],[0,0],[wealthAtTime(1),1],[],options);
optimalValues(1,:)=solutionsFound;
objectiveValue=objectiveValue+utilityFunction(optimalValues(1,1));
objValAtTime(1)=utilityFunction(optimalValues(1,1));


% I find the optimal values of C and alpha at time t=1:numYears-1 (so for Matlab t=2:numYears)
for t=2:numYears
    
    % I find a random number and I decide, thanks to that, which will be
    % the next working condition
    randomNumber=rand(1);
    for p=1:3
        if randomNumber<cumulativeTransitionMatrix(lambdaAtTime(t-1),p)
            lambdaAtTime(t)=p;
            break;
        end
    end
    
    % I simulate the rate of the risky asset at time t
    ratesAtTime(t)=normrnd(mu,sigma);
        
    % I calculate the wealth at time t knowing the formula
    wealthAtTime(t)=wageVector(lambdaAtTime(t))+(wealthAtTime(t-1)-optimalValues(t-1,1))...
        *(1+rf+optimalValues(t-1,2)*(ratesAtTime(t)-rf));
    
    % I now solve the optimization problem to find the 2 optimal values
    externalSum=@(x) 0;
        for l=1:numRates
            internalSum=@(x) 0;
            for j=1:3
                wealthlj=@(x) wageVector(j)+(wealthAtTime(t)-x(1))*(1+rf+x(2)*(ratesReturn(l)-rf));
                valSpl=@(x) ppval(splineList(t+1,j),wealthlj([x(1) x(2)]));
                internalSum=@(x) internalSum([x(1) x(2)])+transitionMatrix(lambdaAtTime(t),j)*valSpl([x(1) x(2)]);
            end
            externalSum=@(x) externalSum([x(1) x(2)])+internalSum([x(1) x(2)])*qVect(l);
        end
    objFunc = @(x) -(utilityFunction(x(1))+gamma*externalSum([x(1) x(2)]));
    options=optimoptions('fmincon','Display','off');
    solutionsFound = fmincon(objFunc,[optimalValues(t-1,1),optimalValues(t-1,2)],[],[],[],[],...
        [0,0],[wealthAtTime(t),1],[],options);
    % I save the 2 solutions found and, thanks to them, I update the
    % objective value of the objective function and the utility at time t
    optimalValues(t,:)=solutionsFound;
    objectiveValue=objectiveValue+(gamma^(t-1))*utilityFunction(optimalValues(t,1));
    objValAtTime(t)=utilityFunction(optimalValues(t,1));
    
end

% I simulate what happens at the final time, when all the decisions have been taken
randomNumber=rand(1);
for p=1:3
    if randomNumber<cumulativeTransitionMatrix(lambdaAtTime(numYears),p)
        lambdaAtTime(numYears+1)=p;
        break;
    end
end

% I find the random value of the return at the final time instant
ratesAtTime(numYears+1)=normrnd(mu,sigma);

% I calculate the wealth at the final time instant
wealthAtTime(numYears+1)=wageVector(lambdaAtTime(numYears+1))+...
    (wealthAtTime(numYears)-optimalValues(numYears,1))*(1+rf+optimalValues(numYears,2)*(ratesAtTime(numYears+1)-rf));

% I finally update all the values that I need to know
optimalValues(numYears+1,:)=[wealthAtTime(numYears+1) 0];
objectiveValue=objectiveValue+(gamma^(numYears))*utilityFunction(optimalValues(numYears+1,1));
objValAtTime(numYears+1)=utilityFunction(optimalValues(numYears+1,1));

end