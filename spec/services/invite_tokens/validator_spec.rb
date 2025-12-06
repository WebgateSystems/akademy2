# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InviteTokens::Validator do
  # Registry is cleared globally in rails_helper after each test

  describe '.call!' do
    context 'when token is nil' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect do
          described_class.call!(nil)
        end.to raise_error(ActiveRecord::RecordNotFound, 'Token not found')
      end
    end

    context 'when token is empty' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect do
          described_class.call!('')
        end.to raise_error(ActiveRecord::RecordNotFound, 'Token not found')
      end
    end

    context 'when token is not registered' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect do
          described_class.call!('unknown-token')
        end.to raise_error(ActiveRecord::RecordNotFound, 'Token not found')
      end
    end

    context 'when token is registered' do
      let!(:invite) do
        described_class.register(
          token: 'valid-token',
          kind: 'teacher',
          school_id: 'school-123'
        )
      end

      it 'returns the invite' do
        result = described_class.call!('valid-token')
        expect(result).to eq(invite)
      end

      it 'returns invite with correct attributes' do
        result = described_class.call!('valid-token')
        expect(result.kind).to eq('teacher')
        expect(result.school_id).to eq('school-123')
      end
    end
  end

  describe '.register' do
    it 'creates an invite with given attributes' do
      invite = described_class.register(
        token: 'new-token',
        kind: 'student',
        school_id: 'school-456',
        school_class_id: 'class-789'
      )

      expect(invite.token).to eq('new-token')
      expect(invite.kind).to eq('student')
      expect(invite.school_id).to eq('school-456')
      expect(invite.school_class_id).to eq('class-789')
      expect(invite.used?).to be false
    end

    it 'makes the invite retrievable via call!' do
      described_class.register(
        token: 'retrievable-token',
        kind: 'teacher',
        school_id: 'school-123'
      )

      expect { described_class.call!('retrievable-token') }.not_to raise_error
    end
  end

  describe '.clear_registry!' do
    it 'removes all registered invites' do
      described_class.register(
        token: 'temp-token',
        kind: 'teacher',
        school_id: 'school-123'
      )

      described_class.clear_registry!

      expect do
        described_class.call!('temp-token')
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'InviteTokens::Invite' do
    describe '#mark_used!' do
      it 'marks invite as used' do
        invite = InviteTokens::Invite.new(
          token: 'test',
          kind: 'teacher',
          school_id: 'school-123',
          used: false
        )

        expect(invite.used?).to be false
        invite.mark_used!
        expect(invite.used?).to be true
      end
    end

    describe '#used?' do
      it 'returns false by default' do
        invite = InviteTokens::Invite.new(token: 'test', kind: 'teacher', school_id: '123')
        expect(invite.used?).to be false
      end

      it 'returns true when used is set to true' do
        invite = InviteTokens::Invite.new(token: 'test', kind: 'teacher', school_id: '123', used: true)
        expect(invite.used?).to be true
      end
    end
  end
end
