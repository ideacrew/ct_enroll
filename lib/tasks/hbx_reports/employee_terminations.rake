require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employee terminations by employer profile and date range"
    task :employee_terminations => :environment do

      census_employees = CensusEmployee.unscoped.terminated.where(:employment_terminated_on.gte => (date_start = Date.new(2015,10,1)))

      field_names  = %w(
          employee_name employee_hbx_id employer_legal_name employer_hbx_id date_of_hire date_added_to_roster employment_status date_of_termination date_terminated_on_roster
        )

      processed_count = 0

      time_stamp = Time.now.strftime("%Y%m%d_%H%M%S")
      file_name = File.expand_path("#{Rails.root}/public/employee_terminations_#{time_stamp}.csv")

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        census_employees.each do |census_employee|
          employee_name             = census_employee.full_name
          employee_hbx_id           = census_employee.try(:employee_role).try(:person).try(:hbx_id)
          employer_legal_name       = census_employee.employer_profile.organization.legal_name
          employer_hbx_id           = census_employee.try(:employer_profile).try(:hbx_id)
          date_of_hire              = census_employee.hired_on
          date_added_to_roster      = census_employee.created_at
          employment_status         = census_employee.aasm_state
          date_of_termination       = census_employee.employment_terminated_on
          date_terminated_on_roster = census_employee.coverage_terminated_on

          # Only include ERs active on the HBX
          active_states = %w(registered eligible binder_paid enrolled suspended)

          if active_states.include? census_employee.employer_profile.aasm_state
            csv << field_names.map do |field_name|
              if eval(field_name).to_s.blank? || field_name != "ssn"
                eval("#{field_name}")
              elsif field_name == "ssn"
                '="' + eval(field_name) + '"'
              end
            end

            processed_count += 1
          end
        end
      end

      # pubber = Publishers::Legacy::EmployeeTerminationReportPublisher.new
      # pubber.publish URI.join("file://", file_name)

      puts "For period #{date_start} - #{Date.today}, #{processed_count} employee terminations output to file: #{file_name}"
    end
  end
end
