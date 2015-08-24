module Api
  class UsersController < Api::BaseController
    skip_before_filter :require_user!
    def show
      render json: {user: User.new(user)}
    end

    def disconnect
      render json: {}
    end

    protected
    def user
      @user ||= User.find(params[:id])
    end
  end
end