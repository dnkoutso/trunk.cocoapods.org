require 'token'

require 'app/models/owner'

module Pod
  module TrunkApp
    class Session < Sequel::Model
      DEFAULT_TOKEN_LENGTH = 32 # characters
      DEFAULT_VERIFICATION_TOKEN_LENGTH = 8 # characters
      DEFAULT_VALIDITY_LENGTH = 128 # days

      self.dataset = :sessions
      plugin :timestamps
      plugin :after_initialize

      many_to_one :owner, :class => 'Pod::TrunkApp::Owner'

      attr_accessor :token_length
      attr_reader :valid_for

      subset(:valid) { valid_until > Time.now }
      subset(:verified, :verified => true)

      def after_initialize
        super
        set_defaults
      end

      def valid_for=(duration_in_days)
        @valid_for = duration_in_days
        self.valid_until = Time.now + duration_in_days.days
      end

      def to_yaml
        { 'created_at' => created_at, 'valid_until' => valid_until, 'token' => token, 'verified' => verified }.to_yaml
      end

      def self.with_token(token, verified_only = true)
        return if token.nil?
        dataset = valid
        dataset = dataset.verified if verified_only
        dataset.where(:token => token).first
      end

      private

      def set_defaults
        if new?
          self.valid_for ||= DEFAULT_VALIDITY_LENGTH
          self.token_length ||= DEFAULT_TOKEN_LENGTH
          set_tokens
        end
      end

      def set_tokens
        self.token = Token.generate(:length => token_length)
        self.verification_token = Token.generate(:length => DEFAULT_VERIFICATION_TOKEN_LENGTH)
      end
    end
  end
end
