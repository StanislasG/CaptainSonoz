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
	SayMissileExplode
	SayMineExplode
	SayPassingDrone
	SayAnswerDrone
	SayPassingSonar
	SayAnswerSonar
	SayDeath
	SayDamageTaken
in

% ------------------------------------------
% Structure
% ------------------------------------------
% myInfo(id:___ path:___ surface:___)
% 		- id: my ID, id(id:___ color:___ name:___)
% 		- path: my path, list of pt(x:___ y:___) where path.1 = position
%		- surface: true if at surface, false if submarin is underwater
% 
% todo reflection about a list of all possible position instead of path (recompute with each new info about the player), could be usefull for integration of sonar and drone
% player(id:___ lives:___ possibilities:___ mines:___ charge:charge(mine:___ missile:___ sonar:___ drone:___))
% 		- id: to match ID sent by main
% 		- possibilities: list of possible points for player's position
% 		- mines: mines of a player, nil | (<position>|mines)
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

	% Get my position (MyInfo.path.1)
	fun{GetPosition MyInfo}
		case MyInfo.path 
			of H|_ 			then H
			[] pt(x:_ y:_)	then MyInfo.path
		end
	end

	fun {Dive MyInfo}
		myInfo(id:MyInfo.id path:{GetPosition MyInfo}|nil surface:false) 
	end

	fun {Surface MyInfo} 
		myInfo(id:MyInfo.id path:{GetPosition MyInfo}|nil surface:true)	
	end
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
			myInfo(id:MyInfo.id path:Pos|nil surface:true)
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
		MyInfo = myInfo(id:id(id:ID color:Color name:'PlayerNameTest') path:nil surface:true)
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
				player(id:ID lives:Input.maxDamage possibilities:{ValidPositions {GeneratePositions}} mines:nil charge:charge(mine:0 missile:0 sonar:0 drone:0))|{CreatePlayer ID+1}
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
		P Possib
	in		
		% Calculate useful info
		P = {GetPosition MyInfo}

		Possib = directions(north:{AccessiblePosition {North P}} east:{AccessiblePosition {East P}} south:{AccessiblePosition {South P}} west:{AccessiblePosition {West P}})

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
			myInfo(id:MyInfo.id path:Pos|MyInfo.path surface:false)
		end
	end

	% Find a valid path
	fun {FindPath Pos Path Possib}
		if Possib == directions(north:0 east:0 south:0 west:0) 
			then surface
		else
			if Path == nil then {ChooseDirection Possib}
			elseif Path.1 == {North Pos} then {FindPath Pos Path.2 directions(north:0            	east:Possib.east  south:Possib.south  west:Possib.west)}
			elseif Path.1 == {South Pos} then {FindPath Pos Path.2 directions(north:Possib.north 	east:Possib.east  south:0             west:Possib.west)}
			elseif Path.1 == {East  Pos} then {FindPath Pos Path.2 directions(north:Possib.north 	east:0            south:Possib.south  west:Possib.west)}
			elseif Path.1 == {West  Pos} then {FindPath Pos Path.2 directions(north:Possib.north 	east:Possib.east  south:Possib.south  west:0          )}
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
	fun {PlayerModification WantedID PlayersInfo Fun Args}
		case PlayersInfo
		of nil then nil
		[] player(id:ID lives:_ possibilities:_ mines:_ charge:_)|Next then
			if (ID == WantedID) then
				{Fun Args PlayersInfo.1}|Next
			else
				PlayersInfo.1|{PlayerModification WantedID Next Fun Args}
			end
		end
	end

	% Moving
	% Args: arguments(direction:___)
	fun{SayMove Args Player}
		local 
			NewPossibilities = {ValidPositions {NewPositionList Player.possibilities Args.direction}}
		in
			player(id:Player.id lives:Player.lives possibilities:NewPossibilities mines:Player.mines charge:Player.charge)
		end
	end

	fun{SaySurface ID Player}
		{System.show iAmHere}
	end
	
	fun{SayCharge ID KindItem Player}
		{System.show iAmHere}
	end
	
	fun{SayMinePlaced ID Player}
		{System.show iAmHere}
	end
	
	fun{SayMissileExplode ID Pos ?Message Player}
		{System.show iAmHere}
	end
	
	fun{SayMineExplode ID Pos ?Message Player}
		{System.show iAmHere}
	end
	
	fun{SayPassingDrone Drone ?ID ?Answer}
		{System.show iAmHere}
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
			%todo case surface saySurface
			%todo sayMove to main
			{TreatStream T NewMyInfo PlayersInfo}

		[]dive|T then
			{TreatStream T {Dive MyInfo} PlayersInfo}

		[]chargeItem(?ID ?KindItem)|T then 
			{ChargeItem ID KindItem MyInfo} %todo, currently only null
			{TreatStream T MyInfo PlayersInfo}

		[]fireItem(?ID ?KindFire)|T then 
			%<fireitem> ::= null | mine(<position>) | missile(<position>) | <drone> | sonar
			%<drone> ::= drone(row <x>) | drone(column <y>)
			%<mine> ::= null | <position>
			{FireItem ID KindFire MyInfo}
			{TreatStream T MyInfo PlayersInfo}

		[]fireMine(?ID ?Mine)|T then 
			{FireMine ID Mine MyInfo}
			{TreatStream T MyInfo PlayersInfo}

		[]isDead(?Answer)|T then 
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayMove(ID Direction)|T then 
			%everyone is getting the message
			{TreatStream T MyInfo PlayersInfo}
			
		[]saySurface(ID)|T then
			%everyone is getting the message
			{TreatStream T MyInfo PlayersInfo}

		[]sayCharge(ID KindItem)|T then 
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayMinePlaced(ID)|T then 
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayMissileExplode(ID Position ?Message)|T then
			
			%todo sayDamgeTaken
			%todo sayDeath
			Message = null %no dommage taken
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayMineExplode(ID Position ?Message)|T then 
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayPassingDrone(Drone ?ID ?Answer)|T then 
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayAnswerDrone(Drone ID Answer)|T then 
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayPassingSonar(?ID ?Answer)|T then 
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayAnswerSonar(ID Answer)|T then 
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayDeath(ID)|T then 
			{TreatStream T MyInfo PlayersInfo}
		
		[]sayDamageTaken(ID Damage LifeLeft)|T then 
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
