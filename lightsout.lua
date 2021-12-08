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
engine.name="MxSynths"

grid_layout = {}
scales={}
scales2={}
chordscale=Sequins{}
notes_current={}
notes_row_last={}


function init()
  -- https://github.com/schollz/mx.synths#usage-as-library
  local mxsynths_=include("mx.synths/lib/mx.synths")
  mxsynths=mxsynths_:new()
  params:set("mxsynths_release",0.1) -- will be easier to hear release
  make_chords()
  generate_melody_grid_based_on_chords()
  -- make_grid_layout()
  make_grid_layout_alt()
  grid_=grid__:new()

  local redrawer=metro.init()
  redrawer.time=1/15
  redrawer.count=-1
  redrawer.event=redraw
  redrawer:start()

  -- scale_full=MusicUtil.generate_scale_of_length(12, 1, 64)
  -- for _, note in ipairs(MusicUtil.generate_scale_of_length(12, 1, 128)) do
  --   table.insert(scale_full,note)
  -- end

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
          -- engine.mx_note_on(note,0.5,2)
          print(note)
      end
      end,
      division=1,
    })
  end
  sequencer:hard_restart()

  clock.run(function() -- re-enable this to have the kolor UI draw properly
    while true do
      clock.sleep(1/10)
      redraw()
    end
  end)

end

function make_chords(root_num, scale_type, length)
  local root_num = root_num or 48
  local scale_type = scale_type or "major"
  local length = length or 8
  local scale = MusicUtil.generate_scale_of_length (root_num, scale_type, length)
  table.reverse(scale) -- Reverse it to get it into the proper orientation for the grid
  chordscale:settable(scale)
end

function make_grid_layout_alt()
  k=1
  for col=1,16 do
      for row=1,8 do 
      if col==1 then
          scales[row]={}
      end
      scales[row][col]=grid_layout[col][row]
      k=k+1
      end
      k = k - 3
  end
end

function generate_melody_grid_based_on_chords()
  local root_num = 48+12 -- add an octave because this is a melody
  local scale_type = "Major"
  local scale = MusicUtil.generate_scale(root_num, scale_type)
  local scale_len = tab.count(scale)
  print("scale length: "..scale_len)
  for _, note in ipairs(scale) do
      for beat=1,4 do -- make the same column 4 times in grid_layout
          local grid_notes = {}
          -- local chord_types = MusicUtil.chord_types_for_note(note,root_num,scale_type)
          -- local lookup_chord_by_name = tab.invert(chord_types)
          -- local chord = MusicUtil.generate_chord(note,scale_type)
          local note_name = MusicUtil.note_num_to_name(note)
          local chord_by_degree = {}
          for i=1,7 do -- gimme 8 notes for a grid column
              table.insert(chord_by_degree,MusicUtil.generate_chord_scale_degree(note,scale_type,i))
          end
          -- print("note ".._..": "..note_name.."("..note..")".." grid col: ")
          local chord_to_play = chord_by_degree[1]
          -- tab.print(chord_to_play)
          local chord_intervals = {1,3,5,7,4,6}
          for _,index in ipairs(chord_intervals) do
              for k=1,3 do
                  local note = chord_by_degree[index][k]
                  if tab.contains(grid_notes,note)==false and tab.count(grid_notes)<8 then 
                      table.insert(grid_notes,chord_by_degree[index][k])
                      -- print("inserted:"..chord_by_degree[index][k])
                  end
              end
          end
          table.reverse(grid_notes)
          -- tab.print(grid_notes)
          table.insert(grid_layout, grid_notes)
      end
      
  end
  tab.print(grid_layout)
end

function make_grid_layout()
  k=1
  for col=1,16 do
    for row=1,8 do 
      if col==1 then
        scales[row]={}
      end
      -- scales[row][col]=scale_full[k]
      scales[row][col]=chordscale[row]
      k=k+1
    end
    k = k - 3
  end
  tab.print(scales)
 end

function print_grid_layout(layout)
  local l = layout or grid_layout
  for _,col in ipairs(l) do
    -- print("row:"..row)
    tab.print(col)
  end
end

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

end

function enc(k,d)

end

function key(k,z)

end

function redraw()
  screen.clear()
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