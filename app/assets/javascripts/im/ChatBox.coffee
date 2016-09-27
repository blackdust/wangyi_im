@ChatBox = React.createClass
  getInitialState: ->
    messages: @props.data.messages
    talker_id: null

  # 一些 初始化和回调中需要用到的方法
  pushMsg: (msgs)->
    if !Array.isArray(msgs)
      msgs = [msgs]
    sessionId = msgs[0].sessionId
    @data.msgs = @data.msgs || {}
    @data.msgs[sessionId] = @nim.mergeMsgs(@data.msgs[sessionId], msgs)
    

  componentDidMount: ->
    onConnect = ()->
      console.log "连接成功"

    onWillReconnect = (obj)->
      console.log "断开 即将重连"

    onDisconnect = (error)->
      console.log "断开"
      if error
        switch(error.code)
          when 302 then break
          when "kicked" then break
          else break   

    onError = ()->
      console.log error

    onSyncDone = ()->
      console.log "同步完成"

    onRoamingMsgs = (obj)=>
      console.log "收到漫游消息"
      console.log obj
      @pushMsg obj.msgs

    onOfflineMsgs = (obj)=>
      console.log "收到离线消息"
      console.log obj
      @pushMsg obj.msgs
    
    onMsg = (msg)=>
      console.log '收到消息', msg.scene, msg.type, msg
      @pushMsg(msg)


    @data = {}
    hash = 
    appKey: @props.data.app_key,
    account: @props.data.current_user.id,
    token: @props.data.current_user.token,
    onconnect: onConnect,
    onwillreconnect: onWillReconnect,
    ondisconnect: onDisconnect,
    onerror: onError,
    onsyncdone: onSyncDone,
    onroamingmsgs: onRoamingMsgs,
    onofflinemsgs: onOfflineMsgs,
    onmsg: onMsg

    @nim = NIM.getInstance hash
    # 初始化后自动登录和同步数据

  set_talker: (id)->
    @setState
      talker_id: id 

  render: ->
    message_list_data =
      chater_self: @props.data.chater_self
      messages: @state.messages

    message_input_area_data =
      send_message_text: @send_message_text

    <div className="chat-box">
      <MessageList data={message_list_data}/>
      <MessageInputArea data={message_input_area_data} ref="message_input_area"/>
      <UsersList data={@props.data.users} function={@set_talker}/>
    </div>
  


  send_message_text: ()->
    content        = @refs.message_input_area.refs.message_input.value
    toChatUsername = @state.talker_id

    sendMsgDone = (error, msg)=>
      console.log error
      console.log msg
      console.log '发送' + msg.scene + ' ' + msg.type + '消息' + (!error?'成功':'失败') + ', id=' + msg.idClient
      @pushMsg(msg)

    msg = @nim.sendText
        scene: 'p2p',
        to: toChatUsername,
        text: content,
        done: sendMsgDone

    console.log  "正在发消息给" + msg.idClient
    @pushMsg(msg)


UsersList = React.createClass
  render: ->
    <div className="user-list">
      {
        for item, index in @props.data
          <div className="user-item">
            <button className="ui button" onClick={@check_talk_target} data={item.id}>{item.name}</button>
          </div>  
      }
    </div>
  check_talk_target: (e)->
    jQuery(".user-item button").css("color","black")
    jQuery(e.target).css("color","red")
    talker_id = jQuery(e.target).attr("data")
    @props.function(talker_id)

MessageList = React.createClass
  render: ->
    <div className="message-list">
      {
        for item, index in @props.data.messages
          replace_text = item.text.replace(/\r?\n/g, "</br>")
          message_text = {__html: replace_text}

          chater_self = @props.data.chater_self
          if item.chater.id == chater_self.id && item.chater.name == chater_self.name
            textclass = "right-message"
          else
            textclass = "left-message"

          key = "#{index}:#{item.text}"
          <div className=textclass key={key}>
             <div className="chater">{item.chater.name + "     " + item.chater.time}</div>
             <div className="text" dangerouslySetInnerHTML={message_text} />
          </div>
      }
    </div>

MessageInputArea = React.createClass
  render: ->
    <div className="text-input">
      <div className="textarea">
        <textarea type="text" placeholder="输入你想说的话" ref="message_input" onKeyDown={@textarea_keydown} onKeyUp={@textarea_keyup}/>
      </div>
      <button className="ui button" onClick={@props.data.send_message_text}>发送</button>
    </div>

  textarea_keyup: (e)->
    @input_keycodes = []

  textarea_keydown: (e)->
    @input_keycodes ||= []
    @input_keycodes[e.keyCode] = true
    if @input_keycodes[13] && @input_keycodes[17]
      @props.data.send_message_text()
