% demo for co-clustering and VB co-clustering
%
% ---
% Eye-Movement analysis with HMMs (emhmm-toolbox)
% Copyright (c) 2021-07-29
% Antoni B. Chan, Janet H. Hsiao, Lan Hui
% City University of Hong Kong, University of Hong Kong

% 2019-10-26: added t-test and anova for model differences for each stimuli
%             added debugmode=2
% 2020-03-10: v0.77 - added journal experiment
% 2021-07-28: v0.80 - added VB co-clustering
%                   - put all experiment options into one structure
%                   - save space when saving mat file

clear
close all

%% options structure for the experiment %%%%%%%%%%%%%%%%%%%%%%%%
OPT = struct;

% set DEBUGMODE=1, only the first 10 subjects and first 5 stimuli and used
%                  and only 5 trials are used for VB-HMM and VHEM.
%                  This is mainly to test the code.
% set DEBUGMODE=2, only the first 10 subjects, first 15 stimuli, and use
%                  default number of trials for VB-HMM and VHEM
%                  This is mainly to test the code.
% set DEBUGMODE=0 for the real experiment.
OPT.DEBUGMODE = 0;

% flags to run individual HMMs and co-clustering
%   1 = compute the HMMs and save them
%   0 = use the previously saved ones
do_indhmms = 1;  % for individual HMMs
do_cluster = 1;  % for co-clutering HMMs
    
% names of mat files for saving individual and group hmms
outindmat = 'individual_hmms.mat';
outgrpmat = 'vbcogroup_hmms.mat';

%% the following data is required:
%
% 1) fixation XLS file - with the following columns:
%      SubjectID - subject name (same as before)
%      TrialID   - trial number (same as before)
%      StimuliID - the name of the stimuli image viewed (required for co-clustering)
%      FixX - fixation X coordinate (same as before)
%      FixY - fixation Y coordinate (same as before)
%
% NOTE: For one subject, TrialID should be unique across all stimuli.
%       I.e., different stimuli cannot have the same TrialID.
%
% 2) imgsize = [xsize, ysize] of stimuli 
%    - we assume that all stimuli images are the same size.
%
% 3) imginfo XLS file - contains the information about each stimuli, 
%    and the valid box region  for that stimuli (e.g., if there is a border around 
%    the actual stimuli). It has the following columns:
%      StimuliID - image name
%      Xlo - lower X coordinates of valid box
%      Xhi - upper X coordinates
%      Ylo - lower Y coordinates
%      Yhi - upper Y coordinates
% 
% 4) imgdir - location of the images
% 5) outdir - where to save the output images and mat files.

% change this to select one of the demos/experiments below
OPT.datasource = 0

switch(OPT.datasource)  
  case 0
    %% synthetic data (10 trials per person per stimuli)
    % using co-clustering (number of clusters K is set manually)
    OPT.fixationfile = 'test-data/test-data.xlsx';
    OPT.imgdir       = 'test-data/';
    OPT.imgsize      = [1280; 768];
    OPT.imginfo      = 'test-data/test-info.xlsx';
    OPT.outdir       = 'test-data-results/';
    
    OPT.S = 1:3;
    OPT.HEM_K = 2;
    OPT.HEM_S = [];
    OPT.SWAP_CLUSTERS = [];
    OPT.vb_cocluster = 0;   % use standard co-clustering
    
    OPT.DEBUGMODE = 1; % set debugging mode for quick test
    outgrpmat = 'cogroup_hmms.mat';  % file name for group mat

  case 1
    %% synthetic data (10 trials per person per stimuli)
    % using VB co-clustering - automatically selects number of clusters K
    OPT.fixationfile = 'test-data/test-data.xlsx';
    OPT.imgdir       = 'test-data/';
    OPT.imgsize      = [1280; 768];
    OPT.imginfo      = 'test-data/test-info.xlsx';
    OPT.outdir       = 'test-data-vb-results/';
    
    OPT.S = 1:3;
    OPT.HEM_K = 1:5;
    OPT.HEM_S = [];
    OPT.SWAP_CLUSTERS = [];
    OPT.vb_cocluster = 1;   % use vb co-clustering
    
    OPT.DEBUGMODE = 1; % set debugging mode for quick test
    
    
  case 10
    %% full experiment using VB co-clustering
    % this version will automatically select the number of clusters K
    OPT.fixationfile = 'brm-data/fixations-new.xlsx';
    OPT.imgdir       = 'brm-data/images/';
    OPT.imgsize      = [640; 480];
    OPT.imginfo      = 'brm-data/stimuli-info.xlsx';
    OPT.outdir       = 'brm-data-vb-results/';
    
    % individual HMM settings (set vbopt like this)    
    OPT.S               = 2:4;  % number of ROIs to try
    OPT.vbopt.numtrials = 100; 
    
    % co-clustering settings 
    OPT.vb_cocluster    = 1;     % vb-coclustering
    OPT.HEM_K           = 1:5;   % try these numbers of clusters
    OPT.HEM_S           = [];    % use median
    OPT.SWAP_CLUSTERS   = [2 1]; % swap the cluster IDs for consistency w/ paper
    OPT.vbhemopt.trials = 50;    % options for vb co-clustering
    OPT.vbhemopt.seed   = 3000;
    OPT.vbhemopt.alpha0 = 1e6;   % encourage equal-sized clusters
    OPT.vbhemopt.v0     = 10;
    
    % on a MacBook Pro (with parallel computing toolbox)
    % computinn the individual HMMs takes about 6.3 hours
    % co-clustering takes about 1.1 hour
    do_indhmms = 1;    % run individual HMMs (set to 0 to reuse results)
    do_cluster = 1;    % run co-clustering (set to 0 to reuse results)
    OPT.DEBUGMODE = 0; % for code testing, set debugging mode to 1

  case 11
    %% full experiment using co-clustering
    % this version predefines the number of clusters K=2
    OPT.fixationfile = 'brm-data/fixations-new.xlsx';
    OPT.imgdir       = 'brm-data/images/';
    OPT.imgsize      = [640; 480];
    OPT.imginfo      = 'brm-data/stimuli-info.xlsx';
    OPT.outdir       = 'brm-data-results/';
    
    % individual HMM settings (set vbopt like this)
    OPT.S               = 2:4;  % number of ROIs to try   
    OPT.vbopt.numtrials = 100;
    
    % co-clustering settings
    OPT.vb_cocluster  = 0;
    OPT.HEM_K         = 2;    % use K=2 clusters
    OPT.HEM_S         = [];   % use median
    OPT.SWAP_CLUSTERS = [2 1]; % swap cluster IDs for consistency w/ paper
    OPT.hemopt.seed   = 3000;
    OPT.hemopt.trials = 50;    
    outgrpmat = 'cogroup_hmms.mat';  % file name for group mat
    
    do_indhmms = 1;    % run individual HMMs (set to 0 to reuse results)
    do_cluster = 1;    % run co-clustering
    OPT.DEBUGMODE = 0; % for code testing, set debugging mode to 1
    
  case 12
    %% replicate the exact BRM experiment using VB co-clustering
    %  (This is the exact experiment used in the BRM paper.
    %   Note that the individual HMMs are slightly different from the above 
    %   experiments due to changes in MATLAB).
    OPT.fixationfile = 'brm-data/fixations-new.xlsx';
    OPT.imgdir       = 'brm-data/images/';
    OPT.imgsize      = [640; 480];
    OPT.imginfo      = 'brm-data/stimuli-info.xlsx';
    OPT.outdir       = 'brm-data-vb-results-paper/';
    
    % individual HMM settings (set vbopt like this)    
    OPT.S               = 2:4;  % number of ROIs to try
    OPT.vbopt.numtrials = 100; 
    outindmat           = 'individual_hmms_paper.mat'; % pre-computed individual HMMs

    % co-clustering settings 
    OPT.vb_cocluster    = 1;     % vb-coclustering
    OPT.HEM_K           = 1:5;   % try these numbers of clusters
    OPT.HEM_S           = [];    % use median
    OPT.SWAP_CLUSTERS   = [2 1]; % swap the cluster IDs for consistency w/ paper
    OPT.vbhemopt.trials = 50;    % options for vb co-clustering
    OPT.vbhemopt.seed   = 1200;
    OPT.vbhemopt.alpha0 = 1e6;   % encourage equal-sized clusters
    outgrpmat           = 'vbcogroup_hmms_paper.mat';
                
    do_indhmms = 0;    % individual HMMs are already pre-computed
    do_cluster = 1;    % run co-clustering
    OPT.DEBUGMODE = 0; % for code-testing, set debugging mode

  otherwise
    error('bad mode');
end


%% output sub-directories
OPT.outdir_fix              = '1_fixations_stimuli/';
OPT.outdir_indhmms          = '2_indhmms_stimuli/';
OPT.outdir_grphmms          = '3_grphmms_all/';
OPT.outdir_grphmms_stim     = '4_grphmms_stimuli/';
OPT.outdir_grphmms_fix      = '5_grphmms_fixations/';
OPT.outdir_grphmms_clusters = '6_grphmms_cluster/';

%% options for saving images
OPT.SAVE_FIXATION_PLOTS = 0;  % change this to 1 if you want to show fixations on each image.
OPT.SAVE_GROUP_MEMBERS_PLOTS = 1; % change this to 1 if you want to plot cluster members with group hmm.
OPT.IMAGE_EXT = 'jpg';        % format for output images
OPT.SORT_BY_DIFF = 1;         % 1 = when generating image outputs, sort by KL divergence between HMMs

OPT

%% figure options
figopts = {'Position', [20 0 1240 800]};
stpopts = {0.005, 0.01, 0.01};
subplotwidth = 10;

%% setup directories %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[success, msg] = mkdir(OPT.outdir);
[success, msg] = mkdir(OPT.outdir, OPT.outdir_fix);
[success, msg] = mkdir(OPT.outdir, OPT.outdir_indhmms);
[success, msg] = mkdir(OPT.outdir, OPT.outdir_grphmms);
[success, msg] = mkdir(OPT.outdir, OPT.outdir_grphmms_stim);
[success, msg] = mkdir(OPT.outdir, OPT.outdir_grphmms_fix);
[success, msg] = mkdir(OPT.outdir, OPT.outdir_grphmms_clusters);

%% estimate the subject HMMs for each stimuili %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (do_indhmms)

  %% read fixations
  [alldata, SubjNames, TrialNames, StimuliNames] = read_xls_fixations2(OPT.fixationfile);
  
  %% read in images for all Stimuli
  tmp = unique(cat(1,StimuliNames{:}));
  StimuliNamesImages = cell(length(tmp),2);
  StimuliNamesImages(:,1) = tmp;
  for j=1:length(tmp)
    StimuliNamesImages{j,2} = imread([OPT.imgdir tmp{j}]);
  end
  
  %% preprocess the fixations -- remove fixations outside of image boundaries
  alldata_OLD = alldata;
  alldata = preprocess_fixations(alldata, StimuliNames, OPT.imginfo, StimuliNamesImages);
  
  %% sort data by stimuli for co-clustering
  % NOTE: the order of Stimuli will be alphabetized
  [alldataC, TrialNamesC, StimuliNamesC] = sort_coclustering(alldata, TrialNames, StimuliNames);
  
  % remove to avoid confusion
  clear alldata alldata_OLD TrialNames StimuliNames
  
  % for debugging, only take the first 5 stimuli, and 10 subjects
  if OPT.DEBUGMODE
    fprintf('<strong>*** USING DEBUG MODE ***\n</strong>');
    fprintf('set "DEBUGMODE=0" in the script to use all the data and full trials\n');
    
    OPT.MAXSTIM = 5;
    OPT.MAXSUBJ = 10;
    
    fprintf('<strong>*** DEBUG: selecting subset - first %d stimuli, first %d subjects</strong>\n', OPT.MAXSTIM, OPT.MAXSUBJ);
    alldataC = alldataC(1:OPT.MAXSTIM,1:OPT.MAXSUBJ);
    TrialNamesC = TrialNamesC(1:OPT.MAXSTIM,1:OPT.MAXSUBJ);
    StimuliNamesC = StimuliNamesC(1:OPT.MAXSTIM);
  end
  
  [Nstimuli, Nsubjects] = size(alldataC);
  % map from StimuliNamesC to entry in StimuliNamesImages
  mapC = zeros(1,Nstimuli);
  for j=1:Nstimuli
    mapC(j) = find(strcmp(StimuliNamesC{j}, StimuliNamesImages(:,1)));
  end
  
  % reorder to match StimuliNamesC
  StimuliNamesImagesC = StimuliNamesImages(mapC,:);
  clear StimuliNamesImages
  
  %% setup output names - use stimuli name or stimuli index
  stimname = @(j) ['_' sprintf('%03d', j)];
  stimname = @(j) ['_' StimuliNamesC{j}(1:end-4)];
  
  
  %% show subjects
  if OPT.SAVE_FIXATION_PLOTS
    figure(figopts{:});
    for j=1:Nstimuli
      clf
      for i=1:Nsubjects
        subtightplot(ceil(Nsubjects/subplotwidth), subplotwidth, i, stpopts{:});
        plot_fixations(alldataC{j,i}, StimuliNamesImagesC{j,2});
      end
      drawnow
      
      outfile = [OPT.outdir OPT.outdir_fix 'fixations_stimuli_' stimname(j)];
      fprintf('saving fixation plot: %s\n', outfile);
      savefigs(outfile, OPT.IMAGE_EXT);
    end
  end
  
  
  %% vbhmm parameters (default parameters)
  vbopt.alpha0 = 0.1;
  vbopt.mu0    = OPT.imgsize/2;
  vbopt.W0     = 0.005;
  vbopt.beta0  = 1;
  vbopt.v0     = 5;
  vbopt.epsilon0 = 0.1;
  vbopt.showplot = 0; 
  vbopt.bgimage  = '';
  vbopt.learn_hyps = 1;
  vbopt.seed = 1000;
  vbopt.numtrials = 100;
  
  % add options from OPT structure
  if isfield(OPT, 'vbopt')
    fn = fieldnames(OPT.vbopt);
    for i = 1:length(fn)
      ff = fn{i};
      vbopt.(ff) = OPT.vbopt.(ff);
      if isnumeric(vbopt.(ff))
        fprintf('-- set vbopt.%s = %s\n', ff, mat2str(vbopt.(ff)));
      else
        fprintf('-- set vbopt.%s = \n', ff)
        vbopt.(ff)
      end
    end
  end
  
  if OPT.DEBUGMODE == 1
    fprintf('<strong>*** DEBUG: set number of trials to 5</strong>\n');
    vbopt.numtrials = 5;  % for testing
  end
  
  tstart = tic;
  
  %% learn HMMs from data
  hmm_subjects = cell(Nstimuli, Nsubjects);
  figure(figopts{:})
  
  for j=1:Nstimuli
    fprintf('*** Stimuli %d *********************************************\n', j);
    
    [tmp] = vbhmm_learn_batch(alldataC(j,:), OPT.S, vbopt);
    hmm_subjects(j,:) = tmp;
    
    %% show subject HMMs
    %figure(myfig);
    clf
    for i=1:Nsubjects
      if ~isempty(hmm_subjects{j,i})
        subtightplot(ceil(Nsubjects/subplotwidth),subplotwidth, i, stpopts{:});
        vbhmm_plot_compact(hmm_subjects{j,i}, StimuliNamesImagesC{j,2});
      end
    end
    drawnow
    
    %% save image
    outfile = [OPT.outdir OPT.outdir_indhmms 'indhmms_stimuli_' stimname(j)];
    fprintf('saving individual HMMS: %s\n', outfile);
    savefigs(outfile, OPT.IMAGE_EXT);
    
  end
  
  telapsed_ind = toc(tstart)
  
  %% save mat file
  outfile = [OPT.outdir outindmat];
  fprintf('saving individual MAT files: %s\n', outfile);
  save(outfile, 'Nstimuli', 'Nsubjects', 'OPT', ...
     'StimuliNamesC', 'SubjNames', 'TrialNamesC', ...
     'mapC', 'alldataC', 'hmm_subjects', 'vbopt');
  
else
  
  %% load the data and individual HMMs from before %%%%%%%%%%%%%%%%
  infile = [OPT.outdir outindmat];
  fprintf('loading individual hmms: %s\n', infile);  
  if ~exist(infile, 'file')
    error('individual hmm mat file does not exist. set do_indhmms=1 and re-run');
  end
    
  OPT_new = OPT; % save current OPT
  load(infile)
  OPT = OPT_new; % set the new OPT
  
  % read in the images, which are not saved in the mat file
  StimuliNamesImagesC = cell(length(StimuliNamesC),2);
  StimuliNamesImagesC(:,1) = StimuliNamesC;
  for j=1:length(StimuliNamesC)
    StimuliNamesImagesC{j,2} = imread([OPT.imgdir StimuliNamesC{j}]);
  end
  
  % setup output names - use stimuli name or stimuli index
  stimname = @(j) ['_' sprintf('%03d', j)];
  stimname = @(j) ['_' StimuliNamesC{j}(1:end-4)];
end


%% exit if we are not doing clustering
if (do_indhmms && ~do_cluster)
  fprintf('-- just computing individual HMMs --\n');
  return
end


%% co-clustering %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (do_cluster)

  %% vb co-clustering %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if OPT.vb_cocluster
    % default parameters
    vbhemopt = struct;
    vbhemopt.tau   = round(get_median_length(alldataC(:)));
    vbhemopt.m0    = OPT.imgsize/2;
    vbhemopt.W0    = 0.005;
    vbhemopt.initmode  = 'vbh3m'; 
    vbhemopt.learn_hyps = 1;
    vbhemopt.Nv   = 10;
    vbhemopt.seed = 1000;
    
    % add options from OPT structure
    if isfield(OPT, 'vbhemopt')
      fn = fieldnames(OPT.vbhemopt);
      for i = 1:length(fn)
        ff = fn{i};
        vbhemopt.(ff) = OPT.vbhemopt.(ff);
        if isnumeric(vbhemopt.(ff))
          fprintf('-- set vbhemopt.%s = %s\n', ff, mat2str(vbhemopt.(ff)));
        else
          fprintf('-- set vbhemopt.%s = \n', ff)
          vbhemopt.(ff)
        end
      end
    end
    
    if OPT.DEBUGMODE
      fprintf('<strong>*** DEBUG: set trials to 5</strong>\n');
      vbhemopt.trials = 5;
    end
    
    tstart = tic;
    
    % run VB co-clustering
    [vbco] = vbhem_cocluster(hmm_subjects, OPT.HEM_K, OPT.HEM_S, vbhemopt);
    
    telapsed_vbco = toc(tstart)
    
    % swap the groups (if desired)
    if ~isempty(OPT.SWAP_CLUSTERS)
      vbco_OLD = vbco;
      vbco = vbhem_co_permute_clusters(vbco, OPT.SWAP_CLUSTERS);
    end
    
    
    %% save mat file
    outfile = [OPT.outdir outgrpmat];
    fprintf('saving group MAT file: %s\n', outfile);
    save(outfile, 'vbco','vbhemopt','OPT');
  
    
  else
    %% coclustering %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    hemopt.tau = round(get_median_length(alldataC(:)));
    hemopt.seed = 3000;
    hemopt.trials = 50;
    hemopt.initmode  = 'gmmNew';    
        
    % add options from OPT structure
    if isfield(OPT, 'hemopt')
      fn = fieldnames(OPT.hemopt);
      for i = 1:length(fn)
        ff = fn{i};
        hemopt.(ff) = OPT.hemopt.(ff);
        if isnumeric(hemopt.(ff))
          fprintf('-- set hemopt.%s = %s\n', ff, mat2str(hemopt.(ff)));
        else
          fprintf('-- set hemopt.%s = \n', ff)
          hemopt.(ff)
        end
      end
    end
    
    tstart = tic;
    
    %% run co-clustering
    [cogroup_hmms, trials] = vhem_cocluster(hmm_subjects, OPT.HEM_K, [], hemopt);
    
    telapsed_co = toc(tstart)
    
    %% swap clusters (if desired)
    if ~isempty(OPT.SWAP_CLUSTERS)     
      cogroup_hmms_old = cogroup_hmms;
      for i=1:length(cogroup_hmms)
        cogroup_hmms{i} = vhem_permute_clusters(cogroup_hmms{i}, OPT.SWAP_CLUSTERS);
      end
    end
    
    %% save mat file
    outfile = [OPT.outdir outgrpmat];
    fprintf('saving group MAT file: %s\n', outfile);
    save(outfile, 'cogroup_hmms','hemopt','OPT');    
  end
     
else
  %% load previous group model
  infile = [OPT.outdir outgrpmat];
  fprintf('loading group file: %s\n', infile);
  
  if ~exist(infile, 'file')
    error('group hmm mat file does not exist. set do_cluster=1 and re-run');
  end
    
  load(infile)
end


%% get the results from vb-coclustering or coclustering
if OPT.vb_cocluster
  % vb-coclustering results
  HEM_K = vbco.K; % get the selected K
  cg_hmms = vbco.cogroup_hmms;
  grps = vbco.groups;
else
  % coclustering results
  HEM_K = length(cogroup_hmms{1}.hmms);
  cg_hmms = cogroup_hmms;
  grps = cogroup_hmms{1}.groups;
end


%% compute LL and AB scale
for i=1:Nsubjects
  for j=1:Nstimuli
    for k=1:HEM_K
      if ~isempty(alldataC{j,i})
        % compute LL: if more than one sample for this stimuli, then average.
        % the LL for each subject of each situli under each model
        LL(i,j,k) = mean(vbhmm_ll(cg_hmms{j}.hmms{k}, alldataC{j,i}));
      else
        LL(i,j,k) = 0;
      end
    end
  end
end

% (assumes K=2)
% LL of subject under model 1 and 2
LL1 = sum(LL(:,:,1),2);  % sum over stimuli
LL2 = sum(LL(:,:,2),2);

% compute AB scale
% since some stimuli are missing, then normalize
AB = (LL1 - LL2) ./ (abs(LL1) + abs(LL2));


%% visualize the group HMMs in various ways
if (OPT.SORT_BY_DIFF)
  %% compute KL divergence between models for each stimuli
  % (assumes K=2)
  % mean LL(stim1,model1) - LL(stim1, model2)
  
  if (HEM_K~=2)
    warning('K~=2, using differences between clusters 1 and 2 for sorting');
  end
  
  % sum over subject
  KL1 = mean( LL(grps{1},:,1) - LL(grps{1},:,2), 1); % KL(M1 || M2)
  KL2 = mean( LL(grps{2},:,2) - LL(grps{2},:,1), 1);  % KL(M2 || M1)
  
  % sort by difference
  diffstim = abs(KL1 + KL2); %SKL
  [~,sortedinds] = sort(diffstim, 'descend');
else
  sortedinds = 1:Nstimuli;
end

%% view co-clustering results for each stimuli
figure(figopts{:})
MAX_ROWS = 5;
count = 1;
for j=1:Nstimuli
  jj = mod(j-1, MAX_ROWS)+1;
  subplotinfo = [MAX_ROWS, HEM_K, (jj-1)*HEM_K + [1:HEM_K]];
  vhem_plot(cg_hmms{j}, StimuliNamesImagesC{j,2}, 'c', subplotinfo);
  
  if (mod(j, MAX_ROWS)==0) || (j==Nstimuli)
    drawnow
    outfile = [OPT.outdir OPT.outdir_grphmms sprintf('grphmms_all_%03d', count)];
    fprintf('saving co-clustering group HMMs: %s\n', outfile);
    %export_fig(outfile, '-png', '-transparent');    
    savefigs(outfile, OPT.IMAGE_EXT);
    count = count+1;
    clf
  end
  
end

%% view group HMMs (sorted by KL)
figure(figopts{:})
for jj=1:Nstimuli
  j = sortedinds(jj);
  clf
  vhem_plot(cg_hmms{j}, StimuliNamesImagesC{j,2}, 'c', [1 HEM_K 1:HEM_K]);
  drawnow
  outfile = [OPT.outdir OPT.outdir_grphmms_stim 'grphmms_stimuli_' sprintf('%03d', jj) stimname(j)];
  fprintf('saving co-clustering group HMMs: %s\n', outfile);
  %export_fig(outfile, '-png', '-transparent');
  savefigs(outfile, OPT.IMAGE_EXT);
end

%% view fixations on group hmms
for jj=1:Nstimuli
  j = sortedinds(jj);
  hfig = vhem_plot_fixations(alldataC(j,:), cg_hmms{j}, StimuliNamesImagesC{j,2}, 'c', 1, figopts);
  drawnow
  %
  outfile = [OPT.outdir OPT.outdir_grphmms_fix 'grphmms_fixations_stimuli_' sprintf('%03d', jj) stimname(j)];
  fprintf('saving group HMMs w/ fixations: %s\n', outfile);
  figure(hfig)
  %export_fig(outfile, '-png', '-transparent');  
  savefigs(outfile, OPT.IMAGE_EXT);
  close(hfig)
end

%% view group hmms and cluster members
if OPT.SAVE_GROUP_MEMBERS_PLOTS
  for j=1:Nstimuli
    hfigs = vhem_plot_clusters(cg_hmms{j}, hmm_subjects(j,:), StimuliNamesImagesC{j,2});
    drawnow
    
    for k=1:HEM_K
      figure(hfigs(k))
      
      outfile = [OPT.outdir OPT.outdir_grphmms_clusters 'grphmms_cluster_stimuli' stimname(j) sprintf('_%d', k)];
      fprintf('saving group HMMs cluster %d: %s\n', k, outfile);
      savefigs(outfile, OPT.IMAGE_EXT, hfigs(k));
      %export_fig(outfile, '-pdf', '-transparent');
      %export_fig(outfile, '-png', '-transparent');
      close(hfigs(k));
    end
  end
end

%% analyze LL of group differences
if (HEM_K == 2)
  %% get LL for each group
  stim_LL1 = [];
  stim_LL2 = [];
  
  for j=1:Nstimuli
    % get LL for group 1 under models 1 and 2
    stim_LL1(:,j,1) = LL(grps{1}, j, 1);
    stim_LL1(:,j,2) = LL(grps{1}, j, 2);
    
    % get LL for group 2 under models 2 and 1
    stim_LL2(:,j,1) = LL(grps{2}, j, 2);
    stim_LL2(:,j,2) = LL(grps{2}, j, 1);
  end
  
  %% average stimuli
  fprintf('=== group difference (overall) ===\n');
  
  % average LL over stimulus for group 1 under models 1 and 2
  LL1_grp1 = mean(stim_LL1(:,:,1),2); % subjects in group under group 1 model
  LL1_grp2 = mean(stim_LL1(:,:,2),2); % subjects in group under group 2 model
  
  [h1,p1,ci1,stats1] = ttest(LL1_grp1, LL1_grp2, 'tail', 'both');
  deffect = computeCohen_d(LL1_grp1,LL1_grp2, 'paired');
  fprintf('model1 vs model2 using grp1 data: p=%0.4g, t(%d)=%0.4g, cohen_d=%0.4g\n', ...
    p1, stats1.df, stats1.tstat, deffect);
  
  % average LL over stimulus for group 2 under models 1 and 2
  LL2_grp1 = mean(stim_LL2(:,:,1),2); % subjects in group under group 1 model
  LL2_grp2 = mean(stim_LL2(:,:,2),2);% subjects in group under group 2 model
   
  [h2,p2,ci2,stats2] = ttest(LL2_grp1, LL2_grp2, 'tail', 'both');
  deffect = computeCohen_d(LL2_grp1,LL2_grp2, 'paired');
  fprintf('model1 vs model2 using grp2 data: p=%0.4g, t(%d)=%0.4g, cohen_d=%0.4g\n', ...
    p2, stats2.df, stats2.tstat, deffect);
  
    
  %% t-test for symmetric KLD
  for j=1:Nstimuli
    % G1 data under G1 model, G2 data under G2 model
    stim_LL1c = [stim_LL1(:,j,1); stim_LL2(:,j,1)];
    % G1 data under G2 model, G2 data under G1 model
    stim_LL2c = [stim_LL1(:,j,2); stim_LL2(:,j,2)];
    [stim_hc(j), stim_pc(j)] = ttest2(stim_LL1c, stim_LL2c, 'tail', 'right');
  end
  
  fprintf('=== group test (each stimuli, symmetric KL) ===================\n');
  fprintf('t-test for symmetric KLD\n');
  fprintf('comparison between group models:\n');
  fprintf('  number of sig diff models (combined):  %d/%d \n', sum(stim_hc), length(stim_hc));
  
  figure
  hold on
  bar(diffstim(sortedinds).*stim_hc(sortedinds), 'g')
  bar(diffstim(sortedinds).*(1-stim_hc(sortedinds)), 'r')
  hold off
  legend({'sig. diff', 'no diff'})
  hold off
  xlabel('sorted index (stimuli)');
  ylabel('KLD')
  title('sorted KLD and statistical test');
  
  outfile = [OPT.outdir 'skld_stats'];
  fprintf('saving SKLD stats: %s\n', outfile);
  savefigs(outfile, OPT.IMAGE_EXT);

end



