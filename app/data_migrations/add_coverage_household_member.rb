require File.join(Rails.root, "lib/mongoid_migration_task")

class AddCoverageHouseholdMember < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['hbx_id'])
    family_member_id = ENV['family_member_id'].to_s
    if person.size != 1
      raise "Invalid Hbx Id"
    end
    family_member = person.first.primary_family.family_members.where(id: family_member_id).first
    ch = person.first.primary_family.active_household.coverage_households.where(:is_immediate_family => true).first
    chm = ch.add_coverage_household_member(family_member)
    chm.save if chm.present?
    ch.save
    puts "Family member added to coverage household successfully" unless Rails.env.test?
  end
end
