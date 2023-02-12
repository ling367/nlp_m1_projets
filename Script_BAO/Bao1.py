#!/usr/bin/python
#-----------------------------------------------------
#version : regex_python
#Votre Nom : GLY
#commande dans la terminal : 
#python3 Bao1.py ./2021 3210(3234/3246)(international,économie,culture)

#L'objectif de ce programme : extraire les infos
#Le programme prend en argument les éléments en-dessous:
#  - le nom du répertoire des fichiers xml à traiter
#  - le numéro de rubrique à prendre en traitement
#Le programme a comme objectifs
#  - identifier et extraire les informations <title> et <description>
#Le programme va produire comme sortie deux fichiers de textes: 
#  - [out_txt{rub_num}.txt] ( brut ) 
#  - [out_xml{rub_num}.xml] ( structuré)
#import time
import sys 
import re
import os 

#encodage en python par défaut est utf-8
#------------------------------------------------------                        
# fonction néttoyage pour enlever les bruits dans les sorties
def nettoyage(texte):
    texte_net = re.sub("<!\[CDATA\[(.*?)\]\]>", "\\1", texte)
    texte_net = re.sub("&amp;","\1",texte_net)
    return texte_net
#-----------------------------------------------------
#parcours les fichiers dans le répertoire, poursuivre l'extraction 
#pourquoi une seule fonction qui fait le parcours du répertoire et extraction des informations? mais pas 2?
# Pour avoir le compteur qui fonctionne pour item et fichier
#deux boucles séparées, ça coupe
def par_trai_print(rep):
	#os.walk() fonction pour-->parcourir l'arborecence de haut en bas
	for path,noms,fichiers in os.walk(rep):
		for fic in fichiers:
			#on trouve tous les fichiers xml:
			if re.search(rf'{rub_num}.+\.xml',fic):
				#keyword global : r & w une variable dans la fonction
				global cpt_fic
				cpt_fic += 1
				fic_path = path + "/" + fic
				print (cpt_fic,"Traitement :",fic_path)
				fic_xml = open(fic_path,"r",encoding="utf-8")
				textelu = fic_xml.read()
				# récupérons les infos en tuple : (titre,description)
				text = re.findall(r"<item><title>(.+?)<\/title>.+?<description>(.+?)<\/description>",textelu)# attention aux différences entre experssion perl et python( enlevé-gis)
				for (titre,description) in text:
					#on ne veut pas de doublon d'extraction : 
					#vu que les données sont un tuple, ils vont en pair; 
					#il suffit de regarder si le premier élément du tuple soit le même:
                    			global uniq
                    			if titre not in uniq:
                        			uniq.add(titre)
                        			global nb_item
                        			nb_item += 1
                        			# faisons appel à la fonction nettoyage pour enlever les bruits
                        			titre = nettoyage(titre)
                        			description = nettoyage(description)
                        			out_txt.write("TITRE : "+titre+"\nDESCRIPTION : "+description+"\n\n")
                        			out_xml.write("<item><titre>"+titre+"</titre>\n""<description>"+description+"</description></item>\n\n")


# mettons les fonctions ensemble pour effectuer le traitement ensemble :::::::
#start = time.time()
rep = sys.argv[1]
rub_num = sys.argv[2]
#le nom du repertoire ne doit pas se terminer par un "/"
rep=re.sub("\/$","",rep)

# Ouverture des fichier de sortie
out_txt = open("./BAO1/BAO1_Py_out{}.txt".format(rub_num),"w", encoding="UTF-8") 
out_xml = open("./BAO1/BAO1_Py_out{}.xml".format(rub_num),"w", encoding="UTF-8") 

#Écriture de l'en-tête xml.
out_xml.write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n")
out_xml.write("<corpus2022>\n")

#déclarer les variables : les compteurs & tuple vide pour évider des doublons
cpt_fic = 0
nb_item = 0
uniq = set()
print ("Traitement de :",rub_num)

par_trai_print(rep)
print ("Nombre d'items traités :",nb_item)
#fermer les fichiers de sortie une fois que le taitement soit terminé.
out_xml.write("</corpus2022>\n")
out_xml.close()
out_txt.close()                        

