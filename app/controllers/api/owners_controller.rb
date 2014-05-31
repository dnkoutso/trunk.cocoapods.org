require 'app/controllers/api_controller'
require 'app/models/owner'

module Pod
  module TrunkApp
    class OwnersController < APIController
      get '/:email', :requires_owner => false do
        if owner = Owner.find_by_email(params[:email])
          json_message(200, owner.public_attributes)
        end
        json_error(404, 'No owner found with the specified email.')
      end
    end
  end
end
