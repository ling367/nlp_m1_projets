#/usr/bin/perl
<<DOC; 
version : regexp
Votre Nom : GLY
commande dans la terminal : 
perl Bao2.pl ./2021 3210(3234/3246) -(international,économie,culture)

Le script:::::::::::::::::::::::::::::::::::::::::::::
Le programme prend en argument les éléments en-dessous:
  - le nom du répertoire des fichiers xml à traiter
  - le numéro de rubrique à prendre en traitement
Le programme a comme objectifs
  - identifier et extraire les informations <title> et <description>
  - segmenter les informations extraites
  - les annoter avec treetagger et udpipe
Le programme va produire comme sortie ces fichiers de textes: 
  - TreeTagger$Rubrique.xml
  - TreeTagger$Rubrique(CoNLL)
  - udpipe$Rubrique(CoNLL)
  - udpipe$Rubrique.xml
  :::::::::::::::::::::::::::::::::::::::::::::::::::::::
  Pour BÀO2, il faut intégrer les fonctions suivantes:
  - segmentation TD(tokenezition) -----ok
  - étiquetage TreeTagger --------ok
  - étiquetage UdPipe ------ok
  - transformation de la sortie d'udpipe : txt==>xml --ok
  :::::::::::::::::::::::::::::::::::::::::::::::::::::::
DOC
#use Timer::Runtime ;
#-----------------------------------------------------------
# strictement en utf-8 
use strict ;
use utf8 ;
# les sorties à l'écran en UTF8
binmode(STDOUT,":utf8");
# nom du fichier
my $Repertoire="$ARGV[0]";
#le nom du repertoire ne doit pas se terminer par un "/"
$Repertoire=~ s/[\/]$//;
my $Rubrique ="$ARGV[1]" ;
#--------------------------------------------------
# on initialise une variable contenant le flux de sortie 
open my $outTXT,">:encoding(UTF-8)", "./BAO2/BAO2_pl_out$Rubrique.txt";
open my $outXML,">:encoding(UTF-8)", "./BAO2/BAO2_pl_out$Rubrique.xml";
#----------------------------------------
print $outXML "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
print $outXML "<corpus2022>\n";
# ---------------------------------------------------
#dico pour éviter les doublons( résultat 3210 - 6675?)
my %dico_des_titres =();
my $cptItem=0;
#compter mes fichier rss
my $cptFile=0;
#---------------------------------------------------------
&ParcArbFile($Repertoire);
#---------------------------------------------------------
# fermer la balise
print $outXML "</corpus2022>\n" ;
close $outTXT;
close $outXML;
#------------------------------------------------------
#BAO2----Étiquetage avec TT et UP
#TT prend en entrée le fichier texte xml
#UP prend en entrée le fichier texte txt
&TreeTagger;
&UdPipe;
print "Nombre d'items traités :", $cptItem,"\n"; 
print "\nAnnotation terminé.";
#Je ne garde que les sorties dont je me sers pour la prochaine étape, je suprime donc les fichiers de stokage pour la segmentation.
system("rm fic_stock$Rubrique.txt");
system("rm TD_seg$Rubrique.txt");
system("rm ./BAO2/BAO2_pl_out$Rubrique.txt");
system("rm ./BAO2/BAO2_pl_out$Rubrique.xml");
#----programme terminé--------------------------
exit;
#----------------------------------------------
# Première étape : Parcourir arborescence des fichiers

sub ParcArbFile{
	my $path = shift(@_);
	opendir(DIR, $path) or die "can't open $path: $!\n";
#opendir : un descripteur de repectoire (un mot clé qui désigne dans le reste du script pour désigner le répertoire)
	my @files = readdir(DIR);#récupère ...
	#lire le répertoire; readdir = ls -l 
	# dans bash ; lecture de la liste dnas le répertoire 
	#lit toutes les ressources disponibles dans le répertoire x
	closedir(DIR);
	foreach my $file (@files) {
		next if $file =~ /^\.\.?$/;
		$file = $path."/".$file; # le. c'est la concaténation 
		if (-d $file) {
			&ParcArbFile ($file); #recurse !
			print "$file - Parcouru \n"
		#si $file est un répertoire ? sinon, on poursuit le traitement 
		}
		#on est pas sûr que ça prendra moins de temps 
		#mes documents vont s'écraser
#       TRAITEMENT à réaliser sur chaque fichier
#       Insérer ici le filtreur
#traiter que les fichier xml relevant de la rubrique que j'ai choisi 
	        if (-f $file){
	        	if ($file =~/$Rubrique.+xml$/) {
	        	print $cptFile++, "Traitement :",$file,"\n";	
			&traitement($file);
			}
		}
	}
}
			
			
#---------------------------------------------------------------
# Deuxième étape : Effectuer le traitement des fichiers rss 	
# Pour BÀO 2 il faut ajouter l'étape de segmentation
# Quand on print les pairs de titres et descriptions		
sub traitement {
	my $file = shift(@_);			
	open my $fichier,"<:encoding(UTF-8)",$file; #descripteur de fichier
	$/ = undef; 
	my $textelu = <$fichier>; #lecture du fichier
	close $fichier;
#opérateur de recherche : =~ // option de recherche : i, g(continue aux suivant et pas s'arreter)-chercher,continue, s(multiligne qui ne retient pas la retour à la ligne)
#option s passe sans prendre en compte les retour à la ligne
	while($textelu=~/<item><title>(.+?)<\/title>.+?<description>(.+?)<\/description><guid.+?\/(\d{4}\/\d{2}\/\d{2}).+?<\/item>/sg) {
   		my $titre=$1;
		my $description=$2;
		#éliminer les doublons
		if (! (exists $dico_des_titres{$titre})){
			$dico_des_titres{$titre}=$description;
			($titre,$description)=&nettoyage($titre,$description);
    			#Attention! au fichier txt, ici il ne faut pas segmenter en token 
    			#car on veux garder le texte segmenté en phrase pour l'Udpipe 
    			# sinon sent_id devient pour chaque token, c'est une phrase, et c'est pas correct!
    			#erreur repérée en BAO3 --> corrigée 
    			print $outTXT $titre,"\n";
			print $outTXT $description,"\n\n";
			#######################
    			#segmentation 
    			my($titre_seg,$description_seg)=&segmentationTD($titre,$description);
			print $outXML "<item>\n<titre>\n$titre_seg\n</titre>\n<description>\n$description_seg\n</description>\n</item>\n";
			$cptItem++;  
		}
		
	}

}
#--------------------------------------------------------
# Étape 2-bis -----Segmentation titre et description
# logique : 
# - créer un fichier vide texte brut pour mettre mes données ( fic_stock$Rubrique.txt)
# - ensuite je lance le programme pour effectuer la segmentation 
# - j'écris mes résultats dans un nouveau fichier vide (TD_seg$Rubrique.txt)
sub segmentationTD{
	# récupération de mes arguments en haut(titre et description)
	my ($titre,$description)=@_;
	#traiterment un par un
	#~#
	#d'abord traiter les titres
	#créer et mettre mes données dans fic_stock$Rubrique.txt
	open my $fic_stock, ">:encoding(UTF-8)","fic_stock$Rubrique.txt";
	print $fic_stock $titre;
	close $fic_stock;
	#lancer le script de tokenization
	system("perl ./treetagger/tokenise-utf8.pl fic_stock$Rubrique.txt > TD_seg$Rubrique.txt");
	##écrit dans le fichier les titres segmentés
	undef $/;
	open my $fic_seg, "<:encoding(UTF-8)","TD_seg$Rubrique.txt";
	my $titre_seg=<$fic_seg>;
	close $fic_seg;
	#ensuite les description
	#~#
	#créer et mettre mes données dans fic_stock$Rubrique.txt attention, pas d'éclaration de nouvelle variable élimine my
	open $fic_stock, ">:encoding(UTF-8)","fic_stock$Rubrique.txt";
	print $fic_stock $description;
	close $fic_stock;
	#lancer le script de tokenization
	system("perl -f ./treetagger/tokenise-utf8.pl fic_stock$Rubrique.txt > TD_seg$Rubrique.txt");
	##écrit dans le fichier les titres segmentés
	#attention : pas undef$/
	open $fic_seg, "<:encoding(UTF-8)","TD_seg$Rubrique.txt";
	my $description_seg=<$fic_seg>;
	close $fic_seg;
	#mettons deux retours à la ligne
	$/="\n\n";
	return $titre_seg,$description_seg;
}


#----------------------------------------
sub TreeTagger{
	#effectuer pos-tagging par TT
	print "\nLancer TreeTgger pour l'étiquetage:\n";
	system ("./treetagger/bin/tree-tagger  -lemma -token -no-unknown -sgml ./treetagger/lib/french-utf8.par  ./BAO2/BAO2_pl_out$Rubrique.xml > ./BAO2/BAO2_Pl_Tree_tagger$Rubrique ");
	print "\nÉcriture du fichier XML étiqueté:\n";
	#------lance treetagger2xml-utf8.pl pour transférer le fichiers coNLL en xml structuré
	system ("perl ./treetagger/treetagger2xml-utf8.pl ./BAO2/BAO2_Pl_Tree_tagger$Rubrique utf-8");
	print "\nTerminée"
	#pb rencontré : sortie xml vide
	#raison : nom du fichier sortie étiqueté par treetagger différent du fichier d'entrée du reetagger2xml-utf8.pl ( sortie de la dernière != entrée de celui) !!!!!!!!!!!
}
#-----------------------------------------------
sub UdPipe{
	#lance udpipe , attention à l'environement du travail linux64 et au répertoire où se situe le programme 
	print "\n\nLancer Udpipe pour l'étiquetage:\n";
	system("./udpipe/udpipe-1.2.0-bin/bin-linux64/udpipe --tokenize --tokenizer=presegmented --tag --parse  ./udpipe/modeles/french-gsd-ud-2.5-191206.udpipe ./BAO2/BAO2_pl_out$Rubrique.txt > ./BAO2/BAO2_Pl_udpipe$Rubrique.txt");
	print "\nTransferer la sortie en XML:\n";
	system ("perl ./udpipe/udpipe2xml.pl ./BAO2/BAO2_Pl_udpipe$Rubrique.txt ./BAO2/BAO2_Pl_udpipe$Rubrique.xml utf-8");
	print "Transoformation terminée."	
}		
#---------------------------------------------------------
# Étape 3 Observer les résultats d'extraction et faire un néttoyage 

# à enlever : <![CDATA[ ; ]]>
#Pb rencontré BAO2 ==> sortie ttag.xml il y a du bruit 
#au tour d'item nb
sub nettoyage {# version informatiquement plus générique
	my @propre=();
	my $titre = $_[0];
	my $description = $_[1];
	#my $titre = shift @_;
	foreach my $var (@_){
        	$var=~s/<!\[CDATA\[//;
        	$var=~s/\]\]>$//;
        	$var=~s/\.+$/\./g;
        	$var=~s/$/\./g;
        	$var=~s/&amp;//;
        	push @propre,$var;#mets qqch à la fin de la liste et 
        }
    	return @propre;
}




