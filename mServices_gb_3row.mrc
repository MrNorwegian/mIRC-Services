@ -1,186 +0,0 @@
alias b {
  if ( *c* iswm $chan($chan).mode ) { return $1 }
  else { return $+($chr(2),$1-,$chr(2)) }
}

alias tree_rute { 
  if ( *c* iswm $chan($chan).mode ) { return $+($chr(40),$1,$chr(41)) }
  else { 
    if ( $1 isin %win ) { return $+($chr(3),12,$chr(40),$chr(3),9,$1,$chr(3),12,$chr(41)) }
    else { return $+($chr(3),4,$chr(40),$chr(3),9,$1,$chr(3),4,$chr(41)) }
  }
}
alias ms.gb.3row {
  if ( $3 == !3row2 ) {
    var %ms.gb.nick $1
    var %ms.gb.chan $2
    var %ms.gb.cmd $3
    var %ms.gb.arg1 $4
    var %ms.gb.arg2 $5
    var %ms.gb.arg3 $6

    ; todo, nick check
    if ( %ms.gb.arg1 == reset ) && ($nick == naka) { 
      ms.servicebot.say $ms.config.get(numeric,%ms.gb.bot) %ms.gb.chan Deleting channels: $readini(rad.ini,data,games)
      var %i $numtok($readini(rad.ini,data,games),32)
      while (%i) {
        remini rad.ini $gettok($readini(rad.ini,data,games),%i,32)
        remini rad.ini $+($gettok($readini(rad.ini,data,games),%i,32),_stats)
        dec %i
      }
      .msg %ms.gb.chan Deleting data.
      remini rad.ini data
      .msg %ms.gb.chan Removing $numtok($readini(rad.ini,users,totaln),32) users.
      remini rad.ini users
      .msg %ms.gb.chan Done.
    }
    elseif ( %ms.gb.arg1 == create ) {
      if (!$readini(rad.ini,users,$address($nick,1))) {
        ; = handle win los tot
        writeini rad.ini users totaln $addtok($readini(rad.ini,users,totaln),$nick,32)
        writeini rad.ini users totala $addtok($readini(rad.ini,users,totala),$address($nick,1),32)
        writeini rad.ini users $address($nick,1) $nick 0 0 0
        writeini rad.ini $+(%ms.gb.chan,_stats) $nick 0 0 0
        writeini rad.ini $+(%ms.gb.chan,_stats) $3 0 0 0
        .msg %ms.gb.chan %ms.gb.nick - Din bruker er nå opprettet med $nick som brukernavn etter $address($nick,1) hostmask.
      }
    }
    elseif ( %ms.gb.arg1 == start ) {
      if ($3) {
        if ($3 ison $chan) {
          if ( $istok($readini(rad.ini,users,totala),$address($3,1),32) ) {
            if (!$readini(rad.ini,$chan,players)) {
              set %3rad_rounds_ [ $+ [ $chan ] ] 0

              writeini rad.ini $chan start $nick
              writeini rad.ini $chan turn $nick
              writeini rad.ini $chan $nick X
              writeini rad.ini $chan $3 O
              writeini rad.ini $chan players $nick $3
              writeini rad.ini data games $iif($readini(rad.ini,data,games),$addtok($readini(rad.ini,data,games),$chan,32),$chan)
              writeini rad.ini $chan r1 N N N
              writeini rad.ini $chan r2 N N N
              writeini rad.ini $chan r3 N N N
              .msg $chan Starter spillet mellom $+($chr(40),$nick,$chr(32),$readini(rad.ini,$chan,$nick),$chr(41)) og $+($chr(40),$3,$chr(32),$readini(rad.ini,$chan,$3),$chr(41),.) $+($chr(40),$nick,$chr(32),$readini(rad.ini,$chan,$nick),$chr(41)) Begynner.
              .msg $chan $b(Husk å ikke bytt nick under spillet.)
              tree_cycle $chan
            }
            else { .msg $chan Det er allerede et spill gående mellom $readini(rad.ini,$chan,players) | halt }
          }
          else { .msg $chan $3 har ikke noe bruker i dette spillet, personen må " !3rad create " | halt }
        }
        else { .msg $chan $3 er ikke i kanalen. | halt }
      }
      else { .msg $chan Du har ikke nevnt noen. | halt }
    }
    elseif ( %ms.gb.arg1  == stop ) { 
      remini rad.ini $chan
      unset %3rad_rounds_ [ $+ [ $chan ] ]
      .msg $chan Done.

    }
    elseif ( %ms.gb.arg1  == status ) {
      if ($readini(rad.ini,users,$address($nick,1))) {
        var %handle $gettok($readini(rad.ini,users,$address($nick,1)),1,32)
        var %wins $gettok($readini(rad.ini,users,$address($nick,1)),2,32)
        var %tap $gettok($readini(rad.ini,users,$address($nick,1)),3,32)
        var %games $gettok($readini(rad.ini,users,$address($nick,1)),4,32)
        .msg $chan $nick - Du ( $+ %handle $+ ) har spilt totalt %games runder, der du har vunnet %wins og tapt %tap
      }
    }
    elseif ( %ms.gb.arg1  == rute ) {
      if ($readini(rad.ini,$chan,turn) == $nick) { 
        if ( $regex($3,/^[1-9]{1}$/) ) { 
          if ( $tree_control(free,$3) == 1 ) {
            if ( $tree_control(insert,$3,$nick) == 1 ) {
              .msg $chan Oki $+($chr(40),$nick,$chr(32),$readini(rad.ini,$chan,$nick),$chr(41)) du valgte rute nr $3 $+ . La oss se om du vinner 
              if ( $tree_control(winner,$chan,$nick) == 1 ) { 
                .msg $chan $+($chr(40),$nick,$chr(32),$readini(rad.ini,$chan,$nick),$chr(41)) VANT !!!! 
                tree_cycle $chan
                .msg $chan Vinner-debug " %win "
                ; Lagre antal runder, osv.
                ; stoppe spillet.
                ; etc
              }
              if ( %3rad_rounds_ [ $+ [ $chan ] ] >= 9 ) {
                unset %3rad_rounds_ [ $+ [ $chan ] ]
                remini rad.ini $chan
                ; writeini rad.ini data games $iif($readini(rad.ini,data,games),$addtok($readini(rad.ini,data,games),$chan,32),$chan)
                .msg $chan Spillet er over.
              }
              else { 
                if ($gettok($readini(rad.ini,$chan,players),1,32) == $readini(rad.ini,$chan,turn)) { 
                  writeini rad.ini $chan turn $gettok($readini(rad.ini,$chan,players),2,32)
                }
                elseif ($gettok($readini(rad.ini,$chan,players),2,32) == $readini(rad.ini,$chan,turn)) { 
                  writeini rad.ini $chan turn $gettok($readini(rad.ini,$chan,players),1,32)
                }
                tree_cycle $chan
                .msg $chan Nei, det gjorde du vist ikke :(
                .msg $chan Nå er det $+($chr(40),$readini(rad.ini,$chan,turn),$chr(32),$readini(rad.ini,$chan,$readini(rad.ini,$chan,turn)),$chr(41)) sin tur, kanskje han\hun er flinkere :P
                .msg $chan Velg en rute $+($chr(40),$readini(rad.ini,$chan,turn),$chr(32),$readini(rad.ini,$chan,$readini(rad.ini,$chan,turn)),$chr(41)) ( !3rad rute 1-9 )
              }
            }
            else { .msg $chan Error, en feil i scriptet (kode "insert") (Debug " $1- ") | .msg $chan Gi naka besjed. | halt }
          }
          else { .msg $chan Den ruta er tatt, du må velge en annen. | tree_cycle $chan }
        }
        else { .msg $chan Du må velte en rute mellom 1 til 9 | tree_cycle $chan }
      }
      else { .msg $chan $nick Det er ikke din tur. }
    }
    elseif ( $2 == cycle ) { tree_cycle $chan }
    else { .msg $chan Ugjyldig komando. ( create|start|stop|status ) | halt }
  }
}
alias tree_ccontrol {  
  if ( $1 == info ) { return $gettok($readini(rad.ini,$2,r $+ [ $gettok(%rule [ $+ [ $3 ] ],1,32) ] ]),$gettok(%rule [ $+ [ $3 ] ],2,32),32) }
}
alias tree_control {
  if ( $1 == free ) {
    if ( $gettok($readini(rad.ini,$chan,r $+ [ $gettok(%rule [ $+ [ $2 ] ],1,32) ] ]),$gettok(%rule [ $+ [ $2 ] ],2,32),32) == N ) { return 1 }
    else { return 2 }
  }
  if ( $1 == insert ) {
    inc %3rad_rounds_ [ $+ [ $chan ] ]
    var %curr $readini(rad.ini,$chan,r $+ [ $gettok(%rule [ $+ [ $2 ] ],1,32) ] ])
    var %tmp_new $puttok(%curr,$readini(rad.ini,$chan,$3),$gettok(%rule [ $+ [ $2 ] ],2,32),32)
    writeini rad.ini $chan r $+ [ $gettok(%rule [ $+ [ $2 ] ,1,32) ] ] %tmp_new
    return 1
  }

  if ( $1 == winner ) { 
    if ( $tree_ccontrol(info,$2,1) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,4) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,7) == $readini(rad.ini,$2,$3) ) { set -u2 %win 1 4 7 | return 1 }    
    elseif ( $tree_ccontrol(info,$2,2) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,5) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,8) == $readini(rad.ini,$2,$3) ) { set -u2 %win 2 5 8 | return 1 }
    elseif ( $tree_ccontrol(info,$2,3) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,6) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,9) == $readini(rad.ini,$2,$3) ) { set -u2 %win 3 6 9 | return 1 }
    elseif ( $tree_ccontrol(info,$2,7) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,8) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,9) == $readini(rad.ini,$2,$3) ) { set -u2 %win 7 8 9 | return 1 }
    elseif ( $tree_ccontrol(info,$2,4) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,5) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,6) == $readini(rad.ini,$2,$3) ) { set -u2 %win 4 5 6 | return 1 }
    elseif ( $tree_ccontrol(info,$2,1) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,2) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,3) == $readini(rad.ini,$2,$3) ) { set -u2 %win 1 2 3 | return 1 }
    elseif ( $tree_ccontrol(info,$2,1) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,5) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,9) == $readini(rad.ini,$2,$3) ) { set -u2 %win 1 5 9 | return 1 }
    elseif ( $tree_ccontrol(info,$2,3) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,5) == $readini(rad.ini,$2,$3) ) && ( $tree_ccontrol(info,$2,7) == $readini(rad.ini,$2,$3) ) { set -u2 %win 3 5 7 | return 1 }
    else { return 0 }
  }
}
alias tree_rute { 
  if ( *c* iswm $chan($chan).mode ) { return $+($chr(40),$1,$chr(41)) }
  else { 
    if ( $1 isin %win ) {
      return $+($chr(3),12,$chr(40),$chr(3),9,$1,$chr(3),12,$chr(41)) 
    }
    else {
      return $+($chr(3),4,$chr(40),$chr(3),9,$1,$chr(3),4,$chr(41)) 
    }
  }
}
alias tree_cycle {
  var %i 1
  while (%i <= 3) {
    var %out1 $replace($readini(rad.ini,$1,r1),X,$tree_rute(X,$1),O,$tree_rute(O),N,$tree_rute($chr(32)))
    var %out2 $replace($readini(rad.ini,$1,r2),X,$tree_rute(X,$1),O,$tree_rute(O),N,$tree_rute($chr(32)))
    var %out3 $replace($readini(rad.ini,$1,r3),X,$tree_rute(X,$1),O,$tree_rute(O),N,$tree_rute($chr(32)))
    inc %i
  }
  .msg $chan %out1
  .msg $chan %out2
  .msg $chan %out3
}