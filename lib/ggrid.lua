-- local pattern_time = require("pattern")
local GGrid={}


function GGrid:new(args)
  local m=setmetatable({},{__index=GGrid})
  local args=args==nil and {} or args

  m.grid_on=args.grid_on==nil and true or args.grid_on

  -- initiate the grid
  m.g=grid.connect()
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- setup visual
  m.visual={}
  m.lightsout={}
  m.playing={}
  m.grid_width=16
  for i=1,8 do
    m.lightsout[i]={}
    m.playing[i]={}
    m.visual[i]={}
    for j=1,m.grid_width do
      m.visual[i][j]=0
      m.lightsout[i][j]=0
      m.playing[i][j]=0
    end
  end


  -- keep track of pressed buttons
  m.pressed_buttons={}

  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=0.03
  m.grid_refresh.event=function()
    if m.grid_on then
      m:grid_redraw()
    end
  end
  m.grid_refresh:start()

  return m
end


function GGrid:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function GGrid:key_press(row,col,on)
  if on then
    self.pressed_buttons[row..","..col]=true
  else
    self.pressed_buttons[row..","..col]=nil
  end

  local buttons={}
  for k,_ in pairs(self.pressed_buttons) do
    local row,col=k:match("(%d+),(%d+)")
    buttons[#buttons+1]={tonumber(row),tonumber(col)}
  end


  if on then
    -- if pressing more than one button
    if #buttons==2 then
      if buttons[1][1]==buttons[2][1] then 
        print("two buttons on a row pressed")
        self:toggle_tie(buttons[1][1],buttons[1][2],buttons[2][2])
      end
    else
      -- do anything you want with key press
      -- if row==1 and col==2 then...
      self:toggle_key(row,col)
    end
  end
end

function GGrid:toggle_tie(row,col1,col2)
  local foo=col1
  if col1>col2 then 
    col1=col2 
    col2=foo
  end
  print("toggle_tie",row,col1,col2)
  -- create a tie (enter "2" for each col between col1 and col2 on row)
  -- start at 15 and go down
  for col=col1, col2 do
    self.lightsout[row][col]=15-(col-col1)*2
    if self.lightsout[row][col]<2 then 
       self.lightsout[row][col]=2 -- must be greater than 2 to be tie
    end
  end
end

function GGrid:toggle_key(row,col)
  print("row:",row,"col:",col,"note:",scales[row][col])
  if self.lightsout[row][col]>0 then
    self.lightsout[row][col] = 0
  else
    self.lightsout[row][col] = 1
  end
end

function GGrid:get_visual()
  -- clear visual (generic)
  for row=1,8 do
    for col=1,self.grid_width do
      self.visual[row][col]=self.visual[row][col]-1
      if self.visual[row][col]<0 then
        self.visual[row][col]=0
      end
    end
  end

  -- specific to "lights out"
  -- illuminate lights out
  for row in ipairs(self.lightsout) do
    for col in ipairs(self.lightsout[row]) do
      if self.lightsout[row][col]>0 then
        self.visual[row][col]=self.lightsout[row][col]
        -- make the note_flag "1" brighter
        if self.visual[row][col]==1 then 
          self.visual[row][col]=15
        end
      end
    end
  end

  -- highlight columns
  if self.highlight_column~=nil then 
    local col=self.highlight_column
    for row=1,8 do 
      self.visual[row][col]=self.visual[row][col]+5
      if self.visual[row][col]>15 then 
        self.visual[row][col]=15
      end
    end
  end

  -- grid_.highlight_column=1

  -- illuminate currently pressed button (generic)
  for k,_ in pairs(self.pressed_buttons) do
    local row,col=k:match("(%d+),(%d+)")
    self.visual[tonumber(row)][tonumber(col)]=15
  end

  
  return self.visual
end


function GGrid:grid_redraw()
  self.g:all(0)
  local gd=self:get_visual()
  local s=1
  local e=self.grid_width
  local adj=0
  for row=1,8 do
    for col=s,e do
      if gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

return GGrid
