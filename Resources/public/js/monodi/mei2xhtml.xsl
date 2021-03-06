<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:xhtml="http://www.w3.org/1999/xhtml" 
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    exclude-result-prefixes="svg mei">

  <!-- TODO: - Small caps for base chants? -->

  <xsl:key name="id" match="*[@xml:id]" use="@xml:id"/>
  
  <!--<xsl:output doctype-system="about:legacy-compat"/>-->
  
  <xsl:param name="idPrefix"/>
  
  <xsl:param name="transformNode" select="/"/>
  
  <!-- PARAMETERS FOR INFLUENCING GENERAL INTERACTION, DISPLAY AND JAVASCRIPT STUFF -->
  <xsl:param name="setContentEditable" select="'true'"/>
  <xsl:param name="onblurWorkaroundForEmptyEditableElements" select="'true'"/>
  <!-- The onload parameter allows to supply the content of an onload attribute.
       The attribute will be generated on the body element.
       This is especially useful for printing the page. The value could e.g. be:
       'window.print();window.close()' (would window.close() actually work?) -->
  <xsl:param name="onload"/>
  <xsl:param name="displayAnnotations" select="'true'"/>
  <xsl:param name="interactiveCSS" select="'true'"/>
  <xsl:param name="printAnnotations" select="'true'"/>
  
  <!-- SPACING PARAMETERS -->
  <!-- These following lengths are given in terms of scaleStepSize -->
  <!-- VERTICAL SPACING -->
  <xsl:param name="scaleStepSize" select="3.5"/>
  <xsl:param name="spaceAboveStaff" select="9"/>
  <xsl:param name="spaceBelowStaff" select="6"/>
  <xsl:variable name="musicAreaHeight" select="$scaleStepSize * (8 + $spaceAboveStaff + $spaceBelowStaff)"/>
  <xsl:param name="musicAnnotHeight" select="10"/>
  <!--<xsl:param name="annotSpaceAboveStaff" select="$spaceAboveStaff - 4"/>-->
  <xsl:param name="textAnnotHeight" select="4"/>
  
  <!-- HORIZONTAL SPACING -->
  <!-- Space that a single note (including padding) takes up -->
  <xsl:param name="noteSpace" select="4.5"/>
  <xsl:param name="apostrophaSpace" select="3"/>
  <!-- TODO: Think about adding oriscus/liquescent/quilisma space -->
  <xsl:param name="accidentalSpace" select="1.5"/>
  <xsl:param name="sbPbWidth" select="6"/>
  <xsl:param name="sbPbMarkerHeight" select="5"/>
  <xsl:param name="pbLineDistance" select="1"/>
  <xsl:param name="paddingAfterIneume" select="4"/>
  <xsl:param name="paddingBeforeFirstSyllable" select="2"/>
  <xsl:param name="paddingAroundHyphen" select="1"/>
  <xsl:param name="paddingAfterSyllableText" select="2.5"/>
  <xsl:param name="paddingAfterSyllablePitches" select="2"/>
  <xsl:param name="lineLeftMargin" select="40"/>  
  <xsl:param name="lineLabelPadding" select="$paddingAfterSyllableText"/>
  <xsl:param name="indentOnLineBreak" select="40"/>  
  
  <xsl:param name="leftShiftOfSyllableText" select="1"/>
  
  <!--<xsl:param name="syllableMarginLeft" select="2"/>
  <xsl:param name="syllableLeftShift" select="1"/>
  <xsl:param name="syllableMarginTop" select="1"/>--><!-- What were these things for? -->
  <!--<xsl:param name="uneumeDistance" select="1.5"/>--><!-- We don't need this any more because distance between slurred/unslurred notes should be the same -->

  <!-- GRAPHICAL PROPERTIES OF INDIVIDUAL SYMBOLS -->
  <xsl:param name="noteheadSize" select="1"/>
  <xsl:param name="liquescentNoteheadSize" select=".7"/>
  <xsl:param name="liquescentColor" select="'#31a'"/>
  
  <xsl:param name="staffLineWidth" select=".25"/>
  <xsl:param name="ledgerLineWidth" select="$staffLineWidth * 1.3"/>
  <xsl:param name="ledgerLineProtrusion" select=".7"/>
  <xsl:param name="slurLineWidth" select=".4"/>
  <!-- sbPbLineWidth is in pixels -->
  <xsl:param name="sbPbLineWidth" select="2"/>

  <xsl:param name="annotLabelBorderRadius" select="3"/>
  <xsl:param name="musicTextDistance" select="0"/><!-- This is the distance in pixels -->

  <xsl:param name="paddingSlurEndNotes" select="3"/>
  <xsl:param name="paddingSlurCenterNotes" select="2"/>
  <xsl:param name="lowestSlurPosition" select="1"/>
  
  <xsl:param name="annotationColorCodes" select="'
    internal:#c11;
    typesetter:#11c;
    public:#a70;
    diacriticalMarking:#384;
    specialProperty:#808;'"/>
  
  <xsl:variable name="stafflines">
    <svg:svg height="{$musicAreaHeight}px" viewBox="0 0 1 {$musicAreaHeight}" class="stafflines" preserveAspectRatio="none">
      <svg:path 
          d="m0 ,{$spaceAboveStaff*$scaleStepSize}h1
             m-1,{ 2*$scaleStepSize}h1
             m-1,{ 2*$scaleStepSize}h1
             m-1,{ 2*$scaleStepSize}h1
             m-1,{ 2*$scaleStepSize}h1"/>
    </svg:svg>
  </xsl:variable>
  
  <xsl:template match="/">
    <!-- Depending on the Parameter $transformNode, different outputs are generated.
         Options are: 
           - A complete HMTL document when $transformNode hasn't be set explicitly 
           - A style element, if it has been set to <style> 
           - If $transformNode has been set to another string in angled brackets, 
             the first element of this name is transformed
           - Otherewise, the string will be interpreted as an ID and the element with
             this ID will be transformed. -->
    <xsl:choose>
      <xsl:when test="$transformNode=/">
        <html>
          <head>
            <title><xsl:value-of select="mei:mei/mei:meiHead/mei:fileDesc/mei:titleStmt/mei:title"/></title>
            <xsl:call-template name="createStyleElement"/>
            <style type="text/css" id="highlightStyle"/>
          </head>
          <!-- onload can be used e.g. for supplying JavaScript that triggers the print dialog when the pages is loaded -->
          <body>
            <xsl:if test="string-length($onload) != 0">
              <xsl:attribute name="onload">
                <xsl:value-of select="$onload"/>
              </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="/*"/>
          </body>
        </html>
      </xsl:when>
      <!-- Output <style> element -->
      <xsl:when test="$transformNode='&lt;style>'">
        <xsl:call-template name="createStyleElement"/>
      </xsl:when>
      <!-- Transform first node with this name -->
      <!-- QUESTION: Do we need this??? -->
      <xsl:when test="starts-with($transformNode,'&lt;')">
        <xsl:variable name="elementName" select="translate($transformNode,'&gt;&lt;','')"/>
        <xsl:variable name="foundElement" select="(//*[local-name()=$elementName])[1]"/>
        <xsl:apply-templates select="$foundElement"/>
      </xsl:when>
      <!-- Transform element with supplied ID -->
      <xsl:when test="key('id',$transformNode)">
        <xsl:apply-templates select="key('id',$transformNode)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">
          ERROR: Element with ID <xsl:value-of select="$transformNode"/> does not exist.
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="createStyleElement">
    <style type="text/css"><!-- General layout -->
      ._mei {
        display:inline;
        position:relative;
      }
      .layer ._mei {
        display:inline-block;
      }
      /* Exceptions to the above display:inline-block:*/
      .annotLabel, <!--.meiHead,--> .annot {
        display:none;
      }
      .editionLine, .fileDesc > .seriesStmt {
        display:block;
      }
      .syllable > div {
        display:inline-block;
        vertical-align:top;
      }
      .musicLayer > .ineume, .musicLayer > .pb {
        height:<xsl:value-of select="$musicAreaHeight + ($musicTextDistance + $textAnnotHeight) * $scaleStepSize"/>px;
        <!-- We have to make sure the text that was moved down using CSS transform has enough space as well: -->
        padding-bottom:1em;
      }
      .sb.edition {
        vertical-align:bottom;
      }
      .note > svg { <!-- Width of notes varies depending on accidentals, therefore we don't give a width here -->
        height:<xsl:value-of select="$musicAreaHeight"/>px;
      }
      .uneume {
        white-space: nowrap;
      }
      ._mei.mei, ._mei.music, ._mei.body, ._mei.mdiv, ._mei.score, ._mei.section, ._mei.staff, ._mei.layer, ._mei.editionLine  {
        width: 100%;
      }
<!--    </style>
    <style type="text/css"> <!-\- Music styling -\->-->
      .stafflines, .slur {
        stroke:currentColor;
        fill:none;
        position:absolute;
        left:0;
      }
      .stafflines {
        stroke-width:<xsl:value-of select="$staffLineWidth * $scaleStepSize"/>px;
        width: 100%;
      }
      .ineume > .stafflines {
        z-index:-10;
      }
      .slur {
        stroke-width:<xsl:value-of select="$slurLineWidth * $scaleStepSize"/>px;
      }
      .note {
        fill:currentColor;
        stroke:none;
      }
      .ledgerlines {
        stroke:currentColor;
        stroke-width:<xsl:value-of select="$scaleStepSize * 2 * ($noteheadSize + $ledgerLineProtrusion)"/>;
        stroke-dasharray:<xsl:value-of select="concat($scaleStepSize * $ledgerLineWidth,' ',$scaleStepSize *(2 - $ledgerLineWidth))"/>;
        stroke-dashoffset:<xsl:value-of select="-.5*$scaleStepSize*$ledgerLineWidth"/>;
      }
      .liquescent .ledgerlines {
        stroke-width:<xsl:value-of select="$scaleStepSize * 2 * ($liquescentNoteheadSize + $ledgerLineProtrusion)"/>;
      }
      .liquescent {
        color:<xsl:value-of select="$liquescentColor"/>;
      }
      .dummy.note {
        opacity:.5;
      }
      .musicLayer > .sb, .musicLayer > .pb {
        min-width:<xsl:value-of select="$scaleStepSize * $sbPbWidth"/>px;
        height:100%;
      }
      .breakWrapper > .musicLayer > .pb, .breakWrapper > .musicLayer > .sb {
        z-index:10;
      }
      <!-- We create the sort-of barlines that mark a page or system break in the source 
           using borders of pseudo-elements before and after -->
      .musicLayer > .sb:after, .musicLayer > .pb:after {
        content:"";
        border-left:<xsl:value-of select="$sbPbLineWidth"/>px solid;
        position:absolute;
        left:<xsl:value-of select=".5*($sbPbWidth * $scaleStepSize - $sbPbLineWidth)"/>px;
        height:<xsl:value-of select="$scaleStepSize * $sbPbMarkerHeight"/>px;
        margin-top: <xsl:value-of select="$musicAreaHeight - $scaleStepSize * $sbPbMarkerHeight"/>px;
        z-index:-1;
      }
      .musicLayer > .pb:after {
        border-right:<xsl:value-of select="$sbPbLineWidth"/>px solid;
        width:<xsl:value-of select="$pbLineDistance * $scaleStepSize"/>px;
      }
      .musicLayer .folioDescription {
        position:relative;
        border:1px solid black;
        font-style:italic;
        min-width:1em;
        min-height:1em;
        top:<xsl:value-of select="$musicAreaHeight - $scaleStepSize * $sbPbMarkerHeight"/>px;
        margin-top:-1em;
        background-color:rgba(255,255,255,.9);
        z-index: 10;
      }
      .musicLayer > .pb, .musicLayer > .sb {
        margin-right:1em;
        vertical-align:top;
      }
<!--    </style>
    <style type="text/css"><!-\- Text styling -\->-->
      <!-- To make contenteditable fields visible when they are empty, we dislay a rectangle instead: 
           We create two empty inline-blocks.
           One (:after) makes sure the layout is reserving room,
           the other one (:before) is drawing the rectangle -->
      ._mei *[contenteditable=true]:empty:after, *[contenteditable=true]:empty:before {
        content:"";
        display:inline-block;
        height:1em;
        min-width:.5em;
        z-index:-1;
      }
      .meiHead *[contenteditable=true]:empty:before {
        content:attr(title);
        opacity:.5;
        color:black;
      }
      ._mei *[contenteditable=true]:empty:not(:focus):before {
        position:relative;
        border:1px dotted black;
        opacity:.5;
      }
      <!-- We don't support line breaks in our contenteditable fields -->
      ._mei [contenteditable] * {
        display:inline;
      }
      ._mei [contenteditable] br {
        display:none;
      }
<!--    </style>
    <style type="text/css"> <!-\- Layout fine tuning -\->-->
      .sb.edition {
        min-width:<xsl:value-of select="$lineLeftMargin - $lineLabelPadding"/>px;
        padding-right:<xsl:value-of select="$lineLabelPadding"/>px;
        vertical-align:top;
        margin-right:1em;
      }
      .sb.edition > .att_label {
        position:absolute;
        white-space:nowrap;
        margin-top:-1em;
      }
      .sb.edition > .att_label:not(:focus) {
        text-transform:uppercase;
      }
      .sb.edition > .att_n {
        <!-- We want to center this field centered vertically before the staff, which is at 
             half the $musicAreaHeight.  We have to take into account the 1em height taken away
             by the rubric caption that's placed above and half this field's own em height. -->
        vartical-align:top;
        margin-top:<xsl:value-of select=".5*$musicAreaHeight"/>px;
        -webkit-transform:translatey(-.25em);
        transform:translatey(-.25em);
      }
      <!-- We want to visualize wrapped lines by indenting the part(s) that don't fit on the first line.
           This is kind of a "reverse indent" as usually you have the first paragraph of a text indented.
           Because text-indent applies to the first part of the wrapped line, we need to make it negative 
           and shift the whole block to the right using margin-left --> 
      .editionLine {
        text-indent:<xsl:value-of select="-$indentOnLineBreak - $lineLeftMargin"/>px;
        margin-left:<xsl:value-of select=" $indentOnLineBreak + $lineLeftMargin"/>px;
        margin-bottom:-2em;
      }
      .editionLine > * {
        text-indent:0;
      }
      .syl {
        <!-- We left-align the syllable text with the first notehead and shift by the desired value -->
        margin-left:<xsl:value-of select="(.5*($noteSpace - $noteheadSize) - $leftShiftOfSyllableText)*$scaleStepSize"/>px;
        margin-right:<xsl:value-of select="$paddingAfterSyllableText * $scaleStepSize"/>px;
      }
      <!-- It's more pleasing to have a little more space to the left of the first notes, so we shift all the "first" music and text elements in the line -->
      <!-- TODO: Is there a better way? This feels a little hacky. -->
      .sb.edition + .syllable > .textLayer > .syl,
      .sb.edition + .syllable > .musicLayer > .ineume:first-of-type {
        margin-left:<xsl:value-of select="$paddingBeforeFirstSyllable * $scaleStepSize"/>px;
      }
      .musicLayer {
        margin-bottom:<xsl:value-of select="$musicTextDistance * $scaleStepSize"/>px;
        min-height: <xsl:value-of select="$musicAreaHeight + $scaleStepSize * $spaceBelowStaff"/>px;
      }
      .sb.source:after {
        padding-right:<xsl:value-of select="$paddingAfterSyllableText * $scaleStepSize"/>px;
      }
      .hyphen {
        margin-left:<xsl:value-of select="$paddingAroundHyphen * $scaleStepSize"/>px;
        <!-- After hyphens, we don't need as much space as after usual syllables, 
             therefore subtract the usual padding and "replace" it with the hyphen padding --> 
        margin-right:<xsl:value-of select="($paddingAroundHyphen - $paddingAfterSyllableText)*$scaleStepSize"/>px;
      }
      .ineume {
        padding-right:<xsl:value-of select="$paddingAfterIneume * $scaleStepSize"/>px;
        margin-bottom:.5em;
      }
      .ineume:last-of-type {
        margin-right:<xsl:value-of select="$paddingAfterSyllablePitches * $scaleStepSize"/>px; 
      }
      <!-- Apostrophae are usually spaced closer together -->
      .apostropha .note + .note {
        margin-left:<xsl:value-of select="($apostrophaSpace - $noteSpace)*$scaleStepSize"/>px;
      }
      
      <!-- Header Styles -->
      <!--.relationList > .sbN, .classification .term, .repository > * {-->
      .relationList > .sbN:empty {
        display:none;
      }
      .workDesc {
        margin-top:3em;
      }
      .work *, .seriesStmt > *, .repository > *, .sourceDesc > *, .provenance > .name > *, .meiHead > div:not(._mei) > * {
        display:inline;
        padding:.2em;
      }
      .meiHead > *  * {
        display:inline;
      }
      [title="transcription no."] {
         border: 1px solid black;
       }
      .geogName:after, .title > .num:after, .term[title=genre]:after, .incipText > .p:after, .identifier:not(:last-of-type):after {
        content:",";
      }
      .seriesStmt > .title > .num:after {
        content:" -";
      }
      .classification, .sourceDesc * {
        display:inline;
      }
      .physLoc, .sourceDesc, .repository, .work, .meiHead > *, .biblList > .bibl {
        display:block;
      }
      .meiHead .term:not(:empty), .relation > *:first-child {
        margin-right:.5em;
      }
      .biblList {
        display:block;
        <!--padding-top: 1em;-->
      }
      .relation:before {
        content:"(";
      }
      .relation:after {
        content:")";
      }
      .meiHead [contenteditable]:empty:before {
        position:relative;
      }
      <!--</style>-->
    <!-- TODO: Fix the following annotation display -->
    <xsl:if test="$displayAnnotations = 'true'">
      <!--<style type="text/css"> <!-\- Annotation styling -\->-->
        <!-- First of all, make space for the annotations -->
        .editionLine {
          padding-top:<xsl:value-of select="$musicAnnotHeight * $scaleStepSize"/>px;
          padding-bottom:<xsl:value-of select="$textAnnotHeight * $scaleStepSize"/>px;
        }
        .textLayer { <!-- We don't want music and text layer annotations to overlap -->
          <!--margin-top:4px;-->
          height:0;
          transform:translate(0,<xsl:value-of select="$musicAreaHeight"/>px);
          -webkit-transform:translate(0,<xsl:value-of select="$musicAreaHeight"/>px);
          position: relative;
          z-index:10;
        }
        <!-- Now, to the annotation labels themselves -->
        .annotLabel {
          display:block;
          position:absolute;
          width:100%;
          height:100%;
          font-size:80%;
        }
        .annotLabel:before { <!-- This creates the box around the label and the annotated element -->
          content:"";
          position:absolute;
          bottom:1px;
          right:1px;
          border:1px solid currentColor;
          border-radius:<xsl:value-of select="$annotLabelBorderRadius"/>px;
          z-index:-1;
        }
        .musicLayer > .sb.source > .annotLabel:before {
          height:<xsl:value-of select="$musicAreaHeight"/>px;
        }
        .annotLabel > a { <!-- This contains the actual label text -->
          <!--position:absolute;-->
          position:relative;
          <!--width:min-content;-->
          <!-- TODO: Displaying full width works with display:inline-block, but position has to be fixed.
                     Is there a specific reason for using block instead of inline-block? -->
          display:block;
          color:black;
          border-radius:<xsl:value-of select="$annotLabelBorderRadius"/>px;
          white-space:nowrap;
          text-decoration:none;
          text-align:center;
          overflow:hidden;
          min-width:1em;
          margin-bottom:-.8em;
          max-width:100%;
          z-index:1;
        }
        .annotLabel > a, .annotLabel:before { <!-- In general, we shift the label "out of the way" to the top... -->
          margin-top:-1em;
          top:1px;
          left:1px;
          right:1px;
        }
        <!-- ...but we don't do it for these typical annotations: -->
        .note    > .annotLabel > a,
        .note    > .annotLabel:before,
        .textLayer .annotLabel > a,
        .textLayer .annotLabel:before,  
        .sb.edition .annotLabel > a,
        .sb.edition .annotLabel:before,
        .musicLayer > .sb.source > .annotLabel > a, 
        .musicLayer > .sb.source > .annotLabel:before 
        { 
          margin-top:1px;
        }
        <!-- This is the background for the label -->
        .annotLabel > a:before {
          content:"";
          position:absolute;
          display:block;
          width:100%;
          height:100%;
          background-color:currentColor;
          opacity:.2;
          z-index:-1;
        }
        .annotLabel > a:empty:after { <!-- TODO: Replace this by a min-width solution -->
          content:"_";
          opacity:0;
        }
        .endAnnot > a {
          text-align:right;
        }
        .startAnnot > a {
          text-align:left;
        }
        .annotLabel.accumulatedAnnot {
          display:none; <!-- We don't show labels if there is more than one because they would stack up and be unreadable -->
        }
        .annotGroup:hover {
          width:auto; <!-- We want to show the full labels on hover, so make width adjust to the length of the labels. -->
        }
        .annotGroup:hover:before {
          border:none; <!-- As we make .annotGroup wider on hover, the border would enclose more elements than it should; so we hide it. -->
        }
        .annotGroup:hover > .annotLabel {
          display:block;
          position:relative;
          height:2.5em;
          z-index:10;
        }
        .annotGroup:hover > .annotLabel:before {
          border:none;
        }
        ._mei .annotGroup:hover > .annotLabel > a:before {
          border:none;
        }
        .annotGroup:hover > .annotLabel > a {
          overflow:visible;
          min-width:3em;
        }
        .annotGroup:hover > a {
          display:none;  <!-- Hide the "+" -->
        }
        <!-- Special styling of music layer annotations -->
        <!--.nc   > .annotLabel:before, 
        .note > .annotLabel:before {
          height:<xsl:value-of select="$musicAreaHeight + $musicAnnotHeight * $scaleStepSize"/>px;
        }
        .note > .annotLabel, 
        .nc   > .annotLabel {
          height:<xsl:value-of select="$musicAnnotHeight * $scaleStepSize"/>px;
          top:<xsl:value-of select="-$musicAnnotHeight * $scaleStepSize"/>px;
          border-radius:<xsl:value-of select="$annotLabelBorderRadius"/>px;
          <!-\-overflow:hidden;-\->      
        }
        .nc   > .annotLabel > a,
        .note > .annotLabel > a { <!-\- This is for annotations for notes and spaces -\->
          transform-origin:right;
          transform:translate(-100%,-50%) rotate(270deg) translate(0,50%) translate(-1px,1px);
          -webkit-transform-origin:right;
          -webkit-transform:translate(-100%,-50%) rotate(270deg) translate(0,50%) translate(-1px,1px);
          -o-transform-origin:right;
          -o-transform:translate(-100%,-50%) rotate(270deg) translate(0,50%) translate(-1px,1px);
          max-width:<xsl:value-of select="$scaleStepSize * $musicAnnotHeight"/>px;
          left:auto;
          right:auto;
          top:auto;
        }
        .nc   > .annotLabel.endAnnot > a, 
        .note > .annotLabel.endAnnot > a {
          transform:        translate(-1px,-50%) rotate(270deg) translate(-1px,-50%) ;
          -webkit-transform:translate(-1px,-50%) rotate(270deg)  translate(-1px,-50%) ;
          -o-transform:     translate(-1px,-50%) rotate(270deg)  translate(-1px,-50%) ;
        }-->
        
        <!-- Special styling for text layer annotations -->
        .textLayer .annotLabel,
        .sb.edition .annotLabel {
          top:<xsl:value-of select="$textAnnotHeight * $scaleStepSize"/>px;
          left:-3px;
          padding-right:6px;
        }
        .textLayer .annotLabel:before,
        .sb.edition .annotLabel:before {
          top:<xsl:value-of select="-$textAnnotHeight * $scaleStepSize"/>px;
        }
  
        <!-- Define "brackets" for start/end annotation labels by making some borders open -->
        .startAnnot:before {
          border-right-color:transparent;
          border-radius:<xsl:value-of select="concat($annotLabelBorderRadius,'px 0 0 ',$annotLabelBorderRadius,'px')"/>;
          <!--background-image: -moz-linear-gradient(left, currentColor 0%, rgba(100,100,100,0) 90%);-->
        }
        .endAnnot:before {
          border-left-color:transparent;
          border-radius:<xsl:value-of select="concat('0 ',$annotLabelBorderRadius,'px ',$annotLabelBorderRadius,'px 0')"/>;
          right:0;
        }
        <!-- On the text layer, we don't multiLayerAnnots to have a top border (for music layer, an exception is defeind below) -->
        .annotLabel.multiLayerAnnot:before {
          border-top-color:transparent;
        }
        .annotLabel.startAnnot.multiLayerAnnot:before {
          border-radius:0 0 0 <xsl:value-of select="$annotLabelBorderRadius"/>px;
        }
        .musicLayer .annotLabel.startAnnot.multiLayerAnnot:before {
          border-radius:<xsl:value-of select="$annotLabelBorderRadius"/>px 0 0 0;
          border-color:currentColor transparent transparent currentColor;
        }
        .annotLabel.endAnnot.multiLayerAnnot:before {
           border-radius:0 0 <xsl:value-of select="$annotLabelBorderRadius"/>px 0;
           border-color:transparent currentColor currentColor transparent;
        }
        .musicLayer .annotLabel.endAnnot.multiLayerAnnot:before {
          border-radius:0 <xsl:value-of select="$annotLabelBorderRadius"/>px 0 0;
          border-color:currentColor currentColor transparent transparent;
        }
        <!-- Special style to show that this is an annotation spanning multiple elements -->
        .annotLabel.multiElementAnnot:before {
          border-style:dotted;
        }
        
        <xsl:call-template name="create-annotation-color-styles"/>
      
      
      <!-- "Spell checking" detecting some weird situations/bad encoding -->
      
      .note.unpitched, .liquescent.uLiquescentFollowing, .liquescent.dLiquescentFollowing {
        background-color:rgba(100%,10%,0%,.5);
      }
      .note.unpitched:after, .liquescent.uLiquescentFollowing:after, .liquescent.dLiquescentFollowing:after {
        color:black;
        left:0;
        position:absolute;
        white-space: nowrap;
        background-color:rgba(100%,100%,100%,.5);
      }
      
      <!-- This is a warning: Liquescents with these class only occur when there are two consecutive liquescents
             with unknown pitch, which is basically wrong -->
      .note.unpitched:after {
        content: "Error: Can't display unknown pitch";
      }
      .liquescent.uLiquescentFollowing:after, .liquescent.dLiquescentFollowing:after {
        content: "Warning: Liquescent followed by liquescent with unkown pitch"
      }
      <!--</style>-->
    </xsl:if>
    <xsl:if test="$interactiveCSS='true'">
      <!--<style type="text/css"><!-\- Interactive CSS -\->-->
        .note:hover:before, .musicLayer > .sb:hover:before, .musicLayer > .pb:hover:before { <!-- Highlighting of music layer elements -->
          content:"";
          position:absolute;
          width:100%;
          height:<xsl:value-of select="$musicAreaHeight"/>px;
          background-color:rgba(0,0,0,.2);
        }
        .annotLabel > a:hover {
          width:max-content;
          max-width:none;
          border:1px solid currentColor;
          background-color:#fff;
          z-index:1;
          min-width:100%;
          position:absolute;
        }
        .annotLabel > a:hover > .annotSelectionExtender:before {
          content:"↔";
          border:1px solid black;
          background-color: rgba(255,255,255,.5);
          padding:.4em;
        }
        .annotLabel > a:hover {
          min-width:3em;
          text-align:right;
        }
        .annotLabel:not(.endAnnot) > a:hover {
          right:auto;
        }
        .annotLabel.endAnnot > a:hover {
          left:auto;
        }
        [contenteditable]:not(:empty):hover, [contenteditable]:empty:focus:hover, [contenteditable=true]:not(:focus):hover:empty:before {
          background-color:rgba(0%,53%,80%,.1);
        }
      <!--</style>-->
    </xsl:if>
      
      <!-- For batch print, we must prevent collisions between two consequent documents -->
      
      ._mei.mei + ._mei.mei:before {
        content:"";
        display:block;
        height:<xsl:value-of select="$musicAreaHeight"/>px;
      }
      
      <xsl:if test="$printAnnotations">
        .printedAnnots {
          display:none;
        }
        
        @media print {
          .printedAnnots {
            display: table;
            margin-top:2em;
            border-collapse: collapse;
          }
          .printedAnnot {
            display: table-row;
            border: .1em solid black;
          }
          .printedAnnot:before {
            content:attr(type);
          }
          .printedAnnot > *,
          .printedAnnot:before {
            display:table-cell;
            min-width:1.5em;
            border: .1em solid black;
            padding: .2em;
          }
        }
      </xsl:if>
    </style>
  </xsl:template>
  
  <xsl:template name="create-annotation-color-styles">
    <!-- Turns a list (like "typesetter:red; internal:blue; specialNeumes:green;") into proper style, like
         .annotLabel.typesetter { border-color:red;} .annotLabel.internal { border-color:blue;} etc. -->
    <xsl:param name="styleDefinitions" select="$annotationColorCodes"/>
    <xsl:if test="contains($styleDefinitions,';')">
      <xsl:variable name="annotationClass" select="substring-before($styleDefinitions,':')"/>
      <xsl:variable name="annotationColor" select="substring-before(substring-after($styleDefinitions,':'),';')"/>
      <xsl:value-of select="concat('._mei .annotLabel.',normalize-space($annotationClass),'{color:',$annotationColor,';}&#10;')"/>
      <xsl:value-of select="concat('._mei .annotLabel.',normalize-space($annotationClass),' > a:before{background-color:',$annotationColor,';}&#10;')"/>
      <xsl:call-template name="create-annotation-color-styles">
        <xsl:with-param name="styleDefinitions" select="substring-after($styleDefinitions,';')"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <!-- Don't copy text nodes that only have white space -->
  <xsl:template match="text()[normalize-space()='']"/>

  <!-- meiHead formatting -->
  <xsl:template match="mei:meiHead">
    <div class="_mei meiHead">
      <xsl:apply-templates select="@xml:id"/>
      <!-- Section/volume number -->
      <xsl:apply-templates select="mei:fileDesc/mei:seriesStmt"/>
      <!-- source no., source identifier -->
      <div>
        <xsl:apply-templates select="mei:fileDesc/mei:sourceDesc/@xml:id"/>
        <xsl:apply-templates select="mei:fileDesc/mei:sourceDesc/@n" mode="process-editable-attributes"/>
        <xsl:apply-templates select="mei:fileDesc/mei:sourceDesc/mei:source/@label" mode="process-editable-attributes"/>
      </div>
      <div>
        <xsl:apply-templates select="mei:workDesc/mei:work/@n" mode="process-editable-attributes"/>
        <!-- Genre, regulardized incipt, standardized feast, start folio -->
        <xsl:apply-templates select="mei:workDesc/mei:work/mei:classification/mei:termList[@label='genre']"/>
        <xsl:apply-templates select="mei:workDesc/mei:work/mei:incip"/>
        <xsl:apply-templates select="mei:workDesc/mei:work/mei:classification/mei:termList[@label='regularizedLiturgicFunction']"/>
        <xsl:apply-templates select="mei:fileDesc/mei:sourceDesc/mei:source/mei:physDesc/mei:extent/mei:identifier[@type='startFolio']"/>
      </div>
      <!-- Übersichtszeile: -->
      <div>
        <!-- Text edition shorthand, text number -->
        <xsl:apply-templates select="mei:workDesc/mei:work/mei:relationList"/>
        <!-- Base chant incipit -->
        <xsl:apply-templates select="mei:workDesc/mei:work/mei:classification/mei:termList[@label='baseChantIncipit']"/>
        <!-- feast, service, base chant genre -->
        <xsl:apply-templates select="mei:workDesc/mei:work/mei:classification/mei:termList[@label='liturgicFunction']"/>
        <!-- trope element numbers -->
        <xsl:for-each select="//mei:sb[not(@source)]/@n">
          <xsl:value-of select="concat(.,' ')"/>
        </xsl:for-each>
      </div>
      <div>
        <!-- melody catalogue author, melody number, trope complex number -->
        <xsl:apply-templates select="mei:workDesc/mei:work/mei:biblList/mei:bibl/*[preceding-sibling::mei:genre='melody catalogue']"/>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="mei:music">
    <div class="_mei music">
      <xsl:apply-templates select="@*"/>
      <svg:svg style="display:none">
        <svg:defs>
          <svg:path id="{$idPrefix}standardNotehead" transform="scale({.006 * $scaleStepSize}) scale(1,-1) translate(-189)"
              d="M152 -174c-80 0 -152 54 -152 143c0 99 108 204 224 204c102 0 154 -68 154 -140c0 -118 -114 -207 -226 -207z" />
          <svg:path id="{$idPrefix}oriscusNotehead" transform="scale({.006 * $scaleStepSize}) scale(1,-1) translate(-218)" stroke="none"
              d="M32 -180c-54 0 -33 186 9 340c5 17 24 18 41 18c-3 -100 -8 -165 30 -165c43 0 238 168 292 168s33 -186 -9 -340c-4 -17 -24 -18 -40 -18c3 100 7 165 -30 165c-44 0 -239 -168 -293 -168z"/>
          <svg:path id="{$idPrefix}quilismaNotehead" transform="scale({.006 * $scaleStepSize}) scale(1,-1) translate(-275)"
              d="M0 32c0 32 84 119 111 119c26 0 110 -126 140 -126c31 0 228 105 279 139c25 17 27 -18 10 -42c-48 -68 -303 -288 -363 -288c-33 0 -177 164 -177 198z"/>
          <svg:path id="{$idPrefix}apostrophaNotehead" transform="scale({.006 * $scaleStepSize}) scale(1,-1) translate(-129)"
              d="M122 108c25 0 136 -78 136 -105c0 -42 -156 -237 -202 -270c-18 -12 -48 -9 -39 7c18 32 88 149 88 174c0 26 -105 69 -105 86c0 24 93 108 122 108z" />
          <svg:path id="{$idPrefix}dLiquescentFollowingNotehead" transform="scale({.006 * $scaleStepSize}) scale(1,-1) translate(-189)"
            d="M378 34v-9v-440c0 -16 -16 -22 -42 -21c4 99 9 235 10 367c-41 -63 -118 -104 -194 -104c-80 0 -152 54 -152 143c0 99 108 204 224 204c102 0 154 -68 154 -140z" />
          <svg:path id="{$idPrefix}uLiquescentFollowingNotehead" transform="scale({.006 * $scaleStepSize}) scale(1,-1) translate(-189)"
              d="M152 -174c-80 0 -152 54 -152 143c0 99 108 204 224 204c58 0 97 -26 117 -53l1 2c-1 12 -3 28 -4 66l-6 228c0 18 22 25 46 19v-402c0 -118 -114 -207 -226 -207z" />
          <svg:path id="{$idPrefix}sAccidental" transform="scale({.006 * $scaleStepSize}) scale(1,-1)"
              d="M0 -149c0 -7 -1 -10 -9 -12l-76 -24v-175c0 -8 -20 -15 -33 -12c0 46 -1 108 -1 177l-101 -32v-183c0 -8 -20 -14 -33 -12c0 48 -1 113 -1 185l-68 -21c-11 -3 -17 0 -17 12v93c0 6 2 8 9 10l75 23c-1 62 -2 125 -2 186l-65 -20c-11 -3 -17 0 -17 12v93c0 6 2 9 9 11
               l72 22c-1 71 -1 133 -1 174c0 18 22 26 46 18c-2 -35 -3 -100 -4 -180l92 29c-1 74 -1 139 -1 181c0 20 24 26 47 20c-2 -36 -3 -105 -4 -188l70 21c9 3 13 0 13 -9v-94c0 -8 -1 -9 -9 -12l-75 -23c0 -62 -1 -126 -1 -189l72 23c9 3 13 0 13 -9v-95zM-121 -79l-2 187
               l-96 -30c0 -61 0 -125 -1 -187z"/>
          <svg:path id="{$idPrefix}fAccidental" transform="scale({.006 * $scaleStepSize}) scale(1,-1)"
              d="M-228 427c-3 -60 -5 -174 -6 -289c26 40 80 78 132 78c64 0 102 -50 102 -125c0 -144 -203 -306 -245 -306c-13 0 -25 6 -25 30c-3 137 -8 491 -8 597c0 15 24 17 50 15zM-156 148c-29 0 -60 -30 -79 -55c-1 -103 -1 -203 -1 -261c84 63 128 151 128 234
                c0 51 -18 82 -48 82z" />
          <svg:path id="{$idPrefix}nAccidental" transform="scale({.006 * $scaleStepSize}) scale(1,-1)"
              d="M-7 183c0 -193 7 -395 7 -548c0 -15 -16 -20 -42 -20c2 59 4 156 4 257l-157 -70c-12 -5 -16 3 -16 15c0 235 -8 409 -8 547c0 15 17 20 42 20c-2 -60 -3 -156 -4 -257l156 68c12 4 18 -2 18 -12zM-181 24v-113l144 64v113z" />
        </svg:defs>
      </svg:svg>
      <xsl:apply-templates select="*|text()"/>
    </div>
  </xsl:template>
  
  <xsl:template match="mei:*" name="standard-transformation">
    <div class="_mei {local-name()}">
      <xsl:attribute name="class">
        <xsl:value-of select="concat('_mei ',local-name())"/>
        <xsl:apply-templates select="@*" mode="generate-classes"/>
      </xsl:attribute>
      <xsl:apply-templates select="." mode="create-title"/>
      <xsl:apply-templates select="." mode="create-contenteditable"/>
      <xsl:apply-templates select="@xml:id"/>
      <xsl:apply-templates select="@*" mode="process-editable-attributes"/>
      <xsl:apply-templates select="@*[not(local-name()='id')]|*|text()"/>
    </div>
  </xsl:template>
  
  <xsl:template match="@*" mode="generate-classes"/>
  <xsl:template match="@source" mode="generate-classes">
    <xsl:value-of select="' source '"/>
  </xsl:template>
  
  <xsl:template match="@*" mode="process-editable-attributes"/>
  <xsl:template match="mei:sourceDesc/@n|mei:source/@label|mei:work/@n|mei:relation/@label|mei:relation/@n|mei:sb/@label|mei:sb/@n" mode="process-editable-attributes">
    <div data-editable-attribute="{local-name()}" data-element-id="{../@xml:id}" class="att_{local-name()}">
      <xsl:call-template name="set-content-editable"/>
      <xsl:apply-templates select="." mode="create-title"/>
      <xsl:value-of select="."/>
    </div>
  </xsl:template>
  
  <xsl:template match="mei:layer">
    <div class="_mei layer">
      <!-- We render line by line, therefore find all system breaks -->
      <xsl:apply-templates select="@xml:id|mei:sb[not(@source)]"/>
    </div>
  </xsl:template>
  
  <xsl:template match="mei:sb[not(@source)]">
    <div class="editionLine">
      <div class="_mei sb edition">
        <xsl:apply-templates select="@xml:id"/>
        <xsl:apply-templates select="@label" mode="process-editable-attributes"/>
        <xsl:apply-templates select="@n" mode="process-editable-attributes"/>
      </div>
      <xsl:apply-templates select="following-sibling::*
        [not(self::mei:sb) or @source]
        [generate-id(preceding-sibling::mei:sb[not(@source)][1]) = generate-id(current())]"/>
    </div>
    <xsl:if test="$printAnnotations = 'true'">
      <div class="printedAnnots">
        <xsl:apply-templates mode="print-annotations"
          select="following-sibling::*
          [not(self::mei:sb) or @source]
          [generate-id(preceding-sibling::mei:sb[not(@source)][1]) = generate-id(current())]//@xml:id|@xml:id"/>
      </div>
    </xsl:if>
  </xsl:template>
  
  <xsl:template mode="print-annotations" match="@xml:id">
    <xsl:apply-templates select="//mei:annot[string(@startid) = concat('#', current())]" mode="print-annotations"/>
  </xsl:template>
  
  <xsl:template mode="print-annotations" match="mei:annot">
    <div class="printedAnnot" type="{@type}">
      <div class="label">
        <xsl:value-of select="@label"/>
      </div>
      <div class="text">
        <xsl:value-of select="."/>
      </div>
    </div>
  </xsl:template>
  
  <!-- This creates a "building block" consisting of staff lines and a text layer -->
  <xsl:template match="mei:syllable">
    <div class="_mei {local-name()}">
      <xsl:apply-templates mode="create-title" select="."/>
      <xsl:apply-templates select="@xml:id"/>
      <!-- If the first element on the music layer is a pb/sb, we want to put that into a separate div
           so that the text starts with the first note in the syllable. -->
      <xsl:for-each select="mei:*[self::mei:sb or self::mei:pb][not(preceding-sibling::mei:ineume)]">
        <div class="breakWrapper">
          <div class="musicLayer">
            <xsl:copy-of select="$stafflines"/>
            <xsl:apply-templates select="."/>
          </div>
        </div>
      </xsl:for-each>
      <div class="syllabeContentWrapper">
        <div class="textLayer">
          <xsl:apply-templates select="mei:syl"/>
        </div>
        <div class="musicLayer">
          <xsl:copy-of select="$stafflines"/>
          <xsl:apply-templates select="mei:ineume|mei:*[self::mei:sb or self::mei:pb][preceding-sibling::mei:ineume]"/>
        </div>
      </div>
    </div>
  </xsl:template>
  
  <xsl:template match="mei:ineume|mei:sb[@source]">
    <div>
      <xsl:attribute name="class">
        <xsl:value-of select="concat('_mei ',local-name())"/>
        <xsl:apply-templates select="@*" mode="generate-classes"/>
      </xsl:attribute>
      <xsl:apply-templates select="." mode="create-title"/>
      <xsl:apply-templates select="@xml:id"/>
      <xsl:apply-templates select="@*[not(local-name()='id')]|*"/>
      <xsl:copy-of select="$stafflines"/>
    </div>
  </xsl:template>
  
  
  <!-- By default, don't create title element -->
  <xsl:template match="*|@*" mode="create-title"/>
  <!-- For specific elements, create a title -->
  <xsl:template match="mei:sb[@source]" mode="create-title">
    <xsl:attribute name="title">line break in the source</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:syllable/mei:pb" mode="create-title" priority="1">
    <xsl:attribute name="title">page break in the source</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:seriesStmt/mei:title/mei:num" mode="create-title">
    <xsl:attribute name="title">section no.</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:seriesStmt/mei:identifier/mei:num" mode="create-title">
    <xsl:attribute name="title">volume no.</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:term[@label]" mode="create-title">
    <xsl:attribute name="title"><xsl:value-of select="@label"/></xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:term[@label='baseChantGenre']" mode="create-title" priority="1">
    <xsl:attribute name="title">base chant genre</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:work/@n" mode="create-title">
    <xsl:attribute name="title">transcription no.</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:relation/@label" mode="create-title">
    <xsl:attribute name="title">text edition incl. volume no.</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:relation/@n" mode="create-title">
    <xsl:attribute name="title">text's identifying no.</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:work/mei:classification/mei:termList[@label='baseChantIncipit']/mei:term" mode="create-title">
    <xsl:attribute name="title">base chant incipit</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:sourceDesc/@n" mode="create-title">
    <xsl:attribute name="title">source no.</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:sourceDesc/mei:source/@label" mode="create-title">
    <xsl:attribute name="title">source identifier</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:sb[not(@source)]/@label" mode="create-title">
    <xsl:attribute name="title">rubric caption</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:sb[not(@source)]/@n" mode="create-title">
    <xsl:attribute name="title">line no.</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:source/mei:physDesc/mei:provenance/mei:geogName" mode="create-title">
    <xsl:attribute name="title">source provenance</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:repository/mei:geogName" mode="create-title">
    <xsl:attribute name="title">source location</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:repository/mei:corpName" mode="create-title">
    <xsl:attribute name="title">institution</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:repository/mei:identifier" mode="create-title">
    <xsl:attribute name="title">shelf mark</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:work/mei:classification/mei:termList[@label='genre']/mei:term" mode="create-title">
    <xsl:attribute name="title">genre</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:incipText/mei:p" mode="create-title">
    <xsl:attribute name="title">incipit</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:identifier[@type='startFolio']" mode="create-title">
    <xsl:attribute name="title">start folio</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:biblList[@type='textEditions']/mei:bibl/mei:title" mode="create-title">
    <xsl:attribute name="title">
      <xsl:value-of select="concat(count(../preceding-sibling::mei:bibl) + 1,'. text edition title')"/>
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:author[preceding-sibling::mei:genre='melody catalogue']" mode="create-title">
    <xsl:attribute name="title">melody catalogue author</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:identifier[@type='melodyNumber']" mode="create-title">
    <xsl:attribute name="title">melody no.</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:identifier[@type='tropeComplexNumber']" mode="create-title">
    <xsl:attribute name="title">trope complex no.</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:identifier[@type='volumeNumber']" mode="create-title">
    <xsl:attribute name="title">volume no.</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:identifier[@type='textNumber']" mode="create-title">
    <xsl:attribute name="title">text no.</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:biblList[@type='melodyCatalogues']/mei:bibl/mei:author" mode="create-title">
    <xsl:attribute name="title">melody catalogue author</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:bibl[@label='melodyCatalogue']/mei:identifier[@type='melodyNumber']" mode="create-title">
    <xsl:attribute name="title">melody number</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:bibl[@label='melodyCatalogue']/mei:identifier[@type='tropeComplexNumber']" mode="create-title">
    <xsl:attribute name="title">trope complex number</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:provenance/mei:name/mei:geogName" mode="create-title">
    <xsl:attribute name="title">place of provenance</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:provenance/mei:name/mei:corpName" mode="create-title">
    <xsl:attribute name="title">institution</xsl:attribute>
  </xsl:template>
  <!-- TODO: Add more titles -->
  
  <xsl:template match="mei:syl">
    <div class="_mei {local-name()}">
      <xsl:apply-templates select="@xml:id"/>
      <span>
        <xsl:call-template name="set-content-editable"/>
        <xsl:copy-of select="text()"/>
        <!-- We're postponing proper @wordpos handling to 1.x, therefore the following doesn't have an effect right now -->
        <xsl:apply-templates select="@wordpos" mode="create-hyphen"/>
      </span>
    </div>
  </xsl:template>
  
  <xsl:template match="@wordpos[.='i' or .='m']" mode="create-hyphen">                                
    <span class="hyphen">-</span>
  </xsl:template>
  
  <xsl:template mode="create-contenteditable" match="*"/>
  <xsl:template name="set-content-editable" mode="create-contenteditable" match="mei:seriesStmt//mei:num|mei:term|mei:p|mei:repository/*|mei:geogName|mei:corpName|mei:bibl/*|mei:identifier[not(*)]">
    <xsl:if test="$setContentEditable='true'">
      <xsl:attribute name="contenteditable">true</xsl:attribute>
      <xsl:if test="$onblurWorkaroundForEmptyEditableElements='true'">
        <!-- If a contenteditable element is visually empty, but the "*[contenteditable=true]:empty" CSS rule doesn't kick in,
             the following attribute might help to ensure "actual" emptyness: -->
        <xsl:attribute name="onblur">if (event.target.textContent.match(/^\s*$/)) event.target.innerHTML=''</xsl:attribute>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@*"/>

  <!-- This copies the ID and checks for annotations for this ID. -->
  <xsl:template match="@xml:id">
    <xsl:attribute name="id">
      <xsl:value-of select="concat($idPrefix,.)"/>
    </xsl:attribute>
    <xsl:variable name="idRef" select="concat('#',.)"/>
    <xsl:variable name="annotations" select="//mei:annot[contains(concat(@plist, @startid, @endid), $idRef)]"/>
    <xsl:variable name="annotationLabels">
      <xsl:for-each select="$annotations">
        <div class="annotLabel {@type}" data-annotation-id="{@xml:id}">
          <xsl:attribute name="class">
            <xsl:value-of select="concat('annotLabel ',@type,' ')"/>
            <xsl:if test="count($annotations) &gt; 1">
              <!-- TODO: Find a better class name? -->
              <xsl:value-of select="' accumulatedAnnot '"/>
            </xsl:if>
            <!-- Mark annot if we have a start, end, single or multiple annot.
                   We will display them differently (using "bracket" and "corner" shaped borders) -->
            <xsl:choose>
              <xsl:when test="(@startid=$idRef and @endid=$idRef) or normalize-space(@plist)=$idRef">
                <xsl:value-of select="' singleElementAnnot '"/>
              </xsl:when>
              <xsl:when test="contains(@plist, $idRef)">
                <xsl:value-of select="' multiElementAnnot '"/>
              </xsl:when>
              <xsl:when test="@startid=$idRef"> startAnnot </xsl:when>
              <xsl:when test="@endid  =$idRef"> endAnnot </xsl:when>
            </xsl:choose>
            <!-- We now test if both start and end of annotation are on the same "level"
                   (count() will return 1 if on the text layer, 0 otherwise) -->
            <xsl:if test="count(
              key('id',substring(@startid,2))[ancestor-or-self::mei:syl or not(ancestor-or-self::mei:syllable)][1]
            ) != count(
              key('id',substring(@endid  ,2))[ancestor-or-self::mei:syl or not(ancestor-or-self::mei:syllable)][1]
            )">
              <xsl:value-of select="' multiLayerAnnot '"/>
            </xsl:if>
          </xsl:attribute>
          <a href="#{$idPrefix}{@xml:id}" title="{@type} annotation:&#10;{.}">
            <xsl:value-of select="concat(@label,'&#160;')"/>
            <span class="annotSelectionExtender"/>
          </a>
        </div>
      </xsl:for-each>
    </xsl:variable>
    <!-- We copy the annotations here so that we can display them on hover --> 
    <xsl:copy-of select="$annotationLabels"/>
    <xsl:if test="count($annotations) &gt; 1">
      <div class="annotLabel annotGroup">
        <xsl:copy-of select="$annotationLabels"/>
        <a href="#" title="multiple annotations">+</a>
      </div>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="mei:pb[@source]">
    <div class="_mei pb {@label}">
      <xsl:apply-templates select="." mode="create-title"/>
      <xsl:apply-templates select="@xml:id"/>
      <div class="folioDescription">
        <xsl:apply-templates select="." mode="create-title"/>
        <xsl:call-template name="set-content-editable"/>
        <span class="folioNumber">
          <xsl:value-of select="@n"/>
        </span>
        <span class="rectoVerso">
          <!-- We only want "r" or "v" to be displayed, not "recto" or "verso" (waste of space) -->
          <xsl:value-of select="substring(@func,1,1)"/>
        </span>
      </div>
      <!-- Staff lines inside <pb> won't be positioned consistently between 
           Chrome and Firefox, so we leave them out for now. -->
      <!-- <xsl:copy-of select="$stafflines"/> -->
    </div>
  </xsl:template>
  
  <xsl:template match="mei:uneume">
    <!-- We do not use @name or @form in mono:di, but if they were there, it would make sense to hand them on as classes -->
    <div class="_mei uneume {@name} {@form}">
      <xsl:apply-templates select="@xml:id"/>
      
      <!-- Add a slur for uneumes with more than one note 
           QUESTION: Do we at all have uneumes with only one element? Maybe this would not make sense. -->
      <xsl:if test="count(descendant::mei:note/@pname) &gt; 1">
        <xsl:variable name="width" select="$scaleStepSize * ($noteSpace * count(descendant::mei:note/@pname) + $accidentalSpace * count(descendant::mei:note[position() &gt; 1]/@accid))"/>
        
        <svg:svg width="{$width}px" height="{$musicAreaHeight}px" 
            viewBox="0 {-$scaleStepSize * ($spaceAboveStaff + 4)} {$width} {$musicAreaHeight}" class="slur">
          <xsl:variable name="highestEndNoteStep">
            <xsl:call-template name="get-highest-notehead-step">
              <xsl:with-param name="noteheads" select="descendant::mei:note[@pname][position() = 1 or position() = last()]"/>
            </xsl:call-template>
          </xsl:variable>
          
          <xsl:variable name="highestCenterNoteStep">
            <xsl:call-template name="get-highest-notehead-step">
              <xsl:with-param name="noteheads" select="descendant::mei:note[@pname]"/>
            </xsl:call-template>
          </xsl:variable>
          
          <xsl:variable name="preliminarySlurStep">
            <xsl:choose>
              <!-- We must avoid that slurs disappear "into the invisible sky" -->
              <xsl:when test="($highestCenterNoteStep - $paddingSlurCenterNotes - 2)*$scaleStepSize &lt; -.5*$musicAreaHeight">
                <xsl:copy-of select="-.5*$musicAreaHeight div $scaleStepSize + 2"/>
              </xsl:when>
              <!-- We also have a lowest slur position -->
              <xsl:when test="$highestCenterNoteStep - $paddingSlurCenterNotes &gt; $lowestSlurPosition">
                <xsl:copy-of select="1"/>
              </xsl:when>
              <xsl:when test="$highestEndNoteStep - $paddingSlurEndNotes &lt; $highestCenterNoteStep - $paddingSlurCenterNotes">
                <xsl:copy-of select="$highestEndNoteStep - $paddingSlurEndNotes"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="$highestCenterNoteStep - $paddingSlurCenterNotes"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          
          <!-- If preliminarySlurEndStep is on a staff line (i.e. $preliminarySlurStep is even), we have to move the slur one step up -->
          <xsl:variable name="y1" select="($preliminarySlurStep - (($preliminarySlurStep * $preliminarySlurStep + 1) mod 2)) * $scaleStepSize"/>
          <xsl:variable name="y2" select="$y1 - 2*$scaleStepSize"/>
          <xsl:variable name="x1" select=".5*($noteSpace - 1) * $scaleStepSize"/>
          <xsl:variable name="x2" select="$width - $x1"/>
          
          <svg:path transform="translate({$scaleStepSize * $accidentalSpace * count(mei:note[1]/@accid)},0)"
              d="M{$x1} {$y1}
                 C{$x1} {$y2} {$x1} {$y2} {.5*($x1 + $x2)} {$y2}
                 C{$x2} {$y2} {$x2} {$y2} {$x2           } {$y1}"/>
        </svg:svg>
      </xsl:if>
      
      <xsl:apply-templates select="*"/>
    </div>
  </xsl:template>
  
  <!-- notehead step of b4 will be 0 because it's in the center of the staff (symmetry makes things easier) -->
  <xsl:template mode="get-notehead-step" match="mei:note[@pname and @oct]" name="get-highest-notehead-step">
    <xsl:param name="noteheads" select="."/>
    <xsl:variable name="sortedSteps">
      <!-- We create a string of integers, each occupying 4 characters (filled up with spaces) -->
      <xsl:for-each select="$noteheads">
        <xsl:sort select="number(translate(@pname,'cdefgab','01234567')) + 7*number(@oct)" order="descending"/>
        <xsl:value-of select="substring(
            concat(
              -(number(translate(@pname,'cdefgab','01234567')) + 7*number(@oct) - 34),
              '    '
            ),1,4
          )"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:copy-of select="number(substring($sortedSteps,1,4))"/>
  </xsl:template>
  <!-- Notes without clear pitch orient themselves by their preceding note 
       We only need this template for erroneous consecutive liquescents with unknown pitch -->
  <xsl:template mode="get-notehead-step" match="mei:note[not(@pname and @oct)]">
    <xsl:apply-templates select="preceding::mei:note[1]" mode="get-notehead-step"/>
  </xsl:template>

  <!-- We don't render properly encoded liquescents of unknown pitch when preceded by a normal note as both pitches are unified in one symbol -->
  <xsl:template match="mei:note[@intm and @label='liquescent' and not(@pname and @oct)]
                               [preceding-sibling::*[1]/self::mei:note[@pname and @oct]]"/>
  <xsl:template match="mei:note">
    <div>
      <xsl:variable name="noteheadType">
        <xsl:apply-templates select="." mode="get-notehead-type"/>
      </xsl:variable>
      <xsl:attribute name="class">
        <xsl:value-of select="concat('_mei note ',@label,' ',$noteheadType,' ')"/>
        <xsl:if test="not(@pname and @oct)">unpitched</xsl:if>
      </xsl:attribute>
      <xsl:apply-templates select="@xml:id"/>
      
      <xsl:variable name="noteheadStep"><!-- $noteheadStep = 0 means note is on center line (i.e. a "b") -->
        <xsl:apply-templates mode="get-notehead-step" select="."/>
      </xsl:variable>
      <xsl:variable name="requiredAccidentalSpace" select="$scaleStepSize * $accidentalSpace * count(@accid)"/>
      
      <svg:svg width="{$noteSpace * $scaleStepSize + $requiredAccidentalSpace}px" height="{$musicAreaHeight}px" 
          viewBox="{-.5*$noteSpace * $scaleStepSize - $requiredAccidentalSpace} {-$scaleStepSize*(4 + $spaceAboveStaff)} {$noteSpace * $scaleStepSize + $requiredAccidentalSpace} {$musicAreaHeight}">
        <!-- Choose if and where to draw ledger lines. Ledgerlines will be styled with dash pattern. -->
        <xsl:choose>
          <xsl:when test="$noteheadStep &lt; -5">
            <svg:line y1="{($ledgerLineWidth - 6)*$scaleStepSize}" y2="{(-.5 + $noteheadStep) * $scaleStepSize}" class="ledgerlines"/>
          </xsl:when>
          <xsl:when test="$noteheadStep &gt; 5">
            <svg:line y1="{(6 - $ledgerLineWidth)*$scaleStepSize}" y2="{( .5 + $noteheadStep) * $scaleStepSize}" class="ledgerlines"/>
          </xsl:when>
        </xsl:choose>
        
        <xsl:if test="@accid"> <!-- if > 0, we have an accidental -->
          <svg:use class="accidental" xlink:href="#{$idPrefix}{@accid}Accidental"
              x="{$scaleStepSize * (-.5*$noteSpace) + 1.2 * $accidentalSpace}" y="{$noteheadStep * $scaleStepSize}"/>
        </xsl:if>
        
        <svg:use xlink:href="#{$idPrefix}{$noteheadType}Notehead">
          <xsl:attribute name="transform">
            translate(0,<xsl:value-of select="$noteheadStep * $scaleStepSize"/>)
            <xsl:if test="contains(@label,'liquescent')">
              scale(<xsl:value-of select="$liquescentNoteheadSize"/>)
            </xsl:if>
          </xsl:attribute>
        </svg:use>
      </svg:svg>
      <xsl:apply-templates select="*|text()"/>
    </div>
  </xsl:template>
  
  <xsl:template match="*" mode="get-notehead-type">
    <xsl:value-of select="'standard'"/>
  </xsl:template>
  <xsl:template match="*[following-sibling::*[1]/self::mei:note[@label='liquescent' and @intm and not(@pname and @oct)]]" mode="get-notehead-type" priority="1">
    <xsl:value-of select="concat(following-sibling::*[1]/self::mei:note/@intm,'LiquescentFollowing')"/>
  </xsl:template>
  <xsl:template match="*[contains(@label,'oriscus'   )]" mode="get-notehead-type">oriscus</xsl:template>
  <xsl:template match="*[contains(@label,'quilisma'  )]" mode="get-notehead-type">quilisma</xsl:template>
  <xsl:template match="*[contains(@label,'apostropha')]" mode="get-notehead-type">apostropha</xsl:template>
  
</xsl:stylesheet>