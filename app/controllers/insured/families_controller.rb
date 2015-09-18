class Insured::FamiliesController < FamiliesController

  before_action :init_qualifying_life_events, only: [:home, :manage_family, :find_sep]
  # layout 'application', :only => :find_sep

  def home
    set_consumer_bookmark_url(family_account_path)
    @hbx_enrollments = @family.enrolled_hbx_enrollments || []
    @employee_role = @person.employee_roles.try(:first)

    respond_to do |format|
      format.html
    end
  end

  def manage_family
    @family_members = @family.active_family_members
    # @employee_role = @person.employee_roles.first

    respond_to do |format|
      format.html
    end
  end

  def find_sep
    set_consumer_bookmark_url(family_account_path)
    @hbx_enrollment_id = params[:hbx_enrollment_id]
    @change_plan = params[:change_plan]

    render :layout => 'application' 
  end

  def record_sep
    if params[:qle_id].present?
      qle = QualifyingLifeEventKind.find(params[:qle_id])
      special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: params[:effective_on_kind])
      special_enrollment_period.selected_effective_on = Date.strptime(params[:effective_on_date], "%m/%d/%Y") if params[:effective_on_date].present?
      special_enrollment_period.qle_on = Date.strptime(params[:qle_date], "%m/%d/%Y")
      special_enrollment_period.qualifying_life_event_kind = qle
      special_enrollment_period.save
    end

    action_params = {person_id: @person.id, consumer_role_id: @person.consumer_role.try(:id), enrollment_kind: 'sep'}
    if @family.enrolled_hbx_enrollments.any?
      action_params.merge!({change_plan: "change_plan"})
    end

    redirect_to new_insured_group_selection_path(action_params)
  end

  def personal
    @family_members = @family.active_family_members
    respond_to do |format|
      format.html
    end
  end

  def inbox
    @folder = params[:folder] || 'Inbox'
    @sent_box = false
  end
  
  def documents_index

  end

  def document_upload
    @consumer_wrapper = Forms::ConsumerRole.new(@person.consumer_role)
  end

  def check_qle_date
    @qle_date = Date.strptime(params[:date_val], "%m/%d/%Y")
    start_date = TimeKeeper.date_of_record - 30.days
    end_date = TimeKeeper.date_of_record + 30.days
    if params[:qle_id].present?
      @qle = QualifyingLifeEventKind.find(params[:qle_id]) 
      start_date = TimeKeeper.date_of_record - @qle.post_event_sep_in_days.try(:days)
      end_date = TimeKeeper.date_of_record + @qle.pre_event_sep_in_days.try(:days)
      @effective_on_options = @qle.employee_gaining_medicare(@qle_date) if @qle.is_dependent_loss_of_esi?
    end

    @qualified_date = (start_date <= @qle_date && @qle_date <= end_date) ? true : false
  end

  def purchase
    @enrollment = @family.try(:latest_household).try(:hbx_enrollments).active.last

    if @enrollment.present?
      plan = @enrollment.try(:plan)
      if @enrollment.employee_role.present?
        @benefit_group = @enrollment.benefit_group
        @reference_plan = @benefit_group.reference_plan
        @plan = PlanCostDecorator.new(plan, @enrollment, @benefit_group, @reference_plan)
      else
        @plan = UnassistedPlanCostDecorator.new(plan, @enrollment)
      end
      @enrollable = @family.is_eligible_to_enroll?

      @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
      @terminate = params[:terminate].present? ? params[:terminate] : ''
      render :layout => 'application'
    else
      redirect_to :back
    end
  end

  private
  def init_qualifying_life_events
    @qualifying_life_events = []
    if @person.employee_roles.present?
      @qualifying_life_events += QualifyingLifeEventKind.shop_market_events
    elsif @person.consumer_role.present?
      @qualifying_life_events += QualifyingLifeEventKind.individual_market_events
    end
  end

end
