class Users::RegistrationsController < Devise::RegistrationsController
  before_filter :configure_permitted_parameters
  skip_before_filter :auth_user
  after_action :set_gcm_key, :only => ["create"]

  def new
    build_resource({:email => params[:email], :name => params[:name], :facebook_id => params[:facebook_id], :gender => params[:gender], :birthday => params[:birthday] })
    respond_with self.resource
  end

  def check_email #AJS추가
    user_email_input = params[:user_email_input]
    is_new_email = true if User.find_by_email(user_email_input).blank?
    render :json => {:is_new_email => is_new_email}
  end

  def create
    if params[:user][:facebook_id].blank?
      params[:user][:sign_up_type] = "email"
    else
      params[:user][:password] = "is_facebook"
      params[:user][:sign_up_type] = "facebook"
      params[:user][:agree_access_term] = true
    end
    params[:user][:remember_me] = true

    params[:user][:password_confirmation] = params[:user][:password]
    params[:user][:string_id] = User.get_uniq_string_id( params[:user][:email].split("@")[0] )
    super

    user = User.find_by(:email => params[:user][:email])
    UserMailer.delay.welcome_email(user)
    AdminMailer.delay.signup_submitted(user)
  end

  def edit
  end

  def update
    if current_user.sign_up_type == "facebook"
      params[:user][:current_password] = "is_facebook"
      params[:user][:sign_up_type] = "both"
    end
    if current_user.valid_password?(params[:user][:current_password])
      if params[:user][:password] != params[:user][:password_confirmation]
        flash[:custom_notice] = "비밀번호 확인란이 일치하지 않습니다"
      elsif params[:user][:password].length < 8
        flash[:custom_notice] = "비밀번호는 8자 이상으로 해주세요"
      else
        flash[:custom_notice] = "비밀번호가 변경되었습니다"
      end
    else
      flash[:custom_notice] = "기존 비밀번호를 정확히 입력해주세요"
    end
    super
  end


  protected
  def update_resource(resource, params)
    resource.update_with_password(params)
  end

  def after_create_path_for(resource)
    path = root_path
    path
  end

  def after_update_path_for(resource)
    "/users/change_password"
  end


  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:email, :password, :password_confirmation, :remember_me, :sign_up_type, :string_id, :name, :gender, :birthday, :facebook_id, :agree_access_term)
    end
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:email, :current_password, :password, :password_confirmation, :remember_me, :sign_up_type, :string_id, :name, :gender, :birthday, :facebook_id, :agree_access_term)
    end
  end
end
