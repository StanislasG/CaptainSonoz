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
	AccessiblePosition
	
	% Game start functions
	StartPlayer
	InitPosition

	% In-game management functions
	Move FindPath ChooseDirection
	Dive Surface

	Function % for compiling TODO delete this
in

% ------------------------------------------
% Structure
% ------------------------------------------
% myInfo(id:___ path:___ surface:__)
% 		- id: my ID, id(id:___ color:___ name:___)
% 		- path: my path, list of pt(x:___ y:___) where path.1 = position
%		- surface: true if at surface, false if submarin is underwater
% 
% player(id:___ lives:___ path:___ mines:___)


% ------------------------------------------
% Base functions
% ------------------------------------------
	% Return pt north/... of Pos
	fun {North Pos} pt(x:Pos.x   y:Pos.y-1) end
	fun {South Pos} pt(x:Pos.x   y:Pos.y+1) end
	fun {East  Pos} pt(x:Pos.x+1 y:Pos.y  ) end
	fun {West  Pos} pt(x:Pos.x-1 y:Pos.y  ) end

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
			myInfo(id:MyInfo.id path:Pos surface:true)
		end
	end

	% Start Player (portPlayer from PlayerManager)
	fun{StartPlayer Color ID}
		Stream
		Port
		MyInfo
	in
		% MyInfo will be stored by passing it as argument in TreatStream
		MyInfo = myInfo(id:id(id:ID color:Color name:'PlayerNameTest') path:nil surface:true)
		{NewPort Stream Port}
		thread
			{TreatStream Stream MyInfo nil} % TODO : player name ?
		end
		Port
	end


% ------------------------------------------
% In-game management - Send Information
% ------------------------------------------
	% Moving
	fun {Move ID Pos Direction MyInfo}
		P Possib
	in
		% Calculate useful info
		P = MyInfo.path.1
		Possib = directions(north:{AccessiblePosition {North P}} east:{AccessiblePosition {East P}} south:{AccessiblePosition {South P}} west:{AccessiblePosition {West P}})
		% Assign values to unassigned var
		Direction = {FindPath MyInfo.path.1 MyInfo.path Possib}
		ID = MyInfo.id
		case Direction
		of north   then Pos = {North P}
		[] south   then Pos = {South P}
		[] east    then Pos = {East  P}
		[] west    then Pos = {West  P}
		[] surface then Pos = P
		end 
		% Return modified MyInfo
		if(Pos == P) then
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

% ------------------------------------------
% In-game management - Receive Information
% ------------------------------------------
	fun{Dive MyInfo}	myInfo(id:MyInfo.id path:MyInfo.path 	surface:false)	end
	fun{Surface MyInfo} myInfo(id:MyInfo.id path:MyInfo.path.1 	surface:true)	end
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

		[]chargeItem(?ID ?KindItem)|T then Var in
			%<item> ::= null | mine | missile | sonar | drone
			%<drone> ::= drone(row <x>) | drone(column <y>)
			%<mine> ::= null | <position>
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]fireItem(?ID ?KindFire)|T then Var in
			%<fireitem> ::= null | mine(<position>) | missile(<position>) | <drone> | sonar
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]fireMine(?ID ?Mine)|T then Var in
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]isDead(?Answer)|T then Var in
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]sayMove(ID Direction)|T then Var in
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]saySurface(ID)|T then Var in
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]sayCharge(ID KindItem)|T then Var in
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]sayMinePlaced(ID)|T then Var in
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]sayMissileExplode(ID Position ?Message)|T then Var in
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]sayMineExplode(ID Position ?Message)|T then Var in
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]sayPassingDrone(Drone ?ID ?Answer)|T then Var in
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]sayAnswerDrone(Drone ID Answer)|T then Var in
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]sayPassingSonar(?ID ?Answer)|T then Var in
			{Function Var}
		[]sayAnswerSonar(ID Answer)|T then Var in
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]sayDeath(ID)|T then Var in
			{Function Var}
			{TreatStream T MyInfo PlayersInfo}
		[]sayDamageTaken(ID Damage LifeLeft)|T then Var in
			{Function Var}
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
