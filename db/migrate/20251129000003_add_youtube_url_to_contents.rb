class AddYoutubeUrlToContents < ActiveRecord::Migration[8.0]
  def change
    add_column :contents, :youtube_url, :string
  end
end
