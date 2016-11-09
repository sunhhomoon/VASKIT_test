class PreviewImage < ActiveRecord::Base

  has_attached_file :image, :styles => { :crop => "1024>x" }, :processors => [:cropper],
                    :url  => "/assets/preview_images/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/assets/preview_images/:id/:style/:basename.:extension",
                    :default_url => "/images/custom/card_image_preview.png"
  validates_attachment_size :image, :less_than => 20.megabytes
  validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/pjpeg', 'image/pjpeg', 'image/png', 'image/jpg', 'image/gif', 'application/octet-stream']
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h

  before_create :rename_file

  def rename_file
    if ["jpg", "jpeg", "gif", "png"].include?( self.image_file_name.split(".").last )
      charset = %w{ 2 3 4 6 7 9 a b c d e f g h i j k l m n o p q r s t v w x y z}
      self.image_file_name = (0...6).map{ charset.to_a[rand(charset.size)] }.join + "." +  self.image_file_name.split(".").last
    end
  end

  def cropping?
    !crop_x.blank? && !crop_y.blank? && !crop_w.blank? && !crop_h.blank?
  end

  def reprocess_image
    image.reprocess!
  end

end
