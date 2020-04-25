functor
import
	GUI
	Input
	PlayerManager
	System % added for System.show
define
	% FUNCTIONS
	% Initialise
	CreatePlayers
	InitPlayers
	% Small functions
	ArrayReplace
	NextPlayer
	% In-game management
	Move
	Charge 
	Fire
	Mine
	% For recursivity
	DamagingItem
	Sonar
	Drone
	% Broadcasting
	Broadcast
	% Main
	TurnByTurn

	% VARIABLES
	GuiPort
	Players
in

% -------------------------------------------------
% Initialisation
% -------------------------------------------------
		% Create a list of players
	fun {CreatePlayers}
		local 
			fun {CreatePlayerList ID NPlayers Players Colors}
				if (ID =< NPlayers) then
					case Players#Colors
					of (Hplayer|Tplayer)#(Hcolor|Tcolor) then {PlayerManager.playerGenerator Hplayer Hcolor ID} | {CreatePlayerList ID+1 NPlayers Tplayer Tcolor}
					else raise wrongPlayerException('ERROR : Players and/or Colors have wrong format') end
					end
				else nil
				end
			end
		in
			{CreatePlayerList 1 Input.nbPlayer Input.players Input.colors}
		end
	end

	% Initialise all the players
	proc {InitPlayers PlayerList}
		case PlayerList
		of Player|T then ID Pos in 
			{Send Player initPosition(ID Pos)}
			{Wait ID} {Wait Pos}
			{Send GuiPort initPlayer(ID Pos)}
			{InitPlayers T}
		else skip
		end
	end

% -------------------------------------------------
% Small functions
% -------------------------------------------------
	fun{ArrayReplace Array Pos NewItem}
		if(Pos<1) then {System.show pos_error} raise wrongArrayPositionException() end
		elseif(Pos==1) then NewItem|Array.2 
		else Array.1|{ArrayReplace Array.2 Pos-1 NewItem} end
	end

	fun{NextPlayer CurrentPlayer}
		if (CurrentPlayer == Input.nbPlayer) then 1 %Id start at 1
		else CurrentPlayer+1 end
	end
	
% -------------------------------------------------
% In-game management
% -------------------------------------------------
	% Moving
	fun{Move CurrentPlayer}
		ID Pos Direction
	in
		{Send {List.nth Players CurrentPlayer} move(?ID ?Pos ?Direction)}
		{Wait ID} {Wait Pos} {Wait Direction}
		% Check if player is dead
		if ID==null then false
		else
			% Broadcast and return false to indicate end of turn
			if Direction == surface then
				{Send GuiPort surface(ID)}
				{Broadcast saySurface(ID)}
				false
			% Broadcast direction and return true to indicate continuing to play
			else
				{Send GuiPort movePlayer(ID Pos)}
				{Broadcast sayMove(ID Direction)}
				true
			end
		end
	end

	% Charging an item
	proc{Charge CurrentPlayer}
		KindItem
		ID
	in
		% Get information about item charged
		{Send {List.nth Players CurrentPlayer} chargeItem(?ID ?KindItem)}
		{Wait ID} {Wait KindItem}
		% Check if player is dead
		if ID == null then skip
		else
			% Check if player has fully charged an item
			if KindItem == null then skip
			% Broadcast information if player has fully charged an item
			else {Broadcast sayCharge(ID KindItem)}
			end
		end
	end

	% Firing an item
	proc{Fire CurrentPlayer}
		ID
		Item
	in
		{Send {List.nth Players CurrentPlayer} fireItem(?ID ?Item)}
		{Wait ID} {Wait Item}
		% Check if player is dead
		if ID == null then skip
		else
			% Check item fired
			case Item
			of null then skip
			% Mine : notify all players and update GUI
			[] mine(Position) then
				{Broadcast sayMinePlaced(ID)}
				{Send GuiPort putMine(ID Position)}
			% Missile : notify all players and send back answers if damaged players. Used proc "DamagingItem" to handle recursivity
			[] missile(Position) then
				{DamagingItem ID Position missile}
			[] sonar then
				{Sonar ID CurrentPlayer}
			[] drone(RowOrColumn Number) then
				{Drone ID CurrentPlayer drone(RowOrColumn Number)}
			end
		end
	end

	% Handle mines
	proc{Mine CurrentPlayer}
		ID
		MinePosition
	in
		% Ask if exploding mine
		{Send {List.nth Players CurrentPlayer} fireMine(?ID ?MinePosition)}
		{Wait ID} {Wait MinePosition}
		% Handle answer
		if MinePosition == null then skip
		else 
			{DamagingItem ID MinePosition mine}
			{Send GuiPort removeMine(ID MinePosition)} %todo in damagingitem
		end
	end

% -------------------------------------------------
% Functions for recursivity
% -------------------------------------------------

	% On fire of missile or mine (missile with fireItem and mine with fireMine)
	proc{DamagingItem ID Position KindItem}
		proc{DamagingItemRecursive ID Position KindItem PlayerList}
			case PlayerList
			of nil then skip
			[] Player|T then
				% Handle message to current player
				local Message in
					case KindItem
					of missile then {Send Player sayMissileExplode(ID Position ?Message)}
					[] mine then {Send Player sayMineExplode(ID Position ?Message)}
					end
					{Wait Message}
					% Broadcast information
					if Message == null then skip
					else {Broadcast Message}
					end
				end
				{DamagingItemRecursive ID Position KindItem T}
			end
		end
	in
		{DamagingItemRecursive ID Position KindItem Players}
	end

	% Handle sonar recursivity
	proc{Sonar ID CurrentPlayer}
		proc{SonarRecursive ID CurrentPlayer PlayerList}
			case PlayerList
			of nil then skip
			[] Player|T then
				% Handle message to current player
				local EnnemyID Answer in
					{Send Player sayPassingSonar(?EnnemyID ?Answer)}
					% Send back information to player that has sent the sonar
					{Send {List.nth Players CurrentPlayer} sayAnswerSonar(EnnemyID Answer)}
				end
				% Recursive call
				{SonarRecursive ID CurrentPlayer T}
			end
		end
	in
		{SonarRecursive ID CurrentPlayer Players}
	end

	% Handle drone recursivity
	proc{Drone ID CurrentPlayer Drone}
		proc{DroneRecursive ID CurrentPlayer Drone PlayerList}
			case PlayerList
			of nil then skip
			[] Player|T then
				% Handle message to current player
				local EnnemyID Answer in
					{Send Player sayPassingDrone(Drone ?EnnemyID ?Answer)}
					% Send back information to player that has sent the drone
					{Send {List.nth Players CurrentPlayer} sayAnswerDrone(Drone EnnemyID Answer)}
				end
				% Recursive call
				{DroneRecursive ID CurrentPlayer Drone T}
			end
		end
	in
		{DroneRecursive ID CurrentPlayer Drone Players}
	end

% -------------------------------------------------
% Broadcasting
% -------------------------------------------------
	% Send a message to all players
	proc {Broadcast Message}
		proc{MessageToPlayer Message PlayerNumber}
			if(PlayerNumber =< Input.nbPlayer) then
				{Send {List.nth Players PlayerNumber} Message}
				{MessageToPlayer Message PlayerNumber+1}
			else skip
			end
		end
	in 
		{MessageToPlayer Message 1}
	end

% -------------------------------------------------
% Turn-by-turn
% -------------------------------------------------
	proc{TurnByTurn CurrentPlayer TimeAtSurface}
		% Set delay
		{Time.delay Input.guiDelay}
		
		% If the player is at surface and can dive
		if({List.nth TimeAtSurface CurrentPlayer} == Input.turnSurface) then
			{Send {List.nth Players CurrentPlayer} dive}
			% Recursive call
			{TurnByTurn {NextPlayer CurrentPlayer} {ArrayReplace TimeAtSurface CurrentPlayer ~1}}
		
		% If the player is at surface but can't dive
		elseif ({List.nth TimeAtSurface CurrentPlayer} >= 0 andthen {List.nth TimeAtSurface CurrentPlayer} < Input.turnSurface) then
			% Recursive call
			{TurnByTurn {NextPlayer CurrentPlayer} {ArrayReplace TimeAtSurface CurrentPlayer ({List.nth TimeAtSurface CurrentPlayer}+1)}}
		
		% If the player is under water
		else
			% Player's turn is over
			if {Not {Move CurrentPlayer}} then 
				{TurnByTurn {NextPlayer CurrentPlayer} {ArrayReplace TimeAtSurface CurrentPlayer 0}} % todo 0 or 1, do not understand the rules
			% Player's turn continues
			else
				% Charge an item
				{Charge CurrentPlayer}
				% Fire an item
				{Fire CurrentPlayer}
				% Mine explosion
				{Mine CurrentPlayer}
			end
			% Recursive call
			{TurnByTurn {NextPlayer CurrentPlayer} TimeAtSurface}
		end

	end

% ------------------------------------------
% Starting point
% ------------------------------------------

	% Launch interface
	GuiPort = {GUI.portWindow}
	{Send GuiPort buildWindow}
    
	% Initialise players
	Players = {CreatePlayers}
	% Ask every player to set up (choose its initial point, they all are at the surface at this time)
	{InitPlayers Players}

	% When every player has set up, launch the game (either in turn by turn or in simultaneous mode, as specied by the input)
	if (Input.isTurnByTurn) then {TurnByTurn 1 0|0|nil}
	else {System.show isTurnByTurn_is_not_active}
	end
	{System.show program_end}
end