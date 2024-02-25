% % % Initialization of important parameters
% % utilityFunction=@(x) log(x+1); % (x+1) to avoid the problem of x=0
% % numGridPoints=101; % The number of points I use on the grid
% % % I consider my grid as a vector of wealths that starts from 0 and go until
% % % 1000, increasing 10 by 10 (so I have 0,10,20,30,...)
% % wealthVector=linspace(0,1000,numGridPoints);
% % % I choose my gamma as 0.95 because I want to simulate a person that is
% % % interested in preserving his money
% % gamma=0.95;
% % % To simplify I use these 3 values, but in a real case thay can be
% % % considered multiplied by 100 (so 25000 € as the wage of a full time job,
% % % 10000 € as a wage of a part time job and 2000 € as the wage for an
% % % unemployed person
% % wageVector=[250 100 20];
% % % The annual rate of the risk free asset
% % rf=0.01;
% % % The number of years I want to find and apply the policy
% % numYears=35;
% % % The number of Montecarlo simulations to validate the results
% % numSimulations=100;
optimalValueStadard=zeros(numSimulations,1);
differencesWealthStandard=zeros(numSimulations,1);


% % % This matrix contains the probabilities to pass from a state to anoher one
% % % 1st row: Full-time job
% % % 2nd row: Part-time job
% % % 3rd row: Unemployed
% % transitionMatrix=[0.7 0.2 0.1; 0.3 0.5 0.2; 0.15 0.25 0.6];
% % 
% % % I apply the dynamic programming to find the spline list that I need in
% % % order to apply the policy in the Montecarlo simulations
% % splineList=findPolicyDP(transitionMatrix,...
% %         utilityFunction,wealthVector,gamma,wageVector,rf,numYears);

% The simulation is done multiple times to find the approximation of the
% maximum expected value of the utility function, which is the purpose of
% the entire algorithm
for i=1:numSimulations
    
    % I apply the policy that I have found, thanks to the spline list that
    % I pass to the function
    [optimalValuesStandard,objectiveValueStandard,wealthAtTimeStandard,...
        lambdaAtTimeStandard,objValAtTimeStandard,ratesAtTimeStandard]=...
        applyPolicy(splineList,utilityFunction,numYears,transitionMatrix,wageVector,rf,gamma);
    
    differencesWealthStandard(i)=wealthAtTimeStandard(numYears+1)-wealthAtTimeStandard(1);
    optimalValueStadard(i)=objectiveValueStandard;
    
end
% This is the optimized value deriving from the optimization of the
% expected value of the sum of the utility functions
finalValueStandard=sum(optimalValueStadard)/numSimulations;
finalDifferencesWealthStandard=sum(differencesWealthStandard)/numSimulations;