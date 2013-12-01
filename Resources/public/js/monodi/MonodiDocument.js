// General convention: If an element is required as a parameter, an ID, HTML node or MEI node is accepted.
// If an HTML node is supplied, the ID of this node or of its closest ancestor with an ID
// is used to find the corresponding MEI element.

/*jslint vars:true, browser:true, indent:2 */
/*global HTMLElement: false, SVGElement: false, Element: false, Node: false, Attr: false, Document: false,
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
       - xsltParameters: A sub-object that lists any parameters accepted
         by mei2xhtml.xsl as key value pairs.
    */


    var mei, // The MEI document.
        musicContainer = null,
        staticStyleElement = null,
        dynamicStyleElement = null,
        xsltProcessor,
        idPrefix,
        idPrefixLength,
        selectionStyle = parameters.selectionStyle || "color:#d21",
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
      deleteAnnotatedElement: [],
      selectElement: []
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

      if (element instanceof Attr) {
        element = element.parentNode;
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
        var attributeName = element.getAttribute("data-editable-attribute"); 
        element = $ID(element);
        if (attributeName) {
          return $MEI($ID(element)).attributes.getNamedItem(attributeName);
        }
      }

      if (typeof(element) === 'string') {
        element = evaluateXPath(mei,"//*[@xml:id='"+element+"']")[0];
      }

      if (element instanceof Element && element.namespaceURI === meiNS) {
        if (!expectedElementName || element.localName === expectedElementName) {
          return element;
        }
        throw new Error(
          element.localName + " element " + element.getAttributeNS(xmlNS,"id") + ":" + (
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
      var newId = "",
          randomSuffixRange = 10000;
      
      do {
        var newIdNumber = Math.floor((new Date().getTime() + Math.random()) * randomSuffixRange);
        // To save a little space (especially for localStorage), we base-36 encode the number generated above. 
        newId = "mei" + newIdNumber.toString(36);
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
        // As the content of uneume influences the rendering of slurs, 
        // we have to refresh the whole uneume whenever something inside changes
        "(.|ancestor::mei:uneume)[1]"
      )[0] : "<mei>";
      
      var htmlElement;
      switch (element.nodeName || element) {
        case "<mei>":
          musicContainer.innerHTML = "<div></div>";
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
      callUpdateViewCallbacks(htmlElement);
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
      // If not, we don't want to delete as we'd get a line without a syllable which we don't support
      // as the user needs at least one syllable to select for adding content to the line.
      // Same for edition system breaks: If there is no preceding system break, we can't delete  
      if (evaluateXPath(
        element,
        "self::mei:sb[not(@source)][not(preceding-sibling::mei:sb[not(@source)])][concat(@n,@label)!=''] | " +
        "self::mei:syllable[count((following-sibling::*[1]|preceding-sibling::*[1])[self::mei:syllable])=0] | " +
        "self::mei:syl | " +
        "ancestor-or-self::mei:meiHead"
      )[0]) {
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
        throw new Error("Exactly one callback for deleteAnnotatedElement is required, but " + callbacks.deleteAnnotatedElement.length + " were defined.");
      }
      
      return true;
    }

    function removeEmptyElements(element) {
      // This will delete any elements inside syllables that don't have content
      // (i.e. no notes, system/page breaks, no text in syl element)
      // The currently selected element will not be deleted.
      element = element ? $MEI(element) : mei.documentElement;
      
      var emptyElements = evaluateXPath(
        element,
        // The context element might either be inside or outside of a syllable element.
        // If it's inside, then we only want this syllable to be checked for empty elements,
        // if it's outside, then we want to basically check all syllables.
        // All our syllables are living inside one common layer element.  
        "(ancestor-or-self::mei:syllable[1]|descendant-or-self::mei:layer[1])" +
        
        // Now we're selecting all descendant elements that fulfill the "conditions of emptyness"
        "/descendant-or-self::mei:syllable/descendant-or-self::*[ " +
          // syl elements will never be deleted on their own, only together with the whole syllable element
          "not(self::mei:syl) " +
          // We're checking whether there is still some content that shall prevent us from deleting
          "and not(descendant-or-self::mei:syl[string-length() > 0]) " +
          "and not(descendant-or-self::mei:note) " +
          "and not(descendant-or-self::mei:pb) " +
          "and not(descendant-or-self::mei:sb) " +
          // Obviously, the current selection must not be removed, even if it's empty
          ((selectedElement instanceof Element) ? "and not(descendant-or-self::*[@xml:id='" + $ID(selectedElement) + "']) " : " ") +
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
          // checkIfElementCanBeDeleted() will check for annotations and delete them if the user confirms it
          checkIfElementCanBeDeleted(emptyElements[i])
        ) {
          var parent = emptyElements[i].parentNode;
          parent.removeChild(emptyElements[i]);
          refresh(parent);
        }
      }
    }

      
    function newSourceBreak(element, nodeName, insertAfter, leaveFocus) {
      // Inserts and returns a new system break.
      // We place source system breaks inside <syllable> elements as we sometimes have breaks with in a syllable.
      // The editors break the chants into staves only between word borders
      // (typesetters may have to introduce more breaks, which currently are not encoded in MEI).

      element = $MEI(element || selectedElement);

      var newBreak = addSourceAttribute(createMeiElement("<" + nodeName + "/>"));
      
      var insertElementParameters = {
        contextElement : element,
        parent : "ancestor-or-self::mei:syllable[1]"
      };

      if (insertAfter) {
        insertElementParameters.precedingSibling = "ancestor-or-self::*[parent::mei:syllable][1]";
      } else {
        insertElementParameters.followingSibling = "ancestor-or-self::*[parent::mei:syllable][1]";
      }

      insertElement(newBreak, insertElementParameters);
      
      if (!leaveFocus) {
        self.selectElement(newBreak);
      }
      
      return newBreak;
    }
    
    // We use the label attribute on notes like a class attribute,
    // i.e. we can add and remove several classes for liquescents and performance neumes
    function addToLabelAttribute(element, value) {
      var oldLabelAttribute = element.getAttribute("label") || "";
      // In case value is already present on the attribute, we first remove it.
      element.setAttribute("label", (oldLabelAttribute.replace(value,"") + " " + value).trim());
    }
    
    function removeFromLabelAttribute(element, value) {
      var oldLabelAttribute = element.getAttribute("label") || "";
      var newLabelAttribute = oldLabelAttribute.replace(value,"").trim();
      if (newLabelAttribute === "") {
        element.removeAttribute("label");
      } else {
        element.setAttribute("label", newLabelAttribute);
      }
    }
    
    function labelAttributeContains(element, value) {
      var labelAttribute = element.getAttribute("label");
      return labelAttribute && labelAttribute.indexOf(value) > -1;
    }
    
    //////// "Public methods" //////////


    this.ANNOTATION_TYPES = {
      "internal":           {label: "internal annotation",       color:"#c11"},
      "typesetter":         {label: "annotation for typesetter", color:"#11c"},
      "public":             {label: "public annotation",         color:"#a70"},
      "diacriticalMarking": {label: "diacritical marking",       color:"#384"},
      "specialProperty":    {label: "special pitch property",    color:"#808"}
    };

    this.newDocument = function(text, textValidationCallback) {
      // Creates a new document and loads it into the document area.
      // Parameters are optional. If text is provided, also textValidationCallback must be provided.
      // The text layer will begenerated from the hyphenated text so that only the music layer has to be added.
      
      // This function can be tested with the following call:
      /* monodi.document.newDocument(null,function(problemLine, problemLineNumber){
           alert(
             "Line " + problemLineNumber + " does not follow the expected syntax:\n\n  " + 
             problemLine + 
             "\n\nA fallback method will be used for generating the document"
           );
           return true;
         })
       */
      
      // Before entering the music, the project prepares text documents that contains only the text
      // and is formatted in a specific way.
      // It has three Tab separated columns:
      // - left column: line labels (of the form /\d+/ or /[A-Z]/) 
      // - center column: actual sung text
      // - right column: folio numbers (of the form /\|\| f\. \d+v?/)
      // We try to interpret parameter text in this way and extract all the necessary information.
      // If we don't succeed, we signal this to the user and ask the user to either fix the input
      // or make use of the fallback mode which interprets the input as one column of sung text.
      
      function processSyllables(columns, rubricCaption) {
        /*jslint regexp: true*/
        var folioInfo = columns[2] || "",
          sbN = columns[0] || "",
          contentString = '<sb label="' + (rubricCaption || "").replace(/</g,"&lt;") + '" n="' + sbN + '"/>',
          syllables = columns[1] ? columns[1].match(/(<[^>]+>)|([^\s\-]+-?)|([\n\r]+)|(\|\|?)/g) : [""],
          breakMarkerString = "",
          folioInfoComponents = folioInfo.match(/^\|*\s*f\.\s*(\d+)([rv]?)$/) || [],
          i;
          
        for (i=0; i<syllables.length; i+=1) {
          var syllable = syllables[i];
          
          switch (syllable) {
            case "|":
              breakMarkerString = "<sb source=''/>";
              break;
            case "||":
              breakMarkerString = "<pb source='' " + 
                "n='" + (folioInfoComponents[1] || "") + "' " + 
                "func='" + (folioInfoComponents[2] === "v" ? "verso" : (folioInfoComponents[1] ? "recto" : "")) + "'/>";
              break;
            default :
              contentString += "<syllable>" +
                                 "<syl>" + syllable.replace(/</g,"&lt;") + "</syl>" +
                                 breakMarkerString +
                               "</syllable>";
              breakMarkerString = "";
          }
        }
        // TODO: Find a more proper way of giving feedback to the user.
        if (breakMarkerString) {
          alert(
            "Warning: Line break marker at the end of line will be ignored:\n\n" +
            "    " + columns[1] + "\n\n" +
            "Line break markers should be recorded at the start of the following line."
          );
        }
        return contentString;
      }
      
      var contentString = "",
        i;
      if (text) {
        // We have three kinds of matches: Single syllables (delimited by spaces or "-"),
        // escaped areas (using <>) and line breaks.
        var contentStringHasValidColumns = true,
          rubricCaption = "",
          lines = text.split(/\s*[\n\r]+/),
          line;
        for (i=0; i<lines.length; i+=1) {
          line = lines[i];
          // Line that consists of:
          // - Line label (or nothing)
          // - Tab
          // - Line content
          // - optional:
          //   - tab
          //   - /|| f. \d+v?/ // 
          /*jslint regexp: true*/
          if (line.match(/^(\d*|[A-Z]?)\t([^\t]+)\t?(\|*\s*f\.\s*\d+[rv]?)?\s*$/)) {
            var columns = line.split(/\s*\t\s*/);
            // A line that has no line label in the left column,
            // only capital letters in the center column
            // and optionally folio information of the form /f\. \d+v?/ in the third column
            // is a rubric caption.
            if (columns[0] === "" && columns[1].match(/^[A-Z\s<>]+$/)) {
              // This is the rubric caption for the next line
              rubricCaption = columns[1];
            } else {
              contentString += processSyllables(columns, rubricCaption);
              rubricCaption = "";
            }        
          } else {
            contentStringHasValidColumns = line.trim() === "";
            break; 
          }
        }
        if (!contentStringHasValidColumns) {
          // We're offering a fallback method here that does not rely on strict syntax,
          // but can not transcribe all
          contentString = "";
          // Using textValidationCallback, The user is asked whether he wants to process the text in fallback mode
          // (no culomn interpretation) 
          if (textValidationCallback(line, i)) {
            for (i=0; i<lines.length; i+=1) {
              contentString += processSyllables(lines[i]);
            }
          } else {
            return;
          }
        }
      } else {
        contentString = processSyllables([]);
      }
      this.loadDocument({meiString: 
        '<mei xmlns="http://www.music-encoding.org/ns/mei">' +
          '<meiHead>' +
            '<fileDesc>' +
              '<titleStmt>' +
                '<title/>' +
              '</titleStmt>' +
              '<pubStmt/>' +
              '<seriesStmt>' +
                '<title>Corpus monodicum</title>' +
                '<seriesStmt>' +
                  '<title type="section"><num></num></title>' +
                  '<identifier type="volume"><num></num></identifier>' +
                '</seriesStmt>' +
              '</seriesStmt>' +
              '<sourceDesc n="">' +
                '<source label="">' +
                  '<physDesc>' +
                    '<extent>' +
                      '<identifier type="startFolio"></identifier>' +
                    '</extent>' +
                  '</physDesc>' +
                '</source>' +
              '</sourceDesc>' +
            '</fileDesc>' +
            '<workDesc>' +
              '<work n="">' +
                '<incip>' +
                  '<incipText>' +
                    '<p></p>' +
                  '</incipText>' +
                '</incip>' +
                '<biblList>' +
                  '<bibl>' +
                    '<genre>melody catalogue</genre>' +
                    '<author></author>' +
                    '<identifier type="melodyNumber"></identifier>' +
                    '<identifier type="tropeComplexNumber"></identifier>' +
                  '</bibl>' +
                '</biblList>' +
                '<classification>' +
                  '<termList label="genre">' +
                    '<term></term>' +
                  '</termList>' +
                  '<termList label="baseChantIncipit">' +
                    '<term></term>' +
                  '</termList>' +
                  '<termList label="regularizedLiturgicFunction">' +
                    '<term label="feast"></term>' +
                  '</termList>' +
                  '<termList label="liturgicFunction">' +
                    '<term label="feast"></term>' +       
                    '<term label="service"></term>' +
                    '<term label="baseChantGenre"></term>' +
                  '</termList>' +
                '</classification>' +
                '<relationList>' +
                  '<relation rel="hasRealization" label="" n=""/>' +
                '</relationList>' +
              '</work>' +
            '</workDesc>' +
          '</meiHead>' +
          '<music>' +
            '<body>' +
              '<mdiv>' +
                '<score>' +
                  '<section>' +
                    '<staff>' +
                      '<layer>' +
                        contentString +
                      '</layer>' +
                    '</staff>' +
                  '</section>' +
                '</score>' +
              '</mdiv>' +
            '</body>' +
          '</music>' +
        '</mei>'
      });
      
      var elementsWithEmptySourceAttribute = evaluateXPath(mei, "//*[@source[.='']]");
      for (i=0; i<elementsWithEmptySourceAttribute.length; i+=1) {
        addSourceAttribute(elementsWithEmptySourceAttribute[i]);
      }
      
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
      note.setAttribute("intm", intmValue);
      note.setAttribute("label", "liquescent");
      refresh(note);
      return note;
    };
    
    this.toggleFollowingUnpitchedLiquescent = function(intmValue, note) {
      note = $MEI(note || selectedElement, "note");
      var followingLiquescent = (
        evaluateXPath(note, "following-sibling::*[1]/self::mei:note[not(@oct and @pname)]")[0] || 
        this.newNoteAfter(note, true)
      ),
      currentIntm = followingLiquescent.getAttribute("intm"),
      oppositeIntm = intmValue === "u" ? "u" : "d";
      
      if (intmValue === currentIntm) {
        this.deleteElement(followingLiquescent);
      } else {
        this.setIntm(
          (intmValue === currentIntm) ? oppositeIntm : intmValue,
          followingLiquescent
        );
      }
      refresh(note);
    };

    this.selectElement = function(suppliedElement) {
      // CAUTION: I removed the callback for annotated element selection.
      //          I guess we won't need this if we do annotation editing directly at the annotated elements.
      // The argument can either be an ID, an MEI element or an HTML element
      // Returns selected element or null, if no matching MEI element was found.
      // Takes care of highlighting.

      // QUESTION: - When selecting annotation labels, the containing element will be selected.
      //             Do we want this or do we want the annotation itself to be selected?
 
      var previouslySelectedElement = selectedElement;
      
      var element = $MEI(suppliedElement);
      if (element) {
        if (element instanceof Attr) {
          selectedElement = element;
        } else {
          selectedElement = element && evaluateXPath(
            element,
            // We only allow selection of sepcific types of elements 
            "descendant-or-self::*[" + 
              "self::mei:note or self::mei:syllable[not(descendant::mei:note)] " +
              "or self::mei:syl or self::mei:sb or self::mei:pb " +
              "or ancestor::mei:meiHead " +
            "][1]"
          )[0];
        }
        
        if (selectedElement === previouslySelectedElement) {return selectedElement;}
        if (previouslySelectedElement) {removeDummyNotes(previouslySelectedElement);} 
        
        // If we select a syllable element (*not* its syl element), we're operating on the music layer.
        // If there are no notes in this syllable element, we need to generate a dummy note that we can edit.
        if (selectedElement.nodeName === "syllable" && !selectedElement.getElementsByTagName("note")[0]) {
          var newIneume = this.newIneumeAfter(element, true);
          var note = newIneume.getElementsByTagName("note")[0];
          note.setAttribute("label", "dummy");
          refresh(note);
          selectedElement = note;
        }
        
        var selector = selectedElement instanceof Attr 
            ? ($ID(suppliedElement) + " > att_" + selectedElement.localName) 
            :  $ID(selectedElement);
        dynamicStyleElement.textContent = "#" + idPrefix + selector + "{" + selectionStyle + "}"; 
        
        callUpdateViewCallbacks(element);
      } else {
        dynamicStyleElement.textContent = "";
        selectedElement = null;
      }
      
      removeEmptyElements(previouslySelectedElement);
      
      // TODO: Some code like this should go into main.js 
      /*var contenteditable = evaluateXPath($HTML(selectedElement),"descendant-or-self::*[@contenteditable]")[0]
      if (contenteditable) contenteditable.focus()*/
      
      return selectedElement;
    };
    //selectElement = this.selectElement; // We need this because otherwise, private methods obviously 
                                        // can't use this public method without violating strict mode.
    
    // As liquescents with unknown pitch are combined into one symbol together with their preceding note, 
    // we usually don't want to select them.  That's what parameter allowSelectionOfLiquescentsWithUnkownPitch is for.
    this.selectNextElement = function(precedingOrFollowing, allowSelectionOfLiquescentsWithUnkownPitch) {
      if (precedingOrFollowing !== "following" && precedingOrFollowing !== "preceding") {
        throw new Error("Argument passed to selectNextElement() must be string 'preceding' or 'following'");
      }

      var nextElement;
      
      // Test whether we're on the music layer
      if (evaluateXPath(selectedElement, "(ancestor-or-self::mei:ineume|self::mei:pb|self::mei:sb/@source)[1]")[0]) {
        nextElement = evaluateXPath(selectedElement, precedingOrFollowing + "::*[" + 
          "self::mei:note" + (allowSelectionOfLiquescentsWithUnkownPitch ? "|" : "[@pname]|") + 
          "self::mei:pb|" + 
          "self::mei:sb/@source|" +
          // To enable inputting notes into syllables that don't already have any syllables in them,
          // we allow the selection of syllables themselfes.  this.selectElement() will then take care of 
          // creating dummy notes in those syllables that can be edited.
          // The same is done if the first element on the music layer is a <sb> or <pb> because we can't input
          "self::mei:syllable[count(*)=1]" +
        "][1]")[0];
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
          !labelAttributeContains(precedingNote, "apostropha") ||
          evaluateXPath(precedingNote, "ancestor::mei:ineume[1]")[0] !== evaluateXPath(element,"ancestor::mei:ineume[1]")[0]
        )
      ) {
        newNote.removeAttribute("label"); 
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
        precedingSibling: "ancestor-or-self::*[self::mei:syllable or self::mei:sb[not(@source)]][1]",
        leaveFocus: true
      });
      this.setTextContent(text, false, syl);
      if (!leaveFocus) {this.selectElement(syl);}
      return newSyllable;
    };

    this.newSourceSbAfter = function(element, leaveFocus) {
      return newSourceBreak(element, "sb", true, leaveFocus);
    };

    this.newSourceSbBefore = function(element, leaveFocus) {
      return newSourceBreak(element, "sb", false, leaveFocus);
    };

    this.newSourcePbAfter = function(element, folioNumber, rectoVerso, leaveFocus) {
      var newPb = newSourceBreak(element, "pb", true, leaveFocus);
      this.setPbData(folioNumber, rectoVerso, false, newPb);
      return newPb;
    };
    
    this.newSourcePbBefore = function(element, folioNumber, rectoVerso, leaveFocus) {
      var newPb = newSourceBreak(element, "pb", false, leaveFocus);
      this.setPbData(folioNumber, rectoVerso, false, newPb);
      return newPb;
    };
    
    this.newEditionSbAfter = function(element, leaveFocus) {
      // We put edition system breaks in between <syllable>s
      // (as opposed to source system breaks)
      element = $MEI(element || selectedElement);
      var newSb = createMeiElement("<sb n='' label=''/>"),
          newSyllable;

      insertElement(newSb, {
        contextElement : element,
        parent : "ancestor-or-self::mei:layer[1]",
        precedingSibling : "ancestor-or-self::mei:syllable[1]"
      });

      newSyllable = this.newSyllableAfter("", true, newSb); // We can't have empty lines
      if (!leaveFocus) {this.selectElement(evaluateXPath(newSyllable, "mei:syl")[0]);}
      
      return newSb;
    };

    this.setPbData = function(folioNumber, rectoVerso, dontRefresh, pb) {
      // Sets the folio number and recto/verso information for a page break.
      // folioNumber must be an integer or a string of an integer.
      // rectoVerso is optional and must be "recto" or "verso".

      pb = $MEI(pb || selectedElement, "pb");

      if (rectoVerso && !(rectoVerso === "recto" || rectoVerso === "verso")) {
        throw new Error("rectoVerso can only take on the values 'recto' and 'verso', not '" + rectoVerso + "'.");
      }
      // We're requiring folio numbers to only contain alphanumeric characters. We could be more strict
      // We're removing this check right now because we'd risk a quiet error and having something on the screen that does not reflect the data
      /*if (folioNumber && ( typeof folioNumber !== "string" || !folioNumber.match(/^[\w]+$/)[0])) {
        throw new Error("Malformed folio number '" + folioNumber + "'");
      }*/

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
        addToLabelAttribute(element, "liquescent");
        break;
      case "false":
      case false:
        removeFromLabelAttribute(element, "liquescent");
        break;
      default:
        throw new Error("Attempt at setting liquescence flag to " + trueOrFalse + ". Only true or false are allowed");
      }
      
      removeDummyState(element);
      
      refresh(element);
    };

    this.getLiquescence = function(element) {
      element = $MEI(element || selectedElement, "note", "Can not get liquescence flag of non-note elements");
      return labelAttributeContains(element, "liquescent");
    };

    this.toggleLiquescence = function(element) {
      element = $MEI(element || selectedElement, "note", "Can not set liquescence flag of non-note elements");
      this.setLiquescence(!this.getLiquescence(element), element);
    };

    this.getPerformanceNeumeType = function(element) {
      element = $MEI(element || selectedElement, "note", "Can not get performance neume type of non-note elements");
      // For this function, we only regard oriscus, quilisma and apostropha;
      // If liquescent is present, we ignore that.
      var labelAttribute = element.getAttribute("label"); 
      return (labelAttribute && labelAttribute.replace("liquescent","").trim()) || null;
    };

    this.setPerformanceNeumeType = function(performanceNeumeType, element) {
      element = $MEI(element || selectedElement, "note", "Can not assign performance neume type to non-note elements");

      // We remove any pre-existing performance neume classes (except for liquescents)
      removeFromLabelAttribute(element, "oriscus");
      removeFromLabelAttribute(element, "quilisma");
      removeFromLabelAttribute(element, "apostropha");

      // any performanceNeumeType that evaluates to false in a boolean expression shall 
      // result in the removal of any performance neume type 
      switch(performanceNeumeType || null)  {  
      case "oriscus":
      case "quilisma":
      case "apostropha":
        addToLabelAttribute(element, performanceNeumeType);
        break;
      case null:
        break;
      default:
        throw new Error(performanceNeumeType.toString() + " is not a recognized performance neume type. Supported types are oriscus, quilisma and apostropha."); 
      }
      refresh(element);
    };
    
    this.togglePerformanceNeumeType = function(performanceNeumeType, element) {
      element = $MEI(element || selectedElement, "note", "Can not assign performance neume type to non-note elements");

      // We don't allow any performance neume type to be set on notes with following liquescents with unknown pitch
      // because we can't visualize them and the user would not realize that he set a performance neume type.      
      if (evaluateXPath(element, "following-sibling::*[1]/self::mei:note[not(@pname and @oct)]")[0]) {
        this.setPerformanceNeumeType(null, element);
      } else {
        removeDummyState(element);
        this.setPerformanceNeumeType(
          labelAttributeContains(element, performanceNeumeType) ? null : performanceNeumeType, 
          element
        );
      }
    };

    this.setAttribute = function(attributeName, value, dontRefresh, element) {
      element = $MEI(element) || selectedElement;
      element.setAttribute(attributeName, value);
      
      if (!dontRefresh) {
        refresh(element);
      }
      if (element.nodeName === "sb") {
        refresh(document.getElementsByClassName("_mei meiHead")[0]);
      }
    };
    
    this.setTextContent = function(value, dontRefresh, element) {
      element = $MEI(element) || selectedElement;
      element.textContent = value.trim();
      if (!dontRefresh) {refresh(element);}
    };
    
    this.setSbN = function(nText, dontRefresh, sb) {
      sb = sb || selectedElement;
      sb = $MEI(sb, "sb", "System break n attributes can only be assigned to sb elements.");
      sb.setAttribute("n",nText);
      
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

    this.removeCallback = function(callbackEvent, callbackFunction) {
      var i = callbacks[callbackEvent].indexOf(callbackFunction);
      if (i>0) {callbacks[callbackEvent].splice(i,1);}
    };

    this.getSerializedDocument = function() {
      return (new XMLSerializer()).serializeToString(mei);
    };

    this.getPrintHtml = function(documents) {
      var i;
      documents = documents || [mei];
      for (i=0; i<documents.length; i+=1) {
        if (typeof documents[i] === "string") {
          documents[i] = loadXML({xmlString: documents[i]});
        }
      }      
      var printDocument = transform(documents[0], idPrefix + "d0"),
        printDocumentBody = printDocument.getElementsByTagName("body")[0];
      for (i=1; i<documents.length; i+=1) {
        var contentToAppend = transform(documents[i], idPrefix + "d" + i).getElementsByTagName("body")[0].firstElementChild;
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

    var parameter;
    if (parameters.xsltParameters) {
      for (parameter in parameters.xsltParameters) {
        if (parameters.xsltParameters.hasOwnProperty(parameter)) {
          xsltProcessor.setParameter(null, parameter, parameters.xsltParameters[parameter]);
        }
      }
    }

    if (parameters.meiUrl || parameters.meiString || parameters.meiDOM) {
      this.loadDocument(parameters);
    } else {
      this.newDocument();
    }
    this.hookUpToSurroundingHTML(
      parameters.musicContainer,
      parameters.staticStyleElement,
      parameters.dynamicStyleElement
    );

    refresh();
  };
}());