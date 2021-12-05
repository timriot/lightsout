-- lightsout v0.0.0
--
--
-- llllllll.co/t/lightsout
--
--
--
--    ▼ instructions below ▼


grid__=include("lightsout/lib/ggrid")
MusicUtil = require("musicutil")
lattice=require("lattice")
Sequins = require("sequins")


chordscale=Sequins{}
-- Given the C-scale, generate chords based on each note of the scale
-- musicutil.generate_scale_of_length (root_num, scale_type, length)
-- musicutil.generate_chord (root_num, chord_type[, inversion])
-- populate a sequin 
function make_chords()
  local root_num = 48
  local scale_type = "major"
  local length = 8
  local scale = MusicUtil.generate_scale_of_length (root_num, scale_type, length)
  tab.print(scale)
  chordscale:settable(scale)
end



function init()
  -- https://github.com/schollz/mx.synths#usage-as-library
  local mxsynths_=include("mx.synths/lib/mx.synths")
  mxsynths=mxsynths_:new()
  params:set("mxsynths_release",0.1) -- will be easier to hear release
  make_chords()
  grid_=grid__:new()

  local redrawer=metro.init()
  redrawer.time=1/15
  redrawer.count=-1
  redrawer.event=redraw
  redrawer:start()

  scale_full=MusicUtil.generate_scale_of_length(12, 1, 64)
  for _, note in ipairs(MusicUtil.generate_scale_of_length(12, 1, 128)) do
    table.insert(scale_full,note)
  end
  -- shuffled = {}
  -- for i, v in ipairs(scale_full) do
  --   local pos = math.random(1, #shuffled+1)
  --   table.insert(shuffled, pos, v)
  -- end
  -- scale_full=shuffled
  scales={}
  k=1
  for col=1,16 do
    for row=1,8 do 
      if col==1 then
        scales[row]={}
      end
      scales[row][col]=scale_full[k]
      k=k+1
    end
    k = k - 3
  end

  -- start lattice
  local sequencer=lattice:new{
    ppqn=96
  }
  divisions={1/2,1/4,1/8,1/16,1/2,1/4,1/8,1/16,1/2,1/4,1/8,1/16,1/2,1/4,1/8,1/16}
  for i=1,1 do 
    local col=0
    sequencer:new_pattern({
      action=function(t)
        col=col+1
        if col>16 then 
          col=1
        end
        grid_.highlight_column=col
        play_note(col)
      end,
      division=1/4,
    })
    sequencer:new_pattern({
      action=function(t)
        --iterate through chord notes
        local chords_from_note = MusicUtil.generate_chord (chordscale(), "major")
        print("== playing ==")
        for i,note in ipairs(chords_from_note) do
          if i == 1 then
            print(MusicUtil.note_num_to_name(note))
          end 
          local freq = MusicUtil.note_num_to_freq(note)
          --engine.hz(freq)
          print(note)
      end
      end,
      division=1,
    })
  end
  sequencer:hard_restart()

  --  sudo systemctl restart norns-jack.service; sudo systemctl restart norns-matron.service; sudo systemctl restart norns-crone.service; ~/norns/build/maiden-repl/maiden-repl

  -- clock.run(function()
  --   while true do
  --     clock.sleep(1/10)
  --     redraw()
  --   end
  -- end)
end

notes_current={}
notes_row_last={}

function trigger_note(note,row)
  notes_current[row]=note 
  engine.mx_note_on(note,0.5,10)
end

function play_note(col)
  local notes={}
  for row=1,8 do
    local note_flag=grid_.lightsout[row][col]
    local do_release=true
    if note_flag>1 then 
      -- its a tie
      if notes_row_last[row]~=nil and note_flag >= notes_row_last[row] then 
        -- its a new tied-note;res
        -- TODO: note should always start at 15
      else
        do_release=false
      end
    end
    if notes_current[row]~=nil and do_release then 
      -- turn off the note
      engine.mx_note_off(notes_current[row])
      print("note_off",notes_current[row])
      notes_current[row]=nil
    end
    if note_flag>0 and do_release then 
      local note=scales[row][col]
      print("note_on",note_flag,note)
      engine.mx_note_on(note,0.5,10)
      notes_current[row]=note
    end
    notes_row_last[row]=note_flag 
  end



  -- local row=(step-1)%8+1
  -- local light=grid_.lightsout[row][col]
  -- if light>0 then
  --   print(row,col)
  --   print(scales[row][col])
  --   local freq = MusicUtil.note_num_to_freq(scales[row][col])
  --   grid_.visual[row][col]=15
  --   engine.hz(freq)
  --   -- grid_:toggle_key(row,col)
  -- end
end

function enc(k,d)

end

function key(k,z)

end

function redraw()
  screen.clear()
  -- local visual=grid_.visual
  -- screen.level(0)
  -- screen.rect(1,1,128,64)
  -- screen.fill()

  -- https://github.com/schollz/kolor/blob/main/kolor.lua
  if grid_==nil then 
    do return end 
  end
  local gd=grid_.visual
  rows=#gd
  cols=#gd[1]
  for row=1,rows do
    for col=1,cols do
      if gd[row][col]~=0 then
        screen.level(gd[row][col])
        screen.rect(col*8-7,row*8-8+1,6,6)
        screen.fill()
      end
    end
  end
  -- screen.level(15)
  -- screen.rect(position[2]*8-7,position[1]*8-8+1,7,7)
  -- screen.stroke()

  -- for row=1,8 do
  --   for col=1,16 do 
  --     if visual[row][col]>0 then 
  --       screen.level(visual[row][col])
  --       screen.pixel(col*2,row*2)
  --       screen.fill()
  --     end
  --   end
  -- end
  -- screen.move(32,64)
  -- screen.text("lightsout")
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end


function cleanup()

end

function table.reverse(t)
  local len = #t
  for i = len - 1, 1, -1 do
    t[len] = table.remove(t, i)
  end
end