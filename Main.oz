functor
import
	GUI
	Input
	PlayerManager
	System %added for show
define
	PortWindow = GUI.portWindow
	GuiPort

	CreatePlayers
	Players
	InitPlayers
in

% Create a list of players
	fun {CreatePlayers}
		local 
			fun {CreatePlayerList ID NPlayers Players Colors}
				if (ID =< NPlayers) then
					case Players#Colors
					of (Hplayer|Tplayer)#(Hcolor|Tcolor) then {PlayerManager.playerGenerator Hplayer Hcolor ID}{CreatePlayerList ID+1 NPlayers Tplayer Tcolor}
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
	fun {InitPlayers PlayerList}
		case PlayerList
		of Player|T then ID Pos in 
			{Send Player initPosition(ID Pos)}
			{Wait ID} {Wait Pos}
			{Send GuiPort initPlayer(ID Pos)}
			{InitPlayers T}
		end
	end

	%1. Create the port for the GUI and launch its interface
	GuiPort = {PortWindow}
	{Send GuiPort buildWindow}
    
  %2. Create the port for every player
  Players = {CreatePlayers}
  {InitPlayers Players}

	% a faire choisir la position de depart
    
	{System.show 'it worked well until here'}

  %3. Ask every player to set up (choose its initial point, they all are at the surface at this time)
  %4. When every player has set up, launch the game (either in turn by turn or in simultaneous mode, as specied by the input le)


end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%EBNF
%<id> ::= null | id(id:<idNum> color:<color> name:Name)
    %<idNum> ::= 1 | 2 | ... | Input.nbPlayer
    %<color> ::= red | blue | green | yellow | white | black | c(<colorNum> <colorNum> <colorNum>)
        %<colorNum> ::= 0 | 1 | ... | 255

%<position> ::= pt(x:<row> y:<column>)
    %<row> ::= 1 | 2 | ... | Input.nRow
    %<column> ::= 1 | 2 | ... | Input.nColumn

%<direction> ::= <carddirection> | surface
    %<carddirection> ::= east | north | south | west

%<item> ::= null | mine | missile | sonar | drone
%<fireitem> ::= null | mine(<position>) | missile(<position>) | <drone> | sonar
    %<drone> ::= drone(row <x>) | drone(column <y>)
    %<mine> ::= null | <position>