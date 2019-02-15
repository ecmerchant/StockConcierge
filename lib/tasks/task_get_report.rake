namespace :task_get_report do
  desc "レポートの取得"
  task :operate, ['user'] => :environment do |task, args|
    user = args[:user]
    GetReportJob.perform_later(user)
  end
end
