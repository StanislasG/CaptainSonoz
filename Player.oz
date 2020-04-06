functor
import
    Input
    System
export
    portPlayer:StartPlayer
define
    StartPlayer
    TreatStream

    Function % for compiling

    InitPosition
in

    proc{Function Var}
        {System.show 3}
    end


    %inspirated by GUI.oz line 105
    fun{InitPosition ID Position}
        Id Color Name X Y 
    in
        %todo find a way to create store (Id Color Name X Y)
        ID = id(id:Id color:Color name:Name)
        Position pt(x:X y:Y)
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %We can decide how may arguments TreatStream has
    %An example in GUI.oz

    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream}
        end
        Port
    end

    proc{TreatStream Stream}
        case Stream
		of nil then skip
        []initPosition(?ID ?Position)|T then
            %<id> ::= null | id(id:<idNum> color:<color>) name:Name)
                %<idNum> ::= 1 | 2 | ... | Input.nbPlayer
                %<color> ::= red | blue | green | yellow | white | black | c(<colorNum> <colorNum> <colorNum>)
                    %<colorNum> ::= 0 | 1 | ... | 255
            %<position> ::= pt(x:<row> y:<column>)
                %<row> ::= 1 | 2 | ... | Input.nRow
                %<column> ::= 1 | 2 | ... | Input.nColumn

            %todo case ID and Positon null
            {InitPosition ID Position}
            {TreatStream T}
        []move(?ID ?Position ?Direction)|T then Var in
            %<direction> ::= <carddirection> | surface
                %<carddirection> ::= east | north | south | west
            {Function Var}
            {TreatStream T}
        []dive|T then Var in
            {Function Var}
            {TreatStream T}
        []chargeItem(?ID ?KindItem)|T then Var in
            %<item> ::= null | mine | missile | sonar | drone
                %<drone> ::= drone(row <x>) | drone(column <y>)
                %<mine> ::= null | <position>
            {Function Var}
            {TreatStream T}
        []fireItem(?ID ?KindFire)|T then Var in
            %<fireitem> ::= null | mine(<position>) | missile(<position>) | <drone> | sonar
            {Function Var}
            {TreatStream T}
        []fireMine(?ID ?Mine)|T then Var in
            {Function Var}
            {TreatStream T}
        []isDead(?Answer)|T then Var in
            {Function Var}
            {TreatStream T}
        []sayMove(ID Direction)|T then Var in
            {Function Var}
            {TreatStream T}
        []saySurface(ID)|T then Var in
            {Function Var}
            {TreatStream T}
        []sayCharge(ID KindItem)|T then Var in
            {Function Var}
            {TreatStream T}
        []sayMinePlaced(ID)|T then Var in
            {Function Var}
            {TreatStream T}
        []sayMissileExplode(ID Position ?Message)|T then Var in
            {Function Var}
            {TreatStream T}
        []sayMineExplode(ID Position ?Message)|T then Var in
            {Function Var}
            {TreatStream T}
        []sayPassingDrone(Drone ?ID ?Answer)|T then Var in
            {Function Var}
            {TreatStream T}
        []sayAnswerDrone(Drone ID Answer)|T then Var in
            {Function Var}
            {TreatStream T}
        []sayPassingSonar(?ID ?Answer)|T then Var in
            {Function Var}
        []sayAnswerSonar(ID Answer)|T then Var in
            {Function Var}
            {TreatStream T}
        []sayDeath(ID)|T then Var in
            {Function Var}
            {TreatStream T}
        []sayDamageTaken(ID Damage LifeLeft)|T then Var in
            {Function Var}
            {TreatStream T}
		[] _|T then
			{TreatStream T}
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