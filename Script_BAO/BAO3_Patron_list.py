#! usr/bin/python3
# ce script prend en entrée le fichier en txt Conll de Udpipe, et il a pour but d'extraire les patrons désignés
#GAO Lingyun
#commande dans le terminal pour lancer le prgramme::
# python BAO3_Patron_list.py ./BAO2/BAO2_Py_udpipe3210.txt 3210 "NOUN ADP NOUN ADP" 
#Le reste des patrons: 
#VERB DET NOUN
#NOUN ADJ
#ADJ NOUN
#VERB ADP VERB
#NOUN ADP VERB

from typing import List
import re
import sys 
from pathlib import Path
from collections import Counter
rub = sys.argv[2]
with open (sys.argv[1], encoding="UTF-8") as file: lignes = file.readlines()

patron = re.split(r" ",sys.argv[3])

sortie = open (f"./BAO3/{rub} Patrons/Up_{patron}.txt","w",encoding = "UTF-8")
# je vais 3 lists : 

tokens = []
pos = []
patterns = []

for ligne in lignes: 
# je cherche à matcher les lignes qu'il non un seul id, mais pas ceux comme 1-2 , car pas ce genre de ligne manque d'info
            match= re.match(r"^[0-9]+(\t)(\w)+", ligne)#reverse de la ligne qui rend le programme plus efficace
            if match:
                ligne = ligne.split("\t")
                tokens.append(ligne[1])# position 1, 2e colonne --> tokens
                pos.append(ligne[3])#position 3, 4e colonne) --> pos 
nb_pos = len(pos)
for i in range(nb_pos):
# je regarde les lignes derrière le premier élément du patron repérer: si chaque élément correspondent bien aux pos dans mon patron 
    if pos[i:i+len(patron)] == patron[:len(patron)]:
    # je dois rassembler les morceaux pour avoir des patrons complets:
        pattern = " ".join(tokens[i:i+len(patron)])
        patterns.append(pattern)

#print(pos)
#J'ai ainsi la liste des patterns, n'oublie pas de print pour vérifier:
#print(patterns)

#maintenant je fait comme dans le script poue treetagger 
#fonction Counter, dico.items(), pour créer un dict et détourner les paires de clé- valeur en liste tuple

freq_patron = Counter(patterns)
    #et on veut aussi que les résultats soient en ordre décendant:
sortie.write(str(len(patterns))+" "+"élements correspondant au"+str(patron)+" ont été trouvés.\n")
# dict.items() re tourne une liste tuple de paires kay-value . J'applique donc la fonction sorted pour mettre en ordre décroissant mes résultats selon la fréquence. 
for ele in sorted(freq_patron.items(), key=lambda x: x[1],reverse=True):
    freq = str(ele[0])
    pattern = str(ele[1])
    sortie.write(pattern+"\t"+freq+"\n")
    

   


    #passer à la ligne suivante

#### que ce soit traité par perl ou python, il faut avoir les mêmes résultats 
##ligne de commade pour lancer dans le terminal 
#python extract.py corpus-titre-description.xml NOM PRP NOM |wc -l
#perl -CSDA ../patron_treetagger.pl NOM PRP NOM | wc -l
# Pour évaluer le temps d'execusion perl < python ; time - commande bash 
