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
	IsIsland
	NewPosition NewPositionList
	ValidPositions
	AccessiblePosition
	ManhattanDistance
	Dive Surface
	ListPtAnd ListPtExcl
		%create list of points
		GenerateRow GeneratePartRow
		GenerateColumn GeneratePartColumn
		GenerateCross ValidPositionsAround
	MyInfoChangeVal ItemRecordChangeVal 
	PlayerChangeVal
	PlayersInfoPos
	
	% Game start functions
	StartPlayer
	InitPosition
	GeneratePositions

	% In-game management functions
	Move FindPath ChooseDirection
	ChargeItem 
	FireItem
	FireMine

	% Say functions
	PlayerModification
	SayMove 
	SaySurface
	SayCharge
	SayMinePlaced
	SayExplosionMyInfo
	SayMissileExplodeMissileStatus
	SayPassingDrone
	SayAnswerDrone SonarPossibilities
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
% myInfo(id:__ lives:__ path:__ charge:charge(mine:___ missile:___ sonar:___ drone:___) fire:fire(mine:___ missile:___ sonar:___ drone:___) mine:__)
% 		- id: my ID, id(id:___ color:___ name:___)
% 		- lives: the number of lives left
% 		- path: my path, list of pt(x:___ y:___) where path.1 = position
%			- charge: from 0 to Input.Mine / Input.Sonar / ..., if Input.Mine reach the item is loaded and ready to be fired
%			- fire: for mine, missile, sonar, drone 0 (not charged) or 1 (charged)
%			- mine: list of mine(<pos>)
% 
% player(id:___ lives:___ possibilities:___ surface:___ charge:charge(mine:___ missile:___ sonar:___ drone:___))
% 		- id: to match ID sent by main
% 		- lives: number of lives of the submarine
% 		- possibilities: list of possible points for player's position
% 		- surface: true or false
% 		- charge: 0 if the item is not charged and 1 if it is charged


% ------------------------------------------
% Basic functions
% ------------------------------------------
	% Return pt north/... of Pos
	fun {North Pos} pt(x:Pos.x-1 y:Pos.y  ) end
	fun {South Pos} pt(x:Pos.x+1 y:Pos.y  ) end
	fun {East  Pos} pt(x:Pos.x   y:Pos.y+1) end
	fun {West  Pos} pt(x:Pos.x   y:Pos.y-1) end

	% Check if position is an island
	fun {IsIsland X Y} {List.nth {List.nth Input.map X} Y} == 1 end
	
	% Returns the position North/South/... of Pos 
	fun {NewPosition Pos Direction}
		case Direction 
		of north then {North Pos}
		[] south then {South Pos}
		[] east  then {East  Pos}
		[] west  then {West  Pos}
		[] surface then Pos
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
			if (X =< 0 orelse Y =< 0 orelse X > Input.nRow orelse Y > Input.nColumn orelse {IsIsland X Y})
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
		in {GeneratePositionsRec 1 1} end
	end

	fun {Dive MyInfo} 		{MyInfoChangeVal MyInfo path MyInfo.path.1|nil} end
	fun {Surface MyInfo} 	{MyInfoChangeVal MyInfo path MyInfo.path.1|nil}	end

% ------------------------------------------
% Point cloud generators
% ------------------------------------------
	% Return a list where elements must in List1 and List2
	fun{ListPtAnd List1 List2} 
		if(List1==nil) 		then nil
		elseif(List2==nil)	then nil
		else R1 R2 C1 C2 T1 T2 in
			pt(x:R1 y:C1)|T1=List1    
			pt(x:R2 y:C2)|T2=List2
			if(C1>C2) 		then {ListPtAnd List1 T2}
			elseif(C1<C2)	then {ListPtAnd T1 List2}
			elseif(R1>R2)	then {ListPtAnd List1 T2}
			elseif(R1<R2)	then {ListPtAnd T1 List2}
			else pt(x:R1 y:C1)|{ListPtAnd T1 T2} end
		end
	end

	% Return the list ListRef without the elements ListExcl
	fun{ListPtExcl ListRef ListExcl}
		if(ListRef==nil) 		then nil
		elseif(ListExcl==nil)	then ListRef
		else R1 R2 C1 C2 T1 T2 in
			pt(x:R1 y:C1)|T1=ListRef    
			pt(x:R2 y:C2)|T2=ListExcl
			if(C1>C2) 		then {ListPtAnd ListRef T2}
			elseif(C1<C2)	then pt(x:R1 y:C1)|{ListPtAnd T1 ListExcl}
			elseif(R1>R2)	then {ListPtAnd ListRef T2}
			elseif(R1<R2)	then pt(x:R1 y:C1)|{ListPtAnd T1 ListExcl}
			else {ListPtAnd T1 T2} end % same point, must be excl
		end
	end

	% Generate a list of points with the right rownumber
	fun{GenerateRow RowNumber}	{GeneratePartRow RowNumber 1 Input.nColumn} end

	% Generate a list of points with the right rownumber with bound and With a Start and End
	fun{GeneratePartRow RowNumber StartCol EndCol}
		fun{GenerateRowCol ColumnNumber}
			if (ColumnNumber>EndCol orelse ColumnNumber>Input.nColumn) then nil 
			else pt(x:RowNumber y:ColumnNumber) | {GenerateRowCol ColumnNumber+1} end
		end
	in
		if (StartCol<1) then {GenerateRowCol 1}
		else {GenerateRowCol StartCol} end
	end

	% Generate a list of points with the right rownumber
	fun{GenerateColumn ColumnNumber} {GeneratePartColumn ColumnNumber 1 Input.nRow} end

	fun{GeneratePartColumn ColumnNumber StartRow EndRow}
		fun{GeneratColRow RowNumber}
			if (RowNumber>EndRow orelse RowNumber>Input.nRow) then nil 
			else pt(x:RowNumber y:ColumnNumber) | {GeneratColRow RowNumber+1} end
		end
	in
		if (StartRow<1) then {GeneratColRow 1}
		else {GeneratColRow StartRow} end
	end

	% Generate a list of points in cross from around the StartPoint and have arms from Min to Max
	fun{GenerateCross StartPos Min Max} Left Right Up Down X Y in
		pt(x:X y:Y)=StartPos
		Left 	= {GeneratePartRow X Y-Max Y-Min}
		Right 	= {GeneratePartRow X Y+Min Y+Max}
		Up 		= {GeneratePartColumn Y X-Max X-Min}
		Down 	= {GeneratePartColumn Y X+Min X+Max}
		{Append {Append Left Right} {Append Up Down}}
	end

	% Generate a list of valid positions (no island, no ecxeeding borders) around a Position 
	fun{ValidPositionsAround Position} {ValidPositions {GenerateCross Position 1 1}} end

% ------------------------------------------
% Record modification
% variables can be added here if needed
% ------------------------------------------
	% Return a MyInfo record with one label changed
	fun{MyInfoChangeVal Record Label NewVal} ID Lives Path Charge Fire Mine in
		myInfo(id:ID lives:Lives path:Path charge:Charge fire:Fire mine:Mine) = Record
		case Label 
			of id 			then myInfo(id:NewVal lives:Lives path:Path charge:Charge fire:Fire mine:Mine)
			[] lives 		then myInfo(id:ID lives:NewVal path:Path charge:Charge fire:Fire mine:Mine)
			[] path			then myInfo(id:ID lives:Lives path:NewVal charge:Charge fire:Fire mine:Mine)
			[] charge		then myInfo(id:ID lives:Lives path:Path charge:NewVal fire:Fire mine:Mine)
			[] fire			then myInfo(id:ID lives:Lives path:Path charge:Charge fire:NewVal mine:Mine)
			[] mine			then myInfo(id:ID lives:Lives path:Path charge:Charge fire:Fire mine:NewVal)
		end
	end

	% Return an ItemRecord with one label changed
	fun{ItemRecordChangeVal Rec Label NewVal}
		case Rec 
			of charge(mine:Mine missile:Missile sonar:Sonar drone:Drone) then
				case Label 
					of mine 	then charge(mine:NewVal missile:Missile sonar:Sonar drone:Drone)
					[] missile 	then charge(mine:Mine missile:NewVal sonar:Sonar drone:Drone)
					[] sonar	then charge(mine:Mine missile:Missile sonar:NewVal drone:Drone)
					[] drone	then charge(mine:Mine missile:Missile sonar:Sonar drone:NewVal)
				end
			[] fire(mine:Mine missile:Missile sonar:Sonar drone:Drone) then
				case Label 
					of mine 	then fire(mine:NewVal missile:Missile sonar:Sonar drone:Drone)
					[] missile 	then fire(mine:Mine missile:NewVal sonar:Sonar drone:Drone)
					[] sonar	then fire(mine:Mine missile:Missile sonar:NewVal drone:Drone)
					[] drone	then fire(mine:Mine missile:Missile sonar:Sonar drone:NewVal)
				end
		end
	end

	% Return a player with one label changed
	fun{PlayerChangeVal Record Label NewVal} ID Lives Poss Surface Charge in
		player(id:ID lives:Lives possibilities:Poss surface:Surface charge:Charge) = Record
		case Label 
			of id 				then player(id:NewVal lives:Lives possibilities:Poss surface:Surface charge:Charge)
			[] lives 			then player(id:ID lives:NewVal possibilities:Poss surface:Surface charge:Charge)
			[] possibilities	then player(id:ID lives:Lives possibilities:NewVal surface:Surface charge:Charge)
			[] surface			then player(id:ID lives:Lives possibilities:Poss surface:NewVal charge:Charge)
			[] charge			then player(id:ID lives:Lives possibilities:Poss surface:Surface charge:NewVal)
		end
	end

	% no more used
	%player(id:___ lives:___ possibilities:___ surface:___ charge:charge(mine:___ missile:___ sonar:___ drone:___))
	fun{PlayersInfoPos MyInfo PlayersInfo} 
		fun{CheckMine Mine Pos} %Mine list of mine, Pos=ennemi
			%{System.show checkMine(pos:Pos mine:Mine)}
			if(Mine==nil) then null
			elseif({ManhattanDistance Mine.1 Pos}=<1) then Mine.1
			else {CheckMine Mine.2 Pos} end
		end
	in
		case PlayersInfo
		of nil then null %no more players
		[] Player|Next then 
			%{System.show playerPoss(Player.id Player.possibilities)}
			%{System.show mines(MyInfo.mine)}
			if(Player.id == MyInfo.id.id) 				then {PlayersInfoPos MyInfo Next}
			%todo verify if it is correct and impl multi poss + correct Player.possibilities
			elseif(Player.possibilities == nil) 	then {System.show error} {System.show debug(myinfo:MyInfo playersinfo:PlayersInfo)} {System.show Player.possibilities.1} %cause error for debugging 
			elseif (Player.possibilities.2 \= nil) 	then {PlayersInfoPos MyInfo Next}
			
			else Check in
				Check = {CheckMine MyInfo.mine Player.possibilities.1}
				case Check
				of null			then {PlayersInfoPos MyInfo Next}
				[] pt(x:_ y:_)	then 
					{System.show mineFound(Check)} 
					%{Time.delay 2000} 
					Check
				end
			end
		end
	end

% ------------------------------------------
% Initialisation
% ------------------------------------------
	% Initialise Position (random)
	fun{InitPosition ID Pos MyInfo} X Y in
		X = ({OS.rand} mod Input.nRow) + 1
		Y = ({OS.rand} mod Input.nColumn) + 1
		% if position is not accessible
		if({AccessiblePosition pt(x:X y:Y)} == 0)
			then {InitPosition ID Pos MyInfo}
		else 
			ID = MyInfo.id
			Pos = pt(x:X y:Y)
			% return updated info with position
      {MyInfoChangeVal MyInfo path Pos|nil}
		end
	end

	% Start Player (portPlayer from PlayerManager)
	fun{StartPlayer Color ID}
		Stream Port MyInfo PlayersInfo
		fun{CreateAllPlayer ID} 
			if(ID>Input.nbPlayer) then nil 
			else
				player(id:ID lives:Input.maxDamage possibilities:{ValidPositions {GeneratePositions}} surface:true charge:charge(mine:0 missile:0 sonar:0 drone:0))|{CreateAllPlayer ID+1}
			end
		end
	in
		% MyInfo will be stored by passing it as argument in TreatStream
    % Initialise MyInfo
		MyInfo = myInfo(id:id(id:ID color:Color name:player) lives:Input.maxDamage path:nil charge:charge(mine:0 missile:0 sonar:0 drone:0) fire:fire(mine:0 missile:0 sonar:0 drone:0) mine:nil) 
		PlayersInfo = {CreateAllPlayer 1}
		{NewPort Stream Port}
		thread {TreatStream Stream MyInfo PlayersInfo} end 
		Port % TODO : player name ?
	end

% ------------------------------------------
% In-game management - Send Information
% ------------------------------------------
	% Moving randomly
	fun {Move ID Pos Direction MyInfo}
		P Possib N S E W
	in		
		% Calculate useful info
		P = MyInfo.path.1 %current position
		
		N = {AccessiblePosition {North P}}
		S = {AccessiblePosition {South P}}
		E = {AccessiblePosition {East  P}}
		W = {AccessiblePosition {West  P}}

		Possib = directions(north:N east:E south:S west:W)

		% Assign values to unassigned var
		Direction = {FindPath P MyInfo.path Possib}
		ID = MyInfo.id
		Pos = {NewPosition P Direction}

		% Return modified MyInfo
		if(Direction == surface) then {Surface MyInfo}
		else {MyInfoChangeVal MyInfo path Pos|MyInfo.path}
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

	% Always charge mines
	fun{ChargeItem KindItem MyInfo PlayersInfo} NewMyInfo in
    % Charge nothing if mine is already full
    if MyInfo.charge.mine == Input.mine then
      KindItem = null
      NewMyInfo = MyInfo
    % Charge mine
    else 
      KindItem = mine
      NewMyInfo = {MyInfoChangeVal MyInfo charge {ItemRecordChangeVal MyInfo.charge mine MyInfo.charge.mine+1}}
    end
    NewMyInfo
	end

	% Put mine down if it is charged
	fun{FireItem KindFire MyInfo PlayersInfo} MinePos NewMyInfo in
		if MyInfo.charge.mine == Input.mine then
      MinePos = {ValidPositionsAround MyInfo.path.1}
      if MinePos \= null then NewCharge in
        KindFire = mine(MinePos.1)
        NewCharge = {ItemRecordChangeVal MyInfo.charge mine 0}
        NewMyInfo = {MyInfoChangeVal {MyInfoChangeVal MyInfo charge NewCharge} mine MinePos.1|MyInfo.mine}
      end
    else
      KindFire = null
      NewMyInfo = MyInfo
    end
		NewMyInfo
	end

	fun{FireMine Mine MyInfo PlayersInfo}
    NewMines
    % Returns true if a player is in range of a mine
    fun{PlayerInRangeOfMine Position PlayersInfo}
		case PlayersInfo
		of nil then false
		[] H|T then
			if(H.id ==null) then {PlayerInRangeOfMine Position T}
			else
				case H.possibilities
				of P|nil then 
					if {ManhattanDistance P Position} =< 1 then true
					else {PlayerInRangeOfMine Position T}
					end
				else {PlayerInRangeOfMine Position T}
				end
			end
		end
	end

    % Returns a list without the mine that exploded
    % Explodes the first mine that can damage someone (except if damages me)
    fun{RecursiveMine Mine Mines MyPosition PlayersInfo}
		case Mines
		of nil then 
			Mine = null
			nil
		[] H|T then
			if ({ManhattanDistance MyPosition H} > 1) andthen ({PlayerInRangeOfMine H PlayersInfo}) then
			Mine = H
			T
			else 
			H | {RecursiveMine Mine T MyPosition PlayersInfo}
			end
		end
		end
	in
		NewMines = {RecursiveMine Mine MyInfo.mine MyInfo.path.1 PlayersInfo}
		{MyInfoChangeVal MyInfo mine NewMines}
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
		if WantedID == null then PlayersInfo
		else
			case PlayersInfo
			of nil then nil
			%dead player
			[] null|Next then PlayersInfo.1|{PlayerModification WantedID Next Fun Args}
			[] player(id:null lives:_ possibilities:_ surface:_ charge:_)|Next then
					PlayersInfo.1|{PlayerModification WantedID Next Fun Args} 
			[] player(id:ID lives:_ possibilities:_ surface:_ charge:_)|Next then
				if (ID == WantedID.id) then
					{Fun Args PlayersInfo.1}|Next
				else
					PlayersInfo.1|{PlayerModification WantedID Next Fun Args}
				end
			end
		end
	end

	% Move broadcasted, try to locate all players based only by elemination of possibilities 
	% Args: arguments(direction)
	fun{SayMove Args Player} NewPossibilities in 
		NewPossibilities = {ValidPositions {NewPositionList Player.possibilities Args.direction}}
		% Return
		{PlayerChangeVal {PlayerChangeVal Player surface false} possibilities NewPossibilities}
	end

	% Update Player.surface when player has surfaced
	% Args: arguments() [no arguments]
	fun{SaySurface Args Player} 
		{PlayerChangeVal Player surface true}
	end
	
	% Updates Player's charge number on an item
	% Args: arguments(itemKind)
	fun{SayCharge Args Player} PCharge NewCharge in
		PCharge = Player.charge
		% Edit charge
		NewCharge = {ItemRecordChangeVal PCharge Args.itemKind 1}
		% Return
		{PlayerChangeVal Player charge NewCharge}
	end
	
	% Update mine charge status when mine is placed
	% Args: arguments() [no arguments]
	fun{SayMinePlaced Args Player} NewCharge in
		% Edit charge
		NewCharge = {ItemRecordChangeVal Player.charge mine 0}
		% Return
		{PlayerChangeVal Player charge NewCharge}
	end

	% On missile explosion, edit missile charge status
	% Args: arguments() [no arguments]
	fun{SayMissileExplodeMissileStatus Args Player} NewCharge in
		% Edit charge
		NewCharge = {ItemRecordChangeVal Player.charge missile 0}
		% Return
		{PlayerChangeVal Player charge NewCharge}
	end
	
	% Edit MyInfo on mine explosion
	fun{SayExplosionMyInfo MyInfo Pos Message} DamageTaken NewMyInfo in
		if MyInfo.id == null then
			Message = null
			NewMyInfo = MyInfo
		else
			% Compute damage taken
			case {ManhattanDistance MyInfo.path.1 Pos}
				of 1 then	DamageTaken = 1
				[] 0 then	DamageTaken = 2
				else 		DamageTaken = 0
			end
			% Send message
			if DamageTaken == 0 then 
				Message = null
				NewMyInfo = {MyInfoChangeVal MyInfo lives (MyInfo.lives-DamageTaken)}
			elseif MyInfo.lives =< DamageTaken then 
				Message = sayDeath(MyInfo.id)
				% Change MyInfo.id to null & lives to lives-DamageTaken
				NewMyInfo = {MyInfoChangeVal {MyInfoChangeVal MyInfo lives (MyInfo.lives-DamageTaken)} id null}
			elseif MyInfo.lives ==0 then
				Message = sayDeath(MyInfo.id)
				NewMyInfo = {MyInfoChangeVal {MyInfoChangeVal MyInfo lives 0} id null}
			else 
				Message = sayDamageTaken(MyInfo.id DamageTaken MyInfo.lives-DamageTaken)
				NewMyInfo = {MyInfoChangeVal MyInfo lives (MyInfo.lives-DamageTaken)}
			end
		end
		% Return edited MyInfo
		NewMyInfo
	end
	
	% Passing drone 
	% Args : arguments(drone:Drone id:?ID answer:?Answer myInfo:MyInfo)
	fun{SayPassingDrone Args Player} Drone ID Answer MyInfo NewCharge in
		% Get info
		arguments(drone:Drone id:ID answer:Answer myInfo:MyInfo) = Args
		% Return info
		ID = MyInfo.id
		case Drone
			of drone(row X) 	then Answer=(MyInfo.path.1.x == X)
			[] drone(column Y)	then Answer=(MyInfo.path.1.y == Y)
		end
		% Edit charge
		NewCharge = {ItemRecordChangeVal Player.charge drone 0}
		% Return
		{PlayerChangeVal Player charge NewCharge}
	end
	
	% Update information about the player possible positions
	fun{SayAnswerDrone Args Player}
		NewPossibilities
		Drone Answer
		PPoss
	in
		arguments(drone:Drone id:_ answer:Answer) = Args
		PPoss = Player.possibilities
		% Calculate
		case Drone 
		of drone(row X) then
			if(Answer) then NewPossibilities = {ValidPositions {ListPtAnd PPoss {GenerateRow X}}}
			else NewPossibilities = {ValidPositions {ListPtExcl PPoss {GenerateRow X}}} 
			end
		[]drone(column Y) then
			if(Answer) then NewPossibilities = {ValidPositions {ListPtAnd PPoss {GenerateColumn Y}}}
			else NewPossibilities = {ValidPositions {ListPtExcl PPoss {GenerateColumn Y}}}
			end
		end
		% Return
		{PlayerChangeVal Player possibilities NewPossibilities}
	end
	
	% Answer with position when other player sends sonar
	% Args : arguments(id:?ID answer:?Answer myInfo:MyInfo)
	fun{SayPassingSonar Args Player} ID Answer MyInfo NewCharge in
		% Get info
		arguments(id:ID answer:Answer myInfo:MyInfo) = Args
		% Return info
		ID = MyInfo.id
		% choose X or Y and send back information (random)
		case ({OS.rand} mod 2)
		of 0 then Answer = pt(x:MyInfo.path.1.x y:(({OS.rand} mod Input.nRow)+1))
		[] 1 then Answer = pt(x:(({OS.rand} mod Input.nColumn)+1) y:MyInfo.path.1.y)
		end
		% Edit charge
		NewCharge = {ItemRecordChangeVal Player.charge sonar 0}
		% Return
		{PlayerChangeVal Player charge NewCharge}
	end
	
	% Update player possibilities with at least x or y correct
	fun{SayAnswerSonar Args Player}	X Y NewPossibilities in
		pt(x:X y:Y) = Args.position
		NewPossibilities = {SonarPossibilities X Y Player.possibilities}
		% Return
		{PlayerChangeVal Player possibilities NewPossibilities}
	end

	% Calculate player's position possibilities after sonar
	fun{SonarPossibilities X Y Poss}
		case Poss
		of nil then	nil
		[] H|T then 
			if (H.x == X orelse H.y == Y) then H|{SonarPossibilities X Y T}
			else {SonarPossibilities X Y T}
			end
		end
	end
	
	% Simply removing player from PlayersInfo if he is dead
	fun{SayDeath ID PlayersInfo}
		case PlayersInfo
		of nil then nil
		[] player(id:PlayerID lives:_ possibilities:_ surface:_ charge:_)|Next then
			if(ID.id == PlayerID) then
				{PlayerChangeVal {PlayerChangeVal PlayersInfo.1 id null} lives 0}|Next
			else PlayersInfo.1|{SayDeath ID Next}
			end
		end
	end
	
	% Update lives of a player who has taken a damage
	fun{SayDamageTaken Args Player} Damage LifeLeft PLives in
		PLives = Player.lives
		arguments(damage:Damage lifeLeft:LifeLeft) = Args
		if (PLives-Damage \= LifeLeft) then {System.show error(damage:Damage lifeLeft:LifeLeft playerLives:PLives)} end
		% Return
		{PlayerChangeVal Player lives LifeLeft}
	end

% ------------------------------------------
% TreatStream
% ------------------------------------------
	proc{TreatStream Stream MyInfo PlayersInfo}
		case Stream
		of nil then skip

		[]initPosition(?ID ?Pos)|T then NewMyInfo in
			NewMyInfo = {InitPosition ID Pos MyInfo}
			{TreatStream T NewMyInfo PlayersInfo}
		
		[]move(?ID ?Pos ?Direction)|T then NewMyInfo in
			NewMyInfo = {Move ID Pos Direction MyInfo}
			{TreatStream T NewMyInfo PlayersInfo}

		[]dive|T then
			{TreatStream T {Dive MyInfo} PlayersInfo}

		[]chargeItem(?ID ?KindItem)|T then NewMyInfo in
			ID=MyInfo.id
			NewMyInfo = {ChargeItem KindItem MyInfo PlayersInfo}
			{TreatStream T NewMyInfo PlayersInfo}

		[]fireItem(?ID ?KindFire)|T then NewMyInfo in
			ID = MyInfo.id
			NewMyInfo = {FireItem KindFire MyInfo PlayersInfo}
			{TreatStream T NewMyInfo PlayersInfo}

		[]fireMine(?ID ?Mine)|T then NewMyInfo in
			ID = MyInfo.id
			NewMyInfo = {FireMine Mine MyInfo PlayersInfo}
			{TreatStream T NewMyInfo PlayersInfo}

		[]isDead(?Answer)|T then
			Answer = (MyInfo.id == null)
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
			{TreatStream T {SayExplosionMyInfo MyInfo Position ?Message} {PlayerModification ID PlayersInfo SayMissileExplodeMissileStatus arguments()}}
		
		[]sayMineExplode(ID Position ?Message)|T then 
			{TreatStream T {SayExplosionMyInfo MyInfo Position Message} PlayersInfo}
		
		[]sayPassingDrone(Drone ?ID ?Answer)|T then
			ID = MyInfo.id
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayPassingDrone arguments(drone:Drone id:ID answer:Answer myInfo:MyInfo)}}
		
		[]sayAnswerDrone(Drone ID Answer)|T then 
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayAnswerDrone arguments(drone:Drone id:ID answer:Answer)}}
		
		[]sayPassingSonar(?ID ?Answer)|T then
			ID = MyInfo.id
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayPassingSonar arguments(id:ID answer:Answer myInfo:MyInfo)}}
		
		[]sayAnswerSonar(ID Answer)|T then
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayAnswerSonar arguments(position:Answer)}}
		
		[]sayDeath(ID)|T then
			% Dead player removed from player list
			{TreatStream T MyInfo {SayDeath ID PlayersInfo}}
		
		[]sayDamageTaken(ID Damage LifeLeft)|T then
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayDamageTaken arguments(damage:Damage lifeLeft:LifeLeft)}}
		
		[] _|T then
			{TreatStream T MyInfo PlayersInfo}
		end
	end
end