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
		if(Pos<1) then raise wrongArrayPositionException() end
		elseif(Pos==1) then NewItem|Array.2 
		else Array.1|{ArrayReplace Array.2 Pos-1 NewItem} end
	end

	fun{NextPlayer CurrentP NbPlayer} ((CurrentP+1) mod NbPlayer)+1 end

	fun{TurnByTurn CurrentP TimeAtSurf NbPlayer}
		%TimeAtSurf array with all player

		if TimeAtSurf.CurrentP == Input.turnSurface then %check if may dive
			{Send Players.CurrentP dive}
		  	{TurnByTurn {NextPlayer CurrentP NbPlayer} {ArrayReplace TimeAtSurf CurrentP ~1} NbPlayer} %~1 == is not waiting to dive
		elseif {And TimeAtSurf.CurrentP<Input.turnSurface  TimeAtSurf.CurrentP>=0} then
			{TurnByTurn {NextPlayer CurrentP NbPlayer} {ArrayReplace TimeAtSurf CurrentP TimeAtSurf.CurrentP+1} NbPlayer}
		else %already under water
			{System.show "good"}
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
		{System.show "isTurnByTurn is active"}
	else
		{System.show "isTurnByTurn is not active"}
	end
end