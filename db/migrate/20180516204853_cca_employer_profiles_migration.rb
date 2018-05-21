class CcaEmployerProfilesMigration < Mongoid::Migration
  def self.up

    if Settings.site.key.to_s == "cca"
      site_key = "cca"

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/employer_profiles_migration_status_#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
      field_names = %w( organization_id benefit_sponsor_organization_id status)

      logger = Logger.new("#{Rails.root}/log/employer_profiles_migration_data.log") unless Rails.env.test?
      logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      CSV.open(file_name, 'w') do |csv|
        csv << field_names

        #build and create GeneralOrganization and its profiles
        status = create_profile(site_key, csv, logger)

        if status
          puts "" unless Rails.env.test?
          puts "Check employer_profiles_migration_data logs & employer_profiles_migration_status csv for additional information." unless Rails.env.test?
        else
          puts "" unless Rails.env.test?
          puts "Script execution failed" unless Rails.env.test?
        end
      end
      logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
  end

  private

  def self.create_profile(site_key, csv, logger)

    #find or build site
    sites = find_site(site_key)
    return false unless sites.present?
    site = sites.first

    #get main app organizations for migration
    old_organizations = Organization.unscoped.exists(:employer_profile => true)

    #counters
    total_organizations = old_organizations.count
    existing_organization = 0
    success =0
    failed = 0
    limit_count = 1000

    say_with_time("Time taken to migrate organizations") do
      old_organizations.batch_size(limit_count).no_timeout.all.each do |old_org|
        begin
          existing_new_organizations = find_new_organization(old_org)
          if existing_new_organizations.count == 0
            @old_profile = old_org.employer_profile

            json_data = @old_profile.to_json(:except => [:_id, :contact_method, :employer_attestation, :broker_agency_accounts, :general_agency_accounts, :employer_profile_account, :plan_years, :updated_by_id, :workflow_state_transitions, :inbox, :documents])
            old_profile_params = JSON.parse(json_data)

            @new_profile = initialize_new_profile(old_org, old_profile_params)
            new_organization = initialize_new_organization(old_org, site)

            benefit_sponsorship = @new_profile.add_benefit_sponsorship
            benefit_sponsorship.source_kind = @old_profile.profile_source.to_sym
            benefit_sponsorship.save!

            raise Exception unless new_organization.valid?
            new_organization.save!

            #employer staff roles migration
            person_records_with_old_staff_roles = find_staff_roles
            link_existing_staff_roles_to_new_profile(person_records_with_old_staff_roles)

            #employee roles migration
            person_records_with_old_employee_roles = find_employee_roles
            link_existing_employee_roles_to_new_profile(person_records_with_old_employee_roles)

            #census employees migration
            census_employees_with_old_id = find_census_employees
            link_existing_census_employees_to_new_profile(census_employees_with_old_id)

            print '.' unless Rails.env.test?
            csv << [old_org.id, new_organization.id, "Migration Success"]
            success = success + 1
          else
            existing_organization = existing_organization + 1
            csv << [old_org.id, existing_new_organizations.first.id, "Already Migrated to new model, no action taken"]
          end
        rescue Exception => e
          failed = failed + 1
          print 'F' unless Rails.env.test?
          csv << [old_org.id, "0", "Migration Failed"]
          logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id},
          validation_errors:
          organization - #{new_organization.errors.messages}
          profile - #{@new_profile.errors.messages},
          #{e.inspect}" unless Rails.env.test?
        end
      end
    end
    logger.info " Total #{total_organizations} old organizations for type: employer profile" unless Rails.env.test?
    logger.info " #{failed} organizations failed to migrated to new DB at this point." unless Rails.env.test?
    logger.info " #{success} organizations migrated to new DB at this point." unless Rails.env.test?
    logger.info " #{existing_organization} old organizations are already present in new DB." unless Rails.env.test?
    return true
  end

  def self.find_new_organization(old_org)
    BenefitSponsors::Organizations::Organization.where(hbx_id: old_org.hbx_id)
  end

  def self.initialize_new_profile(old_org, old_profile_params)
    new_profile = BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new(old_profile_params)

    if @old_profile.contact_method == "Only Electronic communications"
      new_profile.contact_method = :electronic_only
    elsif @old_profile.contact_method == "Paper and Electronic communications"
      new_profile.contact_method = :paper_and_electronic
    elsif @old_profile.contact_method == "Only Paper communication"
      new_profile.contact_method = :paper_only
    end

    build_inbox_messages(new_profile)
    build_documents(old_org, new_profile)
    build_office_locations(old_org, new_profile)
    return new_profile
  end

  def self.build_inbox_messages(new_profile)
    @old_profile.inbox.messages.each do |message|
      new_profile.inbox.messages.new(message.attributes.except("_id"))
    end
  end

  def self.build_documents(old_org, new_profile)

    @old_profile.documents.each do |document|
      doc = new_profile.documents.new(document.attributes.except("_id", "_type", "identifier","size"))
      doc.identifier = document.identifier if document.identifier.present?
      doc.save!
    end

    old_org.documents.each do |document|
      doc = new_profile.documents.new(document.attributes.except("_id", "_type", "identifier","size"))
      doc.identifier = document.identifier if document.identifier.present?
      doc.save!
    end
  end

  def self.build_office_locations(old_org, new_profile)
    old_org.office_locations.each do |office_location|
      new_office_location = new_profile.office_locations.new
      new_office_location.is_primary = office_location.is_primary
      address_params = office_location.address.attributes.except("_id") if office_location.address.present?
      phone_params = office_location.phone.attributes.except("_id") if office_location.phone.present?
      new_office_location.address = address_params
      new_office_location.phone = phone_params
    end
  end

  def self.initialize_new_organization(organization, site)
    json_data = organization.to_json(:except => [:_id, :updated_by_id, :issuer_assigned_id, :version, :versions, :employer_profile, :broker_agency_profile, :general_agency_profile, :carrier_profile, :hbx_profile, :office_locations, :is_fake_fein, :is_active, :updated_by, :documents])
    old_org_params = JSON.parse(json_data)
    general_organization = BenefitSponsors::Organizations::GeneralOrganization.new(old_org_params)
    general_organization.entity_kind = @old_profile.entity_kind.to_sym
    general_organization.site = site
    general_organization.profiles << [@new_profile]
    return general_organization
  end

  def self.find_staff_roles
    Person.where(:employer_staff_roles => {
        '$elemMatch' => {employer_profile_id: @old_profile.id}})
  end

  def self.link_existing_staff_roles_to_new_profile(person_records_with_old_staff_roles)
    person_records_with_old_staff_roles.each do |person|
      person.employer_staff_roles.where(employer_profile_id: @old_profile.id).update_all(benefit_sponsor_employer_profile_id: @new_profile.id)
    end
  end

  def self.find_employee_roles
    Person.where(:"employee_roles.employer_profile_id" => @old_profile.id)
  end

  def self.link_existing_employee_roles_to_new_profile(person_records_with_old_employee_roles)
    person_records_with_old_employee_roles.each do |person|
      person.employee_roles.where(employer_profile_id: @old_profile.id).update_all(benefit_sponsors_employer_profile_id: @new_profile.id)
    end
  end

  def self.find_census_employees
    CensusEmployee.where(employer_profile_id: @old_profile.id)
  end

  def self.link_existing_census_employees_to_new_profile(census_employees_with_old_id)
    census_employees_with_old_id.update_all(benefit_sponsors_employer_profile_id: @new_profile.id)
  end

  def self.find_site(site_key)
    BenefitSponsors::Site.all.where(site_key: site_key.to_sym)
  end
end
