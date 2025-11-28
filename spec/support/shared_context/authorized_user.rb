RSpec.shared_context 'when authorized user' do
  let!(:user) { create(:user) }
  let(:role) { create(:role, name: 'admin', key: 'admin') }
  let(:Authorization) { "Bearer #{generate_token(user)}" }

  before do
    create(:user_role, user:, role:, school: user.school)
  end
end
