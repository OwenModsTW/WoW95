-- WoW95 Games Module
-- Classic Windows 95 games like Minesweeper and Solitaire

local addonName, WoW95 = ...

local Games = {}
WoW95.Games = Games

-- Game definitions for the Start Menu
Games.GAMES = {
    ["Minesweeper"] = {
        name = "Minesweeper",
        icon = {0.6, 0.6, 0.6, 1}, -- Gray icon
        tooltip = "Classic Minesweeper game",
        difficulty = "Beginner", -- Beginner, Intermediate, Expert
        boardSize = {width = 9, height = 9, mines = 10}
    },
    ["Solitaire"] = {
        name = "Solitaire", 
        icon = {0, 0.5, 0, 1}, -- Green icon
        tooltip = "Classic Klondike Solitaire",
        enabled = false -- TODO: Implement later
    }
}

-- Game windows
Games.gameWindows = {}
Games.isInitialized = false

function Games:Init()
    WoW95:Debug("Initializing Games module...")
    
    -- Make games available to Start Menu
    WoW95.GAMES = self.GAMES
    
    self.isInitialized = true
    WoW95:Debug("Games module initialized successfully!")
end

-- Minesweeper Game Implementation
function Games:CreateMinesweeper()
    WoW95:Debug("Creating Minesweeper game...")
    
    if self.gameWindows["Minesweeper"] then
        WoW95:Debug("Minesweeper already exists, showing it")
        self.gameWindows["Minesweeper"]:Show()
        return self.gameWindows["Minesweeper"]
    end
    
    local gameData = self.GAMES["Minesweeper"]
    local board = gameData.boardSize
    
    -- Calculate window size based on board (bigger cells)
    local cellSize = 28  -- Increased from 20
    local windowWidth = (board.width * cellSize) + 60  -- Extra space for borders
    local windowHeight = (board.height * cellSize) + 120 -- Extra space for title, toolbar, borders
    
    -- Create main game window with proper Windows 95 styling
    local gameWindow = WoW95:CreateWindow("WoW95Minesweeper", UIParent, windowWidth, windowHeight, "Minesweeper")
    gameWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    gameWindow.isWoW95Window = true
    gameWindow.programName = "Minesweeper"
    
    -- Game state
    gameWindow.gameState = {
        board = {},
        revealed = {},
        flagged = {},
        gameOver = false,
        won = false,
        mineCount = board.mines,
        flagCount = 0,
        firstClick = true
    }
    
    -- Initialize empty board
    for x = 1, board.width do
        gameWindow.gameState.board[x] = {}
        gameWindow.gameState.revealed[x] = {}
        gameWindow.gameState.flagged[x] = {}
        for y = 1, board.height do
            gameWindow.gameState.board[x][y] = 0  -- 0 = empty, -1 = mine, >0 = number
            gameWindow.gameState.revealed[x][y] = false
            gameWindow.gameState.flagged[x][y] = false
        end
    end
    
    -- Create game toolbar
    self:CreateMinesweeperToolbar(gameWindow, board)
    
    -- Create game board
    self:CreateMinesweeperBoard(gameWindow, board, cellSize)
    
    -- Store reference
    self.gameWindows["Minesweeper"] = gameWindow
    
    -- Notify taskbar
    WoW95:OnWindowOpened(gameWindow)
    
    WoW95:Debug("Minesweeper created successfully!")
    return gameWindow
end

function Games:CreateMinesweeperToolbar(gameWindow, board)
    -- Create toolbar frame
    local toolbar = CreateFrame("Frame", nil, gameWindow, "BackdropTemplate")
    toolbar:SetPoint("TOPLEFT", gameWindow, "TOPLEFT", 12, -38)
    toolbar:SetPoint("TOPRIGHT", gameWindow, "TOPRIGHT", -12, -38)
    toolbar:SetHeight(35)
    
    -- Windows 95 button style
    toolbar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    toolbar:SetBackdropColor(0.75, 0.75, 0.75, 1)
    toolbar:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Mine count display
    local mineCountLabel = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mineCountLabel:SetPoint("LEFT", toolbar, "LEFT", 12, 0)
    mineCountLabel:SetText("Mines: " .. board.mines)
    mineCountLabel:SetTextColor(0, 0, 0, 1)
    mineCountLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    gameWindow.mineCountLabel = mineCountLabel
    
    -- Reset button (smiley face)
    local resetButton = WoW95:CreateButton("Reset", toolbar, 70, 25)
    resetButton:SetPoint("CENTER", toolbar, "CENTER", 0, 0)
    resetButton:SetText("🙂")
    resetButton:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    resetButton:SetScript("OnClick", function()
        self:ResetMinesweeper(gameWindow, board)
    end)
    gameWindow.resetButton = resetButton
    
    -- Timer display
    local timerLabel = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerLabel:SetPoint("RIGHT", toolbar, "RIGHT", -12, 0)
    timerLabel:SetText("Time: 0")
    timerLabel:SetTextColor(0, 0, 0, 1)
    timerLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    gameWindow.timerLabel = timerLabel
    gameWindow.startTime = nil
    gameWindow.gameTime = 0
    
    gameWindow.toolbar = toolbar
end

function Games:CreateMinesweeperBoard(gameWindow, board, cellSize)
    -- Create board container
    local boardFrame = CreateFrame("Frame", nil, gameWindow, "BackdropTemplate")
    boardFrame:SetPoint("TOP", gameWindow.toolbar, "BOTTOM", 0, -8)
    boardFrame:SetSize(board.width * cellSize + 6, board.height * cellSize + 6)
    
    -- Inset border for authentic Windows 95 look with darker background for grid lines
    boardFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    boardFrame:SetBackdropColor(0.5, 0.5, 0.5, 1)  -- Darker gray for grid lines to show
    boardFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    gameWindow.boardFrame = boardFrame
    gameWindow.cells = {}
    
    -- Create individual cells
    for x = 1, board.width do
        gameWindow.cells[x] = {}
        for y = 1, board.height do
            local cell = self:CreateMinesweeperCell(boardFrame, x, y, cellSize)
            cell:SetPoint("TOPLEFT", boardFrame, "TOPLEFT", 
                         (x-1) * cellSize + 4, -((y-1) * cellSize + 4))
            gameWindow.cells[x][y] = cell
        end
    end
end

function Games:CreateMinesweeperCell(parent, x, y, size)
    local cell = CreateFrame("Button", nil, parent, "BackdropTemplate")
    cell:SetSize(size-3, size-3) -- More space for visible grid lines
    
    -- Raised button appearance
    cell:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    cell:SetBackdropColor(0.75, 0.75, 0.75, 1)
    cell:SetBackdropBorderColor(0.9, 0.9, 0.9, 1)
    
    -- Cell text (bigger font)
    local text = cell:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    text:SetText("")
    cell.text = text
    
    -- Store coordinates
    cell.x = x
    cell.y = y
    cell.revealed = false
    cell.flagged = false
    
    -- Click handlers
    cell:SetScript("OnClick", function(self, button)
        Games:OnCellClick(parent:GetParent(), self, button)
    end)
    
    cell:SetScript("OnEnter", function(self)
        if not self.revealed and not self.flagged then
            self:SetBackdropColor(0.8, 0.8, 0.8, 1)
        end
    end)
    
    cell:SetScript("OnLeave", function(self)
        if not self.revealed and not self.flagged then
            self:SetBackdropColor(0.75, 0.75, 0.75, 1)
        end
    end)
    
    -- Enable right-click for flagging
    cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    return cell
end

function Games:OnCellClick(gameWindow, cell, button)
    if gameWindow.gameState.gameOver then return end
    
    local x, y = cell.x, cell.y
    local state = gameWindow.gameState
    
    if button == "RightButton" then
        -- Toggle flag
        if not cell.revealed then
            if cell.flagged then
                -- Remove flag
                cell.flagged = false
                state.flagged[x][y] = false
                cell.text:SetText("")
                cell:SetBackdropColor(0.75, 0.75, 0.75, 1)
                state.flagCount = state.flagCount - 1
            else
                -- Add flag
                cell.flagged = true
                state.flagged[x][y] = true
                cell.text:SetText("🚩")
                cell:SetBackdropColor(1, 0.7, 0.7, 1)
                state.flagCount = state.flagCount + 1
            end
            
            -- Update mine counter
            gameWindow.mineCountLabel:SetText("Mines: " .. (state.mineCount - state.flagCount))
        end
        return
    end
    
    -- Left click - reveal cell
    if cell.flagged or cell.revealed then return end
    
    -- First click - generate mines (avoiding first click)
    if state.firstClick then
        self:GenerateMines(gameWindow, x, y)
        state.firstClick = false
        gameWindow.startTime = GetTime()
        
        -- Start timer
        gameWindow.timer = C_Timer.NewTicker(1, function()
            if not state.gameOver then
                gameWindow.gameTime = math.floor(GetTime() - gameWindow.startTime)
                gameWindow.timerLabel:SetText("Time: " .. gameWindow.gameTime)
            end
        end)
    end
    
    -- Reveal the cell
    self:RevealCell(gameWindow, x, y)
    
    -- Check win condition
    self:CheckWinCondition(gameWindow)
end

function Games:GenerateMines(gameWindow, avoidX, avoidY)
    local state = gameWindow.gameState
    local board = self.GAMES["Minesweeper"].boardSize
    local minesPlaced = 0
    
    -- Clear board first
    for x = 1, board.width do
        for y = 1, board.height do
            state.board[x][y] = 0
        end
    end
    
    -- Place mines randomly, avoiding the first click
    while minesPlaced < board.mines do
        local x = math.random(1, board.width)
        local y = math.random(1, board.height)
        
        -- Don't place mine on first click or if already a mine
        if (x ~= avoidX or y ~= avoidY) and state.board[x][y] ~= -1 then
            state.board[x][y] = -1
            minesPlaced = minesPlaced + 1
        end
    end
    
    -- Calculate numbers for each cell
    for x = 1, board.width do
        for y = 1, board.height do
            if state.board[x][y] ~= -1 then
                local count = 0
                -- Check all 8 adjacent cells
                for dx = -1, 1 do
                    for dy = -1, 1 do
                        local nx, ny = x + dx, y + dy
                        if nx >= 1 and nx <= board.width and ny >= 1 and ny <= board.height then
                            if state.board[nx][ny] == -1 then
                                count = count + 1
                            end
                        end
                    end
                end
                state.board[x][y] = count
            end
        end
    end
end

function Games:RevealCell(gameWindow, x, y)
    local state = gameWindow.gameState
    local board = self.GAMES["Minesweeper"].boardSize
    local cell = gameWindow.cells[x][y]
    
    if cell.revealed or cell.flagged then return end
    
    cell.revealed = true
    state.revealed[x][y] = true
    
    -- Change appearance to sunken
    cell:SetBackdropColor(0.9, 0.9, 0.9, 1)
    cell:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    local value = state.board[x][y]
    
    if value == -1 then
        -- Hit a mine - game over
        cell.text:SetText("💣")
        cell:SetBackdropColor(1, 0.3, 0.3, 1)
        self:GameOver(gameWindow, false)
    elseif value == 0 then
        -- Empty cell - auto-reveal adjacent cells
        for dx = -1, 1 do
            for dy = -1, 1 do
                local nx, ny = x + dx, y + dy
                if nx >= 1 and nx <= board.width and ny >= 1 and ny <= board.height then
                    if not state.revealed[nx][ny] then
                        self:RevealCell(gameWindow, nx, ny)
                    end
                end
            end
        end
    else
        -- Number cell
        cell.text:SetText(tostring(value))
        
        -- Color code numbers
        local colors = {
            [1] = {0, 0, 1, 1},     -- Blue
            [2] = {0, 0.5, 0, 1},   -- Green  
            [3] = {1, 0, 0, 1},     -- Red
            [4] = {0, 0, 0.5, 1},   -- Dark Blue
            [5] = {0.5, 0, 0, 1},   -- Maroon
            [6] = {0, 0.5, 0.5, 1}, -- Teal
            [7] = {0, 0, 0, 1},     -- Black
            [8] = {0.5, 0.5, 0.5, 1} -- Gray
        }
        
        if colors[value] then
            cell.text:SetTextColor(unpack(colors[value]))
        end
    end
end

function Games:CheckWinCondition(gameWindow)
    local state = gameWindow.gameState
    local board = self.GAMES["Minesweeper"].boardSize
    
    local cellsToReveal = (board.width * board.height) - board.mines
    local cellsRevealed = 0
    
    for x = 1, board.width do
        for y = 1, board.height do
            if state.revealed[x][y] then
                cellsRevealed = cellsRevealed + 1
            end
        end
    end
    
    if cellsRevealed == cellsToReveal then
        self:GameOver(gameWindow, true)
    end
end

function Games:GameOver(gameWindow, won)
    local state = gameWindow.gameState
    state.gameOver = true
    state.won = won
    
    -- Stop timer
    if gameWindow.timer then
        gameWindow.timer:Cancel()
        gameWindow.timer = nil
    end
    
    -- Update reset button
    if won then
        gameWindow.resetButton:SetText("😎") -- Cool sunglasses
        WoW95:Print("Minesweeper: You won!")
    else
        gameWindow.resetButton:SetText("😵") -- Dead face
        WoW95:Print("Minesweeper: Game Over!")
        
        -- Reveal all mines
        local board = self.GAMES["Minesweeper"].boardSize
        for x = 1, board.width do
            for y = 1, board.height do
                if state.board[x][y] == -1 and not gameWindow.cells[x][y].revealed then
                    gameWindow.cells[x][y].text:SetText("💣")
                    gameWindow.cells[x][y]:SetBackdropColor(1, 0.5, 0.5, 1)
                end
            end
        end
    end
end

function Games:ResetMinesweeper(gameWindow, board)
    WoW95:Debug("Resetting Minesweeper...")
    
    local state = gameWindow.gameState
    
    -- Stop timer
    if gameWindow.timer then
        gameWindow.timer:Cancel()
        gameWindow.timer = nil
    end
    
    -- Reset game state
    state.gameOver = false
    state.won = false
    state.flagCount = 0
    state.firstClick = true
    gameWindow.startTime = nil
    gameWindow.gameTime = 0
    
    -- Reset board arrays
    for x = 1, board.width do
        for y = 1, board.height do
            state.board[x][y] = 0
            state.revealed[x][y] = false
            state.flagged[x][y] = false
            
            -- Reset cell appearance
            local cell = gameWindow.cells[x][y]
            cell.revealed = false
            cell.flagged = false
            cell.text:SetText("")
            cell:SetBackdropColor(0.75, 0.75, 0.75, 1)
            cell:SetBackdropBorderColor(0.9, 0.9, 0.9, 1)
        end
    end
    
    -- Reset UI
    gameWindow.resetButton:SetText("🙂")
    gameWindow.mineCountLabel:SetText("Mines: " .. board.mines)
    gameWindow.timerLabel:SetText("Time: 0")
    
    WoW95:Debug("Minesweeper reset complete!")
end

-- Public function to open Minesweeper
function Games:OpenMinesweeper()
    return self:CreateMinesweeper()
end

-- Close a game window
function Games:CloseGame(gameName)
    if self.gameWindows[gameName] then
        local gameWindow = self.gameWindows[gameName]
        
        -- Stop any timers
        if gameWindow.timer then
            gameWindow.timer:Cancel()
            gameWindow.timer = nil
        end
        
        -- Notify taskbar
        WoW95:OnWindowClosed(gameWindow)
        
        -- Hide and clear reference
        gameWindow:Hide()
        self.gameWindows[gameName] = nil
        
        WoW95:Debug("Closed game: " .. gameName)
    end
end

-- Register the module
WoW95:RegisterModule("Games", Games)