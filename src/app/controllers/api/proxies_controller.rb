#
# Copyright 2011 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

class Api::ProxiesController < Api::ApiController
  before_filter :proxy_request_path, :proxy_request_body
  before_filter :authorize

  def rules
    proxy_test = lambda {
      route, match, params = Rails.application.routes.set.recognize(request)
      # route names are defined in routes.rb (:as => :name)
      case route.name
      when :api_proxy_owner_pools_path
        find_optional_organization
        if params[:consumer]
          (User.consumer? or @organization.readable?) and current_user.uuid == params[:consumer]
        else
          (User.consumer? or @organization.readable?)
        end
      when :api_proxy_owner_servicelevels_path
        find_optional_organization
        (User.consumer? or @organization.readable?)
      when :api_proxy_consumer_certificates_path, :api_proxy_consumer_releases_path, :api_proxy_certificate_serials_path,
           :api_proxy_consumer_entitlements_path, :api_proxy_consumer_entitlements_post_path, :api_proxy_consumer_entitlements_delete_path,
           :api_proxy_consumer_dryrun_path, :api_proxy_consumer_owners_path, :api_proxy_consumer_deletionrecord_delete_path
        User.consumer? and current_user.uuid == params[:id]
      when :api_proxy_consumer_certificates_delete_path
        User.consumer? and current_user.uuid == params[:consumer_id]
      when :api_proxy_pools_path
        User.consumer? and current_user.uuid == params[:consumer]
      when :api_proxy_entitlements_path
        User.consumer? # query is restricted in Candlepin
      when :api_proxy_subscriptions_post_path
        User.consumer? and current_user.uuid == params[:consumer_uuid]
      else
        Rails.logger.warn "Unknown proxy route #{request.method} #{request.fullpath}, access denied"
        # give the proxy route name using :as parameter and implement rule check here
        false
      end
    }
    {
      :get    => proxy_test,
      :post   => proxy_test,
      :put    => proxy_test,
      :delete => proxy_test
    }
  end

  rescue_from RestClient::Exception do |e|
    Rails.logger.error pp_exception(e)
    if request_from_katello_cli?
      render :json => {:errors => [e.http_body]}, :status => e.http_code
    else
      render :text => e.http_body, :status => e.http_code
    end
  end

  def proxy_request_path
    @request_path = drop_api_namespace(@_request.fullpath)
  end

  def proxy_request_body
    @request_body = @_request.body
  end

  def drop_api_namespace(original_request_path)
    prefix = "#{ENV["RAILS_RELATIVE_URL_ROOT"]}/api"
    original_request_path.gsub(prefix, '')
  end

end
