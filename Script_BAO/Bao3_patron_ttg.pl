#!/usr/bin/perl
#--------------------------------------------------------------------
<<DOC;
Objectifs du programme:
- extraire les patrons qu'on veut
Commande pour lancer le programme dans le terminal prend 3 arguments:
:::::::::::::::::::::::::::::::::::::::::::::::::::

perl Bao3_patron_ttg.pl ./BAO3/BAO3_Pl_Tree_tagger3210.xml "NOUN ADP NOUN ADP" 3210

perl Bao3_patron_ttg.pl ./BAO3/BAO3_Pl_Tree_tagger3210.xml "VERB DET NOUN" 3210

perl Bao3_patron_ttg.pl ./BAO3/BAO3_Pl_Tree_tagger3210.xml "NOUN ADJ" 3210

perl Bao3_patron_ttg.pl ./BAO3/BAO3_Pl_Tree_tagger3210.xml "ADJ NOUN" 3210


---------------
deux patrons de mon choix :
(VERB)AUX VERB VERB
perl Bao3_patron_ttg.pl ./BAO3/BAO3_Pl_Tree_tagger3210.xml "VERB ADP VERB" 3210


perl Bao3_patron_ttg.pl ./BAO3/BAO3_Pl_Tree_tagger3210.xml "NOUN ADP VERB" 3210

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Le prgramme prend en fichier d'entrée le fichier xml de Treetagger dont les étiquettes sont déjà unifiées avec celle d'Udpipe, et celui de 
Format de sortie : la liste des occurrences du patron s\'affiche dans le fichier de sortie
DOC
#--------------------------------------------------------------------
use utf8;
binmode STDOUT,":utf8";
#--------------------------------------------------------------------
# séparer le string des patrons en liste des partrons
my @patron= split(/ /,$ARGV[1]); 
my $pattern = $ARGV[1];
#patrons prêts
#ouverture du fichier d'entree::::
my $rub = $ARGV[2];
open my $fic_entree, "<:encoding(utf-8)", $ARGV[0];
open my $patron_ext, ">:encoding(utf-8)","./BAO3/$rub Patrons/Ttag_$pattern.txt";
my @LISTE=<$fic_entree>;
close($fic_entree);
#ouverture du fichier de sortie:::
# on est prêt pour le traitement :: 
#------------------------------------------------------------
#On veut compter la fréquence des occurences via un dico
my %dicoPatron=();

while (my $ligne=shift @LISTE) {
	my $terme="";
	# si la ligne contenue dans $ligne correspond au premier élément de mon patron
	if ($ligne=~/<element><data type="type">$patron[0]<\/data><data type="lemma">([^<]+?)<\/data><data type="string">([^<]+?)<\/data><\/element>/) {#on veut récupérer la valeur de la 3ème position , soit le token
		$terme=$terme.$2;
		my $len=1;
		my $indice=1;
		# alors il faut que je lise autant de ligne qu'il y a dans le patron et tester chaque terme du patron...
		while (($LISTE[$indice-1]=~/<element><data type=\"type\">($patron[$indice])<\/data><data type=\"lemma\">[^<]+?<\/data><data type=\"string\">([^<]+?)<\/data><\/element>/) and ($indice <= $#patron)) {#longeur d'indice <= longeur du patron
			$terme.=" ".$2;
			$indice++;
			$len++;
		}
		if ($len== $#patron + 1) {
			$dicoPatron{$terme}++;
			$nbTerme++;
		}
	}
	
}


print $patron_ext "$nbTerme éléments correspondant au patron ($pattern) trouvés\n";
#trier de haut en bas le dico
foreach my $patron (sort {$dicoPatron{$b} <=> $dicoPatron{$a} } keys %dicoPatron) {
	print $patron_ext "$dicoPatron{$patron}\t$patron\n";
}
close($patron_ext);
