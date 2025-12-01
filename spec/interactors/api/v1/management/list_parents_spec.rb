# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ListParents do
  let(:parent_role) { Role.find_or_create_by!(key: 'parent') { |r| r.name = 'Parent' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

  let(:school) { create(:school) }
  let(:academic_year) { school.academic_years.create!(year: '2024/2025', is_current: true, started_at: Date.current) }

  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end

  let(:parent_jan) do
    user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
    UserRole.create!(user: user, role: parent_role, school: school)
    user
  end

  let(:parent_anna) do
    user = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school)
    UserRole.create!(user: user, role: parent_role, school: school)
    user
  end

  before do
    parent_role
    school_manager_role
    academic_year
    school_manager.reload
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) do
        {
          current_user: school_manager,
          params: { page: 1, per_page: 20 }
        }
      end

      before do
        parent_jan
        parent_anna
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'returns list of parents' do
        result = described_class.call(context)
        expect(result.form).to be_an(ActiveRecord::Relation)
        expect(result.form.count).to eq(2)
      end

      it 'sets pagination' do
        result = described_class.call(context)
        expect(result.pagination).to include(:page, :per_page, :total, :total_pages, :has_more)
      end

      it 'sets serializer' do
        result = described_class.call(context)
        expect(result.serializer).to eq(ParentSerializer)
      end

      context 'with search' do
        it 'filters by first name' do
          context[:params][:search] = 'Jan'
          result = described_class.call(context)

          expect(result.form.count).to eq(1)
          expect(result.form.first.first_name).to eq('Jan')
        end

        it 'filters by last name' do
          context[:params][:search] = 'Nowak'
          result = described_class.call(context)

          expect(result.form.count).to eq(1)
          expect(result.form.first.last_name).to eq('Nowak')
        end

        it 'filters by email' do
          context[:params][:search] = parent_jan.email
          result = described_class.call(context)

          expect(result.form.count).to eq(1)
        end
      end

      context 'with pagination' do
        it 'respects per_page parameter' do
          context[:params][:per_page] = 1
          result = described_class.call(context)

          expect(result.form.count).to eq(1)
          expect(result.pagination[:has_more]).to be true
        end

        it 'respects page parameter' do
          context[:params][:per_page] = 1
          context[:params][:page] = 2
          result = described_class.call(context)

          expect(result.form.count).to eq(1)
          expect(result.pagination[:page]).to eq(2)
        end
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: { page: 1, per_page: 20 }
        }
      end

      it 'fails with authorization error' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end
  end
end
