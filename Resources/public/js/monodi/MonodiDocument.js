// General convention: If an element is required as a parameter, an ID, HTML node or MEI node is accepted.
// If an HTML node is supplied, the ID of this node or of its closest ancestor with an ID
// is used to find the corresponding MEI element.

/*jslint vars:true, browser:true, indent:2 */
/*global HTMLElement: false, SVGElement: false, Element: false, Node: false, Document: false,
         XPathResult: false, XSLTProcessor: false,
         DOMParser: false, XMLSerializer: false */

(function(){
  "use strict";

  window.MonodiDocument = function(parameters) {
    /* params is a "JSON object" that can have the following fields:
       - one of meiUrl, meiString, meiDOM:
         A document to load.
         (Optional. Document can be loaded later using .loadDocument())
       - staticStyleElement, dynamicStyleElement and musicContainer:
         Two style elements are needed, one for CSS that remains as is,
         one for changing CSS for highlighting/selection etc.
         (Optional, but required if document is to be rendered)
       - one of xsltUrl, xsltString, xsltDOM
       - renderingParameters: A JSON sub-object with all the parameters
         that shall be supplied to the XSLT transformation
         (see the .xsl file for all the available parameters)
       - idPrefix: An optional prefix that will be added to all IDs by
         mono:di.js to prevent ID clashes.
    */


    var mei, // The MEI document.
        musicContainer = null,
        staticStyleElement = null,
        dynamicStyleElement = null,
        xsltProcessor,
        idPrefix,
        idPrefixLength,
        selectionStyle = parameters.selectionStyle || "color:red",
        selectedElement,
        self = this;

    var PITCH_NAMES = ["c","d","e","f","g","a","b"],
        PITCH_VALUES = {},
        i;
    for (i=0; PITCH_NAMES[i]; i+=1) {
      PITCH_VALUES[PITCH_NAMES[i]] = i;
    }

    // To this list, "event handlers" will be added that shall be called after any visualization refresh.
    var callbacks = {
      updateView: [],
      deleteAnnotatedElement: []
    };

    var xmlNS = "http://www.w3.org/XML/1998/namespace";
    var meiNS = "http://www.music-encoding.org/ns/mei";

    //////// "Private methods" and variables //////////

    function error(message) {
      throw new Error(message);
    }

    function evaluateXPath(contextNode, xpath){
      // We make evaluate() more convenient and return the xpath result as an array
      if (!contextNode) {return [];}
      var i;
      var contextDocument = (contextNode.ownerDocument || contextNode);
      var result;
      try {
        result = contextDocument.evaluate(xpath, contextNode, function(nsPrefix) {
          return {
            xml:"http://www.w3.org/XML/1998/namespace",
            mei:"http://www.music-encoding.org/ns/mei"
          }[nsPrefix];
        }, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);
      } catch(error) {
        throw new Error(error.message + ". Illegal XPath expression: " + xpath);
      }
      var resultArray = [];
      for (i=0; i<result.snapshotLength; i+=1) {
        resultArray.push(result.snapshotItem(i));
      }
      return resultArray;
    }

    function loadXML(parameters) {
      // Returns an XML document
      // QUESTION: Make this asynchronous?
      if (parameters.xmlUrl) {
        var xmlHttpRequest = new XMLHttpRequest();
        xmlHttpRequest.open("GET",parameters.xmlUrl,false);
        if (parameters.mime) {xmlHttpRequest.overrideMimeType(parameters.mime);}
        xmlHttpRequest.send(null);
        if (xmlHttpRequest.status === 200) {
          if (xmlHttpRequest.responseXML) {
            return xmlHttpRequest.responseXML;
          }
          var parser = new DOMParser();
          return parser.parseFromString(xmlHttpRequest.response,"text/xml");
        }
        throw new Error("Could not load file " + parameters.xmlUrl);
      }
      return (new DOMParser()).parseFromString(parameters.xmlString,"application/xml");
    }

    function $ID(element) {
      // Takes an ID, an HTML or an MEI element and returns the proper ID.
      if (element instanceof HTMLElement || element instanceof SVGElement) {
        return evaluateXPath(element,'ancestor-or-self::*[@id][1]/@id')[0].value.substr(idPrefixLength);
      }

      if (element instanceof Element && element.namespaceURI === meiNS) {
        return element.getAttributeNS(xmlNS,"id") || error(element.nodeName + " element has no ID.");
      }

      if (typeof(element) === "string") {
        return element;
      }
      throw new Error("Object supplied to $ID could not be mapped to an ID.");
    }

    function $MEI(element, expectedElementName, errorMessage) {
      // Takes an ID, an HTML or an MEI element and returns the proper MEI element.
      if (element instanceof HTMLElement) {
        element = $ID(element);
      }

      if (typeof(element) === 'string') {
        element = evaluateXPath(mei,"//*[@xml:id='"+element+"']")[0];
      }

      if (element instanceof Element && element.namespaceURI === meiNS) {
        if (!expectedElementName || element.localName === expectedElementName) {
          return element;
        }
        throw new Error(                         // TODO: Check whether getAttribute("xml:id") actually works in FF and Chrome
          element.localName + " element " + element.getAttribute("xml:id") + ":" + (
            errorMessage || "Expected " + expectedElementName + " element, but got " + element.localName + " element."
          )
        );
      }/* else {
        throw new Error("Object supplied to $MEI could not be mapped to an MEI element.");
      } */ // Because we also use $MEI() to test for the existence of an element, we don't throw an error here.
    }

    function $HTML(element) {
      // Takes an ID, an HTML or an MEI element and returns the proper HTML element.
      if (element instanceof Document) {
        return musicContainer.firstElementChild;
      }
      
      if (element instanceof HTMLElement) {
        return element;
      }

      if (element instanceof Element) {
        element = $ID(element);
      }
      return document.getElementById(idPrefix + element) || error("Object supplied to $HTML can not be mapped to an HTML element.");
    }

    function setNewId(element) {
      // This function adds an ID to an MEI element so that it can be uniquely identified.
      // It replaces any existing ID, therefore this function should only be called for elements
      // that indeed should get a new ID.
      // TODO: More careful ID generation?
      var newId = "";
      do {
        newId = idPrefix + "mei" + new Date().getTime() + Math.floor((Math.random()*10000));
      } while ($MEI(newId)); // We must avoid IDs that already exist
      element.setAttributeNS(xmlNS,"xml:id",newId);
      return element;
    }

    function createMeiElement(xmlText) {
      xmlText = "<mei xmlns='http://www.music-encoding.org/ns/mei'>" + xmlText + "</mei>";
      var newElement = (new DOMParser()).parseFromString(
        xmlText, 
        "application/xml"
      ).documentElement.firstElementChild;
      
      var elementsWithoutIds = evaluateXPath(newElement,"descendant-or-self::*");
      var i;
      for (i=0; i<elementsWithoutIds.length; i+=1) {
        setNewId(elementsWithoutIds[i]);
      }
      
      return newElement;
    }

    function callUpdateViewCallbacks(element) {
      var i;
      for (i=0; i<callbacks.updateView.length; i+=1) {
        callbacks.updateView[i]($HTML(element));
      }
    }
    

    function isDrawable() {
      // Checks whether everything we need for drawing is there
      return musicContainer && staticStyleElement && dynamicStyleElement && mei && true;
    }

    function transform(transformNode, specialIdPrefix){
      // "raw" method for transforming MEI to HTML/SVG.
      // It's called when initializing the view and by refresh as well as when printing.
      // transformNode is either an ID, a document node or a "tag" (like "<music>")
      // When a "tag" is supplied, the transformation will transform the first element with the supplied tag name.
      var meiDocument;

      xsltProcessor.setParameter(null, "idPrefix", (specialIdPrefix === undefined) ? idPrefix : specialIdPrefix);
      if (transformNode instanceof Document) {
        meiDocument = transformNode;
        xsltProcessor.removeParameter(null,"transformNode");
      } else {
        meiDocument = mei;
        xsltProcessor.setParameter(null,"transformNode",$ID(transformNode));
      }
      meiDocument = meiDocument || mei;
      return xsltProcessor.transformToFragment(meiDocument,document).firstChild;
    }

    function refresh(element) {
      if (!isDrawable()) {return;}
      // If an element was supplied, hand this on to the transform method.
      // If nothing was specified, we want to refresh the full body.
      
      // As any changes inside a uneume might affect the whole group (especially slurs),
      // for any changes of notes inside a uneume, we refresh the whole uneume
      element = element ? evaluateXPath(
        $MEI(element),
        // As the content of uneue influences the rendering of slurs, 
        // we have to refresh the whole uneume whenever something inside changes
        "(.|ancestor::mei:uneume)[1]"
      )[0] : "<mei>";
      
      var htmlElement;
      switch (element.nodeName || element) {
        case "<mei>":
          htmlElement = musicContainer.firstElementChild;
          break;
        case !element.hasAttribute("source") && "sb":
          // transform() will return a whole line of music for edition <sb>s.
          // The whole line is wrapped into the parent element of the HTML element corresponding to the <sb> element.
          htmlElement = $HTML(element).parentElement; 
          break;
        default:
          htmlElement = $HTML(element);
      }
      
      htmlElement.parentElement.replaceChild(transform(element), htmlElement);
      callUpdateViewCallbacks(element);
    }

    function insertElement(newElement, p) {
     /* p can have the following fields:
      * - contextElement: If some of the fields in p are supplied as XPaths, contextElement must be provided. 
      *                   It will be the context node for evaluating the XPaths.
      * - followingSibling: The element before newElement is to be inserted. Must be a child of 
      * - parent: The node where we want to insert the element into. Can be an element or an XPath.
      */
      var precedingSibling = p.precedingSibling && evaluateXPath(p.contextElement, p.precedingSibling)[0];
      var followingSibling = p.followingSibling ? (
                              p.followingSibling instanceof Element ? p.followingSibling : evaluateXPath(p.contextElement, p.followingSibling)[0]
                            ) : precedingSibling && precedingSibling.nextElementSibling;

      var parent = p.parent ? (
                    p.parent instanceof Element ? p.parent : evaluateXPath(p.contextElement, p.parent)[0]
                  ) :
                  followingSibling ? followingSibling.parent : precedingSibling.parent;
      if (!parent) {
        throw new Error("Can not insert " + p.contextElement.localName + " element. No matching parent found in.");
      }

      parent.insertBefore(newElement, followingSibling);

      refresh(p && p.refresh ? (
                p.refresh instanceof Element ? p.refresh : evaluateXPath(p.contextElement, p.refresh)[0]
             ) : parent
      );
      return newElement;
    }

    function addSourceAttribute(element) {
      var sourceIdAttribute = evaluateXPath(mei, "//mei:source[1]/@xml:id[1]")[0];
      element.setAttribute("source","#" + (sourceIdAttribute.textContent || error("No source ID found.")));
      return element;
    }
    
    function removeDummyState(element) {
      evaluateXPath($MEI(element), "descendant-or-self::mei:note[@label='dummy']").forEach(function(note){
        note.removeAttribute("label");
      });
    }
    
    function removeDummyNotes(element) {
      var ineumesWithDummy = evaluateXPath(
        element ? $MEI(element) : mei, 
        "(descendant-or-self::mei:ineume|ancestor::mei:ineume)[descendant::mei:note/@label='dummy']"
      ),
      i;
      
      for (i=0; i<ineumesWithDummy.length; i+=1) {
        var parent = ineumesWithDummy[i].parentNode; 
        parent.removeChild(ineumesWithDummy[i]);
        refresh(parent);
      }      
    }

    function checkIfElementCanBeDeleted(element) {
      /* When deleting we have to check, whether deleting the element affects annotations that are anchored on the element.
       *   If so, we have to ask the user via a callback whether to proceed and delete the 
       *   annotation or anchor it to a different element. 
       */
      
      element = element ? $MEI(element) : selectedElement;
      
      // For syllable elements we check whether we have at least one neighboring syllable element.
      // If not, we don't wan to delete as we'd get a line without a syllable which we don't support
      // as the user needs at least one syllable to select for adding content to the line. 
      if (element.nodeName === "syllable" && evaluateXPath(
        element, 
        "(following-sibling::*[1]|preceding-sibling::*[1])[self::mei:syllable]"
      ).length === 0) {
        return false;
      }
      
      // We check whether one of the IDs that we find inside the element we want to delete 
      // is referenced by another element (namely annotations).
      var ids = evaluateXPath(element, "descendant-or-self::*/@xml:id");
      // We don't want the IDs as attribute nodes, so we extract their values as strings
      var i;  
      for (i=0; i<ids.length; i+=1) {
        ids[i] = ids[i].value;
      }
      var referencingElements = evaluateXPath(
        mei, 
        "//@*[ " + 
          "local-name()='startid' or local-name()='endid' " +
        "][ " +
          ".='#" + ids.join("' or .='#") + "'" +
        "]/parent::*"
      );
      
      // Some annotations can be deleted without problems because they're still attached to a second element
      // We're indexing backwards because we'll possibly delete elements from the array, 
      // which would make the loop skip some elements when going forward
      for (i=referencingElements.length - 1; i>=0; i-=1) {
        var startid = referencingElements[i].getAttribute("startid").substring(1), // @startid/@endid are anyURIs, so they have 
            endid   = referencingElements[i].getAttribute("endid"  ).substring(1), //   a preceding "#" that we have to delete.
            startidIsNotPointingToDeletion = ids.indexOf(startid) < 0,
            endidIsNotPointingToDeletion   = ids.indexOf(endid  ) < 0;
        
        if (startidIsNotPointingToDeletion || endidIsNotPointingToDeletion) {
          // We move the start or end of the annotation (depending on what will not be deleted)
          var idRemainingValid = startidIsNotPointingToDeletion ? startid : endid;
          referencingElements[i].setAttribute(
            startidIsNotPointingToDeletion ? "endid" : "startid",
            "#" + idRemainingValid
          );
          referencingElements.splice(i,1);
          refresh(idRemainingValid);
        } 
      }
      
      if (referencingElements.length > 0) {
        if (callbacks.deleteAnnotatedElement.length === 1) {
          if (callbacks.deleteAnnotatedElement[0](referencingElements, element)) {
            for (i=0; i<referencingElements.length; i+=1) {
              self.deleteElement(referencingElements[i], true);
            }
            return true;
          }
        }
        throw new Error("Exactly one callback for deleteAnnotatedElement is required, but " + callbacks.deleteAnnotatedElement.length + "were defined.");
      }
      
      return true;
    }

    function removeEmptyElements(element) {
      // This will delete any elements inside syllables that don't have content
      // (i.e. no notes, system/page breaks, no text in syl element)
      // The currently selected element will not be deleted.
      var emptyElements = evaluateXPath(
        element ? $MEI(element) : mei,
        // The context element might either be inside or outside of a syllable element.
        // If it's inside, then we only want this syllable to be checked for empty elements,
        // if it's outside, then we want to basically check all syllables.
        // All our syllables are living inside one common layer element.  
        "(ancestor-or-self::mei:syllable[1]|descendant-or-self::mei:layer[1])" +
        
        // Now we're selecting all elements that fulfill the "conditions of emptyness"
        "/descendant-or-self::mei:syllable/descendant-or-self::*[ " +
          // syl elements will never be deleted on their own, only together with the whole syllable element
          "not(self::mei:syl) " +
          // We're checking whether there is still some content that shall prevent us from deleting
          "and not(descendant-or-self::mei:syl[string-length() > 0]) " +
          "and not(descendant-or-self::mei:note) " +
          "and not(descendant-or-self::mei:pb) " +
          "and not(descendant-or-self::mei:sb) " +
          // Obviously, the current selection must not be removed, even if it's empty
          (selectedElement ? "and not(descendant-or-self::*[@xml:id='" + $ID(selectedElement) + "']) " : " ") +
          "and ( " +
            // If we matched a syllable element, we have to make sure that we don't end up with an empty line.
            " not(self::mei:syllable) " +
            " or preceding-sibling::*[1]/self::mei:syllable or following-sibling::*[1]/self::mei:syllable " +
          ") " +
        "]" 
      ),
      i;
      
      for (i=0; i<emptyElements.length; i+=1) {
        /*jslint bitwise:true*/ // compareDocumentPosition() returns a bitmask where bitwise operations are most appropriate
        if (
          !(mei.compareDocumentPosition(emptyElements[i]) & Node.DOCUMENT_POSITION_DISCONNECTED) &&
          checkIfElementCanBeDeleted(emptyElements[i])
        ) {
          // TODO: Check for annotations!
          var parent = emptyElements[i].parentNode;
          parent.removeChild(emptyElements[i]);
          refresh(parent);
        }
      }
    }

      
    function newSourceBreakAfter(element, nodeName, leaveFocus) {
      // Inserts and returns a new system break.
      // We place source system breaks inside <syllable> elements as we sometimes have breaks with in a syllable.
      // The editors break the chants into staves only between word borders
      // (typesetters may have to introduce more breaks, which currently are not encoded in MEI).

      element = $MEI(element || selectedElement);

      var newBreak = addSourceAttribute(createMeiElement("<" + nodeName + "/>"));

      insertElement(newBreak, {
        contextElement : element,
        parent : "ancestor-or-self::mei:syllable[1]",
        precedingSibling : "ancestor-or-self::*[parent::mei:syllable][1]"
      });
      
      if (!leaveFocus) {
        self.selectElement(newBreak);
      }
      
      return newBreak;
    }
    
    //////// "Public methods" //////////


    this.ANNOTATION_TYPES = {
      "internal":           {label: "internal annotation",       color:"#c11"},
      "typesetter":         {label: "annotation for typesetter", color:"#11c"},
      "public":             {label: "public annotation",         color:"#a70"},
      "diacriticalMarking": {label: "diacritical marking",       color:"#384"},
      "specialProperty":    {label: "special pitch property",    color:"#808"}
    };

    // TODO: Implement this or merge .loadDocument()
    this.newDocument = function(text) {
      // Creates a new document and loads it into the document area.
      // Parameter "text" is optional. If provided, the text layer will be
      // generated from the hyphenated text so that only the music layer has to be added.
    };

    this.loadDocument = function(parameters) {
      // Loads document and display it in viewer (if we have a drawable situation).
      // meiDocument can be a document node, a file name or an XML string.
      // Usually, one of xmlString or xmlUrl should be null/undefined.
      mei = parameters.meiDOM || loadXML({
        xmlString: parameters.meiString,
        xmlUrl   : parameters.meiUrl
      });
      var elementsWithoutId = evaluateXPath(mei,"//*[not(@xml:id)]");
      var i;
      for (i=0; i<elementsWithoutId.length; i+=1) {
        setNewId(elementsWithoutId[i]);
      }
      refresh();
    };

    this.hookUpToSurroundingHTML = function(suppliedMusicContainer, suppliedStaticStyleElement, suppliedDynamicStyleElement) {
      function ensureInstanceofHTMLElement(object,nodeName,errorMessage) {
        if (object instanceof HTMLElement && (!nodeName || object.nodeName.toLowerCase() === nodeName)) {
          return object;
        } 
        throw new Error(errorMessage);
      }

      musicContainer = ensureInstanceofHTMLElement(suppliedMusicContainer,null,
        "Parameter musicContainer must be an instance of HTMLElement"
      );
      // We add a dummy element because later, we will call refresh(),
      // which needs something to replace.
      if (musicContainer) {musicContainer.innerHTML = "<div></div>";}
      staticStyleElement = ensureInstanceofHTMLElement(suppliedStaticStyleElement,"style",
        "Parameter staticStyleElement must be an HTML style element"
      );
      dynamicStyleElement = ensureInstanceofHTMLElement(suppliedDynamicStyleElement,"style",
        "Parameter staticStyleElement must be an HTML style element"
      );
      if (mei) {staticStyleElement.innerHTML = transform("<style>").innerHTML;}
      refresh();
    };

    this.unhookFromSurroundingHTML = function(dontCleanUpSurroundingHTML) {
      if (!dontCleanUpSurroundingHTML) {
        musicContainer.innerHTML = staticStyleElement.innerHTML = dynamicStyleElement.innerHTML = "";
      }
      musicContainer = staticStyleElement = dynamicStyleElement = null;
    };

    this.changeScaleStep = function(steps, note) {
      // This changes the scale step of a note by the value provided by parameter "steps".
      // Parameter "note" is optional. If not supplied, the selected note is used.
      // Special case to be handled: If a note doesn't have a @pname,
      // remove @intm and use the closest preceding @pname/@oct as a starting point.

      note = $MEI(
        note || selectedElement, 
        "note", 
        "Can't change scale step of non-note element"
      );

      /* If this note does not have a defined pitch (ascending/descing liquescent),
       * then we need to get the pitch information from the preceding note,
       * which this XPath expression does. */
      var pnameAttribute = evaluateXPath(note,"(@pname|preceding::mei:note/@pname)[last()]")[0];
      var octAttribute   = evaluateXPath(note,"(@oct  |preceding::mei:note/@oct  )[last()]")[0];

      // If the user has messed up things, we might not have valid pitch and octave information
      pnameAttribute = pnameAttribute || {value:"b"};
      octAttribute   = octAttribute   || {value: 4 };

      var oldOctValue = parseInt(octAttribute.value,10);
      /* While pitch values usually only can have values from 0 to 6,
       * newPitchValue can be greater than 6 and less than 0.
       * This is regularized using "%" when setting the attribute.
       * We don't regularize here because we need the information >6 /<0
       * for determining whether there is an octave change. */
      var newPitchValue = PITCH_VALUES[pnameAttribute.value] + steps;

      // We add 7 first to newPitchValue so that "%" always returns positive numbers
      note.setAttribute("pname",PITCH_NAMES[(newPitchValue + 7) % 7]);
      note.setAttribute("oct",  oldOctValue + Math.floor(newPitchValue/7));
      
      removeDummyState(note);

      // We need to refresh the parent ineume because slurs and following liquescents
      // with unknown pitch could be affected by this pitch change.
      // The parent uneume might do the job as well, but who knows whether there could be 
      // liquescents with unknown pitch immediately following this note that are not inside
      // the same uneume element. Their vertical position would depend on the current note.
      refresh(evaluateXPath(note,"ancestor::mei:ineume")[0]);
      return note;
    };

    this.setIntm = function(intmValue, note) {
      /* MEI's "intm" attribute specifies the melodic interval relative to the previous pitch.
       * For mono:di, we only need the values "u" for "up" and "d" for "down" when the
       * actual pitch of a note is unknown */
      note = $MEI(note || selectedElement, "note", "intm attribute can only be set on note elements");
      if (["u","d"].indexOf(intmValue) < 0) {
        throw new Error("Invalid intm value " + intmValue + ". Accepted values are 'u' and 'd'.");
      }
      note.removeAttribute("pname");
      note.removeAttribute("oct");
      note.removeAttribute("accid");
      note.removeAttribute("label");
      note.setAttribute("intm", intmValue);
      note.setAttribute("mfunc", "liquescent");
      refresh(note);
      return note;
    };

    this.selectElement = function(element) {
      // CAUTION: I removed the callback for annotated element selection.
      //          I guess we won't need this if we do annotation editing directly at the annotated elements.
      // The argument can either be an ID, an MEI element or an HTML element
      // Returns selected element or null, if no matching MEI element was found.
      // Takes care of highlighting.

      // QUESTION: - When selecting annotation labels, the containing element will be selected.
      //             Do we want this or do we want the annotation itself to be selected?
 
      var previouslySelectedElement = selectedElement;
      
      if (element) {
        selectedElement = element && evaluateXPath(
          $MEI(element),
          // We only allow selection of sepcific types of elements 
          "descendant-or-self::*[self::mei:note or self::mei:syllable[not(descendant::mei:note)] or self::mei:syl or self::mei:sb or self::mei:pb][1]"
        )[0];
        
        if (selectedElement === previouslySelectedElement) {return;}
        if (previouslySelectedElement) {removeDummyNotes(previouslySelectedElement);} 
        
        // If we select a syllable element (*not* its syl element), we're operating on the music layer.
        // If there are no notes in this syllable element, we need to generate a dummy note that we can edit.
        if (selectedElement.nodeName === "syllable" && !selectedElement.getElementsByTagName("note")[0]) {
          var newIneume = this.newIneumeAfter(element);
          var note = newIneume.getElementsByTagName("note")[0];
          note.setAttribute("label", "dummy");
          refresh(note);
          selectedElement = note;
        }
        
        dynamicStyleElement.textContent = "#" + idPrefix + $ID(selectedElement) + "{" + selectionStyle + "}";
        
        callUpdateViewCallbacks(element);
      } else {
        dynamicStyleElement.textContent = "";
        selectedElement = null;
      }
      
      removeEmptyElements(previouslySelectedElement);
      
      return selectedElement;
    };
    //selectElement = this.selectElement; // We need this because otherwise, private methods obviously 
                                        // can't use this public method without violating strict mode.

    this.selectNextElement = function(precedingOrFollowing) {
      if (precedingOrFollowing !== "following" && precedingOrFollowing !== "preceding") {
        throw new Error("Argument passed to selectNextElement() must be string 'preceding' or 'following'");
      }

      var nextElement;
      
      // Test whether we're on the music layer
      if (evaluateXPath(selectedElement, "(ancestor-or-self::mei:ineume|self::mei:pb|self::mei:sb/@source)[1]")[0]) {
        nextElement = evaluateXPath(selectedElement, precedingOrFollowing + "::*[self::mei:note|self::mei:pb|self::mei:sb/@source|self::mei:syllable[count(*)=1]][1]")[0];
      // Test whether we're on the text layer
      } else if (evaluateXPath(selectedElement, "(self::mei:syl|self::mei:sb[not(@source)])[1]")[0]) {
        nextElement = evaluateXPath(selectedElement, precedingOrFollowing + "::*[self::mei:syl|self::mei:sb[not(@source)]][1]")[0];
      } else {
        throw new Error("We are neither on the text nor on the music layer.");
      }
      
      return this.selectElement(nextElement || selectedElement);
    };

    this.getSelectedElement = function() {
      return selectedElement;
    };

    this.getHtmlElement = function(element) {
      return $HTML(element || selectedElement);
    };

    this.newNoteAfter = function(element, leaveFocus) {
      // Both parameters are optional.
      // Parameter element may be a note or a uneume.
      // If no element is supplied, the currently selected element is used.
      // Usually, the new note gets the focus, unless parameter "leaveFocus" is "true".
      // Returns new inserted note element

      // Note to self: do we sometimes need to change name of containing neume from bistropha to tristropha?
      // Do we derive this information implicitly from number of apostropha components?

      element = (element ? $MEI(element) : selectedElement) || error("Can not insert note. No element to insert after.");
      removeDummyState(element);
      
      // We're copying the preceding note's properties (if existent)
      var precedingNote = evaluateXPath(element,"(descendant-or-self::mei:note|preceding::mei:note)[not(@intm)][last()]")[0];
      var newNote = precedingNote ? setNewId(precedingNote.cloneNode(true)) : createMeiElement("<note pname='b' oct='4'/>");
      // If we're inserting a new new note after an apostropha that is inside the same ineume as the new note,
      // we want it to be an apostropha as well (i.e. retain the label attribute) because ineumes with apostrophae
      // can only contain either exclusively apostropha pitches or non-apostropha pitches.
      if (
        precedingNote && ( 
          precedingNote.getAttribute("label") !== "apostropha" ||
          evaluateXPath(precedingNote,"ancestor::mei:ineume[1]")[0] !== evaluateXPath(element,"ancestor::mei:ineume[1]")[0]
        )
      ) {
        newNote.removeAttribute("label"); 
        newNote.removeAttribute("mfunc"); 
      }
      newNote.removeAttribute("accid");

      insertElement(newNote,{
        contextElement: element, 
        parent: "ancestor-or-self::mei:uneume[1]",
        // Doesn't matter if the XPath for precedingSibling evalutes to an empty set.
        // In that case, newNote is just inserted into the designated parent.
        precedingSibling: "self::mei:note",
        // QUESTION: Does it suffice to refresh the containing uneume? Then we could omit the refresh field. 
        refresh: "ancestor::mei:ineume[1]"
      });
      if (!leaveFocus) {this.selectElement(newNote);}
      return newNote;
    };


    // QUESTION: newUneumeAfter and newIneumeAfter are almost identical. (How) Can we unify them? 
    this.newUneumeAfter = function(element, leaveFocus) {
      // Returns new inserted neume element
      element = $MEI(element || selectedElement);
      removeDummyState(element);

      var newUneume = createMeiElement("<uneume/>");
      insertElement(newUneume,{
        contextElement: element,
        parent: "ancestor-or-self::mei:ineume[1]",
        precedingSibling: "ancestor-or-self::mei:uneume[1]"
      });
      this.newNoteAfter(newUneume, true);
      //check if case exists that new note should not be selected
      //if (!leaveFocus) {
      this.selectElement(newUneume.getElementsByTagName('note')[0]);
      //}
      return newUneume;
    };

    this.newIneumeAfter = function(element, leaveFocus) {
      // Returns new inserted neume element
      element = $MEI(element || selectedElement);
      removeDummyState(element);

      var newIneume = createMeiElement("<ineume/>");
      newIneume = insertElement(newIneume,{
        contextElement: element,
        parent: "ancestor-or-self::mei:syllable[1]",
        precedingSibling: "ancestor-or-self::mei:ineume[1]",
        leaveFocus: true
      });
      this.newUneumeAfter(newIneume, true);
      return newIneume;
    };


    this.setSylText = function(text, dontRefresh, syl) {
      syl = syl || selectedElement;
      syl = $MEI(syl, "syl", "setSylText() only accepts syl elements as first argument, no " + syl.nodeName + " elements.");
      syl.textContent = text.trim();
      if (!dontRefresh) {refresh(syl);}
    };

    this.newSyllableAfter = function(text, leaveFocus, element) {
      text = text || '';
      element = $MEI(element || selectedElement);
      // CAUTION: We simplify this for now and don't encode wordpos info.
      //          Instead, we just leave the hyphens in the text
      // Inserts a new syllable element after the specified element (if paremter "element" is supplied)
      // or the currently selected element.

      var newSyllable = createMeiElement("<syllable><syl></syl></syllable>");
      var syl = newSyllable.firstElementChild;
      newSyllable = insertElement(newSyllable,{
        contextElement: element,
        parent: "ancestor-or-self::mei:layer[1]",
        precedingSibling: "ancestor-or-self::mei:syllable[1]",
        leaveFocus: true
      });
      this.setSylText(text, false, syl);
      if (!leaveFocus) {this.selectElement(syl);}
      return newSyllable;
    };

    this.newSourceSbAfter = function(element, leaveFocus) {
      return newSourceBreakAfter($MEI(element) || selectedElement, "sb", leaveFocus);
    };

    this.newSourcePbAfter = function(element, folioNumber, rectoVerso, leaveFocus) {
      var pb = newSourceBreakAfter(element, "pb", leaveFocus);
      this.setPbData(folioNumber, rectoVerso, pb);
    };
    
    this.newEditionSbAfter = function(element, leaveFocus) {
      // We put edition system breaks on the "text layer", i.e. inside <syllable>
      // (as opposed to source system breaks) 
      element = $MEI(element || selectedElement);
      var newSb = createMeiElement("<sb/>");

      insertElement(newSb, {
        contextElement : element,
        parent : "ancestor-or-self::mei:layer[1]",
        precedingSibling : "ancestor-or-self::mei:syllable[1]",
        leaveFocus : leaveFocus
      });

      this.newSyllableAfter("", true, newSb); // We can't have empty lines
      
      return newSb;
    };

    // TODO: Test this
    this.setPbData = function(folioNumber, rectoVerso, pb, dontRefresh) {
      // Sets the folio number and recto/verso information for a page break.
      // folioNumber must be an integer or a string of an integer.
      // rectoVerso is optional and must be "recto" or "verso".

      pb = $MEI(pb || selectedElement, "pb");

      if (rectoVerso && (rectoVerso !== "recto" || rectoVerso !== "verso")) {
        throw new Error("rectoVerso can only take on the values 'recto' and 'verso', not '" + rectoVerso + "'.");
      }
      // We're requiring folio numbers to only contain alphanumeric characters. We could be more strict
      if (folioNumber && ( typeof folioNumber !== "string" || !folioNumber.match(/^[\w]+$/)[0])) {
        throw new Error("Malformed folio number '" + folioNumber + "'");
      }

      pb.setAttribute("n", folioNumber || "");
      pb.setAttribute("func", rectoVerso || "");
      
      if (!dontRefresh) {refresh(pb);}

      return pb;
    };

    
    this.newAnnot = function(annotProperties) {
      var annot = createMeiElement("<annot/>");
      evaluateXPath(mei, "//mei:score[1]")[0].appendChild(annot);
      this.setAnnotProperties(annot, annotProperties || {});
    };
    
    this.setAnnotProperties = function(annot, properties) {
      annot = $MEI(annot);
      
      var oldProperties = this.getAnnotProperties(annot),
        startid = properties.startid || oldProperties.startid || properties.endid,
        endid   = properties.endid   || oldProperties.endid   || properties.startid,
        type    = properties.type    || oldProperties.type,
        label   = typeof(properties.label) === "string" ? properties.label : (oldProperties.label || ""),
        text    = typeof(properties.text ) === "string" ? properties.text  : (oldProperties.text  || "");
       
      // properties.ids supercedes startid and endid 
      if (properties.ids) {
        startid = properties.ids[0];
        endid   = properties.ids[properties.ids.length - 1];
        // We have to check whether the ids are in the correct order
        /*jslint bitwise:true*/ // compareDocumentPosition() returns a bitmask where bitwise operations are most appropriate
        if ($MEI(endid).compareDocumentPosition($MEI(startid)) & Node.DOCUMENT_POSITION_FOLLOWING) {
          startid = endid;
          endid   = properties.ids[0];
        }
      }

      if (startid && endid) {
        annot.setAttribute("startid", "#" + $ID(startid));
        annot.setAttribute("endid"  , "#" + $ID(endid  ));
      } else {
        throw new Error("An annotation must be given a start or end id.");
      }
      
      if (type) {
        annot.setAttribute("type", type);
      } else {
        throw new Error("An annotation must be given a type.");
      }
      
      annot.setAttribute("label",label);
      annot.textContent = text;
      
      removeDummyState(startid);
      refresh(startid);
      if (startid !== endid)   {
        removeDummyState(endid);
        refresh(endid);
      }
      if (oldProperties.startid !== startid) {refresh(oldProperties.startid);}
      if (oldProperties.endid   !== endid  ) {refresh(oldProperties.endid  );}
    };
    
    this.getAnnotProperties = function(annot) {
      annot = $MEI(annot);
      
      return {
        // We must chop off the leading "#" from startid/endid anyURI
        startid: (annot.getAttribute("startid") || "").substring(1),
        endid  : (annot.getAttribute("endid"  ) || "").substring(1),
        label  : annot.getAttribute("label"),
        type   : annot.getAttribute("type"),
        text   : annot.textContent
      };
    };    

    // TODO: Test this    
    this.getAccidental = function(element) {
      // Returns the current accidental value: "s", "f", "n" (or null, if no accidental is set).
      element = $MEI(element, "note", "Can not return accidental of none-note element");
      return element.getAttribute("accid");
    };

    this.setAccidental = function(accidental, element) {
      // Parameter "accidental" is either "s" (for sharp), "f" (for flat) or false/null/undefined (for no accidental).
      // If it's null, any existing accidental will be removed.
      // Possible pattern for "toggling" accidentals:
      //   setAccidental(note, getAccidental(note) !== toggleAccidental && toggleAccidental)
      element = element || selectedElement;
      element = $MEI(element, "note", "Can not assign accidentals to none-note elements");
      if (!accidental) {
        element.removeAttribute("accid");
      } else {
        if (["s","f","n"].indexOf(accidental) < 0) {
          throw new Error("Only s, f and n are accepted as accidental values, not " + accidental);
        }
        element.setAttribute("accid",accidental);
      }
      
      removeDummyState(element);
      
      refresh(evaluateXPath(element, "ancestor::mei:ineume")[0]);
      return element;
    };

    this.toggleAccidental = function(accidental, element) {
      element = $MEI(element) || selectedElement;
      this.setAccidental(this.getAccidental(element) !== accidental && accidental, element);
    };

    this.setLiquescence = function(trueOrFalse, element) {
      element = $MEI(element, "note", "Can not set liquescence flag on non-note elements") || selectedElement;
      switch(trueOrFalse) {
      case "true":
      case true:
        element.setAttribute("mfunc","liquescent");
        break;
      case "false":
      case false:
        element.removeAttribute("mfunc");
        break;
      default:
        throw new Error("Attempt at setting liquescence flag to " + trueOrFalse + ". Only true or false are allowed");
      }
      
      removeDummyState(element);
      
      refresh(element);
    };

    this.getLiquescence = function(element) {
      element = $MEI(element || selectedElement, "note", "Can not get liquescence flag of non-note elements");
      return element.getAttribute("mfunc") === "liquescent" ? true : false;
    };

    this.toggleLiquescence = function(element) {
      element = $MEI(element || selectedElement, "note", "Can not set liquescence flag of non-note elements");
      this.setLiquescence(!this.getLiquescence(element), element);
    };

    this.getPerformanceNeumeType = function(element) {
      element = $MEI(element || selectedElement, "note", "Can not get performance neume type of non-note elements");
      return element.getAttribute("label");
    };

    this.setPerformanceNeumeType = function(performanceNeumeType, element) {
      element = $MEI(element || selectedElement, "note", "Can not assign performance neume type to non-note elements");

       // any performanceNeumeType that evaluates to false in a boolean expression shall 
       // result in the removal of any performance neume type 
      switch(performanceNeumeType || null)  {  
      case "oriscus":
      case "quilisma":
      case "apostropha":
        element.setAttribute("label", performanceNeumeType);
        break;
      case null:
        element.removeAttribute("label");
        break;
      default:
        throw new Error(performanceNeumeType.toString() + " is not a recognized performance neume type. Supported types are oriscus, quilisma and apostropha."); 
      }
      refresh(element);
    };
    
    this.togglePerformanceNeumeType = function(performanceNeumeType, element) {
      element = $MEI(element || selectedElement, "note", "Can not assign performance neume type to non-note elements");
      var currentPerformanceNeumeType = element.getAttribute("label");
      
      this.setPerformanceNeumeType(
        currentPerformanceNeumeType === performanceNeumeType ? false : performanceNeumeType, 
        element
      );
    };

    // TODO: Test this
    this.setSbLabel = function(labelText, sb, dontRefresh) {
      sb = sb || selectedElement;
      sb = $MEI(sb, "sb", "System break labels can only be assigned to sb elements.");
      sb.setAttribute("label",labelText);
      
      if (!dontRefresh) {refresh(sb);}
    };

    this.deleteElement = function(element, leaveFocus) {
      // Deletes an element. If no parameter was supplied, the currently selected element will be removed.
      // If the currently selected element is deleted, a neighboring element will be selected (if possible, the left neighbor).
      element = element ? $MEI(element) : selectedElement;

      if (!element) {return;}
      var parent = element.parentNode;
      if (parent && checkIfElementCanBeDeleted(element) && element.getAttribute("label") !== "dummy") {
        if (!leaveFocus) {
          selectedElement = element;
          this.selectNextElement("preceding");
          // If selecting the precedig element was not possible (i.e. the same  
          // element is still selected), we try to select the followig one. 
          if (selectedElement === element) {
            this.selectNextElement("following");
          }
          // If there is no following element to select either, we deselect the item.
          if (selectedElement === element) {
            this.selectElement(null);
          }
        }

        parent.removeChild(element);
        if (element.nodeName === "annot") {
          var annotProperties = this.getAnnotProperties(element);
          refresh(annotProperties.startid);
          if (annotProperties.startid !== annotProperties.endid) {
            refresh(annotProperties.endid);
          }
        } else {
          refresh(parent);
        }
        removeEmptyElements(parent);
        
        return true;
      }
    };

    // TODO: Test this
    this.addCallback = function(callbackEvent, callbackFunction) {
      // A function can be registered here that will be called on the specified callbackEvent.
      // Available events are:
      // - updateView: called whenever the visualization is updated.
      //     This is needed for a function that detects whether the document has to be scrolled
      //     because the currently selected element has (partly) moved outside the visible area.
      //     The argument supplied to the callback is the ID of the currently selected element.
      if (callbacks[callbackEvent]) {
        if (typeof callbackFunction === "function") {
          callbacks[callbackEvent].push(callbackFunction);
        } else {
          throw new Error("Second argument to addCallback() must be a function");
        }
      } else {
        throw new Error("Unknown callback event " + callbackEvent);
      }
    };

    // TODO: Test this
    this.removeCallback = function(callbackEvent, callbackFunction) {
      var i = callbacks[callbackEvent].indexOf(callbackFunction);
      if (i>0) {callbacks[callbackEvent].splice(i,1);}
    };

    this.getSerializedDocument = function() {
      return (new XMLSerializer()).serializeToString(mei);
    };

    this.getPrintHtml = function(documents) {
      var printDocument = transform(documents[0], "d0"),
        printDocumentBody = printDocument.getElementsByTagName("body")[0],
        i;
      for (i=1; i<documents.length; i+=1) {
        var contentToAppend = transform(documents[i], "d" + i).getElementsByTagName("body")[0].firstElementChild;
        var defElements = contentToAppend.getElementsByTagName("defs");
        var j;
        for (j=0; j<defElements.length; j+=1) {
          defElements[j].parentNode.removeChild(defElements[j]);
        } 
        printDocumentBody.appendChild(contentToAppend);
      }
      return printDocument;
    };
    
    //this.getMeiDocument = function(){return mei};

    // TODO: - getter/setter für Vorgangsnummer
    //       - method for generating print-ready HTML page


    //////// "Initialization" //////////


    idPrefix = parameters.idPrefix || "";
    idPrefixLength = idPrefix.length;

    xsltProcessor = new XSLTProcessor();
    xsltProcessor.importStylesheet(
      parameters.xsltDOM || loadXML({
        // Either an xmlString or an xmlUrl must be supplied
        xmlString: parameters.xsltString,
        xmlUrl   : parameters.xsltUrl,
        mime     : "application/xslt+xml"
      })
    );
    // QUESTION: Use something like parameters.xsltParameters instead?
    //           It doesn't make too much sense to supply the XSLT processor
    //           with parameters that weren't meant for it.
    var parameter;
    for (parameter in parameters) {
      if (parameters.hasOwnProperty(parameter)) {
        xsltProcessor.setParameter(null, parameter, parameters[parameter]);
      }
    }


    this.loadDocument(parameters);
    this.hookUpToSurroundingHTML(
      parameters.musicContainer,
      parameters.staticStyleElement,
      parameters.dynamicStyleElement
    );

    refresh();
  };
}());