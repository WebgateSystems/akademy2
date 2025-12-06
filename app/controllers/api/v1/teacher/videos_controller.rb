# frozen_string_literal: true

module Api
  module V1
    module Teacher
      class VideosController < ApplicationApiController
        before_action :authorize_access_request!
        before_action :ensure_teacher!
        before_action :set_video, only: %i[show approve reject destroy update]

        # GET /api/v1/teacher/videos
        # List videos for moderation (pending by default, scoped to teacher's classes)
        def index
          # Get students from teacher's classes
          class_ids = current_user.teacher_class_assignments.pluck(:school_class_id)
          student_ids = StudentClassEnrollment.where(school_class_id: class_ids, status: 'approved')
                                              .pluck(:student_id)

          videos = StudentVideo.where(user_id: student_ids)
                               .includes(:user, :subject, :school)
                               .newest_first

          # Filter by status (default: pending)
          status = params[:status] || 'pending'
          videos = videos.where(status: status) if StudentVideo::STATUSES.include?(status)

          # Filter by class
          if params[:class_id].present?
            class_student_ids = StudentClassEnrollment.where(
              school_class_id: params[:class_id],
              status: 'approved'
            ).pluck(:student_id)
            videos = videos.where(user_id: class_student_ids)
          end

          render json: {
            success: true,
            data: videos.map { |v| video_json(v) }
          }
        end

        # GET /api/v1/teacher/videos/:id
        def show
          render json: {
            success: true,
            data: video_json(@video)
          }
        end

        # PUT /api/v1/teacher/videos/:id/approve
        def approve
          unless @video.pending?
            return render json: {
              success: false,
              error: 'Only pending videos can be approved'
            }, status: :unprocessable_entity
          end

          @video.approve!(current_user)

          render json: {
            success: true,
            data: video_json(@video),
            message: 'Video approved successfully'
          }
        end

        # PUT /api/v1/teacher/videos/:id/reject
        def reject
          unless @video.pending?
            return render json: {
              success: false,
              error: 'Only pending videos can be rejected'
            }, status: :unprocessable_entity
          end

          @video.reject!(current_user, params[:reason])

          render json: {
            success: true,
            data: video_json(@video),
            message: 'Video rejected'
          }
        end

        # DELETE /api/v1/teacher/videos/:id
        # Teacher can delete approved videos
        def destroy
          # Log before destroy (video data still available)
          EventLogger.log_student_video_delete(video: @video, user: current_user, client: 'api')

          @video.destroy!

          render json: {
            success: true,
            message: 'Video deleted successfully'
          }
        end

        # PATCH /api/v1/teacher/videos/:id
        # Teacher can edit video details (title, description, etc.)
        def update
          if @video.update(update_params)
            render json: {
              success: true,
              data: video_json(@video),
              message: 'Video updated successfully'
            }
          else
            render json: {
              success: false,
              errors: @video.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def ensure_teacher!
          return if current_user&.teacher?

          render json: { success: false, error: 'Teacher access required' }, status: :forbidden
        end

        def set_video
          @video = StudentVideo.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { success: false, error: 'Video not found' }, status: :not_found
        end

        def update_params
          params.require(:video).permit(:title, :description, :subject_id)
        end

        def video_json(video)
          {
            id: video.id,
            title: video.title,
            description: video.description,
            file_url: video.file&.url,
            thumbnail_url: video.thumbnail&.url,
            youtube_url: video.youtube_url,
            duration_sec: video.duration_sec,
            status: video.status,
            likes_count: video.likes_count,
            author: {
              id: video.user_id,
              name: video.author_name
            },
            subject: {
              id: video.subject_id,
              title: video.subject_title
            },
            school: if video.school
                      {
                        id: video.school_id,
                        name: video.school_name
                      }
                    end,
            moderated_by: if video.moderated_by
                            {
                              id: video.moderated_by_id,
                              name: video.moderated_by.full_name
                            }
                          end,
            moderated_at: video.moderated_at,
            rejection_reason: video.rejection_reason,
            created_at: video.created_at,
            updated_at: video.updated_at
          }
        end
      end
    end
  end
end
