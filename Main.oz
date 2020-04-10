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
	% VARIABLES
	GuiPort
	Players
in
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
	
	% Launch interface
	GuiPort = {GUI.portWindow}
	{Send GuiPort buildWindow}
    
  % Initialise players
  Players = {CreatePlayers}
  {InitPlayers Players}
	
	%TODO choisir la position de depart
	{System.show 'Hey' }


	%3. Ask every player to set up (choose its initial point, they all are at the surface at this time)
	%4. When every player has set up, launch the game (either in turn by turn or in simultaneous mode, as specied by the input le)

end