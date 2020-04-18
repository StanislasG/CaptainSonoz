functor
import
	Input
	System
	OS %added for random
export
	portPlayer:StartPlayer
define
	% Main function
	TreatStream

	% Base functions
	North South East West
	NewPosition NewPositionList
	ValidPositions
	AccessiblePosition
	ManhattanDistance
	PrettyPrintMap
	
	% Game start functions
	StartPlayer
	InitPosition
	CreatePlayers
	GeneratePositions

	% In-game management functions
	Move FindPath ChooseDirection
	Dive Surface GetPosition
	ChargeItem FireItem FireMine

	% Say functions
	PlayerModification
	SayMove 
	SaySurface
	SayCharge
	SayMinePlaced
	SayMissileExplodeMyInfo SayMissileExplodeMissileStatus
	SayMineExplodeMyInfo
	SayPassingDrone
	SayAnswerDrone
	SayPassingSonar
	SayAnswerSonar
	SayDeath
	SayDamageTaken
in

% ------------------------------------------
% Structure code
% ------------------------------------------
%	Structure variables
%	Basic functions
%	Initialisation
%	In-game management - Send Information
%	In-game management - Receive Information
%	TreatStream

% ------------------------------------------
% Structure variables
% ------------------------------------------
% myInfo(id:___ lives:___ path:___ surface:___)
% 		- id: my ID, id(id:___ color:___ name:___)
% 		- lives: the number of lives left
% 		- path: my path, list of pt(x:___ y:___) where path.1 = position
%			- surface: true if at surface, false if submarin is underwater
% 
% player(id:___ lives:___ possibilities:___ surface:___ charge:charge(mine:___ missile:___ sonar:___ drone:___))
% 		- id: to match ID sent by main
% 		- lives: number of lives of the submarine
% 		- possibilities: list of possible points for player's position
% 		- surface: true or false
% 		- charge: from 0 to Input.Mine / Input.Sonar / ..., if Input.Mine reach the item is loaded and ready to be fired


% ------------------------------------------
% Basic functions
% ------------------------------------------
	% Return pt north/... of Pos
	fun {North Pos} pt(x:Pos.x-1 y:Pos.y  ) end
	fun {South Pos} pt(x:Pos.x+1 y:Pos.y  ) end
	fun {East  Pos} pt(x:Pos.x   y:Pos.y+1) end
	fun {West  Pos} pt(x:Pos.x   y:Pos.y-1) end
	
	% Returns the position North/South/... of Pos 
	fun {NewPosition Pos Direction}
		case Direction 
		of north then {North Pos}
		[] south then {South Pos}
		[] east  then {East  Pos}
		[] west  then {West  Pos}
		end
	end

	% Returns the new positions for a whole list
	fun {NewPositionList Pos Direction}
		case Pos of nil then nil
		[] H|T then {NewPosition H Direction} | {NewPositionList T Direction}
		end
	end

	% Returns "Positions" without the non-accessible positions
	fun {ValidPositions Positions}
		case Positions
		of nil then nil
		[] H|T then 
			if {AccessiblePosition H} == 0 then {ValidPositions T}
			else H|{ValidPositions T}
			end
		end
	end

	% Check if accessible position (not outside of bounds and not an island)
	fun {AccessiblePosition Pos}
		% 0 meaning false and 1 meaning true
		case Pos
		of pt(x:X y:Y) then
			if (X =< 0 orelse Y =< 0 orelse X > Input.nRow orelse Y > Input.nColumn orelse {List.nth {List.nth Input.map X} Y} == 1) 
				then 0
			else 1
			end
		[] _ then nil
		end
	end

	% Computes the Manhattan distance between 2 positions
	fun {ManhattanDistance Pos1 Pos2}
		{Number.abs Pos1.x-Pos2.x} + {Number.abs Pos1.y-Pos2.y}
	end

	% Generates a list of all positions on the map
	fun {GeneratePositions}
		local 
			fun {GeneratePositionsRec X Y}
				if (Y == Input.nColumn) then 
					if (X == Input.nRow) then pt(x:X y:Y)|nil
					else pt(x:X y:Y)|{GeneratePositionsRec X+1 1}
					end
				else pt(x:X y:Y)|{GeneratePositionsRec X Y+1}
				end
			end
		in
			{GeneratePositionsRec 1 1}
		end
	end

	fun {Dive MyInfo}
		myInfo(id:MyInfo.id lives:MyInfo.lives path:MyInfo.path.1|nil surface:false) 
	end

	fun {Surface MyInfo} 
		myInfo(id:MyInfo.id lives:MyInfo.lives path:MyInfo.path.1|nil surface:true)	
	end

	%PoinList = pt(x: y:_)|pt|...|nil
	%it works if nothing else is printing to the terminal at the same time
	%with his actual config it take a list of points and add it on the Input map (can be used for visualing the possible positions of the players)
	proc{PrettyPrintMap PointList}
		%change one pt to Char in a given map
		fun{ChangeMap Map X Y Char}
			fun{ChangeRow RMap RX}
				if(RX==1) then {ChangeCol RMap.1 Y}|RMap.2
				else RMap.1|{ChangeRow RMap.2 RX-1} end
			end
			fun{ChangeCol CMap CY}
				if(CY==1) then Char|CMap.2
				else CMap.1|{ChangeCol CMap.2 CY-1} end
			end
		in {ChangeRow Map X} end
		fun{TempMap Map PointList Char}
			case PointList of pt(x:X y:Y)|T then {TempMap {ChangeMap Map X Y Char} T Char}
			else Map end
		end
		proc{PrintMap Map}
			{System.show {List.toTuple '_' Map.1}}
			if(Map.2==nil)==false then {PrintMap Map.2} end
		end
	in {System.show '----'} {PrintMap {TempMap Input.map PointList 9}} {System.show '----'}	end

% ------------------------------------------
% Initialisation
% ------------------------------------------
	% Initialise Position (random)
	fun{InitPosition ID Pos MyInfo}
		X Y
	in
		X = ({OS.rand} mod Input.nRow) + 1
		Y = ({OS.rand} mod Input.nColumn) + 1
		% if position is not accessible
		if({AccessiblePosition pt(x:X y:Y)} == 0)
			then {InitPosition ID Pos MyInfo}
		else
			ID = MyInfo.id
			Pos = pt(x:X y:Y)
			% return updated info with position
			myInfo(id:MyInfo.id lives:MyInfo.lives path:Pos|nil surface:true)
		end
	end

	% Start Player (portPlayer from PlayerManager)
	fun{StartPlayer Color ID}
		Stream
		Port
		MyInfo
		PlayersInfo
	in
		% MyInfo will be stored by passing it as argument in TreatStream
		MyInfo = myInfo(id:id(id:ID color:Color name:'PlayerNameTest') lives:Input.maxDamage path:nil surface:true)
		PlayersInfo = {CreatePlayers}
		{NewPort Stream Port}
		thread
			{TreatStream Stream MyInfo PlayersInfo} % TODO : player name ?
		end
		Port
	end

	fun{CreatePlayers}
		fun{CreatePlayer ID}
			if(ID>Input.nbPlayer) 
				then nil 
			else
				player(id:ID lives:Input.maxDamage possibilities:{ValidPositions {GeneratePositions}} surface:true charge:charge(mine:0 missile:0 sonar:0 drone:0))|{CreatePlayer ID+1}
			end
		end
	in
		{CreatePlayer 1} %first ID is one
	end
% ------------------------------------------
% In-game management - Send Information
% ------------------------------------------
	% Moving randomly
	fun {Move ID Pos Direction MyInfo}
		P Possib N S E W
	in		
		% Calculate useful info
		P = MyInfo.path.1
		
		N = {AccessiblePosition {North P}}
		S = {AccessiblePosition {South P}}
		E = {AccessiblePosition {East  P}}
		W = {AccessiblePosition {West  P}}

		Possib = directions(north:N east:E south:S west:W)

		% Assign values to unassigned var
		Direction = {FindPath P MyInfo.path Possib}
		ID = MyInfo.id
		case Direction
		of north   then Pos = {North P}
		[] south   then Pos = {South P}
		[] east    then Pos = {East  P}
		[] west    then Pos = {West  P}
		[] surface then Pos = P
		end 

		% Return modified MyInfo
		if(Direction == surface) then
			{Surface MyInfo}
		else 
			myInfo(id:MyInfo.id lives:MyInfo.lives path:Pos|MyInfo.path surface:false)
		end
	end

	% Find a valid path
	fun {FindPath Pos Path Possib}
		N S E W 
	in
		directions(north:N east:E south:S west:W) = Possib

		if N#S#E#W == 0#0#0#0
			then surface
		else
			if Path == nil then {ChooseDirection Possib}
			elseif Path.1 == {North Pos} then {FindPath Pos Path.2 directions(north:0	east:E south:S west:W)}
			elseif Path.1 == {East  Pos} then {FindPath Pos Path.2 directions(north:N	east:0 south:S west:W)}
			elseif Path.1 == {South Pos} then {FindPath Pos Path.2 directions(north:N	east:E south:0 west:W)}
			elseif Path.1 == {West  Pos} then {FindPath Pos Path.2 directions(north:N	east:E south:S west:0)}
			else {FindPath Pos Path.2 Possib}
			end
		end
	end

	% Choose a random direction
	fun {ChooseDirection Possib}
		case ({OS.rand} mod 4)
		of 0 then if Possib.north == 1 then north else {ChooseDirection Possib} end
		[] 1 then if Possib.east  == 1 then east  else {ChooseDirection Possib} end
		[] 2 then if Possib.south == 1 then south else {ChooseDirection Possib} end
		[] 3 then if Possib.west  == 1 then west  else {ChooseDirection Possib} end
		end
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%todo need to charge and bind KindItem if produced
	%check when item is produced: Input.mine, Input.missile, Input.sonar, Input.drone

	proc{ChargeItem ID KindItem MyInfo}
		%<item> ::= null | mine | missile | sonar | drone
		ID = MyInfo.id
		KindItem = null
	end

	proc{FireItem ID Item MyInfo}
		ID = MyInfo.id
		Item = null
	end

	proc{FireMine ID Mine MyInfo}
		ID = MyInfo.id
		Mine = null
	end

% ------------------------------------------
% In-game management - Receive Information
% ------------------------------------------
	% Apply "Fun" to the right player
	% Args is a record where are only stored the useful arguments
	% 	For example : arguments(direction:north) for SayMove

	% Information in varialbes
	% wantedID = id(color:_ id:_ name:_)
	% PlayersInfo = player(charge:charge(drone:_ mine:_ missile:_ sonar:_) id:_ lives:_ possibilities:_) | player
	% Fun = _
	% Args = arguments(_)
	fun {PlayerModification WantedID PlayersInfo Fun Args}
		case PlayersInfo
		of nil then nil
		[] player(id:ID lives:_ possibilities:_ surface:_ charge:_)|Next then
			if (ID == WantedID.id) then
				
				{Fun Args PlayersInfo.1}|Next
			else
				PlayersInfo.1|{PlayerModification WantedID Next Fun Args}
			end
		end
	end

	% Move broadcasted, try to locate all players based only by elemination of possibilities 
	% Args: arguments(direction:___)
	fun{SayMove Args Player}
		NewPossibilities
		% Get information
		PID PLives PPoss PSurf PCharge 
	in
		player(id:PID lives:PLives possibilities:PPoss surface:PSurf charge:PCharge) = Player
		% Calculate
		NewPossibilities = {ValidPositions {NewPositionList PPoss Args.direction}}
		%{PrettyPrintMap NewPossibilities}
		% Return
		player(id:PID lives:PLives possibilities:NewPossibilities surface:false charge:PCharge)
	end

	% Update Player.surface when player has surfaced
	% Args: arguments() [no arguments]
	fun{SaySurface Args Player}
		% Get information
		PID PLives PPoss PSurf PCharge 
	in
		player(id:PID lives:PLives possibilities:PPoss surface:PSurf charge:PCharge) = Player
		% Return
		player(id:PID lives:PLives possibilities:PPoss surface:true charge:PCharge)
	end
	
	% Updates Player's charge number on an item
	% Args: arguments(itemKind)
	fun{SayCharge Args Player}
		NewCharge
		% Get information
		PID PLives PPoss PSurf PCharge 
	in
		player(id:PID lives:PLives possibilities:PPoss surface:PSurf charge:PCharge) = Player
		% Calculate
		case Args.itemKind
		of mine    then NewCharge = charge(mine:PCharge.mine+1 missile:PCharge.missile sonar:PCharge.sonar drone:PCharge.drone)
		[] missile then NewCharge = charge(mine:PCharge.mine missile:PCharge.missile+1 sonar:PCharge.sonar drone:PCharge.drone)
		[] sonar   then NewCharge = charge(mine:PCharge.mine missile:PCharge.missile sonar:PCharge.sonar+1 drone:PCharge.drone)
		[] drone   then NewCharge = charge(mine:PCharge.mine missile:PCharge.missile sonar:PCharge.sonar drone:PCharge.drone+1)
		end
		% Return
		player(id:PID lives:PLives possibilities:PPoss surface:PSurf charge:NewCharge)
	end
	
	% Update mine charge status when mine is placed
	% Args: arguments() [no arguments]
	fun{SayMinePlaced Args Player}
		NewCharge
		% Get information
		PID PLives PPoss PSurf PCharge 
	in
		player(id:PID lives:PLives possibilities:PPoss surface:PSurf charge:PCharge) = Player
		% Edit new charges status
		NewCharge = charge(mine:0 missile:PCharge.missile sonar:PCharge.sonar drone:PCharge.drone)
		% Return
		player(id:PID lives:PLives possibilities:PPoss surface:PSurf charge:NewCharge)
	end

	% On missile explosion, edit my info and send message back
	fun{SayMissileExplodeMyInfo MyInfo Pos Message}
		DamageTaken
	in
		% Compute damage taken
		case {ManhattanDistance MyInfo.path.1 Pos}
			of 1 then	DamageTaken = 1
			[] 0 then	DamageTaken = 2
			else 		DamageTaken = 0
		end
		% Send message
		if DamageTaken == 0 then Message = null
		elseif MyInfo.lives =< DamageTaken then Message = sayDeath(MyInfo.id)
		else Message = sayDamageTaken(MyInfo.id DamageTaken MyInfo.lives-DamageTaken)
		end
		% Return edited MyInfo
		myInfo(id:MyInfo.id lives:(MyInfo.lives-DamageTaken) path:MyInfo.path surface:MyInfo.surface)
	end

	% On missile explosion, edit missile charge status
	% Args: arguments() [no arguments]
	fun{SayMissileExplodeMissileStatus Args Player}
		NewCharge
		% Get information
		PID PLives PPoss PSurf PCharge 
	in
		player(id:PID lives:PLives possibilities:PPoss surface:PSurf charge:PCharge) = Player
		% Edit new charges status
		NewCharge = charge(mine:PCharge.mine missile:0 sonar:PCharge.sonar drone:PCharge.drone)
		% Return
		player(id:PID lives:PLives possibilities:PPoss surface:PSurf charge:NewCharge)
	end
	
	fun{SayMineExplodeMyInfo MyInfo Pos Message}
		DamageTaken
	in
		% Compute damage taken
		case {ManhattanDistance MyInfo.path.1 Pos}
			of 1 then	DamageTaken = 1
			[] 0 then	DamageTaken = 2
			else 		DamageTaken = 0
		end
		% Send message
		if DamageTaken == 0 then Message = null
		elseif MyInfo.lives =< DamageTaken then Message = sayDeath(MyInfo.id)
		else Message = sayDamageTaken(MyInfo.id DamageTaken MyInfo.lives-DamageTaken)
		end
		% Return edited MyInfo
		myInfo(id:MyInfo.id lives:(MyInfo.lives-DamageTaken) path:MyInfo.path surface:MyInfo.surface)
	end
	
	proc{SayPassingDrone Drone ?ID ?Answer MyInfo}
		ID = MyInfo.id
		case Drone
			of drone(row X) 	then Answer=(MyInfo.path.1.x == X)
			[] drone(column Y)	then Answer=(MyInfo.path.1.y == Y)
		end
	end
	
	fun{SayAnswerDrone Drone ID Answer Player}
		{System.show iAmHere}
	end
	
	fun{SayPassingSonar ?ID ?Answer}
		{System.show iAmHere}
	end
	
	fun{SayAnswerSonar ID Answer Player}
		{System.show iAmHere}
	end
	
	fun{SayDeath ID Player}
		{System.show iAmHere}
	end
	
	fun{SayDamageTaken ID Damage LifeLeft Player}
		{System.show iAmHere}
	end

% ------------------------------------------
% TreatStream
% ------------------------------------------
	proc{TreatStream Stream MyInfo PlayersInfo}
		case Stream
		of nil then skip

		[]initPosition(?ID ?Pos)|T then NewMyInfo in
			% MyInfo as argument to get information needed
			NewMyInfo = {InitPosition ID Pos MyInfo}
			{TreatStream T NewMyInfo PlayersInfo}
		
		[]move(?ID ?Pos ?Direction)|T then NewMyInfo in
			NewMyInfo = {Move ID Pos Direction MyInfo}
			{TreatStream T NewMyInfo PlayersInfo}

		[]dive|T then
			{TreatStream T {Dive MyInfo} PlayersInfo}

		[]chargeItem(?ID ?KindItem)|T then 
			{ChargeItem ID KindItem MyInfo} %todo, currently only null
			{TreatStream T MyInfo PlayersInfo}

		[]fireItem(?ID ?KindFire)|T then 
			{FireItem ID KindFire MyInfo}
			{TreatStream T MyInfo PlayersInfo}

		[]fireMine(?ID ?Mine)|T then 
			{FireMine ID Mine MyInfo}
			{TreatStream T MyInfo PlayersInfo}

		[]isDead(?Answer)|T then 
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayMove(ID Direction)|T then 
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayMove arguments(direction:Direction)}}
		
		[]saySurface(ID)|T then
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SaySurface arguments()}}

		[]sayCharge(ID KindItem)|T then 
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayCharge arguments(itemKind:KindItem)}}
		
		[]sayMinePlaced(ID)|T then 
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayMinePlaced arguments()}}
		
		[]sayMissileExplode(ID Position ?Message)|T then
			% edit MyInfo (lives) and send Message back
			% edit specific player's info (charge.missile)
			{TreatStream T {SayMissileExplodeMyInfo MyInfo Position Message} {PlayerModification ID PlayersInfo SayMissileExplodeMissileStatus arguments()}}
			% edit PlayersInfo's lives will be done with sayDamageTaken
		
		%todo, reflection: do we add the possible position of the mine, because actually we do not?
		[]sayMineExplode(ID Position ?Message)|T then 
			{TreatStream T {SayMissileExplodeMyInfo MyInfo Position Message} PlayersInfo}
		
		[]sayPassingDrone(Drone ?ID ?Answer)|T then 
			{SayPassingDrone Drone ID Answer MyInfo}
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayAnswerDrone(Drone ID Answer)|T then 
			%todo remove possibilities
			{TreatStream T MyInfo PlayersInfo}
		
		%todo define strat for infomation that we give, count number that maximize unknown
		[]sayPassingSonar(?ID ?Answer)|T then 
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayAnswerSonar(ID Answer)|T then
			%todo remove possibilities
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayDeath(ID)|T then 
			%todo modify PlayersInfo with PlayerModification
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayDamageTaken(ID Damage LifeLeft)|T then 
			%todo modify PlayersInfo with PlayerModification
			{TreatStream T MyInfo PlayersInfo}
		
		[] _|T then
			{TreatStream T MyInfo PlayersInfo}
		end
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%message to be handled

	%initPosition(?ID ?Position)
	%move(?ID ?Position ?Direction)
	%dive
	%chargeItem(?ID ?KindItem)
	%fireItem(?ID ?KindFire)
	%fireMine(?ID ?Mine)
	%isDead(?Answer)
	%sayMove(ID Direction)
	%saySurface(ID)
	%sayCharge(ID KindItem)
	%sayMinePlaced(ID)
	%sayMissileExplode(ID Position ?Message)
	%sayMineExplode(ID Position ?Message)
	%sayPassingDrone(Drone ?ID ?Answer)
	%sayAnswerDrone(Drone ID Answer)
	%sayPassingSonar(?ID ?Answer)
	%sayAnswerSonar(ID Answer)
	%sayDeath(ID)
	%sayDamageTaken(ID Damage LifeLeft)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
