`structured_text_editor` is a package based
on [SuperEditor](https://github.com/superlistapp/super_editor)
that adds functionality for folding of text based on its structure, as well as presenting text
in an "outline" style.

To realize this, structured_text_editor needs to know about the structure of a document;
`SuperEditor`, however, treats documents strictly as a flat list of nodes. Like SuperEditor, this
package does not want to impose any constraints on the `Document` implementation used.
Instead, it expects a `DocumentStructure` that listens to the `Document` and translates
its state into a hierarchical representation; this can eg. happen based on paragraphs with a "
heading" metadata, or on some specific implementation of `MutableDocument` in nested data
structures. If structured_text_editor does not come with an implementation that suits your needs,
you can just derive from ´DocumentStructureProvider` and roll your own.

Other parts of structured_text_editor operate on this representation: A `SingleColumnFoldingLayout`
that replaces SuperEditor's standard SingleColumnLayout, presents the widgets in a tree instead of a
simple list of widgets.

> This project is currently based on a **slightly modified fork of SuperEditor** (stable
> development branch) that I try to keep in sync regularly. This is necessary because right now
> SuperEditor does not yet allow for providing a custom `DocumentLayout` implementation. As soon as
> this problem is solved, this project will switch to depending on the original repo or a future pub
> package.

## Gedanken zur Entwicklung

Ich habe hier unterschiedliche Funktionen, bei denen ich prüfen muss, wo ich sie in die
SuperEditor-Pipeline integriere:

- *Darstellung* der Baumstruktur: Das ist eine Aufgabe der Layout-Klasse, keine der Komponenten.
  Wird implementiert in `SingleColumnFoldingLayout`.
- *Ermitteln* der Dokumentstruktur: Dies muss abgekoppelt sein von einer konkreten
  Document-Implementierung, um meine Erweiterung format- und implementierungsagnostisch zu halten.
  Die Logik wird gekapselt in einer `DocumentStructure`. Die Frage ist, wo ich diesen andocke:
    - Als `Reaction`? Von diesen sind regelmäßig als Raktion weitere Eingriffe in die
      Dokument-Struktur zu erwarten. Das sehe ich eigentlich erstmal nicht -- wobei ich es nicht für
      ausgeschlossen halte, dass Commands Dinge ändern, die Anlass geben, nicht nur die Struktur
      anzupassen, sondern bestimmte Daten auch durch die Struktur korrigierend zurückzuschreiben.
      Allerdings sollten Korrekturen von Fehlern der vorgelagerten Stufen hier nicht erfolgen,
      sondern die Ursache behoben werden. Außderdem gilt, solange ich keinen Anwendungsfall habe,
      YAGNI - you ain't gonna need it.
    - Alternative: Als `Listener`. Diese verändern das Dokument nicht. Wenn ich zum Schluss komme,
      dass es für Änderungen an dieser Stelle keinen wirklich legitimen Grund gibt, sollte ich
      hierauf gehen.
      Hierfür spricht auch, dass es die Gefahr von Zirkeln vermindert, und allgemeine Erwägungen
      einer Separation of Concerns.
- *Verändern* der Dokumentstruktur: Ich werde jedenfalls bei einem Outliner neue Commands erstellen
  müssen, die Veränderungen der Dokumentstruktur mit in der Folge Umstellen von Nodes vornehmen,
  denn ein "Ausrücken" von Kindern schiebt sie z.B. oft nach unten als nächstes Geschwisterkind des
  vorherigen Elternknotens. Es ist wünschenswert, diese Logik zentral anzubieten, da wahrscheinlich
  einige Commands darauf werden zurückgreifen müssen. Es ist außerdem wünschenswert, diese Logik von
  meinem `DocumentStructureProvider` getrennt zu halten, weil durchaus ein Bedürfnis
  nach unterschiedlichen Kombinationen von Strukturgenerierung und Bearbeitungslogik bestehen
  können. Effektiv ist das so eine Art Controller, oder?
- Der eigentliche Folding-Zustand: Abschnitte können ein- oder ausgeklappt sein und das ist Zustand,
  der gegebenenfalls auch programmatisch gesteuert werden muss (nicht nur in einem StetefulWidget).
  Er gehört deshalb in ein `Editable`.
- Auswahlverhalten: Bei einem klassischen Outline-Dokument riskiere ich unerwünschte Ergebnisse,
  wenn ich beliebige Selektionen über Node-Grenzen hinweg (z.B. auch über Kinder und Eltern hinweg)
  erlaube. Outliner wie dynalist selektieren deshalb z.B. alle Abkömmlinge, wenn ich mit der
  Selektion von einem Kind in den Eltern-Node komme; Tana wiederum macht es nochmal anders.
  Evl. wäre es gut, mehrere `Reaction`s anzubieten, die jeweils die `Selection` verändern können, so
  dass der Entwickler wählen kann, welche für ihn sinnvoll ist.

## Wichtige aktuelle Anliegen:

### Am Design arbeiten

- [X]  `super_editor` nochmal analysieren: Wie funktioniert die ganze Editing-Pipeline? Was wäre der
  *saubere Weg*, um Veränderungen in einem `FoldingState` Editable durchzuführen, und entsprechende
  Änderungen dann wieder in der Ansicht zu berücksichtigen?
- [X]  Veränderungen im DocumentFoldingState: `EditCommand`s erhalten in ihrer execute-Methode
  einen `EditContext` übergeben. Über diesen kann mit dem documentFoldingStateKey auf
  den `DocumentFoldingState` zugegriffen werden. Und EditCommands dürfen auf Editables dann
  unmittelbar arbeiten.
- [X]  Wie kommen Änderungen wieder an? Das betreffende Editable sollte ein `ChangeNotifier` sein;
  mein Layout sollte sich dort registrieren.
- [X]  _buildDocComponents sollte nur noch die sichtbaren Komponenten bauen und dafür auf
  edit.foldingState zurückgreifen; dafür sollte foldingState.addListener einfach einen setState()
  ausführen.

### JETZT

- [ ] Standard-Commands für Struktur-Befehle
    - [ ] ODER jetzt wieder mit eigentlicher Eurynome-App anfangen unter Verwendung der Library?
      Diese Befehle sind wahrscheinlich anwendungsspezifisch!
- [X]  Caret-Movements von Node-wise auf Component-Wise umbauen, Sachen aus CommonOps in meine
  Extension rübernehmen
- [X]  HideableNodeWidget sollte state in DocumentFoldingState speichern (draus lesen und rein
  schreiben)

### Layout-Klasse ausgeblendete Components überspringen lassen

Hierfür müssen einige Methoden überarbeitet werden:

- [X]  _findFirstPosition kann so bleiben, erster Node ist *nie* ausgeblendet
- [ ]  _findLastPosition
- [ ]  _findComponentClosestToOffset(documentOffset)
- [ ]  _isBeyondDOcumentEnd - muss ausgeblendete Komponenten überspringen, oder diese tauchen nich
  in _topToBottomComponentKeys auf
- [ ]  getEdgeForPosition - entweder mache ich das so, dass diese Methode `null` zurückgibt, wenn
  die übergebene DocumentPosition auf eine eingeklappte Komponente zeigt. Oder aber das Layout
  entscheidet, in solchen Fällen erst auszuklappen, bevor es die Edge zurückgibt. Vielleicht erstmal
  ersteres ausprobieren.
- [ ]  getRectForPosition - siehe oben
- [ ]  getRectForSelection - wie gehe ich mit einer Selection, die vollständig, teilweise bzw.
  überlappend oder aber ganz umfassend über einem eingeklappten Bereich liegt. Hier spricht einiges
  dafür, darauf zu achten, dass eine Selection, die ein Parent und eins seiner Children umfasst,
  zwangsläufig alle Children ganz umfasst.

### DocumentStructure zu einem Listener machen

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart

const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
