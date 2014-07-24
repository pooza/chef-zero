require 'json'
require 'chef_zero/endpoints/acl_base'

module ChefZero
  module Endpoints
    # /organizations/ORG/<thing>/NAME/_acl/PERM
    # Where thing is:
    # clients, data, containers, cookbooks, environments
    # groups, roles, nodes, users
    # or
    # /organizations/ORG/organization/_acl/PERM
    # or
    # /users/NAME/_acl/PERM
    #
    # Where PERM is create,read,update,delete,grant
    class AclEndpoint < AclBase
      def validate_request(request)
        path = acl_path(request.rest_path[0..-3]) # Strip off _acl/PERM
        perm = request.rest_path[-1]
        if !%w(read create update delete grant).include?(perm)
          raise RestErrorResponse.new(404, "Object not found: #{build_uri(request.base_uri, request.rest_path)}")
        end
        [path, perm]
      end

      def get(request)
        path, perm = validate_request(request)
        if path.size == 4 && path[3] == 'organization' && path[0] == 'organizations'
          # Needs to be 405, but account returns 404
          raise RestErrorResponse.new(404, "Object not found: #{build_uri(request.base_uri, request.rest_path)}")
        end
        acls = DataNormalizer.normalize_acls(get_acls(request, path), request.requestor)
        json_response(200, { perm => acls[perm] })
      end

      def put(request)
        path, perm = validate_request(request)
        acls = JSON.parse(get_data(request, path), :create_additions => false)
        acls[perm] = JSON.parse(request.body, :create_additions => false)[perm]
        set_data(request, path, JSON.pretty_generate(acls))
        json_response(200, {'uri' => "#{build_uri(request.base_uri, request.rest_path)}"})
      end

      # Remove these to get them doing 405 again like they ought to
      def post(request)
        raise RestErrorResponse.new(404, "Method not allowed: POST #{build_uri(request.base_uri, request.rest_path)}")
      end

      def delete(request)
        raise RestErrorResponse.new(404, "Method not allowed: DELETE #{build_uri(request.base_uri, request.rest_path)}")
      end
    end
  end
end
