#Makefile for VScode on windows works with powershell
#more info page 9

#clean
Remove-Item *.ozf

#compile to ozf file

# ozc -c *.oz

ozc -c Input.oz
ozc -c PlayerManager.oz
#ozc -c Player.oz
ozc -c GUI.oz
ozc -c Main.oz

#run code
ozengine Main.ozf