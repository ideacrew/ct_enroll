puts "*"*80
puts "::: Generating CT Carriers:::"

hbx_office = OfficeLocation.new(
    is_primary: true,
    address: {kind: "work", address_1: "address_placeholder", address_2: "address_2", city: "City", state: "St", zip: "10001" },
    phone: {kind: "main", area_code: "111", number: "111-1111"}
  )

org = Organization.new(fein: "061475928", legal_name: "Anthem BlueCross BlueShield", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb89914603000029", abbrev: "ABCBS", hbx_carrier_id: 20014, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: false)

org = Organization.new(fein: "237442369", legal_name: "ConnectiCare", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb89914603000022", abbrev: "CCARE", hbx_carrier_id: 20015, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: false)

puts "::: Generated CT Carriers :::"
puts "*"*80
