# frozen_string_literal: true

require "decidim/core"
require "csv"

# USAGE : bundle exec rake decidim:users:import my.organizaton.host.com admin@example.org ~/path/to/users.csv
# SEND INVITATION :
# Decidim::User.where.not(invitation_token: nil).where(invitation_sent_at: nil).each do |u|
#   u.deliver_invitation
# end
#


namespace :decidim do
  Rails.logger = Logger.new(STDOUT)

  namespace :users do
    desc "Import users from CSV"
    task import: :environment do |task|
      ARGV.each { |a| task a.to_sym do ; end }
      @ROOT = task.application.original_dir
      @TYPES = {}

      if Decidim::Organization.exists?(:host => ARGV[1])
        @organization = Decidim::Organization.find_by(:host => ARGV[1])
      else
        Rails.logger.error "Could not find any organization with host \"#{ARGV[1]}\""
        exit 1
      end

      if Decidim::User.exists?(:email => ARGV[2], :admin => true, :decidim_organization_id => @organization.id)
        @invited_by = Decidim::User.find_by(:email => ARGV[2], :admin => true)
      else
        Rails.logger.error "Could not find an administrator with email \"#{ARGV[2]}\""
        exit 1
      end

      import_users

      Rails.logger.close
      exit
    end
  end
end


def path_for(path)
  if path.start_with?("/")
    path
  else
    @ROOT + "/" + path
  end
end

def check_file(path, ext = nil)
  check = true

  if path.blank?
    Rails.logger.error "File path is blank"
    check = false
  end

  unless File.exist?(path_for(path))
    Rails.logger.error "File does not exist or is unreachable"
    check = false
  end

  if ext.present? && File.extname(path) != ".#{ext.to_s}"
    Rails.logger.error "File extension does not match \"#{ext.to_s}\""
    check = false
  end

  return check
end

def import_users

  if check_file(ARGV[3], :csv)
    @csv = CSV.read(path_for(ARGV[3]), col_sep: ';', headers: true, skip_blanks: true, liberal_parsing: true)
  else
    Rails.logger.error "Could not load CSV file \"#{ARGV[3]}\""
    exit 1
  end

  @errors = []

  @csv.each do |row|
    unless Decidim::User.exists?(:email => row["email"].downcase, :decidim_organization_id => @organization.id)
      begin
        new_user = Decidim::User.new(
          email: row["email"].downcase,
          name: row["name"],
          nickname: Decidim::UserBaseEntity.nicknamize(row["name"], organization: @organization),
          organization: @organization,
          admin: false,
          roles: [],
          locale: "fr",
          email_on_notification: false,
          newsletter_notifications_at: nil,
          extended_data: { "source": File.basename(ARGV[3], ".csv") }
        )
        new_user.invite!(@invited_by) do |u|
          u.skip_invitation = true
        end
      rescue ActiveRecord::RecordNotUnique
        @errors.push(row)
        next
      end
    end
  end

  CSV.open(@ROOT + "/tmp/#{File.basename(ARGV[3], ".csv")}_errors.csv", mode = "w+", col_sep: ';', headers: true, skip_blanks: true, liberal_parsing: true) do |file|
    file << @csv.headers
    @errors.each do |row|
      file << row.to_h.values
    end
  end

end
