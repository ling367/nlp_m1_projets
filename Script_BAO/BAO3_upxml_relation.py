#! usr/bin/python3
# vue que j'ai déjà adapter les étiquettes au moment où j'ai tranféré conll en xml, je ne peux pas utiliser la fonction findall

#commande dans le terminal : exemple
#python3 BAO3_upxml_relation.py ./BAO2/BAO2_Py_udpipe3210.xml "obj" 3210

import re
import sys
#from pathlib import Path


# notre fonction pour extraire la relation prend deux arguments: le fichier transféré en xml d'udpipe en tant que corpus, et le nom de la relation
#Buffer utilié::<data [^>]+>

def extract_relation(corpus, relation):
	#on crée un buffer pour stocker les pair de (key d'inedx,token/lemme) phrases
	phrase_buf = {}
	#un autre buffer en forme de liste de tuple (lemme/token_dep,id_gouv)
	relation_buf = []
	#on stock ici les coules de dep et gouv
	couples = set()
	#on ouvre le fichier d'entrée et on lit ligne par ligne, et on déoupe chaque phrase pour les mettre dans une liste des lignes :
	with open(corpus,"r",encoding = "UTF-8") as file:
		lignes = file.readlines()
	for ligne in lignes:
		if ligne.startswith("<element>"):
			fileds =re.findall("<data[^>]+>([^<]+)</data>",ligne)
			#j'ai en tout 10 collones dont 4 j'en n'ai pas besoin:
			idx, pos,lemma,token,id_gouv,relat = fileds
		 #hésitation : je prend le token comme ce que l'on a fait perl ou je prend le lemma? quel impact il y aura sur mon graphe? À tester:::::( lemma au final) 
			phrase_buf[idx]=lemma
			if relat == relation:
				relation_buf.append((lemma,id_gouv))
		if ligne=="</phrase>\n":#découpage de lecture
		#écriture des couples (id_gouv,lemme)
			for dep_lemma,id_gouv in relation_buf:
				couples.add((f"{phrase_buf[id_gouv]}",f"{dep_lemma}"))
		
		#remets les buffer en état initial pour le prochain tour
			relation_buf = []
			phrase_buf = {}
			
	fic.write("Le nombre de relation repérées:"+str(len(couples))+"\n\n")			
	for item in couples:
		fic.write(f"{item[0]} -{relation}-> {item[1]}\n")
		

	
					
  #  ---------------------------------------
if __name__=="__main__":
	corpus=sys.argv[1]
	#Le corpus est le premier argument de la liste d'arguments.
	relation=sys.argv[2]
	#La relation est le deuxième argument.
	#On donne le numéro de la rubrique dans la commande et il est le 3e argument.
	rub = sys.argv[3]
	#On ouvre notre fichier de sortie et dans son nom, on précise la rubrique, que le fichier de travail est celui étiqueté avec UDpipe (ud) et la relation. 
	fic=open(f"./BAO3/{rub} Relations/relation_{relation}_py.txt", "w", encoding="utf-8")
	#On lance la fonction extract_relation() sur notre corpus et la relation.
	print("Extraction de la relation :",relation)
	extract_relation(corpus, relation)
	fic.close()
	
