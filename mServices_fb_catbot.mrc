on *:load: { set %mServices.loaded.catbot true | ms.echo green Loaded mServices_catbot.mrc }
on *:unload: { unset %mServices.loaded.catbot | ms.echo red Unloaded mServices_catbot.mrc }

alias ms.fb.catbot.privmsg { 

  return
}