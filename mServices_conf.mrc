on *:load: { mServices.conf | ms.echo green Loaded mServices_conf.mrc }
on *:unload: { unset %mServices.* | ms.echo red Unloaded mServices_conf.mrc }

on *:start:{
  if ( %mServices.configured == NO ) { ms.echo red Configuration is not set, please configure it before starting the server. }
}
; parse the configuration.
alias mServices.config {
  ; Our services configuration.
  if ( $1 == numeric ) { 
    if ( %mServices.numeric <= 4095 ) { return %mServices.numeric }
    else { echo 4 -st * /mServices.config: Numeric must be between 0 and 4095. | halt }
  }
  if ( $1 == serverName ) { return %mServices.serverName }
  if ( $1 == info ) { return %mServices.info }

  ; Link configuration.
  if ( $1 == hostname ) { return %mServices.hostname }
  if ( $1 == port ) { 
    if ( %mServices.port isnum ) { return %mServices.port }
    else { echo 4 -st * /mServices.config: Port must be a number. | halt }
  }
  if ( $1 == password ) || ( $1 == pass ) { return %mServices.password }

  ; Misc.
  if ( $1 == flags ) { return %mServices.flags }
  if ( $1 == window ) { return %mServices.window }
  if ( $1 == configured ) { return %mServices.configured }
  if ( $1 == rawdebug ) { return %ms.mServices.rawdebug }

}

; For resetting the configuration.
alias mServices.conf {
  ; Our services configuration.
  set %mServices.numeric 0
  set %mServices.info A jupe server for ircu P10 protocol in mSL.
  set %mServices.serverName changeme.localhost

  ; Link configuration.
  set %mServices.server localhost
  set %mServices.port 4400
  set %mServices.password changeme

  ; Misc.
  set %mServices.flags +
  set %mServices.window @mServices
  set %mServices.configured NO
  set %ms.mServices.rawdebug true
  echo -at mServices.* variables is reset to default values, please configure them before starting the server.
}
menu Status {
  mIRC Services Start:/mServices.start
  mIRC Services Stop:/mServices.stop
  mIRC Services ResetConfig:/mServices.conf
  mIRC Services Window:/window $mServices.config(window)
}