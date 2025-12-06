# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:user_roles).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_roles) }
  end

  describe 'validations' do
    subject(:role) { build(:role) }

    it 'is valid with valid attributes' do
      expect(role).to be_valid
    end
  end

  describe 'scopes' do
    let!(:admin_role) { described_class.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
    let!(:teacher_role) { described_class.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

    it 'can find roles by key' do
      expect(described_class.find_by(key: 'admin')).to eq(admin_role)
      expect(described_class.find_by(key: 'teacher')).to eq(teacher_role)
    end
  end
end
