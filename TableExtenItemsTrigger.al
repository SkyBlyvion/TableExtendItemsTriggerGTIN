/* 

TODO: Migrer cette tableextension dans la table extension 50018 "Item Extension" de l'extension :
    "id": "12eacc5c-c397-78fe-ad49-c030e45fcd3e",
    "name": "ItemsExtensionsTables",
    "publisher": "Lopez Nicolas",
    "version": "1.0.1.7",

Ce code est une extension de table pour la table "Item" dans Dynamics 365 Business Central.
Il ajoute un déclencheur (trigger) "OnInsert" pour calculer automatiquement le code GTIN (Global Trade Item Number) lorsqu'un nouvel article est créé.

Comment le code GTIN est calculé :
1. Les 7 premiers caractères du numéro de l'article ("No.") sont extraits.
2. Chaque caractère pertinent est converti en entier.
3. Un total intermédiaire est calculé en utilisant une formule spécifique.
4. Le dernier chiffre de ce total intermédiaire est utilisé pour calculer un code de contrôle.
5. Le code GTIN final est formé en concaténant une constante, les parties extraites du numéro de l'article, et le code de contrôle.

Les déclarations de variables sont dérivées du contexte du code C/AL, où chaque variable joue un rôle spécifique dans le calcul du GTIN.

Exemple :
    numéro "30-9114"
    On extrait les caractères pertinents : "3", "0", "9", "1", "1", "4".
    Conversion des caractères en entiers :
        varRef1 = 3
        varRef2 = 0
        varRef3 = 9
        varRef4 = 1
        varRef5 = 1
        varRef6 = 4
    Calcul du total intermédiaire :
        Formule : varTotCalcul := ((varRef2 + varRef4 + varRef6 + 5) * 3) + (varRef1 + varRef3 + varRef5 + 12)
        Remplacement des valeurs :
        (varRef2 + varRef4 + varRef6 + 5) = (0 + 1 + 4 + 5) = 10
        (varRef1 + varRef3 + varRef5 + 12) = (3 + 9 + 1 + 12) = 25
        Total intermédiaire : varTotCalcul := (10 * 3) + 25 = 30 + 25 = 55
    Extraction du dernier chiffre :
        Si varTotCalcul >= 100 : Formate en 3 caractères, sinon en 2 caractères.
        Ici, varTotCalcul = 55, donc on utilise 2 caractères.
        Dernier chiffre de 55 : 5
    Calcul du code de contrôle :
        Si varTot = 0, alors varClé = 0
        Sinon, varClé := 10 - varTot
        Ici, varTot = 5, donc varClé := 10 - 5 = 5
    Formation du code GTIN :
        Formule : "GTIN" := '326231' + CopyStr(varRefArt, 1, 2) + CopyStr(varRefArt, 4, 4) + Format(varClé)
        Remplacement des valeurs :
        '326231' + CopyStr(varRefArt, 1, 2) + CopyStr(varRefArt, 4, 4) + Format(varClé)
        '326231' + 30 + 9114 + 5
        Code GTIN : '326231 + 309114 + 5'
*/

tableextension 50036 ItemExtension extends Item
{
    trigger OnInsert() // Trigger appelé lors de l'insertion d'un nouvel item
    // Déclaration des variables locales
    var
        varRefArt: Text[7];  // Extrait les 7 premiers caractères du champ "No." pour le calcul du GTIN.
        varTotCalcul: Integer;  // Utilisé pour calculer le total intermédiaire.
        varTot: Integer;  // Utilisé pour stocker le total après formatage.
        varClé: Integer;  // Utilisé pour stocker le code de contrôle final.
        varRef1: Integer;  // Partie du numéro de l'article.
        varRef2: Integer;  // Partie du numéro de l'article.
        varRef3: Integer;
        varRef4: Integer;
        varRef5: Integer;
        varRef6: Integer;
    begin
        // Initialisation des références pour le calcul du GTIN
        varRefArt := CopyStr("No.", 1, 7); // Extrait les 7 premiers caractères du numéro de l'article
        if StrPos(varRefArt, '-') > 0 then begin // Vérifie si le caractère '-' est présent dans les 7 premiers caractères
            // Extraction et conversion des caractères individuels en entiers
            Evaluate(varRef1, CopyStr(varRefArt, 1, 1)); // Convertit le premier caractère en entier
            Evaluate(varRef2, CopyStr(varRefArt, 2, 1)); // Convertit le deuxième caractère en entier
            Evaluate(varRef3, CopyStr(varRefArt, 4, 1)); // Convertit le quatrième caractère en entier
            Evaluate(varRef4, CopyStr(varRefArt, 5, 1)); // Convertit le cinquième caractère en entier
            Evaluate(varRef5, CopyStr(varRefArt, 6, 1)); // Convertit le sixième caractère en entier
            Evaluate(varRef6, CopyStr(varRefArt, 7, 1)); // Convertit le septième caractère en entier

            // Calcul du total intermédiaire en utilisant une formule spécifique
            varTotCalcul := ((varRef2 + varRef4 + varRef6 + 5) * 3) + (varRef1 + varRef3 + varRef5 + 12);

            // Extraction du dernier chiffre du total formatté
            if varTotCalcul >= 100 then
                Evaluate(varTot, CopyStr(Format(varTotCalcul, 3), 3, 1)) // formate le total en 3 caractères
            else
                Evaluate(varTot, CopyStr(Format(varTotCalcul, 2), 2, 1)); // formate le total en 2 caractères

            // Calcul du code de contrôle
            if varTot = 0 then
                varClé := 0
            else
                varClé := 10 - varTot;

            // Formation du code GTIN final
            "GTIN" := '326231' + CopyStr(varRefArt, 1, 2) + CopyStr(varRefArt, 4, 4) + Format(varClé);
        end else
            // Erreur si le caractère '-' n'est pas trouvé dans les 7 premiers caractères
            // Erreur si le format du numéro n'est pas valide.
            Error('Le format du numéro de l''article n''est pas valide. Utilisez le format 00-0000 afin de calculer le GTIN. Le format peut être changé dans la page No. Series (Page=456)');
    end;
}
