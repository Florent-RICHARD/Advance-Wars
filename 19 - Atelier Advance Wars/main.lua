-- Cette ligne permet d'afficher des traces dans la console pendant l'éxécution
io.stdout:setvbuf('no')

-- Empèche Love de filtrer les contours des images quand elles sont redimentionnées
-- Indispensable pour du pixel art
love.graphics.setDefaultFilter("nearest")

-- Cette ligne permet de déboguer pas à pas dans ZeroBraneStudio
if arg[#arg] == "-debug" then require("mobdebug").start() end

math.randomseed(love.timer.getTime())

TailleMap = 10
TailleCase = 8
TailleSet = 16 * 10

Tilemap = {}

Tilemap[1] = { 1,1,1,1,1,1,1,1,1,1 }
Tilemap[2] = { 1,2,2,1,1,1,1,1,1,1 }
Tilemap[3] = { 1,2,1,1,1,1,1,1,1,1 }
Tilemap[4] = { 1,1,1,1,1,1,1,1,1,1 }
Tilemap[5] = { 1,1,1,1,3,3,1,1,1,1 }
Tilemap[6] = { 1,1,1,3,3,1,1,1,1,1 }
Tilemap[7] = { 1,1,1,1,3,1,1,1,1,1 }
Tilemap[8] = { 1,1,1,1,1,1,1,1,1,1 }
Tilemap[9] = { 1,1,1,1,1,1,1,1,1,1 }
Tilemap[10]= { 1,1,1,1,1,1,1,1,1,1 }

Select = {}
Select.c = 1
Select.l = 1

listUnit = {}

-- Les sols
TERRAIN_PLAIN = 1
TERRAIN_MOUNTAIN = 2
TERRAIN_FOREST = 3

dbSols = {}

-- Les unités
dbUnits = {}

-- Contexte de jeu
Contexte = {}
Contexte.Joueur = 1
Contexte.Etat = ""

--function getRanged(pType)
--  if pType == "TANK" then
--    return 1
--  elseif pType == "MISSILE" then
--    return 3
--  else
--    return 1
--  end
--end

function CreeUnit(pType, pJoueur, pLigne, pColonne)
  local Unit = {}
  Unit.Type = pType
  Unit.Joueur = pJoueur
  Unit.HP = dbUnits[pType].HP
  Unit.Ligne = pLigne
  Unit.Colonne = pColonne
  Unit.Range = dbUnits[pType].Range
  table.insert(listUnit, Unit)
end

function StartGame()
  CreeUnit("TANK", 1, 1, 1)
  CreeUnit("INFANTRY", 1, 5, 2)
  CreeUnit("TANK", 2, 1, 8)
  CreeUnit("INFANTRY", 2, 5, 7)
  
  -- Etat par défaut
  Contexte.Etat = "SELECTION"
end

function FinDeTour()
  -- Rétabli les points de déplacements au max
  for u = 1, #listUnit do
    local unit = listUnit[u]
    unit.Range = dbUnits[unit.Type].Range
  end
  Contexte.Etat = "SELECTION"
end

function love.load()

  -- Les sols
  dbSols[TERRAIN_PLAIN] = {}
  dbSols[TERRAIN_PLAIN].Name = "Plain"
  dbSols[TERRAIN_PLAIN].Image = love.graphics.newImage("map_plain.png")
  dbSols[TERRAIN_PLAIN].ImageBattle = love.graphics.newImage("set_plain.png")

  dbSols[TERRAIN_MOUNTAIN] = {}
  dbSols[TERRAIN_MOUNTAIN].Name = "Mountain"
  dbSols[TERRAIN_MOUNTAIN].Image = love.graphics.newImage("map_mountain.png")
  dbSols[TERRAIN_MOUNTAIN].ImageBattle = love.graphics.newImage("set_mountain.png")


  dbSols[TERRAIN_FOREST] = {}
  dbSols[TERRAIN_FOREST].Name = "Forest"
  dbSols[TERRAIN_FOREST].Image = love.graphics.newImage("map_forest.png")
  dbSols[TERRAIN_FOREST].ImageBattle = love.graphics.newImage("set_forest.png")
  
    -- Les unités
  dbUnits["INFANTRY"] = {}        -- "db" veux dire data base (base de données)
  dbUnits["INFANTRY"].HP = 5
  dbUnits["INFANTRY"].Range = 12
  dbUnits["INFANTRY"].Gas = 99
  dbUnits["INFANTRY"].Image = {}
  dbUnits["INFANTRY"].ImageBattle = {}
  dbUnits["INFANTRY"].Image[1] = love.graphics.newImage("infantry_1.png")
  dbUnits["INFANTRY"].ImageBattle[1] = love.graphics.newImage("infantry_battle_1.png")
  dbUnits["INFANTRY"].Image[2] = love.graphics.newImage("infantry_2.png")
  dbUnits["INFANTRY"].ImageBattle[2] = love.graphics.newImage("infantry_battle_2.png")
  dbUnits["INFANTRY"].Effects = {}
  dbUnits["INFANTRY"].Effects[TERRAIN_PLAIN] = 1
  dbUnits["INFANTRY"].Effects[TERRAIN_MOUNTAIN] = 2
  dbUnits["INFANTRY"].Effects[TERRAIN_FOREST] = 2

  dbUnits["TANK"] = {}
  dbUnits["TANK"].HP = 10
  dbUnits["TANK"].Range = 8
  dbUnits["TANK"].Gas = 99
  dbUnits["TANK"].Image = {}
  dbUnits["TANK"].ImageBattle = {}
  dbUnits["TANK"].Image[1] = love.graphics.newImage("tank_1.png")
  dbUnits["TANK"].ImageBattle[1] = love.graphics.newImage("tank_battle_1.png")
  dbUnits["TANK"].Image[2] = love.graphics.newImage("tank_2.png")
  dbUnits["TANK"].ImageBattle[2] = love.graphics.newImage("tank_battle_2.png")
  dbUnits["TANK"].Effects = {}
  dbUnits["TANK"].Effects[TERRAIN_PLAIN] = 1
  dbUnits["TANK"].Effects[TERRAIN_MOUNTAIN] = 0
  dbUnits["TANK"].Effects[TERRAIN_FOREST] = 2
  
  StartGame()

end

function UnitUnder(pLigne, pColonne)
  
  for u = 1, #listUnit do
    -- Unité sélectionnée ?
    local unit = listUnit[u]
    if pColonne == unit.Colonne and pLigne == unit.Ligne then
      return unit
    end
  end
  return nil
end

function love.update(dt)
  
  if Contexte.Etat == "BATTLE" then
    Update_BattleState(dt)
  end
  
end

function Draw_MapState()
  
  love.graphics.scale(4, 4)

  -- Dessine la map
  local x,y = 0,0
  local sx,sy = 0,0
  for l = 1, TailleMap do
    x = 0
    for c = 1, TailleMap do
      if c == Select.c and l == Select.l then
        sx = x
        sy = y
      end
      local idSol = Tilemap[l][c]
      love.graphics.draw(dbSols[idSol].Image, x, y)
      x = x + TailleCase
    end
    y = y + TailleCase
  end
  
  -- Dessine les unités
  love.graphics.setColor(1,1,1,1)
  for u = 1, #listUnit do
    local unit = listUnit[u]
    local x = (unit.Colonne - 1) * TailleCase
    local y = (unit.Ligne - 1) * TailleCase
    love.graphics.draw(dbUnits[unit.Type].Image[unit.Joueur], x, y)
  end
  
  -- Dessine la sélection
  if Select.Unit == nil then
    love.graphics.setColor(1,1,1,1)
  else
    love.graphics.setColor(1,0,0,1)
  end
  love.graphics.rectangle("line", sx, sy, TailleCase, TailleCase)
  love.graphics.setColor(1,1,1,1)
  
  love.graphics.scale(1/4, 1/4)
  love.graphics.setColor(1,1,1)
  
  -- GUI
  for u = 1, #listUnit do
    -- Unité sélectionnée ?
    local unit = listUnit[u]
    if Select.c == unit.Colonne and Select.l == unit.Ligne then
      local xStat = ((TailleCase * 4) * TailleMap) + 10
      love.graphics.print(unit.Type, xStat, 5)
      love.graphics.print("HP "..unit.HP, xStat, 5 + 16)
      love.graphics.print("Range "..unit.Range, xStat, 5 + (16 * 2))
    end
  end
  
  -- Type de sol
  local typeSol = Tilemap[Select.l][Select.c]
  local xStatSol = ((TailleCase * 4) * TailleMap) + 150
  love.graphics.print(dbSols[typeSol].Name, xStatSol, 5)
  
  -- Joueur en cours
  love.graphics.print("Joueur en cours : "..Contexte.Joueur, 0, (TailleCase * TailleMap) * 4)
  
  -- Instuctions
  if Contexte.Etat == "SELECTION" then
    love.graphics.print("Sélectionnez une unité à déplacer", 0, (TailleCase * TailleMap) * 4 + 16)
  elseif Contexte.Etat == "MOVE" then
    love.graphics.print("Déplacez l'unité dans une des 4 directions", 0, (TailleCase * TailleMap) * 4 + 16)
  end

end

function Update_BattleState(dt)
  -- Armée 1
  for n = 1, #Contexte.BattlePositions[1].Hc do
    if Contexte.BattlePositions[1].Hc[n] < Contexte.BattlePositions[1].H[n] then
      Contexte.BattlePositions[1].Hc[n] = Contexte.BattlePositions[1].Hc[n] + 80 * dt
    end
  end
  
  -- Armée 2
  for n = 1, #Contexte.BattlePositions[2].Hc do
    if Contexte.BattlePositions[2].Hc[n] > Contexte.BattlePositions[2].H[n] then
      Contexte.BattlePositions[2].Hc[n] = Contexte.BattlePositions[2].Hc[n] - 80 * dt
    end
  end
end

function Draw_BattleState()
  love.graphics.scale(2, 2)

  -- Décor de gauche
  love.graphics.draw(dbSols[Contexte.Sol1].ImageBattle, 0, 0)
  -- Décor de droite
  love.graphics.draw(dbSols[Contexte.Sol2].ImageBattle, TailleSet + 2, 0)
  
  -- love.graphics.print("Mode de bataille !")
  
  -- Affiche les unités de chaque armée
  -- Armée 1
  for n = 1, #Contexte.BattlePositions[1].V do
    love.graphics.draw(dbUnits[Contexte.Unit1.Type].ImageBattle[1],
      Contexte.BattlePositions[1].Hc[n],
      Contexte.BattlePositions[1].V[n])
  end
  
  -- Armée 2
  for n = 1, #Contexte.BattlePositions[2].V do
    love.graphics.draw(dbUnits[Contexte.Unit2.Type].ImageBattle[2],
      Contexte.BattlePositions[2].Hc[n],
      Contexte.BattlePositions[2].V[n],
      0, -1, 1)
  end
  
  love.graphics.scale(1/2, 1/2)
  love.graphics.setColor(1,1,1)
  
end

function love.draw()

  if Contexte.Etat == "SELECTION" or Contexte.Etat == "MOVE" or Contexte.Etat == "SELECTFIRE" then
    Draw_MapState()
  elseif
    Contexte.Etat == "BATTLE" then
    Draw_BattleState()
  end
  
end

function SelectionnePositions(pListe, pNbPositions)
  -- Tire au sort pNbPositions dans un sac avec les 5 positions possibles
  local sac = { 70, 79, 88, 97, 106 }
  while pNbPositions > 0 do
    local element = love.math.random(1, #sac)
    print("Position tirée au sort", sac[element])
    table.insert(pListe, sac[element])
    table.remove(sac, element)
    pNbPositions = pNbPositions - 1
  end
  -- Tri de la liste obtenue
  function compare(a, b)
    return a < b
  end
  table.sort(pListe, compare)
end

function StartBattle(Unit1, Unit2, Sol1, Sol2)
    Contexte.Unit1 = Unit1
    Contexte.Unit2 = Unit2
    Contexte.Sol1 = Sol1
    Contexte.Sol2 = Sol2
    Contexte.Etat = "BATTLE"
    Contexte.BattlePositions = {}
    Contexte.BattlePositions[1] = {}
    Contexte.BattlePositions[1].V = {}
    Contexte.BattlePositions[1].H = {}
    Contexte.BattlePositions[1].Hc = {}
    Contexte.BattlePositions[2] = {}
    Contexte.BattlePositions[2].V = {}
    Contexte.BattlePositions[2].H = {}
    Contexte.BattlePositions[2].Hc = {}
    -- Tir au sort les positions vertical de chaque armée
    local nbPos1 = math.max(1, math.floor(Unit1.HP / 2))
    local nbPos2 = math.max(1, math.floor(Unit2.HP / 2))
    SelectionnePositions(Contexte.BattlePositions[1].V, nbPos1)
    SelectionnePositions(Contexte.BattlePositions[2].V, nbPos2)
    -- Calcul des positions horizontales
    -- Armée 1
    for n = 1, #Contexte.BattlePositions[1].V do
      Contexte.BattlePositions[1].H[n] = love.math.random(4, 130)
      Contexte.BattlePositions[1].Hc[n] = 0
    end
    -- Armée 2
    for n = 1, #Contexte.BattlePositions[2].V do
      Contexte.BattlePositions[2].H[n] = love.math.random(180, 300)
      Contexte.BattlePositions[2].Hc[n] = (160 * 2)
    end
end

function MoveUnit(pDirection)
  
  local U = Select.Unit
  local sol = 0
  local UnitGoto = nil
  
  -- Récupère le sol vers lequel je me dirige
  if pDirection == "right" then
    sol = Tilemap[U.Ligne][U.Colonne + 1]
    UnitGoto = UnitUnder(Select.l, Select.c + 1)
  elseif pDirection == "left" then
    sol = Tilemap[U.Ligne][U.Colonne - 1]
    UnitGoto = UnitUnder(Select.l, Select.c - 1)
  elseif pDirection == "down" then
    sol = Tilemap[U.Ligne + 1][U.Colonne]
    UnitGoto = UnitUnder(Select.l + 1, Select.c)
  elseif pDirection == "up" then
    sol = Tilemap[U.Ligne - 1][U.Colonne]
    UnitGoto = UnitUnder(Select.l - 1, Select.c)
  end
  
  if UnitGoto ~= nil then
    if UnitGoto.Joueur ~= Contexte.Joueur then
      StartBattle(U, UnitGoto, Tilemap[U.Ligne][U.Colonne], sol)
      return
    end
  end
  
  local cost = dbUnits[U.Type].Effects[sol]
  if U.Range >= cost and cost ~= 0 then
    if pDirection == "right" then
      if UnitGoto == nil then
        Select.c = Select.c + 1
        Select.Unit.Colonne = Select.Unit.Colonne + 1
        U.Range = U.Range - cost
      end
    elseif pDirection == "down" then
      if UnitGoto == nil then
        Select.l = Select.l + 1
        Select.Unit.Ligne = Select.Unit.Ligne + 1
        U.Range = U.Range - cost
      end
    elseif pDirection == "left" then
      if UnitGoto == nil then
        Select.c = Select.c - 1
        Select.Unit.Colonne = Select.Unit.Colonne - 1
        U.Range = U.Range - cost
      end
    elseif pDirection == "up" then
      if UnitGoto == nil then
        Select.l = Select.l - 1
        Select.Unit.Ligne = Select.Unit.Ligne - 1
        U.Range = U.Range - cost
      end
    end
  end
end

function love.keypressed(key)
  
  print(key)

  if key == "escape" then
    love.event.quit()
  end
  
  -- Sélection
  if Contexte.Etat == "SELECTION" then
    if key == "right" and Select.c < TailleMap then
      Select.c = Select.c + 1
    end
    if key == "down" and Select.l < TailleMap then
      Select.l = Select.l + 1
    end
    if key == "left" and Select.c > 1 then
      Select.c = Select.c - 1
    end
    if key == "up" and Select.l > 1 then
      Select.l = Select.l - 1
    end
  end
  -- Move
  if Contexte.Etat == "MOVE" then
    if key == "right" and Select.c < TailleMap then
      MoveUnit(key)
      return
    end
    if key == "down" and Select.l < TailleMap then
      MoveUnit(key)
      return
    end
    if key == "left" and Select.c > 1 then
      MoveUnit(key)
      return
    end
    if key == "up" and Select.l > 1 then
      MoveUnit(key)
      return
    end
  end
  -- Sélection/lock d'une unité
  if key == "space" and Contexte.Etat == "SELECTION" then
    local unit2Select = UnitUnder(Select.l, Select.c)
    if unit2Select ~= nil then
      if unit2Select.Joueur == Contexte.Joueur then
        Select.Unit = unit2Select
        Contexte.Etat = "MOVE"
        return
      end
    end
  end
  --Gestion de l'annulation
  if (key == "a" or key == "space") and Contexte.Etat == "MOVE" then
    Select.Unit = nil
    Contexte.Etat = "SELECTION"
  end
  -- Fin de tour
  if key == "f" and Contexte.Etat == "SELECTION" then
    if Contexte.Joueur == 1 then
      Contexte.Joueur = 2
    else
    Contexte.Joueur = 1
    end
  FinDeTour()
  end
end
