#!/usr/bin/python
#-----------------------------------------------------
#version : regex_python
#Votre Nom : GLY
#commande dans la terminal : 
#python3 Bao2.py ./2021 3210(3234/3246)(international,économie,culture)
#Le programme a comme objectifs
#  - identifier et extraire les informations <title> et <description>
# - segmenter les informations extraites
#  - les annoter avec treetagger et udpipe
#Le programme va produire comme sortie ces fichiers de textes: 
#  - TTagger$Rubrique.xml
#  - TTagger$Rubrique(CoNLL)
#  - udpipe$Rubrique(CoNLL)
#  - udpipe$Rubrique.xml
#  :::::::::::::::::::::::::::::::::::::::::::::::::::::::
#  Pour BÀO2, il faut intégrer les fonctions suivantes:
#  - segmentation TD(tokenezition) -----
#  - étiquetage TreeTagger --------
#  - étiquetage UdPipe ------
#  - transformation de la sortie d'udpipe : txt==>xml(dans fonction udpipe
#j'ai fait le choix de ne pas faire appel au script 
#extract_un_fil
#mais de suivre la même logique que mon script en perl
#import time
import sys 
import re
import os 
#import spacy_udpipe

#udpipe = spacy_udpipe.load("fr-sequoia")
#encodage en python par défaut est utf-8
#------------------------------------------------------                        
# fonction néttoyage pour enlever les bruits dans les sorties
def nettoyage(texte):
    texte_net = re.sub("<!\[CDATA\[(.*?)\]\]>", "\\1", texte) 
    texte_net = re.sub("&amp;","",texte_net)
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
                        			titre_seg = segmentationTD(titre)
                        			description_seg = segmentationTD(description)
                        			#attention!! ici si on mets également le txt segmenter il y aura un 
                        			#problème quand udpipe va faire l'étiquetage
                        			#il faut on garde les segmentation en phrase mais pas en token 
                        			out_txt.write(titre+"\n"
+description+"\n\n")
                        			#titre_seg,description_seg=segmentationTD(titre,description)
                        			out_xml.write("<item>\n<titre>\n"+titre_seg+"</titre>\n<description>\n"+description_seg+"</description>\n</item>\n\n")

#-------------------------------------------------------
#tentation de faire une fonction qui prend un tuple 
#pas résussi
# raison :la fonction write prend un string comme argument
#je fais autrement:
#une fonction qui prend un string pour segmenter, et 
# je sépare la commande en deux comme la fonction nettoyage qui prend chaque fois un string
def segmentationTD(ele):
	with open("stock_tok.txt","w",encoding="utf-8") as stok : stok.write(ele) 
	os.system("perl ./treetagger/tokenise-utf8.pl stock_tok.txt > seg_tok.txt")
	with open("seg_tok.txt","r",encoding="utf-8") as seg: ele_seg = seg.read()
	#seg.close()
	#os.system("rm stock_tok.txt seg_tok.txt")
	#ne pas mettre dans cette boucle, à mettre une fois fini
	return ele_seg
	
#-------------------------------------------------------
#même fonction qu'en perl , on fait appel au programme fourni par M.Fleury 
def udpipe_seg():
	#lance udpipe , attention à l'environement du travail linux64 et au répertoire où se situe le programme
	print ("\nÉtiquetage via Udpipe:\n")
	os.system("./udpipe/udpipe-1.2.0-bin/bin-linux64/udpipe --tokenize --tokenizer=presegmented --tag --parse  ./udpipe/modeles/french-gsd-ud-2.5-191206.udpipe ./BAO2/BAO2_Py_out{}.txt > ./BAO2/BAO2_Py_udpipe{}.txt".format(rub_num,rub_num));
	
	print ("\nMaintenant tranférons CoNLL en XML:\n");
	
	os.system ("perl ./udpipe/udpipe2xml.pl ./BAO2/BAO2_Py_udpipe{}.txt ./BAO2/BAO2_Py_udpipe{}.xml utf-8".format(rub_num,rub_num));
	#with open("udpi utf-8".format(rub_num),"w",encoding="utf-8") as xmlUp: xmlUp.write()
	print ("Transoformation terminée.")	

#-------------------------------------------------------
def ttagger_seg():
	print ("\nLancer TreeTgger pour l'étiquetage:\n");
	os.system ("./treetagger/bin/tree-tagger  -lemma -token -no-unknown -sgml ./treetagger/lib/french-utf8.par  ./BAO2/BAO2_Py_out{}.xml > ./BAO2/BAO2_Py_Tree_Tagger{}".format(rub_num,rub_num));
	print ("\nÉcriture du fichier XML étiqueté:\n");
	#------lance treetagger2xml-utf8.pl pour transférer le fichiers coNLL en xml structuré
	os.system ("perl ./treetagger/treetagger2xml-utf8.pl ./BAO2/BAO2_Py_Tree_Tagger{} utf-8".format(rub_num));
	print ("\nTerminée")

#---------------------------------------------------------
# mettons les fonctions ensemble pour effectuer le traitement ensemble :::::::
#start = time.time()
rep = sys.argv[1]
rub_num = sys.argv[2]
#le nom du repertoire ne doit pas se terminer par un "/"
rep=re.sub("\/$","",rep)

# Ouverture des fichier 
out_txt = open("./BAO2/BAO2_Py_out{}.txt".format(rub_num),"w", encoding="UTF-8") 
out_xml = open("./BAO2/BAO2_Py_out{}.xml".format(rub_num),"w", encoding="UTF-8") 

#Écriture de l'en-tête xml.
out_xml.write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n")
out_xml.write("<corpus2022>\n")

#déclarer les variables : les compteurs ; tuple vide
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
#--------------------
ttagger_seg()   
udpipe_seg()                    
os.system("rm stock_tok.txt seg_tok.txt")
os.system("rm ./BAO2/BAO2_Py_out{}.txt".format(rub_num))
os.system("rm ./BAO2/BAO2_Py_out{}.xml".format(rub_num))

