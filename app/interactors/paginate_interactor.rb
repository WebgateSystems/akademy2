class PaginateInteractor < BaseInteractor
  include Pagy::Backend

  DEFAULT_PAGE = 1

  delegate :params, to: :context

  def pagination_data
    {
      total: @pagy.pages,
      page: @pagy.page
    }
  end

  def disabled_pagy?
    params[:disabled_pagy].to_s == true.to_s
  end
end
