functor
import
	OS
export
	isTurnByTurn:IsTurnByTurn
	nRow:NRow
	nColumn:NColumn
	map:Map
	nbPlayer:NbPlayer
	players:Players
	colors:Colors
	thinkMin:ThinkMin
	thinkMax:ThinkMax
	turnSurface:TurnSurface
	maxDamage:MaxDamage
	missile:Missile
	mine:Mine
	sonar:Sonar
	drone:Drone
	minDistanceMine:MinDistanceMine
	maxDistanceMine:MaxDistanceMine
	minDistanceMissile:MinDistanceMissile
	maxDistanceMissile:MaxDistanceMissile
	guiDelay:GUIDelay
define
	IsTurnByTurn
	NRow
	NColumn
	Map
	NbPlayer
	Players
	Colors
	ThinkMin
	ThinkMax
	TurnSurface
	MaxDamage
	Missile
	Mine
	Sonar
	Drone
	MinDistanceMine
	MaxDistanceMine
	MinDistanceMissile
	MaxDistanceMissile
	GUIDelay
	MapGenerator
in

% ----------------------------------------------------------------
% Generate a map
% ----------------------------------------------------------------
	% Begins by generating the map in the form of one liste (of size NRow * NColumn) and then resizes it to 2 dimensions
	% First, the island have values (1, 2, ...) to keep track of if they are the same or not
	% Positions are stored as pt(x:<x> y:<y>) (x from 1 to NRow and y from 1 to NColumn)

	fun{MapGenerator IslandSizes}
		% Generate a line of zeros of size NRow*NColumn
		fun	{GenerateZeroFlatMap}
			fun {GenerateZeroLine N}
				if N =< 0 then nil
				else 0|{GenerateZeroLine N-1}
				end
			end
		in
			{GenerateZeroLine NRow*NColumn}
		end

		% Resize the FlatMap to the good dimensions
		fun {Resize FlatMap}
			fun {ResizeRecursive Row FlatMap}
				if Row == 0 then nil
				else {List.take FlatMap NColumn} | {ResizeRecursive Row-1 {List.drop FlatMap NColumn}}
				end
			end
		in
			{ResizeRecursive NRow FlatMap}
		end

		% Formats the FlatMap to usable Formats
		fun {Format FlatMap}
			fun {ZeroOrOne Value}
				if Value == 0 then 0
				else 1
				end
			end
		in
			{Resize {List.map FlatMap ZeroOrOne}}
		end

		% Returns the index of Pos in FlatMap
		fun {GetIndex Pos}
			(Pos.x-1) * NColumn + Pos.y
		end

		% Returns the value of the island at Pos
		fun {GetIslandValue Pos FlatMap}
			{List.nth FlatMap {GetIndex Pos}}
		end

		% Cardinal directions
		fun {North Pos} pt(x:Pos.x-1 y:Pos.y  ) end
		fun {South Pos} pt(x:Pos.x+1 y:Pos.y  ) end
		fun {East  Pos} pt(x:Pos.x   y:Pos.y+1) end
		fun {West  Pos} pt(x:Pos.x   y:Pos.y-1) end

		% Checks if a position is valid for an island
		% 	makes islands not touch the sides to avoid trapping a player in a 1x1 square 
		% 	(note: this can still happen with 3x3 7 or 8-tiles islands with a hole in the center, but is very unlikely as the chances of generating an island on a tile depend on the number of island tiles adjacent to it (strictly))
		fun {ValidPosition Pos}
			(Pos.x > 1 andthen Pos.y > 1 andthen Pos.x < NRow andthen Pos.y < NColumn)
		end

		% Returns only the valid positions in the list
		fun {ValidPositionList Positions}
			case Positions
			of nil then nil
			[] H|T then
				if {ValidPosition H} then
					H|{ValidPositionList T}
				else
					{ValidPositionList T}
				end
			end
		end

		% Get valid positions around a specific Pos
		fun {Around Pos}
			{ValidPositionList 
					[ {North Pos} {East  {North Pos}} 
						{East  Pos} {South {East  Pos}} 
						{South Pos} {West  {South Pos}} 
						{West  Pos} {North {West  Pos}}] }
		end

		% Get positions directly adjacent (in the cardinal directions) to the positions in the list
		fun {StrictlyAround PosList}
			case PosList of nil then nil
			[] H|T then
				{North H} | {East H} | {South H} | {West H} | {StrictlyAround T}
			end
		end

		% Checks if a position can be attached to an island without merging
		fun {IsValid Pos IslandValue FlatMap}
			fun {IsValidRecursive PosList IslandValue FlatMap}
				case PosList
				of nil then true
				[] H|T then 
					% if a good expansion slot
					if {GetIslandValue H FlatMap} == IslandValue orelse {GetIslandValue H FlatMap} == 0 then {IsValidRecursive T IslandValue FlatMap}
					else false
					end
				end
			end
		in
			% if out of bounds 
			if {Not {ValidPosition Pos}} then false
			elseif {GetIslandValue Pos FlatMap} \= 0 then false
			else {IsValidRecursive {Around Pos} IslandValue FlatMap}
			end
		end

		% Returns only the valid positions in the list
		fun {IsValidList PosList IslandValue FlatMap}
			case PosList
			of nil then nil
			[] H|T then 
				if {IsValid H IslandValue FlatMap} then H|{IsValidList T IslandValue FlatMap}
				else {IsValidList T IslandValue FlatMap}
				end
			end
		end

		% Change the value at pt(x:X y:Y) to the island value
		fun {MakeIsland Pos IslandValue FlatMap}
			{List.append {List.take FlatMap ({GetIndex Pos}-1)} IslandValue|{List.drop FlatMap {GetIndex Pos}}}
		end

		% Gives all the positions where an island can expand
		fun {ExpansionSlots IslandList IslandValue FlatMap}
			{IsValidList {StrictlyAround IslandList} IslandValue FlatMap}
		end

		% Generate an island of a certain size around a point if the island is constraint by other near islands and can't expand more, smaller-than-size islands can happen
		fun {GenerateIsland Pos Size IslandValue FlatMap}
			% Returns an island expanded by Size tiles
			fun {ExpandIsland PosList Size IslandValue FlatMap}
				if Size =< 1 then FlatMap
				else 
					Slots Chosen NewFlatMap
				in
					% Get the possibilities
					Slots = {ExpansionSlots PosList IslandValue FlatMap}
					if Slots == nil then FlatMap
					else
						% Choose one random expansion slot
						Chosen = {List.nth Slots (({OS.rand} mod {List.length Slots}) + 1)}
						% Change the FlatMap
						NewFlatMap = {MakeIsland Chosen IslandValue FlatMap}
						% Recursive call
						{ExpandIsland Chosen|PosList Size-1 IslandValue NewFlatMap}
					end
				end
			end
		in
			{ExpandIsland Pos|nil Size IslandValue FlatMap}
		end

		% Generate the list of islands and return the FlatMap
		fun {GenerateIslandList IslandSizes FlatMap}
			% Recursive, TimesTried is to avoid infinite loop
			fun {GenerateIslandListRecursive IslandSizes IslandValue FlatMap TimesTried}
				case IslandSizes
				of nil then FlatMap
				[] H|T then Pos in
					% Avoid infinite loops
					if TimesTried == 0 then 
						{GenerateIslandListRecursive T IslandValue+1 FlatMap NRow*NColumn}
					else
						% Get a random position & check if it is a valid starting point for an island
						Pos = pt(x:(({OS.rand} mod NRow) + 1) y:(({OS.rand} mod NColumn) + 1))
						if {IsValid Pos IslandValue FlatMap} then NewFlatMap in
							% Create a new island & recursive call
							NewFlatMap = {GenerateIsland Pos H IslandValue {MakeIsland Pos IslandValue FlatMap}}
							{GenerateIslandListRecursive T IslandValue+1 NewFlatMap NRow*NColumn}
						else
							% Just try again
							{GenerateIslandListRecursive IslandSizes IslandValue FlatMap TimesTried-1}
						end
					end
				end
			end
		in
			{GenerateIslandListRecursive IslandSizes 1 FlatMap NRow*NColumn}
		end

		% Local variables
		EmptyFlatMap
		FlatMap
	in
		EmptyFlatMap = {GenerateZeroFlatMap}
		FlatMap = {GenerateIslandList IslandSizes EmptyFlatMap}
		{Format FlatMap}
	end


% ----------------------------------------------------------------
% Input Variables
% ----------------------------------------------------------------

%%%% Style of game %%%%

	IsTurnByTurn = true

%%%% Description of the map %%%%

	% Map for checking MapGenerator
	% NRow = 19
	% NColumn = 36
	% Map = {MapGenerator [5 2 5 4 7 8 18 13 7 14 3 5 6 7 8 9 9 9 9 9 4 5 5 4 4 3 5 6 7 6 5 4 3]}

	% Small map
	NRow = 6
	NColumn = 10
	Map = [ [0 0 0 0 0 0 0 0 0 0]
					[0 0 0 0 0 0 0 0 0 0]
					[0 0 0 1 1 0 0 0 0 0]
					[0 0 1 1 0 0 1 0 0 0]
					[0 0 0 0 0 0 0 0 0 0]
					[0 0 0 0 0 0 0 0 0 0]]

%%%% Players description %%%%

	% Players for playing on a large map
	% NbPlayer = 8
	% Players = [player2 player2 player2 player2 player2 player2 player2 player2]
	% Colors = [red blue green yellow white c(255 127 255) c(255 255 127) c(127 255 255)]

	% Small number of players
	NbPlayer = 4
	Players = [player2 player2 player2 player2]
	Colors = [red blue green yellow]

%%%% Thinking parameters (only in simultaneous) %%%%

	ThinkMin = 500
	ThinkMax = 3000

%%%% Surface time/turns %%%%

	TurnSurface = 3

%%%% Life %%%%

	MaxDamage = 4

%%%% Number of load for each item %%%%

	Missile = 3
	Mine = 3
	Sonar = 3
	Drone = 3

%%%% Distances of placement %%%%

	MinDistanceMine = 1
	MaxDistanceMine = 2
	MinDistanceMissile = 1
	MaxDistanceMissile = 4

%%%% Waiting time for the GUI between each effect %%%%

	GUIDelay = 500 % ms

end