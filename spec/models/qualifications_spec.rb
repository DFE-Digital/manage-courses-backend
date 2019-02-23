require 'rails_helper'

RSpec.describe Qualifications, type: :model do
  qts_specs = [
    ["recommendation_for_qts", :not_pgde, :not_fe] => %i[qts]
  ]

  qts_pgce_specs = [
    ["professional", :not_pgde, :not_fe] => %i[qts pgce],
    ["postgraduate", :not_pgde, :not_fe] => %i[qts pgce],
    ["professional_postgraduate", :not_pgde, :not_fe] => %i[qts pgce],
  ]

  qts_pgde_specs = [
    ["recommendation_for_qts", :is_pgde, :not_fe] => %i[qts pgde],
    ["professional", :is_pgde, :not_fe] => %i[qts pgde],
    ["postgraduate", :is_pgde, :not_fe] => %i[qts pgde],
    ["professional_postgraduate", :is_pgde, :not_fe] => %i[qts pgde],
  ]

  pgce_specs = [
    ["professional", :not_pgde, :is_further_education] => %i[pgce],
    ["postgraduate", :not_pgde, :is_further_education] => %i[pgce],
    ["professional_postgraduate", :not_pgde, :is_further_education] => %i[pgce]
  ]

  pgde_specs = [
    ["recommendation_for_qts", :is_pgde, :is_further_education] => %i[pgde],
    ["professional", :is_pgde, :is_further_education] => %i[pgde],
    ["postgraduate", :is_pgde, :is_further_education] => %i[pgde],
    ["professional_postgraduate", :is_pgde, :is_further_education] => %i[pgde],
  ]

  nonsensical_specs = [
    ["recommendation_for_qts", :not_pgde, :is_further_education] => []
  ]

  specs = (nonsensical_specs + qts_specs + qts_pgce_specs + qts_pgde_specs + pgce_specs + pgde_specs).freeze

  specs.each do |spec|
    spec.each do |inputs, expected|
      profpost_flag = inputs[0]
      is_pgde = (inputs[1] == :is_pgde)
      is_further_education = (inputs[2] == :is_further_education)

      context "is #{profpost_flag} and is pgde #{is_pgde} and further education #{is_further_education}" do
        subject { Qualifications.new(profpost_flag: profpost_flag, is_pgde: is_pgde, is_further_education: is_further_education) }

        its(:to_a) { should eq(expected) }
      end
    end
  end
end
