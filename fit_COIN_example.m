% run the COIN model
obj = COIN;
obj.x = [zeros(1,50) ones(1,100) zeros(1,50)]; % perturbations
obj.x(5:10:end-5) = NaN; % occasional channel trials
obj.q = [ones(1,50) 2*ones(1,100) ones(1,50)]; % sensory cues
[S,w] = obj.run_COIN;

% define the paradigm
perturbations = obj.x;
cues = obj.q;

% generate synthetic force-field adaptation data (NaN if adaptation not measured)
adaptation = NaN(1,200);
adaptation(isnan(obj.x)) = S{1}.yHat(isnan(obj.x));

% BADS options
options = [];
options.UncertaintyHandling = 1; % tell BADS that the objective is noisy
options.NoiseFinalSamples = 1; % # samples to estimate FVAL at the end (default would be 10) - use more if obj(p).R is small

obj = @(param) fit_COIN(param,perturbations,cues,adaptation);

% YOU MAY WANT TO NARROW/WIDEN/SHIFT THESE BOUNDS!
lb  = [1e-3 0.2    1   1   1e-2 1e-6 1e-4   1e-6]; % lower bounds
plb = [1e-2 0.5    10  10  5e-2 1e-2 1e-3   1e-4]; % plausible lower bounds
pub = [2e-1 0.9    1e5 1e7 2e-1 1e5  0.9    1e2 ]; % plausible upper bounds
ub  = [5e-1 1-1e-6 1e7 1e9 3e-1 1e6  1-1e-4 1e4 ]; % upper bounds

% random starting point inside plausible region
x0 = plb + (pub-plb).*rand(1,numel(plb));

% fit the COIN model to the synthetic data using BADS
[x,fval,exitflag,output] = bads(obj,x0,lb,ub,plb,pub,[],options);

function negativeLogLikelihood = fit_COIN(param,perturbations,cues,adaptation)

    % number of participants
    P = size(adaptation,1);

    % object array
    obj(1,P) = COIN;
    
    for p = 1:P % loop over participants

        % parameters (same for all participants)
        obj(p).sigmaQ = param(1);                       % standard deviation of process noise
        obj(p).adMu = [param(2) 0];                     % mean of prior of retention and drift
        obj(p).adLambda = diag([param(3) param(4)].^2); % precision of prior of retention and drift
        obj(p).sigmaM = param(5);                       % standard deviation of motor noise
        obj(p).alpha = param(6);                        % alpha hyperparameter of the Chinese restaurant franchise for the context
        obj(p).rho = param(7);                          % rho (self-transition) hyperparameter of the Chinese restaurant franchise for the context
        obj(p).alphaE = param(8);                       % alpha hyperparameter of the Chinese restaurant franchise for the cue emissions

        % paradigm (often unique to each participant)
        obj(p).x = perturbations(p,:);
        obj(p).q = cues(p,:);

        % adaptation (unique to each participant)
        obj(p).adaptation = adaptation(p,:);
            
        % number of runs
        obj(p).R = 1;
            
        % number of CPUs available
        obj(p).maxCores = 0;

    end

    % compute objective
    negativeLogLikelihood = obj.objective_COIN;
    
end