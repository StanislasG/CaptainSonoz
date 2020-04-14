functor
import
	GUI
	Input
	PlayerManager
	System % added for System.show
define
	% FUNCTIONS
	CreatePlayers
	InitPlayers
	
	ArrayReplace
	NextPlayer
	TurnByTurn

	% VARIABLES
	GuiPort
	Players
in

% ------------------------------------------
% Initialisation
% ------------------------------------------
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
% ------------------------------------------
% In-game management
% ------------------------------------------
	fun{ArrayReplace Array Pos NewItem}
		if(Pos<1) then {System.show pos_error} raise wrongArrayPositionException() end
		elseif(Pos==1) then NewItem|Array.2 
		else Array.1|{ArrayReplace Array.2 Pos-1 NewItem} end
	end

	fun{NextPlayer CurrentP}
		if (CurrentP == Input.nbPlayer) then 1 %Id start at 1
		else CurrentP+1 end
	end

	proc{TurnByTurn CurrentP TimeAtSurf}
		%TimeAtSurf array with all player and nb of turns their waited
		%~1 == is not waiting to dive

		{Time.delay 250} 

		if ({List.nth TimeAtSurf CurrentP} == Input.turnSurface) then %check if may dive
			{Send {List.nth Players CurrentP} dive} %send dive to the player
		  	{TurnByTurn {NextPlayer CurrentP} {ArrayReplace TimeAtSurf CurrentP ~1} } 
		elseif {And {List.nth TimeAtSurf CurrentP}<Input.turnSurface  {List.nth TimeAtSurf CurrentP}>=0} then
			{TurnByTurn {NextPlayer CurrentP} {ArrayReplace TimeAtSurf CurrentP ({List.nth TimeAtSurf CurrentP}+1)}}
		else %already under water
			%continue playing
			local ID Pos Direction NewTimeAtSurf in
				{Send {List.nth Players CurrentP} move(?ID ?Pos ?Direction)}
				{Wait ID} {Wait Pos} {Wait Direction}
				if (Direction==surface) then 
					{Send GuiPort surface(ID)} 
					NewTimeAtSurf={ArrayReplace TimeAtSurf CurrentP 0}
				else 
					{Send GuiPort movePlayer(ID Pos)} 
					NewTimeAtSurf=TimeAtSurf 
				end
				{TurnByTurn {NextPlayer CurrentP} NewTimeAtSurf}
			end
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

	%4. When every player has set up, launch the game (either in turn by turn or in simultaneous mode, as specied by the input le)
	if (Input.isTurnByTurn) then
		{TurnByTurn 1 0|0|nil}
	else
		{System.show isTurnByTurn_is_not_active}
	end
	{System.show program_end}
end