class Import2020IvlBenefitPackage < MongoidMigrationTask

  def migrate
    puts "::: Creating IVL 2020 benefit packages :::" unless Rails.env.test?

    # BenefitPackages - HBX 2020
    hbx = HbxProfile.current_hbx

    # Second lowest cost silver plan
    # slcsp_2020 = Plan.where(active_year: 2020).and(hios_id: "94506DC0390006-01").first

    # check if benefit package is present for 2020
    bc_period_2020 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2020 }.first

    if bc_period_2020.present?
      # bc_period_2020.slcsp = slcsp_2020.id
      # bc_period_2020.slcsp_id = slcsp_2020.id
    else
    # create benefit package and benefit_coverage_period for 2020
      bc_period_2019 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2019 }.first
      bc_period_2020 = bc_period_2019.clone
      bc_period_2020.title = "Individual Market Benefits 2020"
      bc_period_2020.start_on = Date.new(2020,1,1)
      bc_period_2020.end_on = Date.new(2020,12,31)

      # if we need to change these dates after running this rake task in test or prod environments,
      # we should write a separate script.
      bc_period_2020.open_enrollment_start_on = Date.new(2019,11,1)
      bc_period_2020.open_enrollment_end_on = Date.new(2020,1,31)

      # bc_period_2020.slcsp = slcsp_2020.id
      # bc_period_2020.slcsp_id = slcsp_2020.id

      bs = hbx.benefit_sponsorship
      bs.benefit_coverage_periods << bc_period_2020
      bs.save
    end


    # bc_period_2020 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2020 }.first
    # bc_period_2020.second_lowest_cost_silver_plan = slcsp_2020

    ivl_health_plans_2020         = Plan.individual_health_by_active_year(2020).health_metal_nin_catastropic.entries.collect(&:_id)
    ivl_dental_plans_2020         = Plan.individual_dental_by_active_year(2020).entries.collect(&:_id)
    # ivl_and_cat_health_plans_2020 = Plan.individual_health_by_active_year(2020).entries.collect(&:_id)

    # shop_health_plans_2020        = Plan.shop_health_by_active_year(2020).entries.collect(&:_id)
    # shop_dental_plans_2020        = Plan.shop_dental_by_active_year(2020).entries.collect(&:_id)


    ## 2020 Benefit Packages

    individual_health_benefit_package = BenefitPackage.new(
      title: "individual_health_benefits_2020",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_health_plans_2020,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places:        ["individual"],
          enrollment_periods:   ["open_enrollment", "special_enrollment"],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories:   ["health"],
          incarceration_status: ["unincarcerated"],
          age_range:            0..0,
          citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
          residency_status:     ["state_resident"],
          ethnicity:            ["any"]
        )
    )

    individual_dental_benefit_package = BenefitPackage.new(
      title: "individual_dental_benefits_2020",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_dental_plans_2020,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places:        ["individual"],
          enrollment_periods:   ["open_enrollment", "special_enrollment"],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories:   ["dental"],
          incarceration_status: ["unincarcerated"],
          age_range:            0..0,
          citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
          residency_status:     ["state_resident"],
          ethnicity:            ["any"]
        )
    )

    # individual_catastrophic_health_benefit_package = BenefitPackage.new(
    #   title: "catastrophic_health_benefits_2020",
    #   elected_premium_credit_strategy: "unassisted",
    #   benefit_ids:          ivl_and_cat_health_plans_2020,
    #   benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
    #     market_places:        ["individual"],
    #     enrollment_periods:   ["open_enrollment", "special_enrollment"],
    #     family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
    #     benefit_categories:   ["health"],
    #     incarceration_status: ["unincarcerated"],
    #     age_range:            0..30,
    #     citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
    #     residency_status:     ["state_resident"],
    #     ethnicity:            ["any"]
    #   )
    # )

    native_american_health_benefit_package = BenefitPackage.new(
      title: "native_american_health_benefits_2020",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_health_plans_2020,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["indian_tribe_member"]
      )
    )

    native_american_dental_benefit_package = BenefitPackage.new(
      title: "native_american_dental_benefits_2020",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_dental_plans_2020,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["any"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["dental"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["indian_tribe_member"]
      )
    )

    ivl_health_plans_2020_for_csr_100 = Plan.individual_health_by_active_year_and_csr_kind(2020, "csr_100").entries.collect(&:_id)
    ivl_health_plans_2020_for_csr_94 = Plan.individual_health_by_active_year_and_csr_kind(2020, "csr_94").entries.collect(&:_id)
    ivl_health_plans_2020_for_csr_87 = Plan.individual_health_by_active_year_and_csr_kind(2020, "csr_87").entries.collect(&:_id)
    ivl_health_plans_2020_for_csr_73 = Plan.individual_health_by_active_year_and_csr_kind(2020, "csr_73").entries.collect(&:_id)

    individual_health_benefit_package_for_csr_100 = BenefitPackage.new(
      title: "individual_health_benefits_csr_100_2020",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2020_for_csr_100,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        cost_sharing:         "csr_100",
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    individual_health_benefit_package_for_csr_94 = BenefitPackage.new(
      title: "individual_health_benefits_csr_94_2020",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2020_for_csr_94,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        cost_sharing:         "csr_94",
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    individual_health_benefit_package_for_csr_87 = BenefitPackage.new(
      title: "individual_health_benefits_csr_87_2020",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2020_for_csr_87,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        cost_sharing:         "csr_87",
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    individual_health_benefit_package_for_csr_73 = BenefitPackage.new(
      title: "individual_health_benefits_csr_73_2020",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2020_for_csr_73,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        cost_sharing:         "csr_73",
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    bc_period_2020.benefit_packages = [
        individual_health_benefit_package,
        individual_dental_benefit_package,
        # individual_catastrophic_health_benefit_package,
        native_american_health_benefit_package,
        native_american_dental_benefit_package,
        individual_health_benefit_package_for_csr_100,
        individual_health_benefit_package_for_csr_94,
        individual_health_benefit_package_for_csr_87,
        individual_health_benefit_package_for_csr_73
      ]

    bc_period_2020.save!
  end
end