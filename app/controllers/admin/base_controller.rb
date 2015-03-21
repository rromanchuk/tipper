class Admin::BaseController < ApplicationController
  include AdminAuthenticatable

  layout "admin"

  protected


end
