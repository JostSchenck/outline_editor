`outline_editor` is a package based
on [SuperEditor](https://github.com/superlistapp/super_editor)
that adds functionality for collapsing and expanding of text based on its structure, as well as 
presenting text in an "outline" style.

To realize this, outline_editor needs to know about the structure of a document;
`SuperEditor`, however, treats documents strictly as a flat list of nodes. Like SuperEditor, this
package does not want to impose any constraints on the `Document` implementation used.
Instead, it expects the `Document` to implement an `OutlineDocument` interface that presents
its state in a hierarchical manner; this can eg. happen based on paragraphs with "heading" 
metadata, or on nested data structures. If outline_editor does not come with an implementation that 
suits your needs, just make your Document class implement the OutlineDocument interface.

TThe tree structure is stored in "Treenodes", which can contain super_editor's DocumentNodes (one 
as a title, the rest as content). For the case that OutlineTreenode must be extended, 
OutlineDocument and OutlineTreeDocument are parameterized.  

## Usage

To create an outline editor in your app, you must first create a [Document] of a class that 
implements the [OutlineDocument] interface and create a corresponding [Editor], usually in
the [State] class of your outline editor view. You can eg. use 
[OutlineTreeDocument], which implements the [MutableDocument] interface to also present its 
content as a flat list of nodes towards super_editor.

For details, for now see the example app.


## Gedanken zur Entwicklung

Ich habe hier unterschiedliche Funktionen, bei denen ich prüfen muss, wo ich sie in die
SuperEditor-Pipeline integriere:

- *Verändern* der Dokumentstruktur: Ich werde jedenfalls bei einem Outliner neue Commands erstellen
  müssen, die Veränderungen der Dokumentstruktur mit in der Folge Umstellen von Nodes vornehmen,
  denn ein "Ausrücken" von Kindern schiebt sie z.B. oft nach unten als nächstes Geschwisterkind des
  vorherigen Elternknotens. Es ist wünschenswert, diese Logik zentral anzubieten, da wahrscheinlich
  einige Commands darauf werden zurückgreifen müssen. Es ist außerdem wünschenswert, diese Logik von
  der konkreten `OutlineDocument`-Implementierung getrennt zu halten, weil durchaus ein Bedürfnis
  nach unterschiedlichen Kombinationen von Strukturgenerierung und Bearbeitungslogik bestehen
  können.
- Der eigentliche Folding-Zustand: Abschnitte können ein- oder ausgeklappt sein und das ist Zustand,
  der gegebenenfalls auch programmatisch gesteuert werden muss (nicht nur in einem StetefulWidget).
  Er gehört deshalb in ein `Editable`; leider haben ComponentBuilders keinen Zugriff auf beliebige
  Editables, so dass ich den Folding-Zustand wahrscheinlich im Document aufbewahren muss.
- Auswahlverhalten: Bei einem klassischen Outline-Dokument riskiere ich unerwünschte Ergebnisse,
  wenn ich beliebige Selektionen über Node-Grenzen hinweg (z.B. auch über Kinder und Eltern hinweg)
  erlaube. Outliner wie dynalist selektieren deshalb z.B. alle Abkömmlinge, wenn ich mit der
  Selektion von einem Kind in den Eltern-Node komme; Tana wiederum macht es nochmal anders.
  Evl. wäre es gut, mehrere `Reaction`s anzubieten, die jeweils die `Selection` verändern können, so
  dass der Entwickler wählen kann, welche für ihn sinnvoll ist.
