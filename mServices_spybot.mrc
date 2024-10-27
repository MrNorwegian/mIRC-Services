on *:load: { set %mServices.spybot.loaded true | ms.echo green Loaded mServices_spybot.mrc }
on *:unload: { unset %mServices.spybot.loaded | ms.echo red Unloaded mServices_spybot.mrc }

alias ms.load.spybot {
  if ( %mServices.spybot.loaded == true ) { 
    ms.echo blue [mServices mIRC Services] prepping loading spybot
    set %ms.spybot.numeric $ms.picknumeric
    set %ms.spybot.nick spybot
    set %ms.spybot.user spybot
    set %ms.spybot.host is.here.to.spy.on.you
    set %ms.spybot.ip 127.0.0.1
    set %ms.spybot.realname spybot oO
    set %ms.spybot.modes +x

    ; More channels must be comma separated.
    set %ms.spybot.chan #spychan

    ms.servicebot.spawn %ms.spybot.nick $ctime %ms.spybot.user %ms.spybot.host %ms.spybot.modes %ms.spybot.ip %ms.spybot.numeric %ms.spybot.realname 
    ms.servicebot.join %ms.spybot.numeric %ms.spybot.chan
  }
}
alias ms.unload.spybot { 
  if ( %mServices.spybot.loaded == true ) { 
    ms.servicebot.despawn %ms.spybot.numeric 
  }
}

alias ms.spybot.report { 
  ; remember: %ms.status 

  if ( $1 === S ) { 
    return
  }
  ; N %ms.ns.num %ms.ns.name %ms.ns.hop %ms.ns.starttime %ms.ns.linktime %ms.ns.protocol %ms.ns.maxcon %ms.ns.flags %ms.ns.desc
  if ( $1 === N ) { 
    return
  }
  ; C %ms.cc.num %ms.cc.chan
  if ( $1 === C ) { 
    return
  }
  ; J %ms.cj.num %ms.cj.chan
  if ( $1 === J ) { 
    return
  }
  ; L %ms.cl.num %ms.cl.chan
  if ( $1 === L ) { 
    return
  }
  ; Q %ms.cq.num %ms.cq.chans 
  if ( $1 === Q ) { 
    return
  }
  ; K %ms.ck.num %ms.ck.chan %ms.ck.reason
  if ( $1 === K ) { 
    return
  }
  ; M
  if ( $1 === M ) { 
    return
  }
}