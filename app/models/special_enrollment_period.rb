class SpecialEnrollmentPeriod
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include TimeHelper
  include Acapi::Notifiers
  extend Acapi::Notifiers
  include Concerns::Observable
  include ModelEvents::SpecialEnrollmentPeriod

  after_save :notify_on_save

  embedded_in :family
  embeds_many :comments, as: :commentable, cascade_callbacks: true

  # for employee gaining medicare qle
  attr_accessor :selected_effective_on

  field :qualifying_life_event_kind_id, type: BSON::ObjectId

  # Date Qualifying Life Event occurred
  field :qle_on, type: Date

  # Comments made by admin_comment
  # field :admin_comment, type: String  #Removing this, using polymorphic comment association.

  # Date coverage starts
  field :effective_on_kind, type: String

  # Date coverage takes effect
  field :effective_on, type: Date

  # Timestamp when SEP was reported to HBX
  field :submitted_at, type: DateTime

  field :title, type: String

  # Date Enrollment Period starts
  field :start_on, type: Date

  # Date Enrollment Period ends
  field :end_on, type: Date

  # QLE Answer to specific question
  field :qle_answer, type: String

  # Next Possible Event Date
  field :next_poss_effective_date, type: Date

  # Date Option 1
  field :option1_date, type: Date

  # Date Option 2
  field :option2_date, type: Date

  # Date Option 3
  field :option3_date, type: Date

  # Date Options Array
  field :optional_effective_on, type: Array, default: []

  # CSL#
  field :csl_num, type: String

  # MARKET KIND
  field :market_kind, type:String

  # ADMIN FLAG
  field :admin_flag, type:Boolean

  validate :optional_effective_on_dates_within_range, :next_poss_effective_date_within_range, on: :create

  validates :csl_num,
    length: { minimum: 5, maximum: 10, message: "should be a minimum of 5 digits" },
    allow_blank: true,
    numericality: true

  validates_presence_of :start_on, :end_on, :message => "is invalid"
  validates_presence_of :qualifying_life_event_kind_id, :qle_on, :effective_on_kind, :submitted_at
  validate :end_date_follows_start_date, :is_eligible?

  scope :shop_market,         ->{ where(:qualifying_life_event_kind_id.in => QualifyingLifeEventKind.shop_market_events.map(&:id) + QualifyingLifeEventKind.shop_market_non_self_attested_events.map(&:id) ) }
  scope :individual_market,   ->{ where(:qualifying_life_event_kind_id.in => QualifyingLifeEventKind.individual_market_events.map(&:id) + QualifyingLifeEventKind.individual_market_non_self_attested_events.map(&:id)) }

  after_save :notify_on_save

  after_initialize :set_submitted_at

  def start_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:start_on, new_date.beginning_of_day)
  end

  def end_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:end_on, new_date.end_of_day)
  end

  def contains?(compare_date)
    return false unless start_on.present? && end_on.present?
    (start_on <= compare_date) && (compare_date <= end_on)
  end

  def qualifying_life_event_kind=(new_qualifying_life_event_kind)
    raise ArgumentError.new("expected QualifyingLifeEventKind") unless new_qualifying_life_event_kind.is_a?(QualifyingLifeEventKind)
    self.qualifying_life_event_kind_id = new_qualifying_life_event_kind._id
    self.title = new_qualifying_life_event_kind.title
    @qualifying_life_event_kind = new_qualifying_life_event_kind
    set_sep_dates
    @qualifying_life_event_kind
  end

  def qualifying_life_event_kind
    return @qualifying_life_event_kind if defined? @qualifying_life_event_kind
    if self.qualifying_life_event_kind_id.present?
      @qualifying_life_event_kind = QualifyingLifeEventKind.find(self.qualifying_life_event_kind_id)
    end
  end

  def qle_on=(new_qle_date)
    write_attribute(:qle_on, new_qle_date)
    set_sep_dates
    qle_on
  end

  def effective_on_kind=(new_effective_on_kind)
    write_attribute(:effective_on_kind, new_effective_on_kind)
    set_sep_dates
    effective_on_kind
  end

  def is_active?
    return false if start_on.blank? || end_on.blank?
    (start_on..end_on).include?(TimeKeeper.date_of_record)
  end

  def is_shop?
    return false if qualifying_life_event_kind.blank?
    qualifying_life_event_kind.market_kind == "shop"
  end

  def duration_in_days
    return nil if start_on.blank? || end_on.blank?
    end_on - start_on
  end

  def self.find(id)
    family = Family.where("special_enrollment_periods._id" => BSON::ObjectId.from_string(id)).first
    family.special_enrollment_periods.detect() { |sep| sep._id.to_s == id.to_s } unless family.blank?
  end

private
  def next_poss_effective_date_within_range
    return if next_poss_effective_date.blank?
    return true unless (is_shop? && family.has_primary_active_employee?)
    min_date = sep_optional_date family, 'min', qualifying_life_event_kind.market_kind
    max_date = sep_optional_date family, 'max', qualifying_life_event_kind.market_kind
    if !(min_date || max_date)
      errors.add(:next_poss_effective_date, "No active plan years present") if !(errors.messages.values.flatten.include?("No active plan years present"))
    elsif !next_poss_effective_date.between?(min_date, max_date)
      errors.add(:next_poss_effective_date, "out of range.")
    end
  end

  def optional_effective_on_dates_within_range
    return true unless (is_shop? && family.has_primary_active_employee?)
    optional_effective_on.each_with_index do |date_option, index|
      date_option = Date.strptime(date_option, "%m/%d/%Y")
      min_date = sep_optional_date family, 'min', qualifying_life_event_kind.market_kind
      max_date = sep_optional_date family, 'max', qualifying_life_event_kind.market_kind
      if !(min_date || max_date)
        errors.add(:optional_effective_on, "No active plan years present") if !(errors.messages.values.flatten.include?("No active plan years present"))
      elsif !date_option.between?(min_date, max_date)
        errors.add(:optional_effective_on, "Date #{index+1} option out of range.")
      end
    end
  end

  def set_sep_dates
    return unless @qualifying_life_event_kind.present? && qle_on.present? && effective_on_kind.present?
    set_submitted_at
    set_date_period
    set_effective_on
  end

  def set_submitted_at
    self.submitted_at ||= TimeKeeper.datetime_of_record
  end

  def set_date_period
    self.start_on = qle_on - @qualifying_life_event_kind.pre_event_sep_in_days.days
    self.end_on   = qle_on + @qualifying_life_event_kind.post_event_sep_in_days.days

    # Use end_on date as boundary guard for lapsed SEPs
    @reference_date = [submitted_at.to_date, end_on].min
    @earliest_effective_date = self.is_shop? ? qle_on : [@reference_date, qle_on].max
    start_on..end_on
  end

  def set_effective_on
    return unless self.start_on.present? && self.qualifying_life_event_kind.present?
    self.effective_on = case effective_on_kind
    when "date_of_event"
      qle_on
    when "exact_date"
      qle_on
    when "first_of_month"
      first_of_month_effective_date
    when "first_of_next_month"
      first_of_next_month_effective_date
    when "fixed_first_of_next_month"
      fixed_first_of_next_month_effective_date
    end
    validate_and_set_effective_on if is_shop?
  end

  def validate_and_set_effective_on
    person = self.family.primary_applicant.person if self.family
    employee_role = person.active_employee_roles.first if person.present?
    employer_profile = employee_role.employer_profile if employee_role.present?
    if employee_role && employer_profile.plan_years.published_plan_years_by_date(effective_on).blank? && employer_profile.show_plan_year.present? && employee_role.employer_profile.find_plan_year_by_effective_date(self.effective_on).blank?
      plan_year_start_on = employer_profile.show_plan_year.start_on
      self.effective_on = plan_year_start_on if effective_on < plan_year_start_on
    end
  end


  def first_of_month_effective_date
    if @reference_date.day <= Setting.individual_market_monthly_enrollment_due_on
      # if submitted_at.day <= Settings.aca.individual_market.monthly_enrollment_due_on
      @earliest_effective_date.end_of_month + 1.day
    else
      @earliest_effective_date.next_month.end_of_month + 1.day
    end
  end

  def first_of_next_month_effective_date
    if qualifying_life_event_kind.is_dependent_loss_of_coverage?
      qualifying_life_event_kind.employee_gaining_medicare(qle_on, selected_effective_on)
    elsif qualifying_life_event_kind.is_moved_to_dc?
      calculate_effective_on_for_moved_qle
    elsif is_eligible_to_get_effective_on_based_plan_shopping?
      TimeKeeper.date_of_record.next_month.beginning_of_month
    else
      is_shop? ? first_of_next_month_effective_date_for_shop : first_of_next_month_effective_date_for_individual
    end
  end

  def is_eligible_to_get_effective_on_based_plan_shopping?
    qualifying_life_event_kind.is_loss_of_other_coverage? && !is_shop? && qle_on < TimeKeeper.date_of_record
  end

  def first_of_next_month_effective_date_for_individual
    @earliest_effective_date.end_of_month + 1.day
  end

  def first_of_next_month_effective_date_for_shop
    if @earliest_effective_date == @earliest_effective_date.beginning_of_month
      @earliest_effective_date
    else
      @earliest_effective_date.end_of_month + 1.day
    end
  end

  def fixed_first_of_next_month_effective_date
    qle_on.end_of_month + 1.day
  end

  def calculate_effective_on_for_moved_qle
    if qle_on <= TimeKeeper.date_of_record
      TimeKeeper.date_of_record.end_of_month + 1.day
    else
      if qle_on == qle_on.beginning_of_month
        qle_on.beginning_of_month
      else
        qle_on.end_of_month + 1.day
      end
    end
  end


  ## TODO - Validation for SHOP, EE SEP cannot be granted unless effective_on >= initial coverage effective on, except for
  ## HBX_Admin override


  def is_eligible?
    return true unless is_active?
    return true unless is_shop?

    person = family.primary_applicant.person
    person.active_employee_roles.any? do |employee_role|
      eligible_date = employee_role.census_employee.earliest_eligible_date 
      eligible_date <= TimeKeeper.date_of_record
    end
  end

  def end_date_follows_start_date
    return false unless start_on.present? && end_on.present?
    # Passes validation if end_on == start_date
    errors.add(:end_on, "end_on cannot preceed start_on date") if self.end_on < self.start_on
  end

end
