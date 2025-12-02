# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:user) { instance_double(User) }
  let(:record) { double('Record') }

  describe 'default permissions' do
    it 'denies index' do
      expect(policy.index?).to be(false)
    end

    it 'denies show' do
      expect(policy.show?).to be(false)
    end

    it 'denies create/new' do
      expect(policy.create?).to be(false)
      expect(policy.new?).to be(false)
    end

    it 'denies update/edit' do
      expect(policy.update?).to be(false)
      expect(policy.edit?).to be(false)
    end

    it 'denies destroy' do
      expect(policy.destroy?).to be(false)
    end
  end

  describe ApplicationPolicy::Scope do
    it 'requires subclasses to implement resolve' do
      scope = described_class.new(user, User.all)

      expect { scope.resolve }.to raise_error(NoMethodError, /You must define #resolve/)
    end
  end
end
