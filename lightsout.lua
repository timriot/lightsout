-- lightsout v0.0.0
--
--
-- llllllll.co/t/lightsout
--
--
--
--    ▼ instructions below ▼


grid_=include("lightsout/lib/ggrid")

engine.name="PolyPerc"

function init()
  grid_:new()

  redrawer=metro.init()
  redrawer.time=1/15
  redrawer.count=-1
  redrawer.event=redraw
  redrawer:start()
end


function enc(k,d)

end

function key(k,z)

end

function redraw()
  screen.clear()
  screen.move(32,64)
  screen.text("lightsout")

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
