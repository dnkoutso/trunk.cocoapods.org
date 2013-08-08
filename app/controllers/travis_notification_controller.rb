require 'sinatra/base'
require 'cocoapods-core'

require 'config/init'
require 'app/models/submission_job'
require 'app/models/travis'

module Pod
  module TrunkApp
    class TravisNotificationController < Sinatra::Base
      configure do
        set :root, ROOT
      end

      configure :development, :production do
        enable :logging
      end

      before do
        error 415 unless request.media_type == 'application/x-www-form-urlencoded'
        error 401 unless Travis.authorized_webhook_notification?(env['HTTP_AUTHORIZATION'])
      end

      post '/builds' do
        travis = Travis.new(JSON.parse(request.POST['payload']))
        if travis.pull_request? && job = SubmissionJob.find(:pull_request_number => travis.pull_request_number)
          if travis.pending?
            job.update(:travis_build_url => travis.build_url)
          else
            job.update(:travis_build_success => travis.build_success?, :travis_build_url => travis.build_url)
          end
          halt 204
        end
        halt 200
      end
    end
  end
end
