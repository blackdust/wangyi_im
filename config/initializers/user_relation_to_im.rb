PlayAuth::User.class_eval  do |variable|
  require 'digest'
  field :im_token, :type => String
  after_create :set_im_code

  def set_im_code
    app_secret = ENV["WANG_YI_APP_SECRET"]
    app_key    = ENV["WANG_YI_APP_KEY"]

    curtime = Time.now.to_i
    rand_base = [1,2,3,4,5,6,7,8,9,0]
    nonce = rand_base.sample(8).join()

    sha1 = Digest::SHA1.hexdigest(app_secret + nonce + curtime.to_s)


    command = %~
    curl -X POST -H "AppKey: #{app_key}" -H "Nonce: #{nonce}" -H "CurTime: #{curtime}" -H "CheckSum: #{sha1}" -H "Content-Type: application/x-www-form-urlencoded" -d 'accid=#{self.id}&name=#{self.name}' 'https://api.netease.im/nimserver/user/create.action'
    ~
    
    json = JSON.parse(`#{command}`)
    self.im_token = json["info"]["token"]
    self.save

    #  子账号设置完毕 + 昵称设置完毕
  end
end


   