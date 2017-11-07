function [current_record, games_back,standings] = calc_records(team_data,num_weeks)
% team data(week_no, team_no) is matrix of weekly scores

%% calculate current records
clear wins
for i = 1:num_weeks
    [Y,I]=sort(team_data(i,:),'ascend');
    [X,I2] = sort(I);
    wins(i,:)=I2 - 1;
end

current_record = sum(wins);
games_back = current_record - max(current_record(:));
[Z1,I3]=sort(current_record,'descend');
[Z2,I4] = sort(I3);
standings=I4;