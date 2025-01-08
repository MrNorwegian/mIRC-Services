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
  if ( $1 == channels ) { return $readini(%mServices.config,$2,channels) }
  if ( $1 == chan ) { return $readini(%mServices.config,$2,chan) }
  if ( $1 == ac ) { return $readini(%mServices.config,$2,account) }
}

; $ms.config.get(nick,cservice) - returns nick to cservice and caches it in ram for next time.
; This replaces mServices.config in the future if needed.
; TODO, use fullnumeric and numeric instead of hardreplace with $iif($1 == numeric,$+(%ms.numeric,%ms.conf.tmp),%ms.conf.tmp)
; This need to be changed everywhere in the code.

; TODO, need to redo this caching method, i suspect it's not working as intended on heavy load.
alias ms.config.get { 
  if ( $2 ) {
    var %ms.config.gets configured load nick fullnumericISTODO numeric user host ip realname modes account chan channels debug debugchan report reportchan adminchan
    var %ms.config.num $numtok(%ms.config.gets,32)
    while ( %ms.config.num ) { 
      if ( $1 == $gettok(%ms.config.gets,%ms.config.num,32) ) {
        ; Was the configuration read in the last 1 second? this is a hack to force to read the configuration from the ini file if it's older than 1 second, this is to prevent the cache from being outdated.
        if ( $ms.db(read,cmdlastime,$1) <= $calc($ctime - 1) ) { 
          var %ms.conf.result $ms.db(read,config,$+($2,.,$1))
          if ( %ms.conf.result ) { 
            ; TODO, fullnumeric
            return $iif($1 == numeric,$+(%ms.numeric,%ms.conf.result),%ms.conf.result)
          }
          else { 
            var %ms.conf.tmp $readini(%mServices.config,$2,$1)
            ms.db write config $+($2,.,$1) %ms.conf.tmp
            ; TODO, fullnumeric
            return $iif($1 == numeric,$+(%ms.numeric,%ms.conf.tmp),%ms.conf.tmp)
          }
        }
        else { 
          var %ms.conf.tmp $readini(%mServices.config,$2,$1)
          ms.db write config $+($2,.,$1) %ms.conf.tmp
          ; TODO, fullnumeric
          return $iif($1 == numeric,$+(%ms.numeric,%ms.conf.tmp),%ms.conf.tmp)
        }
      }
      dec %ms.config.num
    }
  }
}

; For resetting the configuration.
alias ms.mServices.makeconfig  {
  ; Our services configuration.
  writeini -n %mServices.config main numeric 512
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
