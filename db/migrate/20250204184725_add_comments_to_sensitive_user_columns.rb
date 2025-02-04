class AddCommentsToSensitiveUserColumns < ActiveRecord::Migration[7.1]
  def change
    safety_assured {
      execute <<-SQL
        COMMENT ON COLUMN rideshare.users.first_name IS 'sensitive_data=true';
        COMMENT ON COLUMN rideshare.users.last_name IS 'sensitive_data=true';
        COMMENT ON COLUMN rideshare.users.email IS 'sensitive_data=true';
        COMMENT ON COLUMN rideshare.users.password_digest IS 'sensitive_data=true';
        COMMENT ON COLUMN rideshare.users.drivers_license_number IS 'sensitive_data=true';
      SQL
    }
  end
end
