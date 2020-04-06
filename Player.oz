functor
import
    Input
export
    portPlayer:StartPlayer
define
    StartPlayer
    TreatStream
in



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream <p1> <p2> ...}
        end
        Port
    end
    proc{TreatStream Stream } <p1> <p2> ...% as as many parameters as you want
        case Stream
		of nil then skip
        []initPosition(?ID ?Position)|T then Var in
            %<id> ::= null | id(id:<idNum> color:<color>) name:Name)
                %<idNum> ::= 1 | 2 | ... | Input.nbPlayer
                %<color> ::= red | blue | green | yellow | white | black | c(<colorNum> <colorNum> <colorNum>)
                    %<colorNum> ::= 0 | 1 | ... | 255
            %<position> ::= pt(x:<row> y:<column>)
                %<row> ::= 1 | 2 | ... | Input.nRow
                %<column> ::= 1 | 2 | ... | Input.nColumn
            {Function Var}
        []move(?ID ?Position ?Direction)|T then Var in
            %<direction> ::= <carddirection> | surface
                %<carddirection> ::= east | north | south | west
            {Function Var}
        []dive|T then Var in
            {Function Var}
        []chargeItem(?ID ?KindItem)|T then Var in
            %<item> ::= null | mine | missile | sonar | drone
                %<drone> ::= drone(row <x>) | drone(column <y>)
                %<mine> ::= null | <position>
            {Function Var}
        []fireItem(?ID ?KindFire)|T then Var in
            %<fireitem> ::= null | mine(<position>) | missile(<position>) | <drone> | sonar
            {Function Var}
        []fireMine(?ID ?Mine)|T then Var in
            {Function Var}
        []isDead(?Answer)|T then Var in
            {Function Var}
        []sayMove(ID Direction)|T then Var in
            {Function Var}
        []saySurface(ID)|T then Var in
            {Function Var}
        []sayCharge(ID KindItem)|T then Var in
            {Function Var}
        []sayMinePlaced(ID)|T then Var in
            {Function Var}
        []initPosition(?ID ?Position)|T then Var in
            {Function Var}
        []sayMissileExplode(ID Position ?Message)|T then Var in
            {Function Var}
        []sayMineExplode(ID Position ?Message)|T then Var in
            {Function Var}
        []sayPassingDrone(Drone ?ID ?Answer)|T then Var in
            {Function Var}
        []sayAnswerDrone(Drone ID Answer)|T then Var in
            {Function Var}
        []sayPassingSonar(?ID ?Answer)|T then Var in
            {Function Var}
        []sayAnswerSonar(ID Answer)|T then Var in
            {Function Var}
        []sayDeath(ID)|T then Var in
            {Function Var}
        []sayDamageTaken(ID Damage LifeLeft)|T then Var in
            {Function Var}
		[] _|T then
			{TreatStream Stream}
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