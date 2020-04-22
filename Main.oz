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
	Broadcast BroadcastExclID
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

%sayMove(ID Direction), saySurface(ID), sayCharge(ID KindItem), sayMinePlaced(ID), sayAnswerDrone(Drone ID Answer), sayAnswerSonar(ID Answer), sayDeath(ID), sayDamageTaken(ID Damage LifeLeft)
	proc{Broadcast Message}
		proc{MessageToPlayer Message CurrentP}
			{System.show broadcast(CurrentP Message)}
			if(CurrentP < Input.nbPlayer) then
				{Send {List.nth Players CurrentP} Message}
				{MessageToPlayer Message {NextPlayer CurrentP}}
			else {Send {List.nth Players CurrentP} Message} end
		end
	in {MessageToPlayer Message 1}  end

	proc{BroadcastExclID Message ID}
		proc{MessageToPlayer Message CurrentP}
			if(ID.id == CurrentP) then
				{MessageToPlayer Message CurrentP+1}
			elseif(CurrentP < Input.nbPlayer) then
				{System.show broadcastExclID(CurrentP Message)}
				{Send {List.nth Players CurrentP} Message}
				{MessageToPlayer Message CurrentP+1}
			elseif(CurrentP == Input.nbPlayer) then
				{System.show broadcastExclID(CurrentP Message)}
				{Send {List.nth Players CurrentP} Message} 
			end
		end
	in {MessageToPlayer Message 1}  end

	proc{TurnByTurn CurrentP TimeAtSurf}
		%TimeAtSurf array with all player and nb of turns their waited
		%~1 == is not waiting to dive

		{Time.delay Input.guiDelay} 

		if ({List.nth TimeAtSurf CurrentP} == Input.turnSurface) then %check if may dive
			{Send {List.nth Players CurrentP} dive} %diving
			{TurnByTurn {NextPlayer CurrentP} {ArrayReplace TimeAtSurf CurrentP ~1}} 
		elseif {And {List.nth TimeAtSurf CurrentP}<Input.turnSurface  {List.nth TimeAtSurf CurrentP}>=0} then %need to wait for diving
			{TurnByTurn {NextPlayer CurrentP} {ArrayReplace TimeAtSurf CurrentP ({List.nth TimeAtSurf CurrentP}+1)}}
		else %already under water
			%continue playing
			local ID Pos Direction in
				{Send {List.nth Players CurrentP} move(?ID ?Pos ?Direction)}
				{Wait ID} {Wait Pos} {Wait Direction}
				if (Direction==surface) then 
					%{System.show mainSurface(id:ID)}
					{Send GuiPort surface(ID)}
					{Broadcast saySurface(ID)}
					{TurnByTurn {NextPlayer CurrentP} {ArrayReplace TimeAtSurf CurrentP 0}} %0 or 1, do not understand the rules
					%end turn
				else 
					%continue playing
					{Send GuiPort movePlayer(ID Pos)}
					{Broadcast sayMove(ID Direction)}

					%charge an item, broadcast if produced
					local IDcharge KindItem in
						{Send {List.nth Players CurrentP} chargeItem(?IDcharge ?KindItem)}
						{Wait IDcharge} {Wait KindItem}
						case KindItem
							of null 	then skip
							[] mine 	then {Broadcast mine}
							[] missile 	then {Broadcast missile}
							[] sonar 	then {Broadcast sonar}
							[] drone 	then {Broadcast drone}
						end
					end

					%ask if item fired, broadcast if fired
					local IDfire Item in
						{Send {List.nth Players CurrentP} fireItem(?IDfire ?Item)}
						{Wait IDfire} {Wait Item}
						case Item
							of null 			then skip
							[] mine(PosMine) then 	
								{Broadcast sayMinePlaced(IDfire)}
								{Send GuiPort putMine(IDfire PosMine)}
							[] missile(PosMiss)	then Message in %todo sayDommageTaken and sayDeath for mine and missile
								{Broadcast sayMissileExplode(ID PosMiss ?Message)}
							[] sonar then SID Answer in %todo reflection broadcast to everyone, also the one that send the sonar?
								{BroadcastExclID sayPassingSonar(?SID ?Answer) ID}
								{Broadcast sayAnswerSonar(SID Answer)}
							[] drone(RowCol Number) then DID Answer in%todo reflection broadcast to everyone, also the one that send the drone?
								{BroadcastExclID sayPassingDrone(drone(RowCol Number) ?DID ?Answer) ID} %todo correct errors
								{Broadcast sayAnswerDrone(drone(RowCol Number) DID Answer)}
						end
					end

					%Player can explode a mine
					local IDmine Mine in
						{Send {List.nth Players CurrentP} fireMine(?IDmine ?Mine)}
						{Wait IDmine} {Wait Mine}
						case Mine 
							of null 		then skip
							[] pt(x:_ y:_) 	then Message in 
								{BroadcastExclID sayMineExplode(IDmine Mine ?Message) IDmine}
								%{Broadcast sayMineExplode(IDmine Mine ?Message)}
								{Send GuiPort removeMine(IDmine Mine)} %todo sayDommageTaken and sayDeath for mine and missile
						end
					end

					{TurnByTurn {NextPlayer CurrentP} TimeAtSurf}
				end
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

	% When every player has set up, launch the game (either in turn by turn or in simultaneous mode, as specied by the input)
	if (Input.isTurnByTurn) then {TurnByTurn 1 0|0|nil}
	else {System.show isTurnByTurn_is_not_active}
	end
	{System.show program_end}
end