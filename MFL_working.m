% MFL modeling


data_2015 = csv2cell('mfl_weekly_totals_2015.csv','fromfile');
weekly_2015=str2double(data_2015(:,5));
data_2016 = csv2cell('mfl_weekly_totals_2016.csv','fromfile');
weekly_2016=str2double(data_2016(:,5));
data_2017 = csv2cell('mfl_weekly_totals_2017.csv','fromfile');
weekly_2017=str2double(data_2017(:,5));
%% sort data into score(team_idx, week_idx)


fid=data_2017;
num_scores = length(fid);
team_key=fid(:,2);
team_list=sort(unique(team_key));
num_teams = length(team_list);
num_games = num_scores/num_teams;
[LIA1,team_idx_key] = ismember(team_key,team_list);

weeks_key=str2double(fid(:,4));
num_weeks=max(weeks_key);
weeks_list=1:num_weeks;
[LIA2,weeks_idx_key] = ismember(weeks_key,weeks_list);

weekly_scores = str2double(fid(:,5));


%% sort data into team_data(week,teamid)
scores=zeros(num_weeks,2);
team_data=zeros(num_weeks,num_teams);
for i = 1:num_teams
    scores(:,1) = weekly_scores(team_idx_key == i);
    scores(:,2) = weeks_key(team_idx_key == i);
    scores = sortrows(scores,2);
    team_data(:,i) = scores(:,1);
end
    

%% track posterior
% for now, gaussian with mean 98 and std 25.
edges = 0:1:200;
edges_std = 1:1:101;

mean_prior = 99.7;
mean_stdev = 20.55;
std_std_prior = 5;
% set prior
for i = 1:length(edges)
    for j = 1:length(edges_std)
        prior(i,j) = normpdf(i,mean_prior,mean_stdev) * normpdf(j,mean_stdev,std_std_prior);
    end
end
prior = prior/sum(prior(:));
%figure; hold on; contour(prior,3);


for i = 1:num_teams
    team_scores = team_data(:,i);
    num_scores = length(team_scores);
    % posterior = likelihood * prior
    posterior = prior;
    for week = 1:num_scores
        posterior = update_posterior(posterior,edges,edges_std,team_scores(week));
        
        
        [C,I] = max(posterior(:));
        [I1,I2] = ind2sub(size(posterior),I);
        
        ml_mean(i,week) = edges(I1);
        ml_std(i,week) = edges_std(I2);
    end
    %contour(posterior,3);
    %legend({'prior','posterior'});
  
end

%% Plot max likelihoods 
figure; hold on
for i = 1:num_teams
    plot([ml_mean(i,num_scores)-2*ml_std(i,num_scores) ml_mean(i,num_scores)+2*ml_std(i,num_scores)],[i i],'Linewidth', 3);
    plot([ml_mean(i,num_scores) ml_mean(i,num_scores)],[i+.2 i-.2],'k');
    text(ml_mean(i,num_scores),i+.4,team_list(i));
end
ylim([0 11]);

%%
figure; hold on;

for i = 1:num_teams
    ml_dist = normpdf(edges,ml_mean(i,num_scores),ml_std(i,num_scores));
    plot(ml_dist)
    text(ml_mean(i,num_scores),max(ml_dist),team_list(i));
end

legend(team_list);

%% calculate current records
clear wins
for i = 1:num_weeks
    [Y,I]=sort(team_data(i,:),'ascend');
    [X,I2] = sort(I);
    wins(i,:)=I2 - 1;
end

current_record = sum(wins)
games_back = current_record - max(current_record(:))
%% calculate all team distribution
all_scores = team_data(:);
tic
num_scores = length(all_scores);
boot_trials = 100000;
all_boot_avg = zeros(boot_trials,1);
all_boot_std = zeros(boot_trials,1);
for i = 1:boot_trials
    all_boot_idx = randi(num_scores,num_scores,1);
    all_boot_avg(i) = mean(all_scores(all_boot_idx));
    all_boot_std(i) = std(all_scores(all_boot_idx));
end
toc

%% calculate distributions for each team
tic
boot_trials = 10000;   
team_boot_avg = zeros(boot_trials,num_teams);
team_boot_std = zeros(boot_trials,num_teams);
team_avg_avg = zeros(num_teams,1);
for i = 1:num_teams
    team_scores = team_data(:,i);
    num_scores = length(team_scores);
 
    for j = 1:boot_trials
        team_boot_idx = randi(num_scores,num_scores,1);
        team_boot_avg(j,i) = mean(team_scores(team_boot_idx));
        team_boot_std(j,i) = std(team_scores(team_boot_idx));
    end
end
toc
team_avg_avg=mean(team_boot_avg,1);
%% Plot figure

% means
figure; hold on;
[N_avg,edges_avg]=histcounts(all_boot_avg,'Normalization','pdf');
cent_avg = (edges_avg(1:end-1)+edges_avg(2:end))/2;
plot(cent_avg,N_avg,'k');

for i = 1:num_teams
    clear N_avg edges_avg
    [N_avg,edges_avg]=histcounts(team_boot_avg(:,i),'Normalization','pdf');
    cent_avg = (edges_avg(1:end-1)+edges_avg(2:end))/2;
    plot(cent_avg,N_avg);
    text(team_avg_avg(i),max(N_avg),team_list(i));
end

legend([ 'league avg' team_list']);

%%
disp(['Mean = ' num2str(mean(boot_avg)) ' ' char(177) ' ' num2str(std(boot_avg))]); 
disp(['Stdev = ' num2str(mean(boot_std)) ' ' char(177) ' ' num2str(std(boot_std))]);
%%
figure;
[N_avg,edges_avg]=histcounts(all_boot_avg,'Normalization','pdf');
cent_avg = (edges_avg(1:end-1)+edges_avg(2:end))/2;
plot(cent_avg,N_avg,'k');

%%
figure;
[N_std,edges_std]=histcounts(boot_std,'Normalization','pdf');
cent_std = (edges_std(1:end-1)+edges_std(2:end))/2;
plot(cent_std,N_std,'k');
