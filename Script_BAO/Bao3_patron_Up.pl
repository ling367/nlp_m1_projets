#!/usr/bin/perl
#--------------------------------------------------------------------
<<DOC;
GAO Lingyun
Objectifs du programme:
- extraire les patrons qu'on veut avec le fichier Conll

Commande dans la terminal ex: 3210
perl bao3_patron_up.pl  [fichier conll].txt [fichier de sortie].txt [patron] 
---------------------------------------------------------
perl Bao3_patron_Up.pl ./BAO2/BAO2_Pl_udpipe3210.txt  "NOUN ADP NOUN ADP" 3210

perl Bao3_patron_Up.pl ./BAO2/BAO2_Pl_udpipe3210.txt "VERB DET NOUN" 3210

perl Bao3_patron_Up.pl ./BAO2/BAO2_Pl_udpipe3210.txt "NOUN ADJ" 3210

perl Bao3_patron_Up.pl ./BAO2/BAO2_Pl_udpipe3210.txt "ADJ NOUN" 3210
-----------------------------
deux patrons de mon choix :
-----------------------------

perl Bao3_patron_Up.pl ./BAO2/BAO2_Pl_udpipe3210.txt  "VERB ADP VERB" 3210

perl Bao3_patron_Up.pl ./BAO2/BAO2_Pl_udpipe3210.txt "NOUN ADP VERB" 3210

DOC
#--------------------------------------------------------------------
use utf8;
use strict;
binmode STDOUT,":utf8";
#--------------------------------------------------------------------
#Ouverture du fichier d'entrée et de sortie:: 
my $rub = $ARGV[2];
my $pattern = $ARGV[1];
open my $fic_conll, "<:encoding(utf-8)","$ARGV[0]" or die ("Ouverture du fichier échouée");
open my $p_extrait,">:encoding(utf8)","./BAO3/$rub Patrons/Upip_$pattern.txt";

#le patron est un string de POS assemblés entre "", j'ai besoin de le 
#découper en une liste d'éléments.
my @patron = split(/ /,$ARGV[1]);

#Création d'un dico, pour compter la fréquence des patrons extraits
my %dico_patron =();

#Pour récupérer les mots et leur POS, j'ai besoin de créer deux listes::
my @mot=();
my @POS=();

# Je dis au programme de lire ligne par ligne la fichier en CONLL::

while (my $ligne=<$fic_conll>) {
#j'identifie en premier les lignes qui contiennent les POS
# ligne qui commence par un chiffre et suivi par une tabulation : mais quand il s'agit des combinaisons comme 1-2, il n'y as pas d'infos à récupérer.
	next if $ligne=~m/^#|\d+-\d+/ ; 
	$ligne =~ s/\r?\n//g;
	#si la ligne n'est pas vide et ne commence pas par une combi de chiffre comme 1-2
	if ($ligne ne "") {
		#il faut enlever les saut de ligne
		# les éléments sont séparés par une tabulation:: on va découper la ligne par segment et les écrire dans les listes-->
		my @line = split(/\t/,$ligne);
		push @mot,$line[1];
		push @POS,$line[3]; #position deux est lemme	
	}
}
close $fic_conll;
#Je vais ensuite parcourir les deux listes, pour ceci, il faut que je sache les "frontières"
#je dois donc savoir la longeur des listes:
#scalar: variable that stores a single unit of data at a time. The data that will be stored by the scalar variable can be of the different type like string, character, floating point, a large group of strings or it can be a webpage and so on.
# pour stoker 
# len_patron = $#patron);
#my $len_lpos= scalar(@POS);

# maintenant on peut parcourir la liste des pos pour récupérer les pos correspondants
my $nb_item=0;
foreach my $i (0..$#POS+1){
	#on identifie la ligne où le POS correspond au premier élément du patron
	if ($POS[$i] eq $patron[0]){#eq = equality vérifier si deux strings sont pareils
		my $stock_pos = join(" ",@POS[$i..$i+$#patron]);
		my $stock_patron = join(" ",@patron[0..$#patron]);
		if ($stock_pos eq $stock_patron) {
			my $patron_ext = join(" ", @mot[$i..$i+$#patron]);
			$dico_patron{lc($patron_ext)}++;
			$nb_item++;
			
		}
	
	}
} 
print $p_extrait "$nb_item éléments trouvés correspondant au patron: ($pattern).\n";
foreach my $patron_ext (sort {$dico_patron{$b} <=> $dico_patron{$a} } keys %dico_patron) {
	print $p_extrait "$dico_patron{$patron_ext}\t$patron_ext\n";
}
close($p_extrait);
