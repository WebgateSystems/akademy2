# frozen_string_literal: true

module Api
  module V1
    module Student
      class EventsController < ApplicationApiController
        before_action :authorize_access_request!
        before_action :require_student!

        # Valid event types for student tracking
        VALID_EVENT_TYPES = %w[
          video_started
          video_completed
          video_progress
          infographic_viewed
          quiz_started
          content_viewed
        ].freeze

        # POST /api/v1/student/events
        # Log student activity events
        def create
          event_type = params[:event_type]
          unless VALID_EVENT_TYPES.include?(event_type)
            return render json: {
              success: false,
              error: "Invalid event type. Valid types: #{VALID_EVENT_TYPES.join(', ')}"
            }, status: :unprocessable_entity
          end

          event_data = build_event_data(event_type)

          EventLogger.log(
            event_type: event_type,
            user: current_user,
            school: current_user.school,
            data: event_data,
            client: params[:client] || 'web'
          )

          render json: { success: true, message: 'Event logged' }, status: :created
        end

        # POST /api/v1/student/events/batch
        # Log multiple events at once (for offline sync)
        def batch
          events = params[:events]

          unless events.is_a?(Array)
            return render json: { success: false, error: 'Events must be an array' }, status: :unprocessable_entity
          end

          logged_count = 0
          errors = []

          events.each_with_index do |event, index|
            event_type = event[:event_type]
            unless VALID_EVENT_TYPES.include?(event_type)
              errors << { index: index, error: "Invalid event type: #{event_type}" }
              next
            end

            EventLogger.log(
              event_type: event_type,
              user: current_user,
              school: current_user.school,
              data: event[:data] || {},
              client: event[:client] || 'mobile',
              occurred_at: event[:occurred_at]&.to_datetime
            )
            logged_count += 1
          rescue StandardError => e
            errors << { index: index, error: e.message }
          end

          render json: {
            success: errors.empty?,
            logged_count: logged_count,
            total_count: events.count,
            errors: errors.presence
          }, status: errors.empty? ? :created : :multi_status
        end

        private

        def require_student!
          return if current_user.student?

          render json: { success: false, error: 'Student access required' }, status: :forbidden
        end

        def build_event_data(event_type)
          case event_type
          when 'video_started', 'video_completed', 'video_progress'
            build_video_event_data
          when 'infographic_viewed', 'content_viewed'
            build_content_event_data
          when 'quiz_started'
            build_quiz_event_data
          else
            params[:data]&.to_unsafe_h || {}
          end
        end

        def build_video_event_data
          {
            content_id: params[:content_id],
            learning_module_id: params[:learning_module_id],
            duration_sec: params[:duration_sec],
            progress_sec: params[:progress_sec],
            progress_percent: params[:progress_percent]
          }.compact
        end

        def build_content_event_data
          {
            content_id: params[:content_id],
            content_type: params[:content_type],
            learning_module_id: params[:learning_module_id]
          }.compact
        end

        def build_quiz_event_data
          {
            learning_module_id: params[:learning_module_id],
            quiz_id: params[:quiz_id]
          }.compact
        end
      end
    end
  end
end
