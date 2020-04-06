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
                else raise wrongPlayerException('is not in form as (H1|T1)#(H2|T2)') end
                end
            else nil %all players are created
            end
        end
    in
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
    GuiPort={PortWindow} 
    {Send GuiPort buildWindow}
    
    Players = {CreatePlayers}
    {InitPlayers}

    %a faire choisir la position de depart
    
    {System.show 'it worked well until here'}
end