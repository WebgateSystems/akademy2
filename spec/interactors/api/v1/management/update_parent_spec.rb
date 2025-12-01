# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::UpdateParent do
  let(:parent_role) { Role.find_or_create_by!(key: 'parent') { |r| r.name = 'Parent' } }
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

  let(:parent_user) do
    user = create(:user, first_name: 'Anna', last_name: 'Kowalska', school: school)
    UserRole.create!(user: user, role: parent_role, school: school)
    user
  end

  let(:student) do
    user = create(:user, school: school, birthdate: Date.new(2015, 3, 15))
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
    user
  end

  let(:student2) do
    user = create(:user, school: school, birthdate: Date.new(2017, 5, 20))
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
    user
  end

  before do
    parent_role
    student_role
    school_manager_role
    academic_year
    school_class
    school_manager.reload
    parent_user.reload
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            id: parent_user.id,
            parent: {
              first_name: 'Anna Updated',
              last_name: 'Kowalska Updated',
              phone: '+48 999 888 777'
            }
          }
        }
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'updates parent attributes' do
        result = described_class.call(context)
        parent = result.form.reload
        expect(parent.first_name).to eq('Anna Updated')
        expect(parent.last_name).to eq('Kowalska Updated')
      end

      it 'sets serializer and status' do
        result = described_class.call(context)
        expect(result.serializer).to eq(ParentSerializer)
        expect(result.status).to eq(:ok)
      end

      context 'with student assignment' do
        before do
          student
          student2
        end

        it 'assigns students to parent' do
          context[:params][:parent][:student_ids] = [student.id]
          result = described_class.call(context)

          expect(result).to be_success
          parent = result.form.reload
          expect(parent.parent_student_links.count).to eq(1)
          expect(parent.students).to include(student)
        end

        it 'replaces existing student assignments' do
          ParentStudentLink.create!(parent: parent_user, student: student, relation: 'other')

          context[:params][:parent][:student_ids] = [student2.id]
          result = described_class.call(context)

          expect(result).to be_success
          parent = result.form.reload
          expect(parent.students).not_to include(student)
          expect(parent.students).to include(student2)
        end

        it 'uses provided relation type' do
          context[:params][:parent][:student_ids] = [student.id]
          context[:params][:parent][:relation] = 'father'
          result = described_class.call(context)

          parent = result.form.reload
          link = parent.parent_student_links.first
          expect(link.relation).to eq('father')
        end

        it 'keeps students when student_ids not provided' do
          ParentStudentLink.create!(parent: parent_user, student: student, relation: 'other')

          # When student_ids is not provided, existing links should remain
          result = described_class.call(context)

          expect(result).to be_success
          parent = result.form.reload
          expect(parent.parent_student_links.count).to eq(1)
        end
      end

      it 'handles email change' do
        context[:params][:parent][:email] = 'new.email@example.com'
        result = described_class.call(context)

        expect(result).to be_success
        # Email update should be processed (skip_reconfirmation is called)
        expect(result.form).to be_present
      end
    end

    context 'when parent not found' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            id: SecureRandom.uuid,
            parent: {
              first_name: 'Test'
            }
          }
        }
      end

      it 'fails with not found error' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.status).to eq(:not_found)
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: {
            id: parent_user.id,
            parent: {
              first_name: 'Test'
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
