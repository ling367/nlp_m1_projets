#! usr/bin/python3
#---------------------------------------------------------------------------------------------------
# pour envoyer les résultats et lancer le programme, voici la commande à insérer dans le terminal::
# python BAO4_graphe.py ./BAO2/BAO2_Py_udpipe3210.xml obj 
#
#cat Graphe_fic | curl -X POST -H 'Content-Type:text/csv' --data-binary @- "https://padagraph.magistry.fr/post_csv/lingyun_graphe"



import re
import sys
#from signal import signal, SIGPIPE, SIG_DFL 

#signal(SIGPIPE,SIG_DFL) 
#from pathlib import Path
corpus=sys.argv[1]
#Le corpus est le premier argument de la liste d'arguments.
relation=sys.argv[2]
#La relation est le deuxième argument.
#On lance la fonction extract_relation()

#on néttoie les lemmas pour que sur le graph il n'y a pas trop de bruit, faut enlevé tous ceux qui ne sont pas lettre
def joligraphe(lemma:str):
	lemma = re.sub("[^\w]","",lemma)
	lemma = re.sub("le|(l')|la|que|de|(d')","",lemma)
	return lemma
# notre fonction pour extraire la relation prend deux arguments: le fichier transféré en xml d'udpipe en tant que corpus, et le nom de la relation
#Buffer utilié::<data [^>]+>

	#on crée un buffer pour stocker les pair de (key d'inedx,token/lemme) phrases
phrase_buf = {}
#un autre buffer en forme de liste de tuple (lemme/token_dep,id_gouv)
relation_buf = []
#on stock ici les coules de dep et gouv
#mais cette fois-ci on aura besoin de compter les fréquence des relations pour le graphe final,il faut donc mettre le tuple de gouverneur - dépendant dans un dict comme key pour ensuite compter leur fréquence avec "value"
dict_paires = {}
#on ouvre le fichier d'entrée et on lit ligne par ligne, et on déoupe chaque phrase pour les mettre dans une liste des lignes :
with open(corpus,"r",encoding = "UTF-8") as file:
	lignes = file.readlines()
for ligne in lignes:
	if ligne.startswith("<element>"):
	# vu qu'au moment où j'ai transféré mon fichier CONLL en XML, j'ai adapté les balises selon la sortie xml de treetaggern on ne peut pas utiliser ici findall pour tous car il existe des balises différents::
	#commence par observer la représentation : à part le premier groupe du numéro du token, le reste des balises contiennent toutes "data", on va les traiter séparément
		fileds =re.findall("<data[^>]+>([^<]+)</data>",ligne)
		
		idx,pos,lemma,token,id_gouv,relat = fileds
		phrase_buf[idx]=lemma
		if relat == relation:
			relation_buf.append((lemma,id_gouv))
	if ligne=="</phrase>\n":#découpage de lecture
	#écriture des paires (id_gouv,lemme) dans le dict. 
		for dep_lemma,id_gouv in relation_buf:
			dep_lemma = joligraphe(dep_lemma)
			gouv_lemma = joligraphe(phrase_buf[id_gouv])
			dict_paires[gouv_lemma,dep_lemma]=dict_paires.get((gouv_lemma,dep_lemma),0)+1
	
	#remets les buffer en état initial pour le prochain tour
		relation_buf = []
		phrase_buf = {}
		
#cette fois si , on écrit dans un fichier de sortie pour envoyer les résultat dans le curl 
# deux sommets à créer pour comprendre les deux bouts de la relation : gouverneur et son dépendant.
#tous les sommets doivent être unique, pour cette raison nous allons les numéroter avec un identifiant : #id
#en définissant le "shape", cela permet à modifier la forme du graphe
	
print ("@Gouv: #id, label, shape")
	#on veut d'abord la moitié de key, soit lemme du gouverneur ( element,_ => premier mot du key, inverse pour l'autre car on a que 2 éléments dans notre clé ) 
for lemme in {gouv_lemma for gouv_lemma,_ in dict_paires.keys()}:
	print(f'g_{lemme},{lemme},diamond')
   	#je veux que les gouverneurs soient présentés en diamond 
   	#ensuite on fait la même chose pour les dépendants
print("@Dep: #id, label")	
for lemme in {dep_lemma for _,dep_lemma in dict_paires.keys()}:
	print(f'd_{lemme},{lemme}')
# une fois que les sommets sont bien relevés, il faut remettre le lien de dépendance. Ici on ajout le poids.f 
print(f"_{relation}:weight:")
for gouv_lemma, dep_lemma in dict_paires.keys():
	print(f"g_{gouv_lemma},--,d_{dep_lemma},{dict_paires[gouv_lemma,dep_lemma]}")

	
	
