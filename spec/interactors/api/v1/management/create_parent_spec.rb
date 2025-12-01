# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::CreateParent do
  let(:parent_role) { Role.find_or_create_by!(key: 'parent') { |r| r.name = 'Parent' } }
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }

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

  let(:student) do
    user = create(:user, school: school, birthdate: Date.new(2015, 3, 15))
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
    user
  end

  before do
    parent_role
    student_role
    school_manager_role
    principal_role
    academic_year
    school_class
    school_manager.reload
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            parent: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com',
              phone: '+48 123 456 789'
            }
          }
        }
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'creates parent user' do
        expect do
          described_class.call(context)
        end.to change(User, :count).by(1)
      end

      it 'assigns parent role' do
        result = described_class.call(context)
        parent = result.form.reload
        expect(parent.user_roles.joins(:role).where(roles: { key: 'parent' }, school: school).exists?).to be true
      end

      it 'assigns user to school' do
        result = described_class.call(context)
        parent = result.form
        expect(parent.school_id).to eq(school.id)
      end

      it 'generates password if not provided' do
        result = described_class.call(context)
        parent = result.form.reload
        expect(parent.encrypted_password).to be_present
      end

      it 'confirms parent immediately' do
        result = described_class.call(context)
        parent = result.form.reload
        expect(parent.confirmed_at).to be_present
      end

      it 'sets serializer and status' do
        result = described_class.call(context)
        expect(result.serializer).to eq(ParentSerializer)
        expect(result.status).to eq(:created)
      end

      it 'handles metadata correctly' do
        context[:params][:parent][:metadata] = { phone: '+48 999 888 777' }
        result = described_class.call(context)
        parent = result.form.reload
        expect(parent.metadata['phone']).to eq('+48 999 888 777')
      end

      context 'with student assignment' do
        before { student }

        it 'assigns students to parent' do
          context[:params][:parent][:student_ids] = [student.id]
          result = described_class.call(context)

          expect(result).to be_success
          parent = result.form.reload
          expect(parent.parent_student_links.count).to eq(1)
          expect(parent.students).to include(student)
        end

        it 'uses provided relation type' do
          context[:params][:parent][:student_ids] = [student.id]
          context[:params][:parent][:relation] = 'mother'
          result = described_class.call(context)

          parent = result.form.reload
          link = parent.parent_student_links.first
          expect(link.relation).to eq('mother')
        end

        it 'defaults to other relation if not provided' do
          context[:params][:parent][:student_ids] = [student.id]
          result = described_class.call(context)

          parent = result.form.reload
          link = parent.parent_student_links.first
          expect(link.relation).to eq('other')
        end
      end

      it 'fails when email is missing' do
        context[:params][:parent].delete(:email)
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to be_an(Array)
      end

      it 'fails when email is duplicate' do
        create(:user, email: 'jan.kowalski@example.com', school: school)

        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to be_an(Array)
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: {
            parent: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com'
            }
          }
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
