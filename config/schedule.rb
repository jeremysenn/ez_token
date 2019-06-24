# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :output, "#{path}/log/cron.log"
set :environment, 'development'

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every :reboot do
  # CentOS VM
  job_type :application, "cd /usr/local/Ruby/ez_token && :task :output"
  # Mac Mini
#  job_type :application, "cd /Users/jeremy/Ruby/ez_token && :task :output"
  
#  application "rails server -p 3003" # Start application server
  application "bundle exec rails server -b 0.0.0.0 -p 3003 -e development"

  application "bundle exec sidekiq -c 5" # Start background workers
end
