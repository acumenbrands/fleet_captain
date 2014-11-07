namespace :fleet_captain do
  desc 'Start a deployment, make sure server(s) ready.'
  task :starting do
    invoke 'docker:start'
  end

  desc 'Started'
  task :started do
  end

  desc 'Build Docker Container'
  task :building do
    # retag the last release as "previous"
    invoke 'docker:retag'
    # tag the current release as 'deploy_tag'
    invoke 'docker:build'
    invoke 'elastic_beanstalk:build'
  end

  desc 'Built docker Container'
  task :built do
  end

  desc 'Update server(s) by setting up a new release.'
  task :updating do
    # push the current relase to docker hub
    invoke 'docker:push'
    # get the beanstalk to pick up the new container 
    invoke 'elastic_beanstalk:kick'
  end

  desc 'Updated'
  task :updated do
    # inform the user
  end

  desc 'Revert server(s) to previous release.'
  task :reverting do
    # get the previously deployed tag from elastic beanstalk
    invoke 'elastic_beanstalk:deploy_tag', previous
  end

  desc 'Reverted'
  task :reverted do
    #inform the user
  end

  desc 'Publish the release.'
  task :publishing do
    invoke 'elastic_beanstalk:deploy_tag', the_revision_of_the_current_commit
  end

  desc 'Published'
  task :published do
    #inform the user
  end

  desc 'Finish the deployment, clean up server(s).'
  task :finishing do
    # remove the EB Zip file
    invoke 'docker:clean_beanstalk'
  end

  desc 'Finish the rollback, clean up server(s).'
  task :finishing_rollback do
    # inform the user
  end

  desc 'Finished'
  task :finished do
    #inform the user
  end

  desc 'Rollback to previous release.'
  task :rollback do
    %w{ starting started
        reverting reverted
        publishing published
        finishing_rollback finished }.each do |task|
      invoke "deploy:#{task}"
    end
  end

  desc 'Deploy a new release using docker.'
  task :deploy do
    %w{ starting started
        building built
        updating updated
        publishing published
        finishing finished }.each do |task|
      invoke "fleet_captain:#{task}"
    end
  end
end

desc 'Deploy a new release with docker.'
task :deploy do
  invoke "fleet_captain:deploy"
end
