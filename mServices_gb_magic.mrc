; Original game was made by Z*Z @ UnderNet
; This is a modified version of the game
; The game is a simple game where the bot will ask you to pick a number between 1-21
; The bot will then ask you to pick a row where the number is located
; The bot will then ask you to pick another row where the number is located
; The bot will then ask you to pick the last row where the number is located
; The bot will then tell you what number you picked

alias ms.gb.magic {
  ; var %ms.gb.nick $1
  ; var %ms.gb.chan $2
  ; var %ms.gb.msg $remove($3,:) $4-

  set %ms.gb.magic.cmd $3
  set %ms.gb.botnum $ms.config.get(numeric,gamebot)

  ; Start a new game
  if ( %ms.gb.magic.cmd == !magic ) { PickRow $1 }

  ; Play the game
  if ( %tmp.game1.room = $2 ) {
    ; First user to pick a number will be the one playing
    if (%tmp.game1.nick == $null) && ($regex($1-,/([123]|green|red|blue)/i)) {
      var %tmp.game.choosen $regml(1)
      set %tmp.game.num 1

      set %tmp.game1.nick $1 
      ms.servicebot.say %ms.gb.botnum %tmp.game1.room Okey $ms.get.client(nick,$1) $+ $chr(44) we gonna play!
      game.StickRow %tmp.game.choosen
    }
    ; 
    elseif (%tmp.game1.nick == $1) && ($regex($1-,/([123]|green|red|blue)/i)) {
      var %tmp.game.choosen $regml(1)
      inc %tmp.game.num
      if (%tmp.game.num < 3) {
        game.StickRow %tmp.game.choosen
      }
      else  {
        Game.StickRow %tmp.game.choosen
        ;disable #game1
      }
    }
    ; Reject other users trying to play if the game is already started
    elseif (%tmp.game1.nick != $1) && ($regex($1-,/(?:[123]|green|red|blue)/i)) {
      ms.servicebot.say %ms.gb.botnum $2 $ms.get.client(nick,$1) $+ : I'm sorry, i can only play with one at time.
    }
  }
}

; First stage of the game, everyone can play but first user choosing a number will be the one playing
alias PickRow {
  unset %tmp.game*
  set %tmp.game1 [1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21]
  ms.servicebot.say %ms.gb.botnum %ms.gb.chan Please pick a number here, do not say the number but what row\color your number is in !
  ms.servicebot.say %ms.gb.botnum %ms.gb.chan (00,03[1][2][3][4][5][6][7]) (00,04[8][9][10][11][12][13][14]) (00,02[15][16][17][18][19][20][21])
  ms.servicebot.say %ms.gb.botnum %ms.gb.chan Which row can I find your number in or what colour are your number?
  set %tmp.game1.room %ms.gb.chan
}

alias game.rows {
  var %tmp.game.i 1
  set %tmp.gamen1,%tmp.gamen2,%tmp.gamen3
  game.trim

  while ($gettok(%tmp.game1,%tmp.game.i,44) != $null) { 
    set $+(%,tmp.gamen,$calc(((%tmp.game.i -1) % 3)+1)) $($+(%,tmp.gamen,$calc(((%tmp.game.i -1) % 3)+1)),2) $+ $gettok(%tmp.game1,%tmp.game.i,44)
    inc %tmp.game.i
  }
  set %tmp.game1 $+($chr(40),$game.green,%tmp.gamen1,,$chr(41) $chr(40),$game.red,%tmp.gamen2,,$chr(41) $chr(40),$game.blue,%tmp.gamen3,,$chr(41))
  unset %tmp.gamen*
  return %tmp.game1
}

alias game.StickRow {
  set %tmp.game2
  game.trim
  var %tmp.game.a 1
  set %tmp.game.r $r(1,2)
  if ($1 == 1) || ($1 == green) { var %tmp.game.i $iif(%tmp.game.r == 1,8,15),%tmp.game.c 1,%tmp.game.i2 $iif(%tmp.game.r == 1,15,8) }
  elseif ($1 == 2) || ($1 == red) { var %tmp.game.i $iif(%tmp.game.r == 1,1,15),%tmp.game.c 8,%tmp.game.i2 $iif(%tmp.game.r == 1,15,1) }
  elseif ($1 == 3) || ($1 == blue) { var %tmp.game.i $iif(%tmp.game.r == 1,1,8),%tmp.game.c 15,%tmp.game.i2 $iif(%tmp.game.r == 1,8,1) }
  else { RETURN }
  while (%tmp.game.a < 8) {
    set %tmp.game2 %tmp.game2 $+ $gettok(%tmp.game1,%tmp.game.i,44)
    inc %tmp.game.i
    inc %tmp.game.a
  }
  while (%tmp.game.a < 15) {
    set %tmp.game2 %tmp.game2 $+ $gettok(%tmp.game1,%tmp.game.c,44)
    inc %tmp.game.c
    inc %tmp.game.a
  }
  while (%tmp.game.a < 22) {
    set %tmp.game2 %tmp.game2 $+ $gettok(%tmp.game1,%tmp.game.i2,44)
    inc %tmp.game.i2
    inc %tmp.game.a
  }
  unset %tmp.game.i %tmp.game.c %tmp.game.i2
  set %tmp.game1 %tmp.game2
  if (%tmp.game.num == 3) {
    game.trim
    ms.servicebot.say %ms.gb.botnum %ms.gb.chan You are thinking on $gettok(%tmp.game1,11,44) $+ . Right?
    ;disable #gamel
    .unset %tmp.game* %ms.gb.*
  }
  else {
    unset %tmp.game2
    ms.servicebot.say %ms.gb.botnum %ms.gb.chan In which row can i find your number in right now?:
    ms.servicebot.say %ms.gb.botnum %ms.gb.chan $game.rows
  }
}

alias game.trim { set %tmp.game1 $replace($remove($strip(%tmp.game1),$chr(40),$chr(41),$chr(32)),][,$+(],$chr(44),[)) }
