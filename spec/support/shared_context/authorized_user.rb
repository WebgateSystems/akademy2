RSpec.shared_context 'when authorized user' do
  let!(:user) { create(:user) }
  let(:role) { create(:role, name: 'admin') }
  let(:Authorization) { "Bearer #{generate_token(user)}" }

  before do
    create(:user_company, user:, company_id: user.current_company_id)
    create(:user_role, user:, role:, company_id: user.current_company_id)
  end
end
