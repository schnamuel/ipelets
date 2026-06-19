# ipelets

* **annotate**: Includes a PDF file page by page and sets some attributes to be annotate-friendly.
* **arcs**: Connects two selected marks by an arc.
* **change width**: Allows to change the width of multiple minipages at the same time.
* **custom parser**: Some helper functions. Necessary for **layer sensitive grouping**
* **decoration_respecting_align**: Treats decorations as part of the bounding box when aligning objects. Also adds some new ways to align objects.
* **join paths**: Adds a shortcut to joinh multiple paths. 
* **layer sensitive grouping**: Overwrites the default Ipe behaviour vor grouping and ungeouping. A group is always places on the layer of the primary selection. Upon ungrouping the objects are places on their original layer (if that layer still exists). Requires **custom parser**. Might clash with other ipelets using the custom tag.
* **linecap**: Adds a shortcut for toggeling the linecap of a path between *round* and *normal*.
* **link**: Adds a shortcut for adding a link to an object.
* **list shortcuts**: Displays all shortcuts.
* **manipulate colors**: Grayscales or inverts the colors of the selected objects.
* **my goodies**: Implements slightly differrent behaviour for some of the functions from the classical **goodies** ipelet. The *regular k-gon* now creates n-gons such that one side is horizontal. The other functions operate on each selected object individually, i.e., *precise rotate* rotates each object around its own center instead of the center of the whole selection.
* **pick marks**: Overwrites the Ipe behaviour for picking attributs of a mark. It now picks the markshape in addition to the other attributes.
* **polygons**: Allows to reverse all arrows in the selection or to change a selected path to a closed polygon.
* **put marks in front**: Puts all marks on the current page in the front.
* **qr code**: Generates a qr code for a given link with the qrcode latex package. 
* **save without timestamp**: Changed the default Ipe behaviour to not save timestamps to make merging easier.
* **selector**: Allows to cycle through objects from top to bot or left to right using shortcuts.