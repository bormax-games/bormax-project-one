# Práce s branchemi
Abychom nemuseli řešit tolik konfliktů a mohli pracovat paralelně, vyzkoušíme si práci s větvemi (branch).

## Git LFS (Large File Storage)
Abychom nezasekali historii repozitáře velkými soubory (textury, modely, zvuky), používáme Git LFS. 

* **Instalace:** Každý programátor si musí jednorázově nainstalovat Git LFS do systému (na Linuxu: `sudo apt install git-lfs`).
* **Aktivace:** Po instalaci je **nezbytné** v terminálu (ve složce projektu) spustit příkaz `git lfs install`.
* **Proč to děláme:** Bez tohoto kroku se vám místo obrázků a zvuků stáhnou jen malé textové soubory (zástupci) a Godot bude hlásit chyby při importu.
* **Kontrola:** V souboru `.gitattributes` v kořenu projektu je definováno, které přípony (např. `.png`, `.wav`, `.blend`) se mají přes LFS ukládat.

## Workflow
Na každou novou featuru, nebo úkol si vytvoříme novou branch.
- Jméno branch bude mít tento formát: `nickname_programatora/popis-featury`
- Všechny změny commituju a pushuju pouze do te svoji branche
- Kdyz mam pocit, ze mam hotovo, tak vytvořím pull request
- V pull requestu popíšu, na čem jsem dělal (v bodech) a nastavím někoho na review
- Když to reviewer zkoukne, tak se obsah branch mergne do mainu
- Před mergem vyřeším konflikty

## Proč je to dobré?
- můžeme pracovat paralelně a neřešit tolik konflikty
- v mainu je vždy aktuální funkční verze aplikace
- každý kód uvidí vždy vícero členů týmu, takže budeme mít větší přehled o tom, co se děje (a jak)

## JAK DELAT REBASE
- `git commit` vsechny svoje zmeny
- `git rebase origin/main` - to origin je dulezite!!!
- pokud to napise, ze nejde rebasnout, tak se obrat na Ivana
- pokud rebase probehl v pohode `git push --force` - NEZBYTNE!!!!

## JAZYK
Vse budeme psat v anglictine (abychom udrzeli konzistentnost v kodu):
- nazvy promennych, funkci, trid, ...
- commit message - presne podle tutorialu jak jsme meli na uvodu do linuxu
- nazvy branche take budou v AJ 
