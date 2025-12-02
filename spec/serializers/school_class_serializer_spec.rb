# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolClassSerializer do
  let(:school) { create(:school) }
  let(:school_class) do
    SchoolClass.create!(
      school: school,
      name: '4A',
      year: '2025/2026',
      qr_token: SecureRandom.uuid,
      metadata: {}
    )
  end

  def serialized_attributes(record = school_class)
    described_class.new(record).serializable_hash[:data][:attributes]
  end

  describe 'base attributes' do
    it 'includes basic fields' do
      attrs = serialized_attributes

      expect(attrs[:name]).to eq('4A')
      expect(attrs[:year]).to eq('2025/2026')
      expect(attrs[:school_id]).to eq(school.id)
      expect(attrs[:created_at]).to be_present
      expect(attrs[:updated_at]).to be_present
    end

    it 'includes school name' do
      expect(serialized_attributes[:school_name]).to eq(school.name)
    end
  end

  describe 'main_teacher attribute' do
    it 'returns nil when there is no main assignment' do
      expect(serialized_attributes[:main_teacher]).to be_nil
    end

    it 'returns id and name when main teacher is assigned' do
      teacher = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
      TeacherClassAssignment.create!(teacher: teacher, school_class: school_class, role: 'main')

      result = serialized_attributes[:main_teacher]

      expect(result).to eq(
        id: teacher.id,
        name: 'Jan Kowalski'
      )
    end
  end

  describe 'teaching_staff attribute' do
    it 'returns empty array when no teaching staff' do
      expect(serialized_attributes[:teaching_staff]).to eq([])
    end

    it 'returns all teaching staff with ids and names' do
      teacher1 = create(:user, school: school, first_name: 'Anna', last_name: 'Nowak')
      teacher2 = create(:user, school: school, first_name: 'Piotr', last_name: 'Zielinski')
      TeacherClassAssignment.create!(teacher: teacher1, school_class: school_class, role: 'teaching_staff')
      TeacherClassAssignment.create!(teacher: teacher2, school_class: school_class, role: 'teaching_staff')

      result = serialized_attributes[:teaching_staff]

      expect(result).to contain_exactly(
        { id: teacher1.id, name: 'Anna Nowak' },
        { id: teacher2.id, name: 'Piotr Zielinski' }
      )
    end
  end

  describe 'students_count attribute' do
    let(:other_class) do
      SchoolClass.create!(
        school: school,
        name: '5B',
        year: '2024/2025',
        qr_token: SecureRandom.uuid,
        metadata: {}
      )
    end

    it 'counts students enrolled in the same academic year' do
      student1 = create(:user, school: school)
      student2 = create(:user, school: school)
      student_other = create(:user, school: school)

      StudentClassEnrollment.create!(student: student1, school_class: school_class)
      StudentClassEnrollment.create!(student: student2, school_class: school_class)
      StudentClassEnrollment.create!(student: student_other, school_class: other_class)

      expect(serialized_attributes[:students_count]).to eq(2)
    end
  end
end
