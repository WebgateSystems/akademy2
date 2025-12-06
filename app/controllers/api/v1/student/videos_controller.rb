# frozen_string_literal: true

module Api
  module V1
    module Student
      class VideosController < ApplicationApiController
        before_action :authorize_access_request!
        before_action :ensure_student!
        before_action :set_video, only: %i[show update destroy toggle_like]

        # GET /api/v1/student/videos
        # List all approved videos with optional filtering
        def index
          page = (params[:page] || 1).to_i
          per_page = (params[:per_page] || 20).to_i.clamp(1, 50)

          # Build search filters
          where_clause = { status: 'approved' }
          where_clause[:subject_id] = params[:subject_id] if params[:subject_id].present?
          where_clause[:school_id] = params[:school_id] if params[:school_id].present?

          # Use Searchkick if available and query present
          if params[:q].present? && searchkick_available?
            results = StudentVideo.search(
              params[:q],
              where: where_clause,
              order: { created_at: :desc },
              page: page,
              per_page: per_page,
              includes: %i[user subject school]
            )
            videos = results.results
            total = results.total_count
          else
            # Fallback to database query
            videos = StudentVideo.approved
                                 .includes(:user, :subject, :school)
                                 .newest_first

            videos = videos.by_subject(params[:subject_id]) if params[:subject_id].present?
            videos = videos.by_school(params[:school_id]) if params[:school_id].present?

            # Simple ILIKE search as fallback
            if params[:q].present?
              query = "%#{params[:q]}%"
              videos = videos.joins(:user).where(
                'student_videos.title ILIKE :q OR student_videos.description ILIKE :q OR ' \
                'users.first_name ILIKE :q OR users.last_name ILIKE :q',
                q: query
              )
            end

            total = videos.count
            videos = videos.offset((page - 1) * per_page).limit(per_page)
          end

          render json: {
            success: true,
            data: videos.map { |v| video_json(v) },
            meta: {
              page: page,
              per_page: per_page,
              total: total,
              total_pages: (total.to_f / per_page).ceil
            }
          }
        end

        # GET /api/v1/student/videos/my
        # List current student's videos (all statuses)
        def my_videos
          videos = current_user.student_videos
                               .includes(:subject, :school)
                               .newest_first

          render json: {
            success: true,
            data: videos.map { |v| video_json(v, include_status: true) }
          }
        end

        # GET /api/v1/student/videos/:id
        def show
          render json: {
            success: true,
            data: video_json(@video, include_status: @video.user_id == current_user.id)
          }
        end

        # POST /api/v1/student/videos
        # Upload a new video
        def create
          video = current_user.student_videos.new(video_params)
          video.school = current_user.school

          if video.save
            # Log to activity log
            EventLogger.log_student_video_upload(video: video, user: current_user, client: 'api')

            # Notify teachers about new video pending approval
            NotificationService.create_student_video_uploaded(video: video)

            render json: {
              success: true,
              data: video_json(video, include_status: true),
              message: 'Video uploaded successfully. Waiting for teacher approval.'
            }, status: :created
          else
            render json: {
              success: false,
              errors: video.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/student/videos/:id
        # Update own pending video (title and description only)
        def update
          unless @video.user_id == current_user.id
            return render json: {
              success: false,
              error: 'You can only edit your own videos'
            }, status: :forbidden
          end

          unless @video.pending?
            return render json: {
              success: false,
              error: 'You can only edit pending videos'
            }, status: :unprocessable_entity
          end

          if @video.update(update_video_params)
            render json: {
              success: true,
              data: video_json(@video, include_status: true),
              message: 'Video updated successfully'
            }
          else
            render json: {
              success: false,
              errors: @video.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/student/videos/:id
        # Delete own pending video
        def destroy
          unless @video.can_be_deleted_by?(current_user)
            return render json: {
              success: false,
              error: 'You can only delete your own pending videos'
            }, status: :forbidden
          end

          # Log before destroy (video data still available)
          EventLogger.log_student_video_delete(video: @video, user: current_user, client: 'api')

          @video.destroy!

          render json: {
            success: true,
            message: 'Video deleted successfully'
          }
        end

        # POST /api/v1/student/videos/:id/like
        # Toggle like on a video
        def toggle_like
          liked = @video.toggle_like!(current_user)

          render json: {
            success: true,
            data: {
              liked: liked,
              likes_count: @video.reload.likes_count
            }
          }
        end

        # GET /api/v1/student/videos/subjects
        # Get subjects for filtering
        def subjects
          subjects = Subject.where(school_id: [nil, current_user.school_id])
                            .order(:order_index)

          render json: {
            success: true,
            data: subjects.map do |s|
              {
                id: s.id,
                title: s.title,
                slug: s.slug
              }
            end
          }
        end

        private

        def ensure_student!
          return if current_user&.student?

          render json: { success: false, error: 'Student access required' }, status: :forbidden
        end

        def set_video
          @video = StudentVideo.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { success: false, error: 'Video not found' }, status: :not_found
        end

        def video_params
          params.require(:video).permit(:title, :description, :subject_id, :file, :thumbnail)
        rescue ActionController::ParameterMissing
          # Fallback for multipart form-data with flat keys like video[title]
          fallback = {
            title: params['video[title]'],
            description: params['video[description]'],
            subject_id: params['video[subject_id]'],
            file: params['video[file]'] || params[:file],
            thumbnail: params['video[thumbnail]']
          }.compact
          ActionController::Parameters.new(fallback).permit(:title, :description, :subject_id, :file, :thumbnail)
        end

        def update_video_params
          params.require(:video).permit(:title, :description)
        end

        def searchkick_available?
          return false if Rails.env.test? && ENV['ELASTICSEARCH_TEST'] != 'true'

          StudentVideo.searchkick_index.exists?
        rescue StandardError
          false
        end

        def video_json(video, include_status: false)
          data = {
            id: video.id,
            title: video.title,
            description: video.description,
            file_url: video.file&.url,
            thumbnail_url: video.thumbnail&.url,
            youtube_url: video.youtube_url,
            duration_sec: video.duration_sec,
            likes_count: video.likes_count,
            liked_by_me: video.liked_by?(current_user),
            author: {
              id: video.user_id,
              name: video.author_name,
              is_me: video.user_id == current_user.id
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
            created_at: video.created_at,
            can_delete: video.can_be_deleted_by?(current_user)
          }

          if include_status
            data[:status] = video.status
            data[:moderated_at] = video.moderated_at
            data[:rejection_reason] = video.rejection_reason
          end

          data
        end
      end
    end
  end
end
