# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::SearchStudentsForParent do
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

  let(:school) { create(:school) }
  let(:academic_year) { school.academic_years.create!(year: '2024/2025', is_current: true, started_at: Date.current) }
  let(:school_class) do
    SchoolClass.create!(name: '1A', school: school, year: academic_year.year, qr_token: SecureRandom.uuid)
  end

  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end

  let(:student_jan) do
    user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, birthdate: Date.new(2015, 3, 15))
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
    user
  end

  let(:student_anna) do
    user = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school, birthdate: Date.new(2016, 5, 20))
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
    user
  end

  before do
    student_role
    school_manager_role
    academic_year
    school_class
    school_manager.reload
  end

  describe '#call' do
    context 'when user is authorized' do
      before do
        student_jan
        student_anna
      end

      context 'with valid search term' do
        let(:context) do
          {
            current_user: school_manager,
            params: { q: 'Jan' }
          }
        end

        it 'succeeds' do
          result = described_class.call(context)
          expect(result).to be_success
        end

        it 'returns matching students' do
          result = described_class.call(context)
          expect(result.form).to be_an(Array)
          expect(result.form.length).to eq(1)
          expect(result.form.first[:first_name]).to eq('Jan')
        end

        it 'includes student details' do
          result = described_class.call(context)
          student_data = result.form.first

          expect(student_data).to include(:id, :first_name, :last_name, :birthdate, :class_name, :email)
        end

        it 'formats birthdate correctly' do
          result = described_class.call(context)
          student_data = result.form.first

          expect(student_data[:birthdate]).to eq('15.03.2015')
        end
      end

      context 'when searching by last name' do
        let(:context) do
          {
            current_user: school_manager,
            params: { search: 'Nowak' }
          }
        end

        it 'returns matching students' do
          result = described_class.call(context)
          expect(result.form.length).to eq(1)
          expect(result.form.first[:last_name]).to eq('Nowak')
        end
      end

      context 'with no matching students' do
        let(:context) do
          {
            current_user: school_manager,
            params: { q: 'Nieistniejący' }
          }
        end

        it 'returns empty array' do
          result = described_class.call(context)
          expect(result.form).to be_empty
        end
      end
    end

    context 'when search term is missing' do
      let(:context) do
        {
          current_user: school_manager,
          params: {}
        }
      end

      it 'fails with error message' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Brak terminu wyszukiwania')
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: { q: 'Jan' }
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
