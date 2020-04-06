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

%internet
    %return a list of ports
    fun{CreatePlayers}
        fun{CreatePlayerList ID NbPlayer Players Colors}
            if(ID =<NbPlayer) then
                case Players#Colors
                of (H1|T1)#(H2|T2) then
                    {PlayerManager.playerGenerator H1 H2 ID}|{CreatePlayerList ID+1 NbPlayer T1 T2}
                else 
                    raise wrongPlayerException('is not in form as (H1|T1)#(H2|T2)') end
                end
            else nil %all players are created
            end
        end
    in
        % (int) Input.nbPlayer, (tab) Input.players, (tab) Input.colors
        {CreatePlayerList 1 Input.nbPlayer Input.players Input.colors}
    end

    %internet
    proc{InitPlayers}
        proc{InitPlayer Liste}
            case Liste
            of nil then skip %last element of the liste
            []Player|Rest then ID Pos in
                %send to each player their start position and their id
                {Send Player initPosition(ID Pos)} 
                {Wait ID}
                {Wait Pos}
                %notify GUI line 259 in GUI.oz
                {Send GuiPort initPlayer(ID Pos)}
	            {InitPlayer Rest}
            end
        end
        in
        {InitPlayer Players} %maybe as parameter?
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %1. Create the port for the GUI and launch its interface
    GuiPort={PortWindow} 
    {Send GuiPort buildWindow}
    
    %2. Create the port for every player using the PlayerManager and assign a unique id between 1 and
    %    Input.nbPlayer (< idnum >). The ids are given in the order they are defined in the input file
    Players = {CreatePlayers}
    {InitPlayers}

    %a faire choisir la position de depart
    
    {System.show 'it worked well until here'}

    
    
    %3. Ask every player to set up (choose its initial point, they all are at the surface at this time)
    %4. When every player has set up, launch the game (either in turn by turn or in simultaneous mode, as
    %   specied by the input le)
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