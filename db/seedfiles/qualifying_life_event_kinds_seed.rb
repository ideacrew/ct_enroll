puts "*"*80
puts "::: Cleaning QualifyingLifeEventKinds :::"
QualifyingLifeEventKind.delete_all

QualifyingLifeEventKind.create!(
    title: "Losing other health insurance", 
    action_kind: "add_benefit",
    reason: "lost_access_to_mec",
    edi_code: "33-LOST ACCESS TO MEC", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 10,
    event_kind_label: 'Date of losing coverage',
    tool_tip: "Someone in the household is losing other health insurance involuntarily"
  )

QualifyingLifeEventKind.create!(
    title: "Had a baby",
    action_kind: "add_benefit",
    reason: "birth",
    edi_code: "02-BIRTH", 
    market_kind: "shop", 
    effective_on_kinds: ["date_of_event"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 15,
    event_kind_label: 'Date of birth',
    tool_tip: "Enroll or add a family member due to birth"
  )

QualifyingLifeEventKind.create!(
    title: "Adopted a child",
    action_kind: "add_benefit",
    reason: "adoption",
    edi_code: "05-ADOPTION", 
    market_kind: "shop", 
    effective_on_kinds: ["date_of_event"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 20,
    event_kind_label: "Date of adoption",
    tool_tip: "Enroll or add a family member due to adoption"
  )

QualifyingLifeEventKind.create!(
    title: "Married",
    action_kind: "add_benefit",
    reason: "marriage",
    edi_code: "32-MARRIAGE", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 25,
    event_kind_label: 'Date of married',
    tool_tip: "Enroll or add a family member because of marriage"
  )

QualifyingLifeEventKind.create!(
    title: "Error occured at the exchange", 
    action_kind: "administrative",
    reason: "enrollment_error_or_misconduct_hbx",
    edi_code: "MISCONDUCT AT HBX",
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: false, 
    date_options_available: false,
    ordinal_position: 30,
    tool_tip: "You are not enrolled or are enrolled in the wrong plan because of an officer, employee, or agent of the Exchange of HHS."
  )

QualifyingLifeEventKind.create!(
    title: "Health plan contract violation", 
    action_kind: "administrative",
    reason: "contract_violation",
    edi_code: "33-CONTRACT VIOLATION",
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: false, 
    date_options_available: true,
    ordinal_position: 35,
    event_kind_label: "Date of contract violation",
    tool_tip: "Enroll due to contract violation"
  )

QualifyingLifeEventKind.create!(
    title: "Moved or moving",
    action_kind: "add_benefit",
    reason: "relocate",
    edi_code: "43-CHANGE OF LOCATION", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30,
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 40,
    event_kind_label: "Date of move", 
    tool_tip: "A qualified individual or enrollee gains access to new QHPs as a result of a permanent move"
  )

QualifyingLifeEventKind.create!(
    title: "I'm a Native American", 
    action_kind: "add_benefit",
    reason: "qualified_native_american",
    edi_code: "NATIVE AMERICAN", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 45,
    event_kind_label: "native american",
    tool_tip: "Native American or Alaskan Native"
  )

QualifyingLifeEventKind.create!(
    title: "Exceptional circumstances", 
    action_kind: "administrative",
    reason: "exceptional_circumstances",
    edi_code: "EX-EXCEPTIONAL CIRCUMSTANCES", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: false, 
    date_options_available: false,
    ordinal_position: 50,
    event_kind_label: "Date of exceptional circumstances",
    tool_tip: "Enroll due to an inadvertent or erroneous enrollment or another exceptional circumstance"
  )


QualifyingLifeEventKind.create!(
    title: "Got my Medicaid denial after open enrollment ended",
    action_kind: "add_benefit",
    reason: "eligibility_change_medicaid_ineligible",
    edi_code: "MEDICAID DENIAL",
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 55,
    event_kind_label: "Date of medicaid denial",
    tool_tip: "Household member(s) had pending Medicaid eligibility at the end of open enrollment but ineligible determination received after open enrollment ended."
)


QualifyingLifeEventKind.create!(
    title: "Changed eligibility for Assistance", 
    action_kind: "add_benefit",
    reason: "eligibility_change_income",
    edi_code: "CHANGE IN ASSISTANCE",
    market_kind: "shop",
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 60,
    event_kind_label: "Date of assistance eligibility",
    tool_tip: "Becomes eligible for assistance, with respect to coverage under a Access health CT Small Business, under such Medicaid plan or a State child health plan" 
)


puts "::: QualifyingLifeEventKinds Complete :::"
puts "*"*80
