#!/usr/bin/perl
#----------------------------------------------------------------------------------
<<DOC; 
En entrée : sortie UDPIPE formatée en XML + une relation syntaxique
# En sortie la liste triée des couples Gouverneur,Dependant en relation
321O
#perl Bao3_upxml_relation.pl ./BAO2/BAO2_Pl_udpipe3210.xml  "obj" 3210

DOC
#----------------------------------------------------------------------------------
use strict;
use utf8;
binmode (STDOUT,":utf8");
#-------------------------------------------------------------------------------------
my $rub =$ARGV[2];
my $relation = $ARGV[1];
my %dico_relations=();
# on découpe le texte par phrase (liste d'items annotés et potentiellement dépendants)
$/="</phrase>\n";
open my $upxml ,"<:encoding(utf8)","$ARGV[0]";
while (my $phrase=<$upxml>){	#-------------------------------------------------------------------------------------
# on traite chaque "paragraphe" en le decoupant "items"
	my @lignes = split(/\n/,$phrase);
	for (my $i=0; $i<=$#lignes; $i++) {
		# si la ligne lue contient la relation, on ira chercher le dep puis le gouv
		# on peut mettre les valeurs qu'on cherche sont entre () , et les numéroter en ordre
		if ($lignes[$i]=~/<element><data type="id">([^<]+)<\/data><data type="type">[^<]+<\/data><data type="lemma">[^<]+<\/data><data type="string">([^<]+)<\/data><data type="ID_GOV">([^<]+)<\/data><data type="relation">([^<]*$relation[^<]*)<\/data><\/element>/i){#attention aux positions des valeurs 
			my $id_dep=$1;
			my $token_dep=$2;
			my $id_gov= $3;
			my $relation=$4;
			#si le gouverneur se situe derrière le dépendant, on parcours les lignes suivantes et chercher la tête syntaxique
			if ($id_dep > $id_gov) {
				for (my $k=0; $k<$i; $k++) {
					if ($lignes[$k]=~/<element><data type="id">$id_gov<\/data><data type="type">[^<]+<\/data><data type="lemma">[^<]+<\/data><data type="string">([^<]+)<\/data><data type="ID_GOV">[^<]+<\/data><data type="relation">[^<]+<\/data><\/element>/) {
						my $token_gov=$1;
#On écrit les résultats dans le dico et on compte leur fréquence 
					$dico_relations{"$token_gov -$relation-> $token_dep"}++;
					}
				}
			}
			else {
				for (my $k=$i+1; $k<=$#lignes; $k++) {
					if ($lignes[$k]=~/<element><data type="id">$id_gov<\/data><data type="type">[^<]+<\/data><data type="lemma">[^<]+<\/data><data type="string">([^<]+)<\/data><data type="ID_GOV">[^<]+<\/data><data type="relation">[^<]+<\/data><\/element>/) {
						my $token_gov=$1;
						$dico_relations{"$token_gov -$relation-> $token_dep"}++;
					}
				}
			}
		}
	}
}
close ($upxml);

# on imprime la liste des couples Gouv,Dep et leur fréquence...
open my $extrait,">:encoding(utf8)", "./BAO3/$rub Relations/relation_obj_pl.txt";
my $cpt = 0;
foreach my $relation (sort {$dico_relations{$b}<=>$dico_relations{$a}} (keys %dico_relations)) {
	print $extrait "$dico_relations{$relation}\t$relation\n";
	$cpt++;
}
print $extrait "$cpt paires de relation ($relation) sont identifiées.";#À trouver à la fin du fichier :
close $extrait;
