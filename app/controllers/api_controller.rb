require 'app/controllers/app_controller'

require 'app/models/owner'
require 'app/models/pod'
require 'app/models/session'
require 'app/models/specification_wrapper'

module Pod
  module TrunkApp
    class APIController < AppController
      before do
        content_type 'text/yaml'
        unless request.media_type == 'text/yaml'
          error 415, "Unable to accept input with Content-Type `#{request.media_type}`, must be `text/yaml`.".to_yaml
        end
      end

      post '/pods' do
        specification = SpecificationWrapper.from_yaml(request.body.read)

        if specification.nil?
          error 400, 'Unable to load a Pod Specification from the provided input.'.to_yaml
        end

        unless specification.valid?
          error 422, specification.validation_errors.to_yaml
        end

        resource_url = url("/pods/#{specification.name}/versions/#{specification.version}")

        # Always set the location of the resource, even when the pod version already exists.
        headers 'Location' => resource_url

        pod = Pod.find_or_create(:name => specification.name)
        # TODO use a unique index in the DB for this instead?
        if pod.versions_dataset.where(:name => specification.version).first
          error 409, "Unable to accept duplicate entry for: #{specification}".to_yaml
        end
        version = pod.add_version(:name => specification.version, :url => resource_url)
        version.add_submission_job(:specification_data => specification.to_yaml)
        halt 202
      end

      get '/pods/:name/versions/:version' do
        if pod = Pod.find(:name => params[:name])
          if version = pod.versions_dataset.where(:name => params[:version]).first
            job = version.submission_jobs.last
            messages = job.log_messages.map do |log_message|
              { log_message.created_at => log_message.message }
            end
            # Would have preferred to use 102 instead of 202, but Ruby’s Net::HTTP apperantly does
            # not read the body of a 102 and so the client might have problems reporting status.
            status = job.failed? ? 404 : (version.published? ? 200 : 202)
            halt(status, messages.to_yaml)
          end
        end
        error 404
      end
    end
  end
end
