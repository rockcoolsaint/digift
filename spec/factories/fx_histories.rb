FactoryBot.define do
  factory :fx_history do
    fx { nil }
    profile { nil }
    current_rate { "9.99" }
    previous_rate { "9.99" }
  end
end
