functor
import
	%import players
	Player
	Player107Basic
	%PlayerBasicAI
	Player017Val
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player1 then {Player107Basic.portPlayer Color ID} 
		[] player2 then {Player.portPlayer Color ID}
		[] playerVal then {Player017Val.portPlayer Color ID}
		end
	end
end

%nothing to do except import the right players