@ChatBoxGroup = React.createClass
  getInitialState: ->
    groups: []
    # [{"name":"name","id":"id"}]

  pushMsg: (msgs)->
    if !Array.isArray(msgs)
      msgs = [msgs]
    sessionId = msgs[0].sessionId
    @data.msgs = @data.msgs || {}
    @data.msgs[sessionId] = @nim.mergeMsgs(@data.msgs[sessionId], msgs)

  onTeamMembers: (obj)->
    # 官方提供错误
    console.log('群id', obj.teamId, '群成员', obj.members)
    teamId = obj.teamId
    members = obj.members
    @data.teamMembers = @data.teamMembers || {};
    @data.teamMembers[teamId] = @nim.mergeTeamMembers(@data.teamMembers[teamId], members);
    @data.teamMembers[teamId] = @nim.cutTeamMembers(@data.teamMembers[teamId], members.invalid)
    console.log 'refreshTeamMembersUI'

  getTeamMembersDone: (error, obj)->
    console.log(error);
    console.log(obj);
    console.log('获取群成员' + (!error?'成功':'失败'));
    if !error
      @onTeamMembers(obj)

  onCreateTeam: (team)->
    console.log '你创建了一个群' + team
    @data.teams = @nim.mergeTeams(@data.teams, team)
    console.log 'refreshTeamsUI'
    @onTeamMembers 
              teamId: team.teamId
              members: @props.data.current_user.id

  onUpdateTeamMember:(teamMember)->
    console.log('群成员信息更新了', teamMember)
    @onTeamMembers
      teamId: teamMember.teamId,
      members: teamMember

  onSyncTeamMembersDone:()->
    console.log('同步群列表完成')

  componentDidMount: ->
    @data = {}
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


    onTeams = (teams)=>
      console.log '收到群列表', teams
      @data.teams = @nim.mergeTeams(@data.teams, teams)

      onInvalidTeams = (teams)=>
        @data.teams = @nim.cutTeams(@data.teams, teams);
        @data.invalidTeams = @nim.mergeTeams(@data.invalidTeams, teams)
        console.log 'refreshTeamsUI'
      onInvalidTeams(teams.invalid)
      
      console.log teams.length
      console.log teams[0]
      groups_ary = []
      for x in teams
        hash = 
        name : x.name
        id:  x.teamId
        groups_ary.push(hash)
      @setState
        groups: groups_ary


    hash = 
    appKey: @props.data.app_key,
    account: @props.data.current_user.id,
    token: @props.data.current_user.token,
    syncTeamMembers:true
    syncTeams:true
    onconnect: onConnect,
    onwillreconnect: onWillReconnect,
    ondisconnect: onDisconnect,
    onerror: onError,
    onsyncdone: onSyncDone,
    onroamingmsgs: onRoamingMsgs,
    onofflinemsgs: onOfflineMsgs,
    onteams: onTeams,
    onsynccreateteam: @onCreateTeam,
    onteammembers:@onTeamMembers,
    onsyncteammembersdone: @onSyncTeamMembersDone,
    onupdateteammember: @onUpdateTeamMember,

    onmsg: onMsg

    @nim = NIM.getInstance hash


    # 初始化后自动登录和同步数据
    # b加入了a的小组后如果收到群组消息才能显示出已加入的组
    getTeamsDone = (error, teams)->
      console.log(error)
      console.log(teams)
      console.log('获取群列表' + (!error?'成功':'失败'))
      if !error
         onTeams(teams)


    @nim.getTeams done: getTeamsDone
 
  join_group: ->
    user_ids = [@props.data.current_user.id]
    for dom in jQuery(document).find(".user-item input:checked")
      user_ids.push(jQuery(dom).attr("data").toString())
    group_name = jQuery(document).find(".group-name").val()

    createTeamDone = (error, obj)=>
      console.log error
      console.log obj
      console.log '创建' + obj.team.type + '群' + (!error?'成功':'失败')
      if !error
        @onCreateTeam(obj.team, obj.owner)

    create_group_hash = 
    type: 'normal',
    name: group_name,
    avatar: 'avatar',
    accounts: user_ids,
    intro: '群简介',
    announcement: '群公告',
    ps: '我建了一个高级->普通群',
    done: createTeamDone

    @nim.createTeam create_group_hash

  quit_group: (event)->
    leaveTeamDone = (error, obj)->
      console.log(error);
      console.log(obj);
      console.log('主动退群' + (!error?'成功':'失败'));

    id = jQuery(ReactDOM.findDOMNode(event.target)).parent().find("p").attr("data")
    @nim.leaveTeam
      teamId: id,
      done: leaveTeamDone

  render: ->
    message_input_area_data =
      send_message_text: @send_message_text
    <div className="chat-box-group">
      <MessageInputArea data={message_input_area_data} ref="message_input_area"/>
      <UsersList data={@props.data.users} function={@join_group}/>
      <GroupList data={@state.groups} function={@quit_group}  get_members={@get_members} invite_other_members={@invite_other_members}/>
    </div>

  send_message_text: ()->
    # 发送消息（群聊） 发一次 队友才知道被加
    message_text = @refs.message_input_area.refs.message_input.value
    receiver_group_id =  jQuery(document).find(".group-list input:checked").attr("value")

    sendMsgDone = (error, msg)=>
      console.log error
      console.log msg
      console.log '发送' + msg.scene + ' ' + msg.type + '消息' + (!error?'成功':'失败') + ', id=' + msg.idClient
      @pushMsg(msg)

    msg = @nim.sendText
        scene: 'team',
        to: receiver_group_id,
        text: message_text,
        done: sendMsgDone

    console.log  "正在发消息给" + msg.idClient
    @pushMsg(msg)

  get_members:(event)->
    id = jQuery(ReactDOM.findDOMNode(event.target)).parent().find("p").attr("data")
    console.log id
    @nim.getTeamMembers
      teamId: id,
      done: @getTeamMembersDone

  invite_other_members: (event)->
    id = jQuery(ReactDOM.findDOMNode(event.target)).parent().find("p").attr("data")
    user_ids = []
    for dom in jQuery(document).find(".user-item input:checked")
      user_ids.push(jQuery(dom).attr("data"))

    addTeamMembersDone = (error, obj)->
      console.log(error);
      console.log(obj);
      console.log('入群邀请发送' + (!error?'成功':'失败'))

    @nim.addTeamMembers
      teamId: id,
      accounts: user_ids,
      ps: '加入我们的群吧',
      done: addTeamMembersDone



GroupList = React.createClass
  render: ->
    <div className="group-list">
      <h3> 用户加入的讨论组</h3>
      { 
        if @props.data != null
          for item in @props.data
            <div className="user-item">
              <p data={item.id}/>{item.name}
              <input type="checkbox" value={item.id}/>
              <button className="ui button" onClick={@props.function}>退出讨论组</button>
              <button className="ui button" onClick={@props.get_members}>获取成员列表</button>
              <button className="ui button" onClick={@props.invite_other_members}>邀请其他成员</button>
            </div>
        else
          <p>没有加入讨论组</p>  
      }
    </div>

  


  invite_other_members:(event)->
    id = jQuery(ReactDOM.findDOMNode(event.target)).parent().find("p").attr("data")
    user_ids = []
    for dom in jQuery(document).find(".user-item input:checked")
      user_ids.push(jQuery(dom).attr("data"))
    builder = new RL_YTX.InviteJoinGroupBuilder()
    builder. setGroupId(id)
    builder. setMembers(user_ids)
    builder. setConfirm(1)
    RL_YTX.inviteJoinGroup builder
    ,
    (obj)->
      console.log obj
      # 等待被邀请者同意
    ,
    (obj)->
      console.log "邀请失败"

UsersList = React.createClass
  render: ->
    <div className="user-list">
      <h3> 用户选择列表</h3>
      {
        for item in @props.data
          <div className="user-item">
            <input type="checkbox" data={item.id} value={item.name}/>{item.name}
          </div>  
      }
      <h3> 新建讨论组名称</h3>
      <input type="text" className="group-name" />
      <button className="ui button" onClick={@props.function}>邀请加入讨论组</button>
    </div>

MessageInputArea = React.createClass
  render: ->
    <div className="text-input">
      <div className="textarea">
        <textarea type="text" placeholder="输入你想说的话（先勾选一个群组）" ref="message_input" onKeyDown={@textarea_keydown} onKeyUp={@textarea_keyup}/>
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

    