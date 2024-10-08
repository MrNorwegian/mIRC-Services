on *:load: { set %mServices.spybot.loaded true | ms.echo green Loaded mServices_spybot.mrc }
on *:unload: { unset %mServices.spybot.loaded | ms.echo red Unloaded mServices_spybot.mrc }

alias ms.load.spybot {
  if ( %mServices.spybot.loaded == true ) { 
    ms.echo green prepping loading spybot
    set %ms.spybot.numeric $ms.makenewclientnumeric
    set %ms.spybot.nick spybot
    set %ms.spybot.user spybot
    set %ms.spybot.host spybot.is.here.to.spy.on.you
    set %ms.spybot.realname spybot oO
    set %ms.spybot.modes +x
    set %ms.spybot.channels #spychan
    ms.echo green spawning %ms.spybot.nick ! %ms.spybot.user @ %ms.spybot.host [ %ms.spybot.realname ] with modes: %ms.spybot.modes 

    ; Making new bot and writing it to the sevrer's database
    mServices.sraw N %ms.spybot.nick 1 $ctime %ms.spybot.user %ms.spybot.host %ms.spybot.modes $inttobase64($longip(127.0.0.1),6) %ms.spybot.numeric $+(:,%ms.spybot.realname)
    ms.newclient %mServices.numeric N %ms.spybot.nick 1 $ctime %ms.spybot.user %ms.spybot.host %ms.spybot.modes $inttobase64($longip(127.0.0.1),6) %ms.spybot.numeric $+(:,%ms.spybot.realname)

    mServices.raw %ms.spybot.numeric J %ms.spybot.channels
  }
}
