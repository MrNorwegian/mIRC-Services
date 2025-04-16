on *:load: { set %mServices.loaded.fishbot true | ms.echo green Loaded mServices_fishbot.mrc }
on *:unload: { unset %mServices.loaded.fishbot | ms.echo red Unloaded mServices_fishbot.mrc }


; <client numeric> <targetchan\targetclient numeric> :<message>
alias ms.fb.fishbot.privmsg { 

  ; Remove : from the beginning of the message.
  var %ms.fb.pmsg.cmd $mid($3,2,9999)
  var %ms.fb.pmsg.text $mid($3,2,9999) $4-
  var %ms.fb.pmsg.arg1 $4
  var %ms.fb.pmsg.arg2 $5

  ; Setting fishbot's numeric and channel in a variable.
  var %ms.fb.pmsg.nc %ms.fb.fishbot.numeric $2

  ; Check if fishbot ison the channel.
  if ( $istok($ms.config.get(channels,fishbot),$2,44) ) { 

    if ( ag isin %ms.fb.pmsg.text ) { ms.servicebot.say %ms.fb.pmsg.nc Ag, ag ag ag ag ag AG AG AG! }
    elseif ( bounce isin %ms.fb.pmsg.text ) { ms.servicebot.say %ms.fb.pmsg.nc moo }
    elseif ( candy isin %ms.fb.pmsg.text ) { ms.servicebot.say %ms.fb.pmsg.nc Same reason. I love candy. }
    elseif ( crack isin %ms.fb.pmsg.text ) { ms.servicebot.say %ms.fb.pmsg.nc Doh, there goes another bench! }
    elseif ( snake isin %ms.fb.pmsg.text ) { ms.servicebot.say %ms.fb.pmsg.nc Ah snake a snake! Snake, a snake! Ooooh, it's a snake! }
    elseif ( %ms.fb.pmsg.cmd == fishbot ) { 
      if (%ms.fb.pmsg.arg1 == help) { ms.servicebot.say %ms.fb.pmsg.nc I am a fishbot, I can do anything. }
      elseif (%ms.fb.pmsg.arg1 == owns) { ms.servicebot.say %ms.fb.pmsg.nc Aye, I do. }
      elseif (%ms.fb.pmsg.arg1 == $null) { ms.servicebot.say %ms.fb.pmsg.nc Yes ? }
      return
    }
    elseif ( fish isin %ms.fb.pmsg.text ) { 
      if ( go m00 == %ms.fb.pmsg.arg1 %ms.fb.pmsg.arg2 ) || ( go moo == %ms.fb.pmsg.arg1 %ms.fb.pmsg.arg2 ) { 
        ms.servicebot.say %ms.fb.pmsg.nc ohh yes they do!
      }
      ; ACTION notes that $nick is truly enlightened.
      else { ms.servicebot.say %ms.fb.pmsg.nc fish go m00! }
    }
    elseif ( hampster isin %ms.fb.pmsg.text ) { ms.servicebot.say %ms.fb.pmsg.nc There is no 'p' in hamster you retard. }
    elseif ( spoon isin %ms.fb.pmsg.text ) { ms.servicebot.say %ms.fb.pmsg.nc There is no spoon. }
  }
  return
}
