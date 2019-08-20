# name: anon-ip
# version: 0.1.0
 
enabled_site_setting :anon_ip_enabled
 
after_initialize do
  module ::AnonIp
    def self.plugin_name
      'anon-ip'
    end
 
    class Engine < ::Rails::Engine
      engine_name ::AnonIp.plugin_name
      isolate_namespace AnonIp
    end
  end
 
  require_dependency "application_controller"
 
  class AnonIp::ApiController < ::ApplicationController
    requires_plugin AnonIp.plugin_name
    before_action :fetch_user
 
    def anonymize
      guardian.ensure_can_anonymize_user!(@user)
      if user = UserAnonymizer.new(@user, current_user, anonymize_ip: '0.0.0.0').make_anonymous
        render json: success_json.merge(username: user.username)
      else
        render json: failed_json.merge(user: AdminDetailedUserSerializer.new(user, root: false).as_json)
      end
    end
 
    def fetch_user
      @user = User.find_by(id: params[:user_id])
      raise Discourse::NotFound unless @user
    end
  end
 
  AnonIp::Engine.routes.draw do
    post ":user_id/anonymize" => "api#anonymize"
  end
 
  Discourse::Application.routes.append do
    mount ::AnonIp::Engine, at: "admin/plugins/anonymizer", constraints: AdminConstraint.new
  end
end