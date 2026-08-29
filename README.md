# Zsírozás (Godot 4.7.2, MVC)

Magyar "Zsírozás" / "Zsír" kártyajáték 2 emberi játékosra, ugyanazon a
gépen ("pass & play"). Szabályok forrása:
https://www.pagat.com/sedma/zsirozas.html

## Futtatás

1. Nyisd meg a `zsirozas` mappát a Godot 4.7.2 szerkesztőben (Import ->
   válaszd ki a `project.godot` fájlt).
2. F5 vagy a Play gomb.
3. A főmenüből indítsd az "Új játék"-ot.

## Játékmenet / kezelőfelület

- **Húzd-és-ejtsd**: a saját (alul, nyitva látszó) lapjaidat az asztal
  közepére kell húznod a kijátszáshoz.
- **Adatvédelmi képernyő ("Felfedés" gomb)**: amikor a másik játékoson
  a sor, egy takaró képernyő jelenik meg - add tovább a gépet, és a
  soron következő játékos nyomja meg a Felfedés gombot, hogy lássa a
  saját lapjait.
- **"Folytatod?" gombpár**: ha az ellenfeled ütné az asztalon lévő
  lapokat, de neked van még illeszkedő rangú lapod (vagy hetesed),
  eldöntheted: folytatod-e az ütést (Igen - utána húzd be a megfelelő
  lapot), vagy engeded az ellenfélnek (Nem).
- A talonból húzás automatikus az ütés után (mindenki négy lapra
  egészül ki, az ütés győztesével kezdve).
- Egy leosztás a teljes pakli elfogyásáig tart, utána a több zsírt
  (ász/tízes) szerző fél nyer (40-40-nél az utolsó ütés győztese dönt).

## Architektúra (MVC)

```
scripts/
  model/          <- tiszta adat + szabálylogika, semmilyen Node-függés
    card_data.gd      Suit/Rank enum, érték, rang-egyezés (hetes = vad lap)
    deck.gd            32 lapos pakli / talon
    player_model.gd    kéz, megszerzett lapok, pontszám
    trick_state.gd      az éppen zajló (több körös) ütés állapota
    game_model.gd        teljes játékállapot, fázisok (enum Phase)

  controller/
    game_controller.gd  a játékmenet állapotgépe - EZ ismeri a szabályokat.
                         Publikus API: start_new_game(), try_play_card(),
                         decide_continue(). Signalokkal értesíti a View-t.

  view/           <- csak megjelenítés, sosem módosítja közvetlenül a Modelt
    card_view.gd        egy lap képe + drag&drop
    hand_view.gd         egy kéz sora (nyitva vagy hátlappal)
    trick_area_view.gd    az asztal közepe / drop-zone
    score_panel.gd        pontszám + talon kijelző
    handoff_overlay.gd    "add tovább a gépet" képernyő
    continue_prompt.gd    "Folytatod?" Igen/Nem
    game_view.gd           a Game.tscn gyökere - összeköti a fentieket
    main_menu_view.gd, result_view.gd

  autoload/
    scene_manager.gd     jelenetváltás (főmenü / játék / eredmény)

scenes/
  main_menu.tscn, game.tscn, result_screen.tscn
  (mindegyik csak egy gyökér Control + a hozzá tartozó script - a teljes
   UI-t a script építi fel _ready()-ben, hogy ne kelljen kézzel .tscn
   fájlokat szerkeszteni)

assets/cards/    <- 32 lap + hátlap, forrás:
  https://github.com/tomasdrus/hungarian-playing-cards (cards-medium,
  181x293px, átlátszó PNG). FONTOS: a repo-ban nincs feltüntetve
  explicit licenc - saját, nem kereskedelmi célú projekthez rendben
  van, de nyilvános megjelentetés előtt érdemes utánajárni / a
  szerzőt megkeresni.
```

## Ismert korlátok / amit még nem tud

- Csak 2 emberi játékos, ugyanazon a gépen (pass & play). Nincs AI, és
  nincs hálózati/online mód.
- Nincs 4 fős / párosos mód (a szabályokban szereplő "üss!" / "ne
  üss!" / "zsírt!" / "ne zsírt!" jelzések így nem relevánsak még).
- Egy meccs = egy leosztás (nincs többfordulós 5/10 pontig tartó
  meccs-rendszer, bár a `GameController._finish_hand()` már
  kiszámolja a kopasz/csupasz eredményt is, erre könnyen ráépíthető).
- Nincs animáció a lapmozgásra (azonnal a célra ugranak), nincs hang.

## Roadmap (a beszélgetés alapján)

1. 4 fős / páros mód: a `GameModel` és `GameController` már 2
   játékossal dolgozik `players: Array[PlayerModel]` formában és
   `opponent_index()`-szel - ezt kell 4 főre és csapat-logikára
   (`team_of(player_index)`) bővíteni, plusz be kell vezetni az "üss!"
   / "zsírt!" jelzéseket parterek között.
2. AI ellenfél: mivel a Controller sosem tudja, hogy egy adott
   `PlayerModel` mögött ember vagy gép áll (csak `try_play_card` /
   `decide_continue` hívásokat kap), egy külön `AIPlayer` osztály
   könnyen "helyettesítheti" az emberi inputot ugyanazon az API-n
   keresztül - nem kell a Controller-t átírni.
3. Többfordulós meccs 5 (vagy 10) pontig, pontszabály szerint
   (40-70 pont = 1 pont, kopasz = 2 pont, csupasz = 3 pont).
