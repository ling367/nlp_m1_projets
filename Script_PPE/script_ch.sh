#!/usr/bin/bash
#néttoyer le résultat des précédentes tentatives 
rm -f "$2/tableau_ch.html";
mkdir ./DUMP-SEG ; 
# pour lancer ce script:
# bash ./PROGRAMMES/test.sh ./URL ./TABLEAUX
# stocker les arguments dans des variables
DOSSIER_URL=$1
DOSSIER_TABLEAUX=$2
#echo "MOTIF=$3" ; > ./minigrep/motif.txt
# Stockage de motif dans une variable et création 
#motif="高校|大学"
#todo: valider les arguments
echo " Le urls sont dans ce répertoire : $1 " ;
echo " Le tableau HTML est créé dans ce répertoire : $2" ;
echo " Les mots cherchés :高校|大学" ;
#--------------------------Construire le tableau html-----------------------------
echo "<html>
	<head>
		<meta charset=\"UTF-8\"/>
		<title>Tableau des URLs CH</title>
	</head>
	<body>" > $2/tableau_ch.html;
#Création d'un nouveau fichier : tableau_ch.html dans le répertoire TABLEAUX
#Ajout d'un compteur des tableaux 
cptTableau=4;  
#Ajouter cette variable dans une boucle pour traiter chaque fichier contenu dans DOSSIER_URL
for fichier in $(ls $1); do # Parcourir les fichiers dans le dossier URL
	echo "Fichier lu : $fichier"
	#on compte les tableaux à l'aide du compteur à 0 pour les parcourir tous
	compteur=1
	#création d'un tableau pour chaque fichier d'url
# ----------Début du tableau-----------------------------------------
	echo "<p align=\"center\"><hr color=\"black\" width=\"80%\"/> </p>" >> $2/tableau_ch.html ;
	echo "<table align=\"center\" border=\"2px\" bordercolor=\"orange\" >" >> $2/tableau_ch.html ;
	echo "<thead style=\"background-color:#FCE7D7; height:150px;\" ><tr><th colspan=\"11\" align=\"center\">Tableau n° $cptTableau</th></tr><tr><th colspan=\"11\" align=\"center\">Fichier : $fichier</th></tr><tr><th colspan=\"11\" align=\"center\">Motif : 高校|大学 </th></tr></thead>" >> $2/tableau_ch.html ;
#---------construction de l'en-tete du tableau et nommer tous les colones----------
	echo "<tr>
	<td align=\"center\">Num.</td>
	<td align=\"center\">Codehttp</td>
	<td align=\"center\">Encodage</td>
	<td align=\"center\">URL</td>
	<td align=\"center\">Pages aspirées</td>
	<td align=\"center\">Dump text</td>
	<td align=\"center\">Fréquence motif</td>
	<td align=\"center\">Index</td>
	<td align=\"center\">Bigrammes</td>
	<td align=\"center\">contexte-txt</td>
	<td align=\"center\">contexte-html</td></tr>" >> $2/tableau_ch.html
#lire chaque fichier du dossier, un par un et écrit dans le tableau
	for line in $(cat "$1/$fichier"); do
		echo "----------------------------";
		echo "Traitement des URLs : $line ";
		echo "----------------------------";
		#je peux travailler avec line (l'url)
		#On va aspirer les pages pour pouvoir les lire hors ligne avec la fonction "curl" (-L qui permet de suivre le lien meme si l'URL est un raccourci, -o qui permet de renvoyer la page aspirée dans un fichier au lieu de la ligne de commande)
		#varibale $line = url
		#'%{http_code}\n' = cela sert pour recuperer le code HTTP = tout est mis ensuite dans une variable.
    		codehttp=$(curl -L -o ./PAGES-ASPIREES/"$cptTableau-$compteur".html $line -w %{http_code});
    #tester la valeur du codehttp
   		echo "$codehttp"
  	  #une variable pour vérifier si la connexion vers l'URL est OK 
    		if [[ $codehttp == 200 ]]
        		then
            			echo "encodage OK, cool! Je continue" 
            # CURL pour récupérer l'encodage option -I en HTML
            # Ensuite on utilise egrep à laquelle on donne charset comme argument pour qu'elle trouve la ligne où l'encodage est indiqué 
            #CUT pour garder la partie de l'encodage utile
        			encodage=$(curl -L -I $line | egrep -i "charset" | cut -d"=" -f2 | tr [a-z] [A-Z] | tr -d "\r");
       			echo "<$encodage>";
            #Détection si l'encodage repéré est en UTF-8 ou pas 
            #si encodage = UTF-8 alors on poursuit les traitements
            #sinon à essayer de savoir son encodage et le convertir en UTF-8 
        			if [[ $encodage =~ 'utf' || $encodage =~ 'UTF' && $encodage =~ '8' ]] ;
            				then
           					echo "encodé en UTF-8 , traitement poursuit"
           					echo "$<$cptTableau><$compteur><$line><$codehttp><$encodage>"
				#-------pages aspirés URLs=> dump le contenu de la page-------
						#lynx  -dump -nolist -assume_charset="UTF-8" -display_charset="UTF-8" ./PAGES-ASPIREES/"$cptTableau-$compteur".html > ./DUMP-TEXT/"$cptTableau-$compteur".txt
				lynx  -dump -nolist -assume_charset="UTF-8" -display_charset="UTF-8" ./PAGES-ASPIREES/"$cptTableau-$compteur".html > ./DUMP-TEXT/"$cptTableau-$compteur".txt ;
            					#lynx -dump -nolist -assume_charset= "UTF-8" -display_charset="UTF-8"> ./PAGES-ASPIREES/"$cptTableau-$compteur".html > ./DUMP-TEXT/"$cptTableau-$compteur".txt ;  	
            					#nétoyage des fichiers dump
            					sed -i '/  [*+]/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
						sed -i '/__/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
						sed -i '/|/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
						sed -i '/BUTTON/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
						sed -i '/alternate/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
						sed -i '/http/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
						sed -i '/IFRAME/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
						sed -i '/png/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
            			#-------script de segmentation en mandarin ( stanford)--------( peut echouer et causer des dump text vide !!!!!!
            					bash ./stanford-segmenter/segment.sh -k ctb ./DUMP-TEXT/"$cptTableau-$compteur".txt UTF-8 0 > ./DUMP-SEG/"$cptTableau-$compteur".txt;
            			#-------traitement pour faire le fichier index hierarchique-----------
            					cat ./DUMP-SEG/"$cptTableau-$compteur".txt | grep -o -P "[\p{Han}\p{L}]+" | sort |uniq -c | sort -n > ./DUMP-TEXT/index"$cptTableau-$compteur".txt ;
            					cat ./DUMP-SEG/"$cptTableau-$compteur".txt | grep -o -P "[\p{Han}\p{L}]+" > ./DUMP-SEG/unigramme"$cptTableau-$compteur".txt ;
            			#-------ensuite bigrammes-------------
            					head -n -1 ./DUMP-SEG/unigramme"$cptTableau-$compteur".txt > ./DUMP-SEG/unigramme1"$cptTableau-$compteur".txt ;
            					tail -n +2 ./DUMP-SEG/unigramme"$cptTableau-$compteur".txt > ./DUMP-SEG/unigramme2"$cptTableau-$compteur".txt ;
            					paste ./DUMP-SEG/unigramme1"$cptTableau-$compteur".txt ./DUMP-SEG/unigramme2"$cptTableau-$compteur".txt > ./DUMP-SEG/Bigramme"$cptTableau-$compteur".txt ;
            					cat ./DUMP-SEG/Bigramme"$cptTableau-$compteur".txt | sort | uniq -c | sort -r >  ./DUMP-TEXT/bigramme"$cptTableau-$compteur".txt ;
            			#-------étape de minigrep : pour la page html---------
            					perl ./minigrep/minigrepmultilingue.pl "UTF-8" ./DUMP-TEXT/"$cptTableau-$compteur".txt ./minigrep/motif.txt ;
            			#-------déplacer en renommant les résultats dans le dossier contexte --------
            					mv resultat-extraction.html ./CONTEXTES/"$cptTableau-$compteur".html 
            					mv ./DUMP-SEG/"$cptTableau-$compteur".txt ./DUMP-TEXT/"$cptTableau-$compteur".txt ; 
            					#-------octenir les contextes des occurences et mettre dans un fichier txt-------
            					CptMotif=$(egrep -coi "高校|大学" ./DUMP-TEXT/"$cptTableau-$compteur".txt) ;
            					egrep -iC2 --color "高校|大学" ./DUMP-TEXT/"$cptTableau-$compteur".txt > ./CONTEXTES/"$cptTableau-$compteur".txt ;
            					echo "<file=\"$cptTableau-$compteur\">" >> ./DUMP-TEXT/dump-complet-$cptTableau.txt
						cat ./DUMP-TEXT/"$cptTableau-$compteur".txt >> ./DUMP-TEXT/dump-complet-$cptTableau.txt
						echo "</file>" >> ./DUMP-TEXT/dump-complet-$cptTableau.txt
						echo "<file=\"$cptTableau-$compteur\">" >> ./CONTEXTES/contexte-complet-$cptTableau.txt
						cat ./CONTEXTES/"$cptTableau-$compteur".txt >> ./CONTEXTES/contexte-complet-$cptTableau.txt
						echo "</file>" >> ./CONTEXTES/contexte-complet-$cptTableau.txt
            					echo "<tr>
           					<td align=\"center\">$compteur</td>
            					<td align=\"center\">$codehttp</td>
            					<td align=\"center\">$encodage</td>
            					<td><a href=\"$line\">$line</a</td>
            					<td align=\"center\"><a href=\"../PAGES-ASPIREES/"$cptTableau-$compteur".html\">"$cptTableau-$compteur".html</a></td>
            					<td align=\"center\"><a href=\"../DUMP-TEXT/"$cptTableau-$compteur".txt\">"$cptTableau-$compteur".txt</a></td>
            					<td align=\"center\">$CptMotif</td>
            					<td align=\"center\"><a href=\"../DUMP-TEXT/index"$cptTableau-$compteur".txt\">index"$cptTableau-$compteur".txt</a></td>
            					<td align=\"center\"><a href=\"../DUMP-TEXT/bigramme"$cptTableau-$compteur".txt\">bigramme"$cptTableau-$compteur".html</a></td> 			
            					<td align=\"center\"><a href=\"../CONTEXTES/"$cptTableau-$compteur".txt\">"$cptTableau-$compteur".txt</a></td>
            					<td align=\"center\"><a href=\"../CONTEXTES/"$cptTableau-$compteur".html\">"$cptTableau-$compteur".html</a></td>
                     				</tr>" >> $2/tableau_ch.html                        
            				else
            					echo "traitement d'url non utf-8" ;
               				testencodg=$(iconv -l | egrep -i "$encodageURL")  ;
               				#(iconv -l | egrep -i encodage);
                				if [[ $testencodg != "" ]]
                					then
                						#obtenir l'encodage_nonutf8
                 						#testencodg= $encodageURL;
                 						#echo "<$encodageURL>" ;
                 						#curl -sL -o ./PAGES-ASPIREES/"$cptTableau-$compteur".html $line ;
                 						#curl -SIL -o ./PAGES-ASPIREES/"$cptTableau-$compteur".html $line ;
                 						#lynx  -dump -nolist  ./PAGES-ASPIREES/"$cptTableau-$compteur".html > ./DUMP-TEXT/"$cptTableau-$compteur".txt
            							#lynx  -dump -nolist -assume_charset="$encodageURL" -display_charset="$encodageURL" "./PAGES-ASPIREES/"$cptTableau-$compteur".html" > ./DUMP-TEXT/"$cptTableau-$compteur".txt ;
            							iconv -f "$encodageURL" -t "UTF-8" ./DUMP-TEXT/"$cptTableau-$compteur".txt > ./DUMP-TEXT/"$cptTableau-$compteur".txt;
            							lynx  -dump -nolist -assume_charset="UTF-8" -display_charset="UTF-8" ./PAGES-ASPIREES/"$cptTableau-$compteur".html > ./DUMP-TEXT/"$cptTableau-$compteur".txt ;
            							#lynx  -dump -nolist -assume_charset="UTF-8" -display_charset="UTF-8" ./PAGES-ASPIREES/"$cptTableau-$compteur".html > ./DUMP-TEXT/"$cptTableau-$compteur".txt;
            							sed -i '/  [*+]/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
								sed -i '/__/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
								sed -i '/|/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
								sed -i '/BUTTON/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
								sed -i '/alternate/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
								sed -i '/http/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
								sed -i '/IFRAME/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
								sed -i '/png/d' ./DUMP-TEXT/$cptTableau-$compteur.txt
            							encodageURL=$(uchardet ./DUMP-TEXT/"$cptTableau-$compteur".txt);
            							echo "$encodageURL" ;
            							echo "encodage connu par iconv, encodage converti";
            							#-------octenir les contextes des occurences et mettre dans un fichier txt-------
            							CptMotif=$(egrep -coi "高校|大学" ./DUMP-TEXT/"$cptTableau-$compteur".txt) ;
            							egrep -iC2 --color "高校|大学" ./DUMP-TEXT/"$cptTableau-$compteur".txt > ./CONTEXTES/"$cptTableau-$compteur".txt ;
            			#-------étape de minigrep : pour la page html---------
            							perl ./minigrep/minigrepmultilingue.pl "UTF-8" ./DUMP-TEXT/"$cptTableau-$compteur".txt ./minigrep/motif.txt ;
            			#-------déplacer en renommant les résultats dans le dossier contexte --------
            							mv resultat-extraction.html ./CONTEXTES/"$cptTableau-$compteur".html 
            			#-------script de segmentation en mandarin ( stanford)--------( peut echouer et causer des dump text vide !!!!!!
            							bash ./stanford-segmenter/segment.sh -k ctb ./DUMP-TEXT/"$cptTableau-$compteur".txt UTF-8 0 > ./DUMP-SEG/"$cptTableau-$compteur".txt;
            							
            			#-------traitement pour faire le fichier index hierarchique-----------
            							cat ./DUMP-SEG/"$cptTableau-$compteur".txt | grep -o -P "[\p{Han}\p{L}]+" | sort |uniq -c | sort -n > ./DUMP-TEXT/index"$cptTableau-$compteur".txt ;
            							cat ./DUMP-SEG/"$cptTableau-$compteur".txt | grep -o -P "[\p{Han}\p{L}]+" > ./DUMP-SEG/unigramme"$cptTableau-$compteur".txt ;
            			#-------ensuite bigrammes-------------
            							head -n -1 ./DUMP-SEG/unigramme"$cptTableau-$compteur".txt > ./DUMP-SEG/unigramme1"$cptTableau-$compteur".txt ;
            							tail -n +2 ./DUMP-SEG/unigramme"$cptTableau-$compteur".txt > ./DUMP-SEG/unigramme2"$cptTableau-$compteur".txt ;
            							paste ./DUMP-SEG/unigramme1"$cptTableau-$compteur".txt ./DUMP-SEG/unigramme2"$cptTableau-$compteur".txt > ./DUMP-SEG/Bigramme"$cptTableau-$compteur".txt ;
            							cat ./DUMP-SEG/Bigramme"$cptTableau-$compteur".txt | sort | uniq -c | sort -r > ./DUMP-TEXT/bigramme"$cptTableau-$compteur".txt ;
            							mv ./DUMP-SEG/"$cptTableau-$compteur".txt ./DUMP-TEXT/"$cptTableau-$compteur".txt ; 
            							echo "<file=\"$cptTableau-$compteur\">" >> ./DUMP-TEXT/dump-complet-$cptTableau.txt
								cat ./DUMP-TEXT/"$cptTableau-$compteur".txt >> ./DUMP-TEXT/dump-complet-$cptTableau.txt
								echo "</file>" >> ./DUMP-TEXT/dump-complet-$cptTableau.txt
								echo "<file=\"$cptTableau-$compteur\">" >> ./CONTEXTES/contexte-complet-$cptTableau.txt
								cat ./CONTEXTES/"$cptTableau-$compteur".txt >> ./CONTEXTES/contexte-complet-$cptTableau.txt
								echo "</file>" >> ./CONTEXTES/contexte-complet-$cptTableau.txt
            							echo "<tr>
           							<td align=\"center\">$compteur</td>
            							<td align=\"center\">$codehttp</td>
            							<td align=\"center\">$encodageURL</td>
            							<td><a href=\"$line\">$line</a</td>
            							<td align=\"center\"><a href=\"../PAGES-ASPIREES/"$cptTableau-$compteur".html\">"$cptTableau-$compteur".html</a></td>
            							<td align=\"center\"><a href=\"../DUMP-TEXT/"$cptTableau-$compteur".txt\">"$cptTableau-$compteur".txt</a></td>
            							<td align=\"center\">$CptMotif</td>
            							<td align=\"center\"><a href=\"../DUMP-TEXT/index"$cptTableau-$compteur".txt\">index"$cptTableau-$compteur".txt</a></td>
            							<td align=\"center\"><a href=\"../DUMP-TEXT/bigramme"$cptTableau-$compteur".txt\">bigramme"$cptTableau-$compteur".txt</a></td> 			
            							<td align=\"center\"><a href=\"../CONTEXTES/"$cptTableau-$compteur".txt\">"$cptTableau-$compteur".txt</a></td>
            							<td align=\"center\"><a href=\"../CONTEXTES/"$cptTableau-$compteur".html\">"$cptTableau-$compteur".html</a></td>
                     						</tr>" >> $2/tableau_ch.html ；
                     				else 
                     				echo "l'encodage n'est pas reconnu par iconv"
            			# l'encodage n'est pas reconnu par iconv
            					echo "<tr>
           							<td align=\"center\">$compteur</td>
            							<td align=\"center\">$codehttp</td>
            							<td align=\"center\">$encodage</td>
            							<td><a href=\"$line\">$line</a</td>
            							<td>-</td>
            							<td>-</td>
            							<td>-</td>
            							<td>-</td>
            							<td>-</td>
            							<td>-</td>
            							<td>-</td>
            							</tr>" >> $2/tableau_ch.html ;
            					#concaténation tentative non-réussi à voir
            					#echo "<file=\"$cptTableau-$compteur\">" >> ./DUMP-TEXT/corpus-complet.txt
						#cat ./DUMP-TEXT/"$cptTableau-$compteur".txt >> ./DUMP-TEXT/corpus-complet.txt
						#echo "</file>" >> ./DUMP-TEXT/corpus-complet-$cptTableau.txt
						#echo "<file=\"$cptTableau-$compteur\">" >> ./CONTEXTES/corpus-complet.txt
						#cat ./CONTEXTES/"$cptTableau-$compteur".txt >> ./CONTEXTES/corpus-complet.txt
						#echo "</file>" >> ./CONTEXTES/corpus-complet.txt
            					fi
            				fi
            			else	
        			echo "urls corompus"
        			echo "<tr>
        			<td align=\"center\">$compteur</td>
        			<td align=\"center\">$codehttp</td>
        			<td>-</td>
        			<td>-</td>
        			<td>-</td>
        			<td>-</td>
        			<td>-</td>
        			<td>-</td>
        			<td>-</td>
        			<td>-</td>
        			<td>-</td>
        			</tr>" >> $2/tableau_ch.html;	                        
            		fi
            compteur=$((compteur+1)) ;
  	  	#le compteur avance à chaque tour	
	done < $1/$fichier ;
		# fermeture de mon tableau
	echo "</table><br />" >> $2/tableau_ch.html
# faut pas oublier de faire le saut de ligne
	cptTableau=$((cptTableau+1))	
done
echo "</body></html>" >> $2/tableau_ch.html ;
