class ImController < ApplicationController
  layout 'im_layout'
  before_filter :check_login

  def chat_box
    ary = User.all.to_a - current_user.to_a
    ary = ary.map{|x|{id:x._id.to_s, name:x.name}}
    @component_name = "chat_box"
    @component_data = {
      chater_self: {id: 1, name: "我"},
      messages: [],
      current_user: {id:current_user.id.to_s, name: current_user.name, token:current_user.im_token},
      users:ary,
      app_key:ENV["WANG_YI_APP_KEY"]
    }

  end

  def chat_box_group
    ary = User.all.to_a - current_user.to_a
    ary = ary.map{|x|{id:x._id.to_s, name:x.name}}
    @component_name = "chat_box_group"
    @component_data = {
      current_user: {id:current_user.id.to_s, name: current_user.name, token:current_user.im_token},
      users:ary,
      app_key:ENV["WANG_YI_APP_KEY"]
    }
  end

  protected
  def check_login
    if current_user.nil?
      redirect_to "/auth/users/developers"
    end
  end
end