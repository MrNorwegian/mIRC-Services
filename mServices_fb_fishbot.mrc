on *:load: { set %mServices.loaded.fishbot true | ms.echo green Loaded mServices_fishbot.mrc }
on *:unload: { unset %mServices.loaded.fishbot | ms.echo red Unloaded mServices_fishbot.mrc }


; <client numeric> <targetchan\targetclient numeric> :<message>
alias ms.fb.fishbot.privmsg { 

  ; Setting fishbot's numeric and channel in a variable.
  var %ms.fb.pmsg.nc %ms.fb.fishbot.numeric $2

  ; Remove : from the beginning of the message.
  ; First word
  var %ms.fb.pmsg.cmd $mid($3,2,9999)

  ; Second word +++++
  var %ms.fb.pmsg.text $mid($3,2,9999) $4-
  ; Only second word
  var %ms.fb.pmsg.args $4-

  ; Check if fishbot ison the channel.
  if ( $istok($ms.config.get(channels,fishbot),$2,44) ) { 

    ; Ugly temp-perm check
    if ( o isin $ms.get.client(modes,$1) ) && ( $left(%ms.fb.pmsg.cmd,1) == ! ) {
      if ( %ms.fb.pmsg.cmd == !addcmd ) { 
        if ( $chr(124) isin %ms.fb.pmsg.args ) {
          ; Save cmd and replace spaces with dots.
          var %arg $replace($gettok(%ms.fb.pmsg.args,1,124),$chr(32),$chr(46))
          ; remove first dot if it exists. (this happens when space after chr125 in !addcmd)
          var %arg $iif($left(%arg,1) == $+($chr(46)),$mid(%arg,2,9999),%arg)
          ; Also need to remove . in the end of the setence
          var %arg $iif($right(%arg,1) == $+($chr(46)),$left(%arg,-1),%arg)
          var %ms.fb.fishbotcmd $+(%ms.fb.fishbot.numeric,.,%arg)
          var %ms.fb.fishbotcmddata $gettok(%ms.fb.pmsg.args,2,124)
          if ( $ms.db(read,fb,%ms.fb.fishbotcmd) ) { 
            ms.servicebot.say %ms.fb.pmsg.nc Command already exists, skipping.
          }
          else { 
            ms.servicebot.say %ms.fb.pmsg.nc Adding command: %arg -> %ms.fb.fishbotcmddata
            ms.db write fb %ms.fb.fishbotcmd %ms.fb.fishbotcmddata
          }
        }
        else { ms.servicebot.say %ms.fb.pmsg.nc Invalid command format, please use: !addcmd <command\setence> | <response> [| <response2> ...] }
      }
      elseif ( %ms.fb.pmsg.cmd == !delcmd ) { 
        if ( %ms.fb.pmsg.args ) { 
          ; Save cmd and replace spaces with dots.
          var %arg $replace($gettok(%ms.fb.pmsg.args,1,46),$chr(32),$chr(46))
          ; remove first dot if it exists. (this happens when space after chr125 in !delcmd)
          var %arg $iif($left(%arg,1) == $+($chr(46)),$mid(%arg,2,9999),%arg)
          ; Also need to remove . in the end of the setence
          var %arg $iif($right(%arg,1) == $+($chr(46)),$left(%arg,-1),%arg)
          var %ms.fb.fishbotcmd $+(%ms.fb.fishbot.numeric,.,%arg)
          if ( $ms.db(read,fb,%ms.fb.fishbotcmd) ) { 
            ms.servicebot.say %ms.fb.pmsg.nc Removing command: %arg
            ms.db rem fb %ms.fb.fishbotcmd
          }
          else { ms.servicebot.say %ms.fb.pmsg.nc Command does not exist, skipping. }
        }
        else { ms.servicebot.say %ms.fb.pmsg.nc Invalid command format, please use: !delcmd <command\setence> }
      }
      elseif ( %ms.fb.pmsg.cmd == !listcmds ) { 
        var %fb $hget(fb,0).data
        var %fbi 1
        ms.servicebot.say %ms.fb.pmsg.nc $+(Total fishbot commands: %fb)
        while (%fbi <= %fb) { 
          ms.servicebot.say %ms.fb.pmsg.nc %fbi $gettok($hget(fb,%fbi).item,2-,46) -> $hget(fb,%fbi).data
          inc %fbi
        }
      }
      elseif ( %ms.fb.pmsg.cmd == !resetcmds ) { 
        var %fb $hget(fb,0).data
        var %fbi 1
        ms.servicebot.say %ms.fb.pmsg.nc $+(Removing fishbot commands: %fb)
        while (%fbi <= %fb) { 
          ms.servicebot.say %ms.fb.pmsg.nc %fbi $gettok($hget(fb,%fbi).item,2-,46) -> $hget(fb,%fbi).data
          ms.db rem fb $hget(fb,%fbi).item
          inc %fbi
        }
      }
    }
    else {
      ; First check for setence
      var %text $+(%ms.fb.fishbot.numeric,.,$replace(%ms.fb.pmsg.text,$chr(32),$chr(46)))
      if ( $ms.db(read,fb,%text) ) {
        var %ms.fb.fishbotcmddata $ms.db(read,fb,%text)
        ms.servicebot.say %ms.fb.pmsg.nc $replace(%ms.fb.fishbotcmddata,$chr(46),$chr(32))
        return
      }
      ; Loop the users sentence and check for commands.
      else {
        var %t $numtok(%ms.fb.pmsg.text,32)
        while (%t) { 
          var %ms.fb.fishbotcmd $+(%ms.fb.fishbot.numeric,.,$gettok(%ms.fb.pmsg.text,%t,32))
          var %ms.fb.fishbotcmddata $ms.db(read,fb,%ms.fb.fishbotcmd)
          if ( %ms.fb.fishbotcmddata ) {
            ms.servicebot.say %ms.fb.pmsg.nc $replace(%ms.fb.fishbotcmddata,$chr(46),$chr(32))

            ; Stop if we found a command.
            ; Later, stop only this match, next can also be something
            return
          }
          dec %t
        }
      }
    }
  }
  return
}
