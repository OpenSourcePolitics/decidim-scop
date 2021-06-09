# frozen_string_literal: true
require "active_support/concern"

module UserExtend
  extend ActiveSupport::Concern

  included do
    # devise :password_expirable, :secure_validatable, :password_archivable
    devise :secure_validatable, :password_archivable
  end
end

Decidim::User.send(:include, UserExtend)
