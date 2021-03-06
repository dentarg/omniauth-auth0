require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Auth0 < OmniAuth::Strategies::OAuth2
      PASSTHROUGHS = %w[
        connection
        redirect_uri
      ]

      option :name, "auth0"
      option :namespace, nil
      option :provider_ignores_state, true

      args [:client_id, :client_secret, :namespace, :provider_ignores_state]

      def initialize(app, *args, &block)
        super
        @options.provider_ignores_state = args[3] unless args[3].nil?

        @options.client_options.site          = "https://#{options[:namespace]}"
        @options.client_options.authorize_url = "https://#{options[:namespace]}/authorize"
        @options.client_options.token_url     = "https://#{options[:namespace]}/oauth/token"
        @options.client_options.userinfo_url  = "https://#{options[:namespace]}/userinfo"
      end

      def authorize_params
        super.tap do |param|
          PASSTHROUGHS.each do |p|
            param[p.to_sym] = request.params[p] if request.params[p]
          end
        end
      end

      credentials do
        hash = {'token' => access_token.token}
        # hash.merge!('refresh_token' => access_token.refresh_token) if access_token.expires? && access_token.refresh_token
        # hash.merge!('expires_at' => access_token.expires_at) if access_token.expires?
        hash.merge!('expires' => true)
        if access_token.params
          hash.merge!('id_token' => access_token.params['id_token'])
          hash.merge!('token_type' => access_token.params['token_type'])
        end
        hash
      end

      uid { raw_info["user_id"] }

      extra do
        { :raw_info => raw_info }
      end

      info do
        {
          :name => raw_info["name"],
          :email => raw_info["email"],
          :nickname => raw_info["nickname"],
          :first_name => raw_info["given_name"],
          :last_name => raw_info["family_name"],
          :location => raw_info["locale"],
          :image => raw_info["picture"]
        }
      end

      def raw_info
        @raw_info ||= access_token.get(options.client_options.userinfo_url).parsed
      end
    end
  end
end