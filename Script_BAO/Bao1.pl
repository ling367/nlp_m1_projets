#/usr/bin/perl
<<DOC; 
version : regexp
Votre Nom : GLY
commande dans la terminal : 
perl Bao1.pl ./2021 3210(3234/3246) -(international,économie,culture)

Le script:::::::::::::::::::::::::::::::::::::::::::::
Le programme prend en argument les éléments en-dessous:
  - le nom du répertoire des fichiers xml à traiter
  - le numéro de rubrique à prendre en traitement
Le programme a comme objectifs
  - identifier et extraire les informations <title> et <description>
Le programme va produire comme sortie deux fichiers de textes: 
  - [outTXT$Rubrique.txt]
  - [outXML$Rubrique.xml]
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
open my $outTXT,">:encoding(UTF-8)", "./BAO1/BAO1_pl_out$Rubrique.txt";
open my $outXML,">:encoding(UTF-8)", "./BAO1/BAO1_pl_out$Rubrique.xml";
#----------------------------------------
print $outXML "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
print $outXML "<corpus2022>\n";
# ---------------------------------------------------
#dico éviter les doublons
my %dico_des_titres =();
my $cptItem=0;
#compter mes fichier rss
my $cptFile=0;
print "\n----Traitement de $Rubrique----\n"

&ParcArbFile($Repertoire);	#recurse!

# fermer la balise
print $outXML "</corpus2022>\n" ;
close $outTXT;
close $outXML;
print "Nombre d'items traités :", $cptItem,"\n"; 
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
		#si $file est un répertoire ?on poursuit le traitement 
		}
		#on est pas sûr que ça prendra moins de temps 
		#mes documents vont s'écraser
#       TRAITEMENT à réaliser sur chaque fichier
#       Insérer ici le filtreur
#traiter que les fichier xml relevant de la rubrique que j'ai choisi 
	        if (-f $file and $file =~ /$Rubrique.+xml$/) {
	        	print $cptFile++, "Traitement :",$file,"\n";	
			&traitement($file);
		}
	}
}
			
			
#---------------------------------------------------------------
# Deuxième étape : Effectuer le traitement des fichiers rss 			
sub traitement {
	my $file = shift(@_);			
	open my $fichier,"<:encoding(UTF-8)",$file; #descripteur de fichier
	$/ = undef; 
	my $textelu = <$fichier>; #lecture du fichier
	close $fichier;
#opérateur de recherche : =~ // option de recherche : i, g(continue aux suivant et pas s'arreter)-chercher,continue, s(multiligne qui ne retient pas la retour à la ligne)
#option s passe sans prendre en compte les retour à la ligne
	while($textelu=~/<item><title>(.+?)<\/title>.+?<description>(.+?)<\/description>/gis) {
   		my $titre=$1;
		my $description=$2;
		#éliminer les doublons
		if (! (exists $dico_des_titres{$titre})){
			$dico_des_titres{$titre}=$description;
			($titre,$description)=&nettoyage($titre,$description);
    			
    			print $outTXT "TITRE : ",$titre,"\n","DESCRIPTION : ",$description,"\n\n" ;
			print $outXML "<item nb=\"$cptItem\">\n<titre>$titre<\/titre>\n<description>$description<\/description>\n<\/item>\n";
			$cptItem++  
		}
		
	}

}
		
#---------------------------------------------------------
# Étape 3 Observer les résultats d'extraction et faire un néttoyage 

# à enlever : <![CDATA[ ; ]]>
sub nettoyage {# version informatiquement plus générique
	my @propre=();
	my $titre = $_[0];
	my $description = $_[1];
	#my $titre = shift @_;
	foreach my $var (@_){
        	$var=~s/<!\[CDATA\[//;
        	$var=~s/\]\]>//;
        	$var=~s/&amp;//;
        	push @propre,$var;#mets qqch à la fin de la liste et 
        }
    	return @propre;
}




