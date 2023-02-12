#! usr/bin/python3
# pour tree-tagger 
#GAO Lingyun
#au lieu de lire tout corpus , on lit au fur et à mesure ce dont on a besoin( point : définir c'est quoi ce qu'on a besoin)
# on veut calculer les occurences 
#et on veut également faire une sorite comme la sortie en perl donc à modifier la sortie 

#python3 BAO3_Patron_Buffer.py 3210 ./BAO3/BAO3_Py_Tree_tagger3210.xml NOUN ADP NOUN ADP
#Le reste des patrons: 
#VERB DET NOUN
#NOUN ADJ
#ADJ NOUN
#VERB ADP VERB
#NOUN ADP VERB
#from traceback import format_exc
from typing import List
import re
import sys 
from collections import Counter
#from pathlib import Path
#la fonction extract prend le fichier xml (string) et une liste de string (patron) comme arguments, et il cherche à matcher une suite des tokens desquels les pos correspondent à notre liste de patron
def extract(fic_xmlstr, patron:List[str]):
    #ici on crée un buffer sous forme de liste de tuple:
    buf = [("---","---")] * len(patron)
    #et notre buffer contient autant d'éléments, et qui a la même taille du patron ; 
    #terme = ""#on voit tous les termes, donc pas ici 
    with open(fic_xml) as corpus:
        for ligne in corpus:
            #j'essaie de pas tout stoker,mais une petite partie 
            #solutoin : créeation d'un buffer pour stoker
            #une ligne c'est pas assez, donc à définir ce qu'on stoke dans notre buf - 
            # pk une ligne n'est pas assez? - complicité - au moins avoir tous mes patrons-
            # buf conteient 3 lignes , mais il lit toujours ligne par ligne 

            buf.pop(0) # toujours O(n) mais pose pas de problème dans la version d'avant, car n est très petit
            match= re.match("<element><data type=\"type\">([^<]+?)<\/data><data type=\"lemma\">[^<]+?<\/data><data type=\"string\">([^<]+?)<\/data><\/element>", ligne)    #échappe les "" et les \ en python 
            if match:
                pos = match.group(1)
                token = match.group(2)
                buf.append((pos,token))
            else:# on remet le buffer à nouveau
                buf = [("---","---")] * len(patron)
            #et ainsi 
            ok = True
            terme = ""
           #on peut donc reprendre presque les mêmes lignes que dans l'autre script
           # pour chaque pos du patron:
            for i, gat in enumerate(patron):#pas de risque , car buf a la même longeur que le patron 
                if gat == buf[i][0]:#l'expression régulier:chaque ligne va passer plusieurs fois dans le match ,comment améliorer?
                #faut pas que je stoke les résultats du match
                    terme = terme + buf[i][1] + f" "#groupe[0] correspond à la totalité 
                else: 
                    ok = False # il faut que tous les match soitent corrects, une seule erreur peut ruiner le traitement 
                    break
            if ok :
                liste_p.append(terme)

 
        
	
	
if __name__=="__main__":
    fic_xml = sys.argv[2]
    patron = sys.argv[3:]
    rub = sys.argv[1]
    sortie = open (f"./BAO3/{rub} Patrons/Tt_{patron}.txt","w",encoding="utf-8")
    liste_p = []
    extract(fic_xml, patron)
# Maintenant que j'ai la liste des patrons, je dois compter leur fréquence et aussi sa taille pour savoir combien de groupe de patrons en tout que j'ai repéré
# ici je veux utiliser Counter, et créer un dico pour associer le patron avec sa fréquence 
    freq_patron = Counter(liste_p)
    #et on veut aussi que les résultats soient en ordre décendant:
    sortie.write(str(len(liste_p))+" "+"élements correspondant au"+str(patron)+" ont été trouvés.\n")
# dict.items() re tourne une liste tuple de paires kay-value . J'applique donc la fonction sorted pour mettre en ordre décroissant mes résultats selon la fréquence. 
    for ele in sorted(freq_patron.items(), key=lambda x: x[1],reverse=True):
        freq = str(ele[0])
        pattern = str(ele[1])
        sortie.write(pattern+"\t"+freq+"\n")
