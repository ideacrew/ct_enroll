module BenefitSponsors
  module SponsoredBenefits
    class ContributionLevel
      include Mongoid::Document
      include Mongoid::Timestamps


      embedded_in :sponsor_contribution,
                  class_name: "BenefitSponsors::SponsoredBenefits::SponsorContribution"


      field :display_name, type: String
      field :contribution_unit_id, type: BSON::ObjectId
      field :is_offered, type: Boolean
      field :order, type: Integer
      field :contribution_factor, type: Float
      field :min_contribution_factor, type: Float
      field :contribution_cap, type: Float
      field :flat_contribution_amount, type: Float

      validates_presence_of :display_name, :allow_blank => false
      validates_presence_of :contribution_unit_id, :allow_blank => false
      validates_presence_of :contribution_factor, :allow_blank => false

      def contribution_pct
        (contribution_factor * 100)
      end

      NAMES = [
          "employee_only",
          "employee_and_spouse",
          "employee_and_one_or_more_dependents",
          "family"
      ]
    end
  end
end
