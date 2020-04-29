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
	ManhattanDistance ManhattanCross
	Dive Surface
	ListPtAnd ListPtExcl
		%create list of points
		GenerateRow GeneratePartRow
		GenerateColumn GeneratePartColumn
		GenerateCross GenerateSimpleCross
		ValidPositionsAround
		GenerateDiagTopBottom
		GenerateDiagBottomTop
		GenerateDiamond ManhattanCross
	MyInfoChangeVal ItemRecordChangeVal 
	PlayerChangeVal PlayerNbChangeVal
	PlayersInfoPos
	PrettyPrintMap
	
	% Game start functions
	StartPlayer
	InitPosition
	GeneratePositions

	% In-game management functions
	Move
		FindPath
		ChooseDirection
	ChargeItem 
		ListPoss
		FewestPossPlayer
	FireItem 
		FindTargetNotOrd
		FindTarget
		FindClosestTarget
		FireItemSearch
		FireItemCheck
	FireMine

	% Detection
	InfoLine
	InfoRow InfoCol
	GetPos
	MaxLineExcl MaxLineIncl
	MinimizeInfoSonar
	MaximizeInfoDrone

	% Say functions
	PlayerModification
	SayMove 
	SaySurface
	SayCharge
	SayMinePlaced
	SayMissileExplodeMyInfo SayMissileExplodeMissileStatus
	SayMineExplodeMyInfo
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
%		- charge: from 0 to Input.Mine / Input.Sonar / ..., if Input.Mine reach the item is loaded and ready to be fired
%		- fire: for mine, missile, sonar, drone 0 (not charged) or 1 (charged)
%		- mine: list of mine(<pos>)
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
	fun{ListPtAnd List1 List2} %answer:true, 
		if(List1==nil) 		then nil
		elseif(List2==nil)	then nil
		elseif({List.member List1.1 List2}) then List1.1|{ListPtAnd List1.2 List2}
		else {ListPtAnd List1.2 List2}
		end
	end

	% Return the list ListRef without the elements ListExcl
	fun{ListPtExcl ListRef ListExcl} %answer:false
		if(ListRef==nil) 		then nil
		elseif(ListExcl==nil)	then ListRef
		elseif({List.member ListRef.1 ListExcl}) then {ListPtExcl ListRef.2 ListExcl}
		else ListRef.1|{ListPtExcl ListRef.2 ListExcl}
		end
	end

	% Generate a list of points with the right rownumber
	fun{GenerateRow RowNumber}	{GeneratePartRow RowNumber 1 Input.nColumn} end

	% Generate a list of points with the right rownumber with bound and With a Start and End
	fun{GeneratePartRow RowNumber StartCol EndCol}
		fun{GenerateRowCol ColumnNumber}
			if (ColumnNumber>EndCol orelse ColumnNumber>Input.nColumn) then nil %todo check == or =>
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

	% Generate a list of positions (no island, no ecxeeding borders) around a Position
	fun{GenerateSimpleCross Position} {GenerateCross Position 1 1} end

	% Generate a list of valid positions (no island, no ecxeeding borders) around a Position 
	fun{ValidPositionsAround Position} {ValidPositions {GenerateCross Position 1 1}} end

	% /!\ StartPt upperLeft (smallest X and y), EndPt bottomRight
	fun{GenerateDiagTopBottom StartPt EndPt} X1 Y1 X2 Y2 in
		pt(x:X1 y:Y1) = StartPt
		pt(x:X2 y:Y2) = EndPt
		if(X1>X2 orelse Y1>Y2) then {System.show errorGenerateDiagTB} nil
		elseif (X1==X2 andthen Y1==Y2) then StartPt|nil
		else StartPt | {GenerateDiagTopBottom pt(x:X1+1 y:Y1+1) EndPt}
		end
	end

	% /!\ StartPt bottomLeft (smallest Y, biggest X), EndPt TopRight
	fun{GenerateDiagBottomTop StartPt EndPt} X1 Y1 X2 Y2 in
		pt(x:X1 y:Y1) = StartPt
		pt(x:X2 y:Y2) = EndPt
		if(X1<X2 orelse Y1>Y2) then {System.show errorGenerateDiagBT} nil
		elseif (X1==X2 andthen Y1==Y2) then StartPt|nil
		else StartPt | {GenerateDiagBottomTop pt(x:X1-1 y:Y1+1) EndPt}
		end
	end

	% generate diamond with Size >= 0
	% size represent the manhattan distance with reference to Pos
	fun{GenerateDiamond StartPt Size} 
		X Y 
		Left Right Up Down
		DiagLU DiagLD DiagUR DiagDR
	in
		if(Size==0) then StartPt|nil
		else
			pt(x:X y:Y) = StartPt
			Left 	= pt(x:X y:Y-Size)		Right 	= pt(x:X y:Y+Size)
			Up 		= pt(x:X-Size y:Y)		Down 	= pt(x:X+Size y:Y)
			% /!\ do not count the corner twice, the upper keep start delete end and for down inverse
			DiagLU	= {List.take {GenerateDiagBottomTop Left Up} Size}
			DiagLD	= {List.drop {GenerateDiagTopBottom Left Down} 1}
			DiagUR	= {List.take {GenerateDiagTopBottom Up Right} Size}
			DiagDR	= {List.drop {GenerateDiagBottomTop Down Right} 1}
			%return
			{Append {Append DiagLU DiagLD} {Append DiagUR DiagDR}}
		end
	end

	% Generate position list between bounds of Min to Max
	fun{ManhattanCross MyPos Min Max}
		if(Max < Min )then {System.show errorManhattanCross} nil
		elseif(Max > Min) then
			{Append {GenerateDiamond MyPos Max} {ManhattanCross MyPos Min Max-1}}
		else
			{GenerateDiamond MyPos Max}
		end
	end

% ------------------------------------------
% Record modification
% ------------------------------------------
	% Return a MyInfo record with one label changed
	fun{MyInfoChangeVal Record Label NewVal} ID Lives Path Charge Fire Mine in %add if needed
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
	
	% not used
	% Change a specific label in a spefic player
	fun{PlayerNbChangeVal List Number Label NewVal}
		if(List==nil)		then {System.show error(thePlayerdoesNotExist)}
		elseif(Number==1) 	then {PlayerChangeVal List.1 Label NewVal}|List.2
		else List.1|{PlayerNbChangeVal List.2 Number-1 Label NewVal}
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
					%{System.show mineFound(Check)} 
					%{Time.delay 2000} 
					Check
				end
			end
		end
	end


	%PointList = pt(x: y:_)|pt|...|nil
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
			if(Map.2\=nil) then {PrintMap Map.2} end
		end
	in {Time.delay 100} {System.show '----'} {PrintMap {TempMap Input.map PointList p}} {System.show '----'}	end

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
		fun{CreateAllPlayer ID} %only used in StartPlayer to init a tracker of all players
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
	fun {Move Pos Direction MyInfo PlayersInfo}
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

		Direction = {FindPath P MyInfo.path Possib MyInfo PlayersInfo}
		Pos = {NewPosition P Direction}

		% Return modified MyInfo
		if(Direction == surface) then {Surface MyInfo}
		else {MyInfoChangeVal MyInfo path Pos|MyInfo.path}
		end
	end

	% Find a valid path
	fun {FindPath Pos Path Possib MyInfo PlayersInfo}
		N S E W 
	in
		directions(north:N east:E south:S west:W) = Possib

		if N#S#E#W == 0#0#0#0
			then surface
		else
			if Path == nil then {ChooseDirection Possib MyInfo PlayersInfo false}
			elseif Path.1 == {North Pos} then {FindPath Pos Path.2 directions(north:0	east:E south:S west:W) MyInfo PlayersInfo}
			elseif Path.1 == {East  Pos} then {FindPath Pos Path.2 directions(north:N	east:0 south:S west:W) MyInfo PlayersInfo}
			elseif Path.1 == {South Pos} then {FindPath Pos Path.2 directions(north:N	east:E south:0 west:W) MyInfo PlayersInfo}
			elseif Path.1 == {West  Pos} then {FindPath Pos Path.2 directions(north:N	east:E south:S west:0) MyInfo PlayersInfo}
			else {FindPath Pos Path.2 Possib MyInfo PlayersInfo}
			end
		end
	end

	% Choose a random direction
	fun {ChooseDirection Possib MyInfo PlayersInfo TryOnce} ClosestEnnemiList X Y Xe Ye Choices in
		ClosestEnnemiList = {FindClosestTarget MyInfo PlayersInfo}
		if(ClosestEnnemiList == nil orelse TryOnce==true) then Choices = [north east south west]%random
		else % go direction of the nearest ennemi
			%{System.show chooseDirection1(ClosestEnnemiList)}
			pt(x:X y:Y) 	= MyInfo.path.1
			pt(x:Xe y:Ye)	= ClosestEnnemiList.1.possibilities.1
			%{System.show chooseDirection2}
			%{System.show chooseDirection(mypos:pt(x:X y:Y) enpos:pt(x:Xe y:Ye) allen(ClosestEnnemiList))}
			if(X==Xe andthen Y==Ye)		then Choices = [north east south west]
			elseif(X<Xe andthen Y<Ye) 	then Choices = [east south]
			elseif(X>Xe andthen Y<Ye)	then Choices = [north east]
			elseif(X<Xe andthen Y>Ye)	then Choices = [south west]
			elseif(X>Xe andthen Y>Ye)	then Choices = [north west]
			elseif(X==Xe andthen Y<Ye)	then Choices = [west]
			elseif(X==Xe andthen Y>Ye)	then Choices = [east]
			elseif(X<Xe andthen Y==Ye)	then Choices = [south]
			elseif(X>Xe andthen Y==Ye)	then Choices = [north]
			end
			{System.show chooseDirection(mypos:pt(x:X y:Y) enpos:pt(x:Xe y:Ye) choices:Choices allen:en(ClosestEnnemiList))}
		end

		%if(TryOnce==true) then
			%{System.show chooseDirection(list:ClosestEnnemiList mypos:pt(x:X y:Y) enpos:pt(x:Xe y:Ye) choices:Choices)}
		%else skip end

		case ({OS.rand} mod {List.length Choices})
		of 0 then if Possib.{List.nth Choices 1} == 1 then {List.nth Choices 1} else {ChooseDirection Possib MyInfo PlayersInfo true} end
		[] 1 then if Possib.{List.nth Choices 2} == 1 then {List.nth Choices 2} else {ChooseDirection Possib MyInfo PlayersInfo true} end
		[] 2 then if Possib.{List.nth Choices 3} == 1 then {List.nth Choices 3} else {ChooseDirection Possib MyInfo PlayersInfo true} end
		[] 3 then if Possib.{List.nth Choices 4} == 1 then {List.nth Choices 4} else {ChooseDirection Possib MyInfo PlayersInfo true} end
		end
	end

	%strategie charge missile then mine then locate with drone/sonar 
	% when ennemi found place mine and shoot with missile 
	fun{ChargeItem KindItem MyInfo PlayersInfo}
		Produced NewMyInfo FewestPoss MaxNbPossSonar MaxNbPossDrone MinNbPossDrone
		%return true if it has charge/produce the item, false if not
		fun{ChargeItemSpec Wanted ?Produced ?NewMyInfo}
			if(MyInfo.fire.Wanted == 0) then % not ready to fire
				if(MyInfo.charge.Wanted+1 == Input.Wanted) then NewCharge NewFire in % item produced
					Produced 	= Wanted
					NewCharge 	= {ItemRecordChangeVal MyInfo.charge Wanted 0}
					NewFire 	= {ItemRecordChangeVal MyInfo.fire Wanted 1}
					NewMyInfo 	= {MyInfoChangeVal {MyInfoChangeVal MyInfo charge NewCharge} fire NewFire}
				else NewCharge in % item charge
					Produced 	= null 
					NewCharge 	= {ItemRecordChangeVal MyInfo.charge Wanted MyInfo.charge.Wanted+1}
					NewMyInfo 	= {MyInfoChangeVal MyInfo charge NewCharge}
				end
				true
			else % already ready to fire, cannot have two of the same item ready to be fire
				false 
			end
		end
	in
		%only one sonar used in the beginning
		MaxNbPossSonar = Input.nRow + Input.nColumn
		%aftertward detection with drones
		if(Input.nRow > 2*Input.drone orelse Input.nColumn > 2*Input.drone)
			then MaxNbPossDrone = 2*Input.drone
		else MaxNbPossDrone = {Value.Min Input.nRow Input.nColumn} end
		MinNbPossDrone = 2

		FewestPoss = {Sort {ListPoss MyInfo PlayersInfo} Value.'<'}.1
		
		%try to charge/produce an item
		if(FewestPoss >= MaxNbPossSonar) then Test in 
			Test = {ChargeItemSpec sonar ?Produced ?NewMyInfo}
		elseif(FewestPoss>=MaxNbPossDrone orelse (MyInfo.charge.drone>=1 andthen FewestPoss<MinNbPossDrone)) then
			Test in Test = {ChargeItemSpec drone ?Produced ?NewMyInfo}
		elseif({ChargeItemSpec missile ?Produced ?NewMyInfo}) 	then skip
		elseif({ChargeItemSpec mine ?Produced ?NewMyInfo})		then skip
		elseif({ChargeItemSpec sonar ?Produced ?NewMyInfo})		then skip
		elseif({ChargeItemSpec drone ?Produced ?NewMyInfo})		then skip
		end
		%bind
		KindItem = Produced
		%{System.show chargeItem(Produced NewMyInfo.charge NewMyInfo.fire)}
		%return
		NewMyInfo
	end

	%return a list of the ennemies number possibilities
	fun{ListPoss MyInfo Players}
		if(Players == nil) then nil
		elseif(Players.1.id == MyInfo.id.id) then {ListPoss MyInfo Players.2}
		else {List.length Players.1.possibilities}|{ListPoss MyInfo Players.2}
		end
	end

	% return the player with the fewest poss(ecxept himself)
	fun{FewestPossPlayer MyInfo Players}
		fun{FewestPossPlayerIn MyInfo Players Candidate}
			if(Players == nil) then Candidate
			elseif(MyInfo.id.id == Players.1.id) then {FewestPossPlayerIn MyInfo Players.2 Candidate}
			elseif({List.length Players.1.possibilities} < {List.length Candidate.possibilities}) then {FewestPossPlayerIn MyInfo Players.2 Players.1}
			else{FewestPossPlayerIn MyInfo Players.2 Candidate}
			end
		end
	in 	
		if(MyInfo.id.id == Players.1.id) then 
			{FewestPossPlayerIn MyInfo Players Players.2.1}
		else
			{FewestPossPlayerIn MyInfo Players Players.1}
		end
	end

	%first try shoot a missile if is right
	%second place a mine and shoot if ennemi damage int this round or if ennemi if has been detected
	%third to detect ennemi
	fun{FireItem KindFire MyInfo PlayersInfo} Fire TargetOrder FewestPoss NewMyInfo in
		Fire = MyInfo.fire %fire(mine:__ missile:__ sonar:__ drone:__)

		%list of record where to shoot order with as first fewest lives
		TargetOrder = {FindTarget MyInfo PlayersInfo}
		if(Fire.sonar==1 andthen {List.length TargetOrder}\={List.length PlayersInfo}) then 
			NewFire in
			KindFire = sonar
			NewFire		= {ItemRecordChangeVal MyInfo.fire sonar 0}
			NewMyInfo	= {MyInfoChangeVal MyInfo fire NewFire}
		
		elseif(Fire.drone==1 andthen {List.length TargetOrder}\={List.length PlayersInfo}) then 
			FewestPoss NewFire
		in
			FewestPoss = {FewestPossPlayer MyInfo PlayersInfo}
			KindFire = {MaximizeInfoDrone FewestPoss.possibilities}
			NewFire		= {ItemRecordChangeVal MyInfo.fire drone 0}
			NewMyInfo	= {MyInfoChangeVal MyInfo fire NewFire}
		
		elseif(Fire.missile==1 andthen TargetOrder\=nil) then MissilePt in
			MissilePt = {FireItemSearch MyInfo TargetOrder missile}
			if (MissilePt==null) then KindFire=null NewMyInfo=MyInfo 
			else NewFire in
				KindFire	= missile(MissilePt)
				NewFire		= {ItemRecordChangeVal MyInfo.fire missile 0}
				NewMyInfo	= {MyInfoChangeVal MyInfo fire NewFire}
			end

		elseif(Fire.mine == 1 andthen TargetOrder\=nil) then MinePt in
			%best option direct hit
			MinePt = {FireItemSearch MyInfo TargetOrder mine}
			if(MinePt==null) then KindFire=null NewMyInfo=MyInfo
			else NewFire in
				KindFire	= mine(MinePt)
				NewFire		= {ItemRecordChangeVal MyInfo.fire mine 0}
				NewMyInfo	= {MyInfoChangeVal {MyInfoChangeVal MyInfo fire NewFire} mine MinePt|MyInfo.mine}
			end

		%todo if not on a player, try to maximise the number of potential hits
		elseif(Fire.mine == 1) then MinePt in
			MinePt = {ValidPositionsAround MyInfo.path.1}
			if(MinePt==null) then KindFire=null NewMyInfo=MyInfo
			else NewFire in
				KindFire	= mine(MinePt.1)
				NewFire		= {ItemRecordChangeVal MyInfo.fire mine 0}
				NewMyInfo	= {MyInfoChangeVal {MyInfoChangeVal MyInfo fire NewFire} mine MinePt.1|MyInfo.mine}
			end

		else 
			%{System.show doNothing}
			KindFire = null
			NewMyInfo = MyInfo
		end
		NewMyInfo
	end


	fun{FindTargetNotOrd Players MyInfo}
		%finish recursif call
		if(Players == nil) then nil
		%check if not dead
		elseif(Players.1==null orelse MyInfo.id ==null orelse (Players.1.lives==0 orelse Players.1.id==null)) then {FindTargetNotOrd Players.2 MyInfo}
		%check if its not us
		elseif(MyInfo.id.id == Players.1.id) then {FindTargetNotOrd Players.2 MyInfo}
		%target possible possitions error 
		elseif(Players.1.possibilities == nil) then {System.show errorPossibilities(myInfo:MyInfo ennemi:Players.1)} {FindTargetNotOrd Players.2 MyInfo}
		%target found
		elseif(Players.1.possibilities.2 == nil) then Players.1 | {FindTargetNotOrd Players.2 MyInfo}
		%target not found
		else {FindTargetNotOrd Players.2 MyInfo} end
	end

	%todo guess better the ennemies postions, here only if 100% sure
	%return a list of players (only if 100% sure for now) ordered with first fewest lives
	fun{FindTarget MyInfo PlayersInfo} %todo check if dead
		%sort the player first fewest lives still alive
		fun{Sort RecordList}
			fun{Sort2 RecordList2 Lives}
				if(Lives>Input.maxDamage) then nil
				elseif(RecordList2==nil) then {Sort2 RecordList Lives+1}
				elseif(RecordList2.1.lives == Lives) then RecordList2.1|{Sort2 RecordList2.2 Lives}
				else {Sort2 RecordList2.2 Lives} end
			end
		in {Sort2 RecordList 1} end
		
	in	{Sort {FindTargetNotOrd PlayersInfo MyInfo}} end

	fun{FindClosestTarget MyInfo PlayersInfo}
		fun{Sort RecordList MaxManhattan}
			fun{Sort2 RecordList2 Dist}
				if(Dist>MaxManhattan) then nil
				elseif(RecordList2==nil) then {Sort2 RecordList Dist+1}
				elseif({ManhattanDistance MyInfo.path.1 RecordList2.1.possibilities.1} == Dist) then RecordList2.1|{Sort2 RecordList2.2 Dist}
				else {Sort2 RecordList2.2 Dist} end
			end
		in {Sort2 RecordList 0} end
		X Y MaxManhattan
	in	
		pt(x:X y:Y) = MyInfo.path.1
		MaxManhattan = Input.nRow + Input.nColumn - (X + Y - 2)
		{System.show {FindTargetNotOrd PlayersInfo MyInfo}}
		{Sort {FindTargetNotOrd PlayersInfo MyInfo} MaxManhattan}
	end
	
	%return a position (to fire with a missile) or null
	%todo better targeting
	%todo better 1 point hit and sink than 2 point hit and not sink
	% return 2 point hit, if not found a 1 point hit, if not found null
	% problem if two ennemies have the same amount of live then it could shout a one point hit even it there is a 2 point hit
	% help: should test all possible ennemie with the same amount of live if multiple option choose the one with 2 points
	fun{FireItemSearch MyInfo TargetOrder Type} 
		%no shot found
		if(TargetOrder == nil) then null
		else EnnemiPos MyPos MissilePos in
			MyPos = MyInfo.path.1 
			EnnemiPos = TargetOrder.1.possibilities.1
			%try to find a target to hit the ennemi
			MissilePos = {FireItemCheck MyPos EnnemiPos Type} 
			if(MissilePos == null) then %try find an other ennemi
				{FireItemSearch MyInfo TargetOrder.2 Type}
			else %target found
				%{System.show fire(type:Type myPos:MyPos hit:MissilePos ennemi:EnnemiPos)}
				MissilePos
			end
		end
	end

	%to remove own hits
	%return a position to hit or null
	fun{FireItemCheck MyPos KillPos Type} 
		Min Max
		OwnDamage TwoPoint OnePoint
	in
		case Type
			of missile then Min=Input.minDistanceMissile Max=Input.maxDistanceMissile
			[] mine then Min=Input.minDistanceMine Max=Input.maxDistanceMine
		end
		OwnDamage = {GenerateSimpleCross MyPos}
		TwoPoint = {ManhattanCross MyPos Min Max}
		OnePoint = {GenerateDiamond MyPos Max+1}
		if({List.member KillPos TwoPoint}) then %two point hit
			KillPos 
		%only two pointshit with the missile
		elseif(Type\=missile andthen {List.member KillPos OnePoint}) then %one point hit
			%two possible shots
			TargetPts in
			%we can shoot on islands, it will never shoot out the bounderies of the game
			TargetPts = {GenerateSimpleCross KillPos}
			%todo better choice
			%try to find shooting point, never goes to check the fourth point
			if({List.member TargetPts.1 TwoPoint}) then TargetPts.1
			elseif({List.member TargetPts.2 TwoPoint}) then TargetPts.2.1
			else TargetPts.2.2.1
			end
		else
			null
		end
	end

	fun{FireMine Mine MyInfo PlayersInfo} 
		%return a MineList without the Mine
		fun{MineExcl MineList Mine} 
			if(MineList == nil) 		then nil
			elseif(MineList.1 == Mine)	then MineList.2
			else {MineExcl MineList.2 Mine} end
		end

		%todo better to find two points hit
		%return <pos> or null
		fun{FindMine MineList TargetOrder}
			% no mine found
			if(TargetOrder == nil) then null
			% try to find mine with an other ennemi
			elseif(MineList == nil) then {FindMine MyInfo.mine TargetOrder.2}
			else MyPos EnnemiPos CurrentMine Explosion in
				MyPos = MyInfo.path.1
				EnnemiPos = TargetOrder.1.possibilities.1 %assume only one poss
				CurrentMine = MineList.1 %CurrentMine = <pos>
				Explosion = CurrentMine|{ValidPositionsAround CurrentMine}
				%do not fire even if the ennemi loses more lives than we do
				if({List.member MyPos Explosion}) then {FindMine MineList.2 TargetOrder}
				elseif({List.member EnnemiPos Explosion}) then CurrentMine
				else {FindMine MineList.2 TargetOrder}
				end
			end
		end

		TargetOrder NewMyInfo 
	in 
		%{System.show startMine}
		TargetOrder = {FindTarget MyInfo PlayersInfo}
		Mine = {FindMine MyInfo.mine TargetOrder}
		%{System.show Mine}%{System.show MyInfo.mine}{Time.delay 1000}
		if(Mine\=null)then
			NewMyInfo = {MyInfoChangeVal MyInfo mine {MineExcl MyInfo.mine Mine}}
		else NewMyInfo=MyInfo
		end
		NewMyInfo
	end

% ------------------------------------------  
% Detection
% ------------------------------------------
	fun{InfoLine Type Number Poss} Line Tmp in
		case Type 
			of row 		then Line = {GenerateRow Number}
			[] column 	then Line = {GenerateColumn Number}
		end
		Tmp = {ListPtAnd Poss Line}
		%{System.show infoLine(Type Number Poss {List.length Tmp})}
		{List.length Tmp}
	end

	fun{InfoRow Poss}
		fun{InfoRowIn Number}
			if(Number>Input.nRow) then nil
			else {InfoLine row Number Poss}|{InfoRowIn Number+1} end
		end
	in {InfoRowIn 1} end

	fun{InfoCol Poss}
		fun{InfoColIn Number}
			if(Number>Input.nColumn) then nil
			else {InfoLine column Number Poss}|{InfoColIn Number+1} end
		end
	in {InfoColIn 1} end

	fun{GetPos List Value}
		fun{GetPosIn List Value Nb}
			if(List.1 == Value) then Nb
			else{GetPosIn List.2 Value Nb+1} end
		end
	in {GetPosIn List Value 1} end

	% return the Line number that is the biggest (without LineNb as candidate)
	fun{MaxLineExcl ListLine LineNb} ListNoLineNb Biggest LineCandidate in
		ListNoLineNb = {List.subtract ListLine {List.nth ListLine LineNb}}
		Biggest = {Sort ListNoLineNb Value.'>'}.1
		LineCandidate = {GetPos ListNoLineNb Biggest}
		if(LineCandidate < LineNb) then LineCandidate
		else LineCandidate+1 end
	end

		% return the Line number that is the biggest
	fun{MaxLineIncl ListLine} Biggest in
		Biggest = {Sort ListLine Value.'>'}.1
	end

	fun{MinimizeInfoSonar Pt Poss} X Y Rows Cols MaxRow MaxCol RowTrue ColTrue in
		pt(x:X y:Y) = Pt
		Rows 	= {InfoRow Poss}
		Cols 	= {InfoCol Poss}
		%{System.show inMini(rows:Rows Cols)}
		MaxRow	= {MaxLineExcl Rows X}
		MaxCol	= {MaxLineExcl Cols Y}
		%{System.show inMini(maxRows:MaxRow MaxCol)}
		RowTrue	= {List.nth Rows X} + {List.nth Cols MaxCol}
		ColTrue	= {List.nth Cols Y} + {List.nth Rows MaxRow} 
		{System.show possAfter(row:RowTrue col:ColTrue )}
		if(RowTrue > ColTrue) then
			pt(x:X y:MaxCol)
		else 
			pt(x:MaxRow y:Y)
		end
	end	

	fun{MaximizeInfoDrone Poss} Rows Cols MaxRow MaxCol  RowTrue ColTrue in
		% zeros, ones with maybe one value >1
		Rows 	= {InfoRow Poss}
		Cols 	= {InfoCol Poss}
		% line number with the biggest value
		MaxRow	= {MaxLineIncl Rows}
		MaxCol	= {MaxLineIncl Cols}
		% check wheter one or two lines
		if({List.nth Cols MaxCol} > 1 andthen {List.nth Rows MaxRow} > 1) then
			%here two lines
			drone(row {List.nth Rows MaxRow})
		elseif({List.nth Cols MaxCol} > 1) then 
			%here one column
			drone(column {List.nth Cols MaxCol})
		else 
			%here one row
			drone(row {List.nth Rows MaxRow})
		end
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
			%dead player
			[] player(null)|Next then
					PlayersInfo.1|{PlayerModification WantedID Next Fun Args} 
			[] player(id:null lives:_ possibilities:_ surface:_ charge:_)|Next then
					PlayersInfo.1|{PlayerModification WantedID Next Fun Args} 
			[] player(id:ID lives:_ possibilities:_ surface:_ charge:_)|Next then
				if (ID == WantedID.id) then %todo change in StartPlayer
					{Fun Args PlayersInfo.1}|Next
				else
					PlayersInfo.1|{PlayerModification WantedID Next Fun Args}
				end
			end
		end
	end

	% Move broadcasted, try to locate all players based only by elemination of possibilities 
	% Args: arguments(direction:___)
	fun{SayMove Args Player} NewPossibilities in 
		NewPossibilities = {ValidPositions {NewPositionList Player.possibilities Args.direction}}
		%{PrettyPrintMap NewPossibilities}
		% Return
		{PlayerChangeVal Player possibilities NewPossibilities} %todo do we set surface to false?
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

	% On missile explosion, edit my info and send message back
	fun{SayMissileExplodeMyInfo MyInfo Pos ?Message} DamageTaken NewMyInfo in
		% Compute damage taken
		case {ManhattanDistance MyInfo.path.1 Pos}
			of 1 then	DamageTaken = 1
			[] 0 then	DamageTaken = 2
			else 		DamageTaken = 0
		end
		% Send message
		if DamageTaken == 0 then 
			Message = null
			NewMyInfo = MyInfo
		elseif MyInfo.lives =< DamageTaken then 
			Message = sayDeath(MyInfo.id)
			% Change MyInfo.id to null & lives to lives-DamageTaken
			NewMyInfo = {MyInfoChangeVal {MyInfoChangeVal MyInfo lives (MyInfo.lives-DamageTaken)} id null}
		else 
			Message = sayDamageTaken(MyInfo.id DamageTaken MyInfo.lives-DamageTaken)
			NewMyInfo = {MyInfoChangeVal MyInfo lives (MyInfo.lives-DamageTaken)}
		end
		% Change MyInfo.lives to lives-DamageTaken
		NewMyInfo
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
	%todo either combine SayMineExplodeMyInfo and SayMissileExplodeMyInfo or find something to distinguish
	fun{SayMineExplodeMyInfo MyInfo Pos Message} DamageTaken NewMyInfo in
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
		else 
			Message = sayDamageTaken(MyInfo.id DamageTaken MyInfo.lives-DamageTaken)
			NewMyInfo = {MyInfoChangeVal MyInfo lives (MyInfo.lives-DamageTaken)}
		end
		% Return edited MyInfo
		NewMyInfo
	end
	
	% Passing drone 
	%todo add the info to our player in PlayersInfo
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

		%{System.show sayPassingDrone(mypos:MyInfo.path.1 ask:Drone ans:Answer)}
		% Edit charge
		NewCharge = {ItemRecordChangeVal Player.charge drone 0}
		% Return
		{PlayerChangeVal Player charge NewCharge}
	end
	
	% Update information about the player possible positions
	fun{SayAnswerDrone Args Player} %todo error in understanding DID (not used)
		NewPossibilities
		Drone DID Answer
		PPoss
	in
		arguments(drone:Drone id:DID answer:Answer) = Args
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
		%{System.show sayAnswerDrone(ans:Answer old:PPoss new:NewPossibilities)}
		% Return
		{PlayerChangeVal Player possibilities NewPossibilities}
	end
	
	% Answer with position when other player sends sonar
	% Answer should be pt(x:<x> y:<y>) where (at least) 1 of the 2 is correct
	% Args : arguments(id:?ID answer:?Answer myInfo:MyInfo)
	fun {SayPassingSonar Args Player} 
		ID Answer MyInfo NewCharge 
	in
		%{System.show sayPassingSonar(Args Player)}
		% Get info
		arguments(id:ID answer:Answer myInfo:MyInfo) = Args
		% Return info
		ID = MyInfo.id
		Answer = {MinimizeInfoSonar MyInfo.path.1 Player.possibilities}
		%todo minimize info given by given position with the fewest information
		%todo update player info with the infomaration that we have given 

		% choose randomly X or Y and send back information
		% case ({OS.rand} mod 2)
		% of 0 then Answer = pt(x:MyInfo.path.1.x y:(({OS.rand} mod Input.nRow)+1))
		% [] 1 then Answer = pt(x:(({OS.rand} mod Input.nColumn)+1) y:MyInfo.path.1.y)
		% end

		%{System.show sayPassingSonar}
		{System.show mini(id:ID poss:{List.length Player.possibilities} result:{MinimizeInfoSonar MyInfo.path.1 Player.possibilities})}
		

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

	% Calculate player's position possibibilities after sonar
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
			if (ID == PlayerID) then Next
			else PlayersInfo.1|{SayDeath ID Next}
			end
		end
	end
	
	% Update lives of a player who has taken a damage
	fun{SayDamageTaken Args Player} Damage LifeLeft PLives in
		PLives = Player.lives
		arguments(damage:Damage lifeLeft:LifeLeft) = Args
		if (PLives-Damage \= LifeLeft) then 
			{System.show error(damage:Damage lifeLeft:LifeLeft playerLives:PLives)} 
		end
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
			NewMyInfo = {InitPosition ID Pos MyInfo} %MyInfo=myInfo(id:_)
			{TreatStream T NewMyInfo PlayersInfo}
		
		[]move(?ID ?Pos ?Direction)|T then NewMyInfo in
			ID = MyInfo.id
			NewMyInfo = {Move Pos Direction MyInfo PlayersInfo}
			{TreatStream T NewMyInfo PlayersInfo}

		[]dive|T then
			{TreatStream T {Dive MyInfo} PlayersInfo}

		[]chargeItem(?ID ?KindItem)|T then NewMyInfo in
			ID=MyInfo.id
			NewMyInfo = {ChargeItem KindItem MyInfo PlayersInfo}
			%{System.show chargeItem(KindItem)}
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
			Answer = (MyInfo.lives == 0)
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
			{TreatStream T {SayMissileExplodeMyInfo MyInfo Position ?Message} {PlayerModification ID PlayersInfo SayMissileExplodeMissileStatus arguments()}}
			% edit PlayersInfo's lives will be done with sayDamageTaken
		
		%todo, reflection: do we add the possible position of the mine, because actually we do not? I don't think we should for the random basic player... for the intelligent, maybe when we have a better idea of where the player is
		[]sayMineExplode(ID Position ?Message)|T then 
			{TreatStream T {SayMineExplodeMyInfo MyInfo Position Message} PlayersInfo}
		
		[]sayPassingDrone(Drone ?ID ?Answer)|T then
			ID = MyInfo.id
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayPassingDrone arguments(drone:Drone id:ID answer:Answer myInfo:MyInfo)}}
		
		[]sayAnswerDrone(Drone ID Answer)|T then 
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayAnswerDrone arguments(drone:Drone id:ID answer:Answer)}}
		
		%todo define strat for infomation that we give, count number that maximize unknown => for intelligent player only
		[]sayPassingSonar(?ID ?Answer)|T then
			ID = MyInfo.id
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayPassingSonar arguments(id:ID answer:Answer myInfo:MyInfo)}}
		
		[]sayAnswerSonar(ID Answer)|T then
			%todo problems might occur if answer isn't "pt(x:<x> y:<y>)" but normally it's correct
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayAnswerSonar arguments(position:Answer)}}
		
		[]sayDeath(ID)|T then
			% Dead player removed from player list
			{TreatStream T MyInfo {SayDeath ID PlayersInfo}}
		
		[]sayDamageTaken(ID Damage LifeLeft)|T then 
			%todo modify PlayersInfo with PlayerModification
			{TreatStream T MyInfo {PlayerModification ID PlayersInfo SayDamageTaken arguments(damage:Damage lifeLeft:LifeLeft)}}
		
		[] _|T then
			{TreatStream T MyInfo PlayersInfo}
		end
	end
end


% todo delete these comments ?
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
