on *:load: { mServices.conf | ms.echo green Loaded mServices_conf.mrc }
on *:unload: { unset %mServices.* | ms.echo red Unloaded mServices_conf.mrc }

on *:start:{
  if ( %mServices.configured == NO ) { ms.echo red Configuration is not set, please configure it before starting the server. }
}

; parse the configuration.
alias mServices.config {
  ; Our services configuration.
  if ( $1 == numeric ) { 
    if ( $readini(%mServices.config,main,numeric) <= 4095 ) { return $v1 }
    else { echo 4 -st * /mServices.config: Numeric must be between 0 and 4095. | halt }
  }
  if ( $1 == maxcon ) { return $readini(%mServices.config,main,maxcon) }
  if ( $1 == serverName ) { return $readini(%mServices.config,main,serverName) }
  if ( $1 == info ) { return $readini(%mServices.config,main,info) }

  ; Link configuration.
  if ( $1 == hostname ) { return $readini(%mServices.config,main,hostname) }
  if ( $1 == port ) { 
    if ( $readini(%mServices.config,main,port) isnum ) { return $v1 }
    else { echo 4 -st * /mServices.config: Port must be a number. | halt }
  }
  if ( $1 == password ) || ( $1 == pass ) { return $readini(%mServices.config,main,password) }

  ; Misc.
  if ( $1 == flags ) { return $readini(%mServices.config,main,flags) }

  ; Checking if %ms.mServices.window is set, this variable is used alot so we "cache" it.
  if ( $1 == window ) { 
    if ( %mServices.window ) { return %mServices.window }
    else { set %mServices.window $readini(%mServices.config,main,window) | return %mServices.window }
  }
  if ( $1 == configured ) { return $readini(%mServices.config,main,configured) }

  if ( $1 == rawdebug ) { 
    ; Checking if %ms.mServices.rawdebug is set, this variable is used alot so we "cache" it.
    if ( %ms.mServices.rawdebug ) { return %ms.mServices.rawdebug }
    else { set %ms.mServices.rawdebug $readini(%mServices.config,main,rawdebug) | return %ms.mServices.rawdebug }
  }
  ; Universal alias for getting servicebot configuration.
  if ( $1 == servicebots ) { return $readini(%mServices.config,main,servicebots) }
  if ( $1 == numeric ) { return $readini(%mServices.config,$2,numeric) }
  if ( $1 == nick ) { return $readini(%mServices.config,$2,nick) }
  if ( $1 == user ) { return $readini(%mServices.config,$2,user) }
  if ( $1 == host ) { return $readini(%mServices.config,$2,host) }
  if ( $1 == ip ) { return $readini(%mServices.config,$2,ip) }
  if ( $1 == realname ) { return $readini(%mServices.config,$2,realname) }
  if ( $1 == modes ) { return $readini(%mServices.config,$2,modes) }
  if ( $1 == channels ) { return $readini(%mServices.config,$2,chan) }
  if ( $1 == ac ) { return $readini(%mServices.config,$2,account) }
}

; For resetting the configuration.
alias ms.mServices.makeconfig  {
  ; Our services configuration.
  writeini -n %mServices.config main numeric 0
  writeini -n %mServices.config main maxcon 512
  writeini -n %mServices.config main serverName changeme.localhost
  writeini -n %mServices.config main info A mIRC Services server

  ; Link configuration.
  writeini -n %mServices.config main hostname localhost
  writeini -n %mServices.config main port 4400
  writeini -n %mServices.config main password changeme

  writeini -n %mServices.config main flags +
  writeini -n %mServices.config main window @mServices
  writeini -n %mServices.config main configured NO
  writeini -n %mServices.config main rawdebug true

  ; Set what servicebots to launch.
  writeini -n %mServices.config main servicebots spybot,funbots

  set %mServices.config mServices.ini
  echo -at mServices.* variables is reset to default values, please configure them before starting the server.
}

menu Status {
  mIRC Services Start:/mServices.start
  mIRC Services Stop:/mServices.stop
  mIRC Services ResetConfig:/ms.mServices.makeconfig
  $iif(%mServices.loaded.funbots == true,mIRC Services FunBots ResetConfig):{ ms.funbots.makeconfig }
  $iif(%mServices.loaded.spybot == true,mIRC Services FunBots ResetConfig):{ ms.spybot.makeconfig }
  -
  mIRC Services ResetDB:/ms.db.reset
  mIRC Services ListDB:/ms.db list
  mIRC Services Window:/window $mServices.config(window)
}
