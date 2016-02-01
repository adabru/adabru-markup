
[TOC]

# 2D-Spiel


## Cocos2D JS

`Cocos2D JS™` ist eine 2D Game-Engine für Windows, Android, … . Ein Beispiel dafür ist [MoonWarriors](http://www.cocos2d-x.org/wiki/MoonWarriors_-_Cocos2d-JS_Showcase).

![MoonWarriors Screenshot](./images/moonwarrior.jpg)



### Scene, Node, Sprite, Menu

Der Kern von [`Cocos2D JS™`](http://www.cocos2d-x.org) Spielen besteht aus den Komponenten `@Scene`, `@Node`, `@Sprite` und `@Menu`.

---

![Menü](./images/2n_main.jpg)
Hi Nikita!

--

![Menü](./images/2n_annotated_scaled.jpg)
Hi Tim Top! :)

--

![Menü](./images/2n_main_sprites_nodes.jpg)

---

Ein Spiel ist in mehrere `@Scene` aufgeteilt, die nacheinander durchlaufen werden.

![scenes](./images/scenes.png)

Das Beispiel-Bild zeigt, dass es eine `@Scene` am Anfang gibt (die *Intro*-`@Scene`). Dann wird das *Menu* gezeigt, wo man *Level 1* auswählen kann. Wenn man *Level 1* gewinnt, kommt man in die Übergangs-`@Scene` *Cutscene 1*, wo zum Beispiel "Level 1 bestanden!" steht. Danach kommt man nach *Level 2*. Wenn man ein Level verliert, kommt man in die *Losing cutscene*.

In der `@Scene` befinden sich die sichtbaren Spielobjekte. Wenn sich ein Spielobjekt bewegen kann (so wie die kleinen Figuren oben im Bild), dann ist es ein `@Sprite`. Wenn es sich nicht bewegen kann (so wie der Punktestand im Bild), dann ist es ein `@Node`.

```js
// Objekte zu einer Scene hinzufügen

var scene = new cc.Scene()

scene.addChild(title_node)
scene.addChild(highscore_node)
scene.addChild(enemy_sprite)
```

Ein `@Sprite` hat folgende Eigenschaften:

|Eigenschaft
`@anchor` | Punkt, um den das Bild gedreht wird
`@color` | Grundfarbe des Objektes
`@height` und `@width` | Größe des Objektes
`@opacity` | Durchsichtigkeit des Objektes
`@rotation` | Drehung des Objektes
`@scale` | Vergrößerung oder Verkleinerung des Objektes
`@skew` | Verzerrung des Objektes
`@position` | Position des Objektes
`@zIndex` | Anordnung des Objektes vor oder hinter anderen Objekten

---

### `@anchor`
![sprite anchor](./images/sprite_anchor.gif)

```js
// links
sprite.anchorX = 0
sprite.anchorY = 0

// mitte
sprite.anchorX = 0.5
sprite.anchorY = 0.5

// rechts
sprite.anchorX = 1
sprite.anchorY = 1
```
--

### `@color`
![sprite color](./images/sprite_color.png)

```js
// links
sprite.color = cc.color(255, 0, 0)

// mitte
sprite.color = cc.color(0, 255, 255)

// rechts
sprite.color = cc.color(123, 123, 123)
```

--

### `@opacity`
![sprite opacity](./images/sprite_opacity.gif)

```js
// ganz sichtbar
sprite.opacity = 1.0

// halb sichtbar
sprite.opacity = 0.5

// durchsichtig
sprite.opacity = 0
```

--

### `@rotation`
![sprite rotation](./images/sprite_rotation.jpg)

```js
// links
sprite.rotation = 0

// mitte
sprite.rotation = 90

// rechts
sprite.rotation = 240
```

--

### `@scale`
![sprite scale](./images/sprite_scale.png)

```js
sprite.scaleX = 2
sprite.scaleY = 0.5
```

--

### `@skew`
![sprite skew](./images/sprite_skew.jpg)

```js
sprite.skewX = 45
```

--

### `@position`
![sprite position](./images/sprite_position.png)

```js
// links
sprite.x = 0
sprite.y = 0

// rechts
sprite.x = 50
sprite.y = 100
```

--

### `@zIndex`
![sprite zindex](./images/sprite_zindex.png)

```js
// links
sprite.zIndex = 2

// mitte
sprite.zIndex = 7

// rechts
sprite.zIndex = 42
```

---

Einen `@Sprite` erzeugen und in die `@Scene` setzen, kann so aussehen:

```js
var mysprite = cc.Sprite.create("irgend_ein_bild.jpg")

// Nach oben links schieben:
mysprite.setPosition(0, scene.height)
// Größer machen:
mysprite.setScale(2.5)
// Drehen:
mysprite.setRotation(60)

scene.addChild(mysprite)
```



### Installation

Um den Code eines Spieles zu schreiben, ist ein Programm zum Schreiben nötig. Ein modernes Programm erleichtert die Arbeit. Eine gute Wahl ist `Atom™`.

---

### `Atom™` installieren

- Zuhause kann man von <https://atom.io> herunterladen
- In der Schule kann man die portable Version von [github](https://github.com/atom/atom/releases/download/v1.5.0-beta0/atom-windows.zip)

- Danach den Download-Ordner öffnen

--

### `zip`-Datei entpacken
![unzip](./images/atom_install_unzip.gif)

--

### `Atom™` starten
![start atom](./images/atom_install_start.gif)

--

### Verknüpfung erstellen
![desktop](./images/atom_install_shortcut.gif)

---

Zunächst das erste kleine Programm:

- Projektordner erstellen [⇖]((./images/cocos_projektordner.gif))
- [`Cocos2D JS™` Download](http://cocos2d-x.org/filecenter/jsbuilder/), Full Version, v3.10 [⇖]((./images/cocos_download.gif))
- `cocos2d-js-v3.10.js↑` und `HelloWorld.png↑` in den Projektordner kopieren [⇖]((./images/cocos_copy.gif))
- `Atom™` starten
- Folgenden Code hineinkopieren:

```html
```↑ ./downloads/examples/beispiel001.html nocomments

Hier noch die Erklärungen:

```html
```↑ ./downloads/examples/beispiel001.html

- Datei im Projektordner als `MeinSpiel.html↑` speichern
- `MeinSpiel.html↑` im Browser öffnen [⇖]((./images/cocos_tobrowser.gif))



### Action

Um ein `@Sprite` zu beleben, verwendet man `@Action`. Es gibt viele verschiedene `@Action`.

|Action
`@moveBy` | Bewegen
`@blink` | Blinken
`@fadeTo` | Ein- und Ausblenden
`@rotateBy` | Drehen
`@scaleTo` | Vergrößern oder Verkleinern
…|…

![Action](./images/action.gif)

```js
// In 0.5 Sekunden einmal rundherumdrehen:
var drehen = cc.rotateBy(0.5, 360)
// Danach in 0.2 Sekunden 20 Pixel nach oben bewegen:
var nachoben = cc.moveBy(0.2, 0, 20)
// In 0.5 Sekunden um 10% Vergrößern
var groesser = cc.scaleBy(0.5, 1.1, 1.1)

// Aktion anwenden:
mysprite.runAction(drehen)
mysprite.runAction(nachoben)
mysprite.runAction(groesser)
```

Um mehrere `@Action` nacheinander auszuführen, sollte man sie in in eine `@Sequence` packen.

```js
var nacheinander = cc.sequence(drehen, nachoben, groesser)

mysprite.runAction(nacheinander)
```

Um mehrere `@Action` gleichzeitig auszuführen, sollte man sie in in eine `@Spawn` packen.

```js
var gleichzeitig = cc.spawn(drehen, nachoben, groesser)

mysprite.runAction(gleichzeitig)
```

Um eine `@Action` ohne Ende zu wiederholen, verwendet man `repeatForever`.

```js
mysprite.runAction(gleichzeitig.repeatForever())
```

### Farben

### Nachschlagen

- Das [original Handbuch](http://www.cocos2d-x.org/programmersguide/2/index.html).
- Alle [Elemente](http://www.cocos2d-x.org/reference/html5-js/V3.8/index.html), die man zum Programmieren verwenden kann (die sogenannte `@API`).
- [Mehr als 100 kleine Beispiele](http://cocos2d-x.org/js-tests/) (der Beispielcode ist im Kontext von `director._runningScene._children[0]`).
- [Videos](https://www.youtube.com/playlist?list=PLRtjMdoYXLf7n9bghH1k63kisb-VDzGu1) von Sonar Systems. In den Videos wird allerdings eine andere Version von `Cocos2D™` verwendet.
- [Game of Life Tutorial](https://www.makeschool.com/tutorials/learn-cocos-studio-and-c-by-building-the-game-of-life/game-of-life-code)

[`Cocos2D JS™` download](http://cocos2d-x.org/filecenter/jsbuilder/).

Erste Beispiele sind folgende:

- [Hallo](./app/webpad/webpad.php?project=hallo)-Beispiel
- [Sprite](./app/webpad/webpad.php?project=sprite)-Beispiel
- [Action](./app/webpad/webpad.php?project=action)-Beispiel
- [Mausklick](./app/webpad/webpad.php?project=mouse)-Beispiel
