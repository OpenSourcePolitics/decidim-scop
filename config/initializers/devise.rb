# frozen_string_literal: true

Devise.setup do |config|
  # ==> Configuration for :validatable
  # Range for password length.
  config.password_length = 12..128

  # ==> Configuration for :invitable
  # The period the generated invitation token is valid, after
  # this period, the invited resource won't be able to accept the invitation.
  # When invite_for is 0 (the default), the invitation won't expire.
  config.invite_for = 15.days
end

NOBSPW.configure do |config|
  config.min_password_length = 12
  config.max_password_length = 128
  config.min_unique_characters = 5
end
