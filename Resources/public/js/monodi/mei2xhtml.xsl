<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:xhtml="http://www.w3.org/1999/xhtml" 
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    exclude-result-prefixes="svg mei">

  <!-- TODO: - Introduce proper accidental symbols (not font based) 
             - Small caps for base chants -->

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
  <xsl:param name="noteheadEllipticity" select="1.1"/>
  <xsl:param name="noteheadSkew" select="10"/>
  <xsl:param name="liquescentNoteheadSize" select=".7"/>
  <xsl:param name="liquescentColor" select="'#31a'"/>
  <xsl:param name="apostrophaNoteheadSize" select=".5*($noteheadSize + $liquescentNoteheadSize)"/>
  
  <xsl:param name="staffLineWidth" select=".25"/>
  <xsl:param name="ledgerLineWidth" select="$staffLineWidth * 1.3"/>
  <xsl:param name="ledgerLineProtrusion" select=".7"/>
  <xsl:param name="slurLineWidth" select=".6"/>
  <!-- sbPbLineWidth is in pixels -->
  <xsl:param name="sbPbLineWidth" select="2"/>

  <xsl:param name="annotLabelBorderRadius" select="3"/>
  <xsl:param name="musicLineSpacing" select="0"/><!-- This is the distance in pixels -->
  
  <xsl:param name="annotationColorCodes" select="'
    internal:#c11;
    typesetter:#11c;
    public:#a70;
    diacriticalMarking:#384;
    specialProperty:#808;'"/>
  
  <xsl:variable name="stafflines">
    <svg:svg width="100%" height="{$musicAreaHeight}px" viewBox="0 0 1 {$musicAreaHeight}" class="stafflines" preserveAspectRatio="none">
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
        display:inline-block;
        position:relative;
      }
      /* Exceptions to the above display:inline-block:*/
      .annotLabel, <!--.meiHead,--> .annot {
        display:none;
      }
      .editionLine, .fileDesc > .seriesStmt {
        display:block;
      }
      .syllable {
        vertical-align:top;
      }
      .musicLayer {
        height:<xsl:value-of select="$musicAreaHeight"/>px;
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
      @namespace xlink url(http://www.w3.org/1999/xlink);
      
      .stafflines,.slur {
        stroke:currentColor;
        fill:none;
        position:absolute;
      }
      .stafflines {
        stroke-width:<xsl:value-of select="$staffLineWidth * $scaleStepSize"/>px;
      }
      .slur {
        stroke-width:<xsl:value-of select="$slurLineWidth * $scaleStepSize"/>px;
      }
      .note {
        fill:currentColor;
        stroke:none;
      }
      .apostropha use {
        stroke:currentColor;
        stroke-width:<xsl:value-of select="$apostrophaNoteheadSize - $liquescentNoteheadSize"/>;
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
      .apostropha .ledgerlines {
        stroke-width:<xsl:value-of select="$scaleStepSize * 2 * ($apostrophaNoteheadSize + $ledgerLineProtrusion) * $scaleStepSize"/>;
      }
      .liquescent {
        color:<xsl:value-of select="$liquescentColor"/>;
      }
      .dummy.note {
        opacity:.5;
      }
      .accidental {
        font-size:<xsl:value-of select="100 * $scaleStepSize div 3"/>%;
      }
      .musicLayer > .sb, .musicLayer > .pb {
        min-width:<xsl:value-of select="$scaleStepSize * $sbPbWidth"/>px;
        height:<xsl:value-of select="$scaleStepSize * 8"/>px;
        <!--margin-top:<xsl:value-of select="$spaceAboveStaff * $scaleStepSize"/>px;-->
        bottom:<xsl:value-of select="$scaleStepSize * $spaceBelowStaff"/>px;
      }
      <!-- We create the sort-of barlines that mark a page or system break in the source 
           using borders of pseudo-elements before and after -->
      .musicLayer > .sb:after, .musicLayer > .pb:after {
        content:"";
        border-left:<xsl:value-of select="$sbPbLineWidth"/>px solid;
        position:absolute;
        left:<xsl:value-of select=".5*($sbPbWidth * $scaleStepSize - $sbPbLineWidth)"/>px;
        height:<xsl:value-of select="$scaleStepSize * 8"/>px;
        bottom:25px;
        z-index:-1;
      }
      .musicLayer > .pb:after {
        border-right:<xsl:value-of select="$sbPbLineWidth"/>px solid;
        width:<xsl:value-of select="$pbLineDistance * $scaleStepSize"/>px;
        <!--left:<xsl:value-of select=".5*(($sbPbWidth - $pbLineDistance) * $scaleStepSize - $sbPbLineWidth)"/>px;-->
      }
      .folioDescription {
        position:relative;
        border:1px solid black;
        margin:-1px 0;
        font-style:italic;
        min-width:1em;
        height:1em;
        <!--top:<xsl:value-of select="$scaleStepSize * 7"/>px;-->
        background-color:rgba(255,255,255,.9);
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
      }
      ._mei *[contenteditable=true]:not(:focus):empty:before {
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
      }
<<<<<<< HEAD
      .sb.edition .sbLabel {
=======
      .sb.edition .att_label {
>>>>>>> thomas
        margin-bottom:2em;
        margin-right:1em;
      }
      <!-- We want to visualize wrapped lines by indenting the part(s) that don't fit on the first line.
           This is kind of a "reverse indent" as usually you have the first paragraph of a text indented.
           Because text-indent applies to the first part of the wrapped line, we need to make it negative 
           and shift the whole block to the right using margin-left --> 
      .editionLine {
        text-indent:<xsl:value-of select="-$indentOnLineBreak - $lineLeftMargin"/>px;
        margin-left:<xsl:value-of select=" $indentOnLineBreak + $lineLeftMargin"/>px;
      }
      .editionLine > * {
        text-indent:0;
      }
      .syl {
        <!-- We left-align the syllable text with the first notehead and shift by the desired value -->
        margin-left:<xsl:value-of select="(.5*($noteSpace - $noteheadEllipticity * $noteheadSize) - $leftShiftOfSyllableText)*$scaleStepSize"/>px;
        margin-right:<xsl:value-of select="$paddingAfterSyllableText * $scaleStepSize"/>px;
      }
      <!-- It's more pleasing to have a little more space to the left of the first notes, so we shift all the "first" music and text elements in the line -->
      <!-- TODO: Is there a better way? This feels a little hacky. -->
      .sb.edition + .syllable > .textLayer > .syl,
      .sb.edition + .syllable > .musicLayer > .ineume:first-of-type {
        margin-left:<xsl:value-of select="$paddingBeforeFirstSyllable * $scaleStepSize"/>px;
      }
      .musicLayer {
        margin-bottom:<xsl:value-of select="$musicLineSpacing * $scaleStepSize"/>px;
      }
      .sb.source:after {
        padding-right:<xsl:value-of select="$paddingAfterSyllableText * $scaleStepSize"/>px;
      }
      .hyphen {
        margin-left:<xsl:value-of select="$paddingAroundHyphen * $scaleStepSize"/>px;
        <!-- After hyphens, we don't need as much space as after usual syllables, therefore subtract something from the margin --> 
        margin-right:<xsl:value-of select="($paddingAroundHyphen - $paddingAfterSyllableText)*$scaleStepSize"/>px;
      }
      .ineume {
        padding-right:<xsl:value-of select="$paddingAfterIneume * $scaleStepSize"/>px;
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
      .work {
        margin-top:2em;
      }
      .work *, .seriesStmt > *, .repository > *, .sourceDesc > * {
        display:inline;
        padding:.2em;
      }
      .work > .att_n {
         border: 1px solid black;
       }
      .repository > *:after {
        content:","
      }
      .classification, .sourceDesc * {
        display:inline;
      }
      .incip, .physLoc, .sourceDesc, .repository, .work, .meiHead > * {
        display:block;
      }
      .incip {
        position:absolute;
        padding:0;
        margin-top:-3em;
      }
      .relation > .att_label:before {
        content:"(";
      }
      .relation > .att_label:after {
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
          margin-top:<xsl:value-of select="$musicAnnotHeight * $scaleStepSize"/>px;
          padding-bottom:<xsl:value-of select="$textAnnotHeight * $scaleStepSize"/>px;
        }
        .textLayer { <!-- We don't want music and text layer annotations to overlap -->
          margin-top:4px;
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
        .sb.edition .annotLabel:before { 
          margin-top:0;
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
      <!--</style>-->
    </xsl:if>
    <xsl:if test="$interactiveCSS='true'">
      <!--<style type="text/css"><!-\- Interactive CSS -\->-->
        .note:hover:before, .musicLayer > .sb:hover:before, .pb:hover:before { <!-- Highlighting of music layer elements -->
          content:"";
          position:absolute;
          width:100%;
          height:100%;
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
        .annotLabel:hover > a > .annotSelectionExtender:before {
          content:"+";
          border:1px solid black;
          background-color: rgba(255,255,255,.5);
          padding:.4em;
        }
        .annotLabel:not(.endAnnot) > a:hover {
          right:auto;
        }
        .annotLabel.endAnnot > a:hover {
          left:auto;
        }
      <!--</style>-->
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

  <xsl:template match="mei:music">
    <div class="_mei music">
      <xsl:apply-templates select="@*"/>
      <svg:svg style="display:none">
        <svg:defs>
          <svg:circle id="standardNotehead" 
              r="{$scaleStepSize}" transform="scale({$noteheadEllipticity},1) skewX({-$noteheadSkew})"/>
          <svg:path id="oriscusNotehead" transform="scale({$scaleStepSize})" stroke="none"
            d="M-1 -1.25
               C 0 -3
                 0  0.75
                 1 -1.25
               L 1  1.25
               C 0  3
                 0 -0.75
                -1  1.25 z"/>
          <svg:path id="quilismaNotehead" transform="scale({.03125 * $scaleStepSize})" stroke="none"
            d="M -48 -40
               c   8  15
                  16  29
                  32  -3
               c   8  15
                  16  29
                  32  -3
               c   8  15
                  16  29
                  32  -3
               v  80
               c -16  32
                 -24  18
                 -32   3
               c -16  32
                 -24  18
                 -32   3
               c -16  32
                 -24  18
                 -32   3 z"/>
          <svg:g id="apostrophaNotehead">
            <svg:use xlink:href="#standardNotehead"/>
            <svg:path class="apostrophaMark" d="M1 0 C 1 1.5 .5 2 0 2" transform="scale({$scaleStepSize})"/>
          </svg:g>
          <svg:path id="dNotehead" d="M-1,.5 1,2" stroke="currentColor" transform="scale({$scaleStepSize})" stroke-linecap="round"/>
          <svg:use id="uNotehead" xlink:href="#dNotehead" transform="scale(1,-1)"/>
        </svg:defs>
      </svg:svg>
      <xsl:apply-templates select="*|text()"/>
    </div>
  </xsl:template>
  
  <xsl:template match="mei:relationList">
    <div class="_mei relationList">
      <xsl:apply-templates select="@*"/>
      <xsl:for-each select="//mei:sb[not(@source)]/@n">
        <div class="sbN"><xsl:value-of select="."/></div>
      </xsl:for-each>
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  
  <xsl:template match="mei:*">
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
  <!-- TODO: We probably want to move away from @label -->
  <xsl:template match="mei:seriesStmt/@label" mode="generate-classes">
    <xsl:value-of select="concat(' ',.,' ')"/>
  </xsl:template>  
  
  <xsl:template match="@*" mode="process-editable-attributes"/>
  <xsl:template match="mei:sourceDesc/@n|mei:work/@n|mei:relation/@label|mei:sb/@label|mei:sb/@n" mode="process-editable-attributes">
    <div data-editable-attribute="{local-name()}" class="att_{local-name()}">
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
<<<<<<< HEAD
        <div title="rubric caption" class="sbLabel">
          <xsl:call-template name="set-content-editable"/>
          <xsl:value-of select="@label"/>
        </div>
        <span title="line label" class="sbN">
          <xsl:call-template name="set-content-editable"/>
          <xsl:value-of select="@n"/>
        </span>
=======
        <xsl:apply-templates select="@label" mode="process-editable-attributes"/>
        <xsl:apply-templates select="@n" mode="process-editable-attributes"/>
>>>>>>> thomas
      </div>
      <xsl:apply-templates select="following-sibling::*
        [not(self::mei:sb) or @source]
        [generate-id(preceding-sibling::mei:sb[not(@source)][1]) = generate-id(current())]"/>
    </div>
  </xsl:template>
  
  <!-- This creates a "building block" consisting of staff lines and a text layer -->
  <xsl:template match="mei:syllable">
    <div class="_mei {local-name()} {local-name(@source)}">
      <xsl:apply-templates mode="create-title" select="."/>
      <xsl:apply-templates select="@xml:id"/>
      <!-- TODO: move stafflines into the pitches div, adjust CSS for proper placement.
                 This is more meaningful and it's immediately clear that a click event on
                 the staff lines addresses the pitches layer -->
      <xsl:copy-of select="$stafflines"/>
      <div class="musicLayer">
        <xsl:apply-templates select="*[not(self::mei:syl)]"/>
      </div>
      <div class="textLayer">
        <xsl:apply-templates select="mei:syl"/>
      </div>
    </div>
  </xsl:template>
  
  <!-- By default, don't create title element -->
  <xsl:template match="*|@*" mode="create-title"/>
  <!-- For specific elements, create a title -->
  <xsl:template match="mei:sb" mode="create-title">
    <xsl:attribute name="title">line break in the source</xsl:attribute>
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
  <xsl:template match="mei:relation/@label" mode="create-title">
    <xsl:attribute name="title">text edition</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:sourceDesc/@n" mode="create-title">
    <xsl:attribute name="title">source no.</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:source/mei:physDesc/mei:provenance/mei:geogName">
    <xsl:attribute name="title">source provenance</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:repository/mei:geogName">
    <xsl:attribute name="title">source location</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:repository/mei:corpName">
    <xsl:attribute name="title">institution</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:repository/mei:identifier">
    <xsl:attribute name="title">shelf mark</xsl:attribute>
  </xsl:template>
  <xsl:template match="mei:incipText/mei:p">
    <xsl:attribute name="title">incipit</xsl:attribute>
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
  <xsl:template name="set-content-editable" mode="create-contenteditable" match="mei:seriesStmt//mei:num|mei:term|mei:p|mei:repository/*|mei:geogName">
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
    <xsl:variable name="annotations" select="//mei:annot[contains(concat(@plist,' ',@startid,' ',@endid,' '),concat($idRef,' '))]"/>
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
              <xsl:when test="contains(concat(@plist,' '),concat($idRef,' '))">
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
    <div class="_mei pb {@label}" title="page break in the source">
      <xsl:apply-templates select="@xml:id"/>
      <div class="folioDescription" title="folio information for page break in source">
        <xsl:call-template name="set-content-editable"/>
        <span class="folioNumber">
          <xsl:value-of select="@n"/>
        </span>
        <span class="rectoVerso">
          <!-- We only want "r" or "v" to be displayed, not "recto" or "verso" (waste of space) -->
          <xsl:value-of select="substring(@func,1,1)"/>
        </span>
      </div>
    </div>
  </xsl:template>
  
  <xsl:template match="mei:uneume">
    <!-- We do not use @name or @form in mono:di, but if they were there, it would make sense to hand them on as classes -->
    <div class="_mei uneume {@name} {@form}">
      <xsl:apply-templates select="@xml:id"/>
      
      <!-- Add a slur for uneumes with more than one note 
           QUESTION: Do we at all have uneumes with only one element? Maybe this would not make sense. -->
      <xsl:if test="count(descendant::mei:note) &gt; 1 and not(@name='apostropha')">
        <xsl:variable name="accidentalOnFirstNote">
          <xsl:apply-templates select="descendant::mei:note[1]" mode="get-accidental"/>
        </xsl:variable>
        <xsl:variable name="accidentals"> <!-- This holds all accidentals (including for first note) as unicode glyphs -->
          <xsl:apply-templates select="descendant::mei:note" mode="get-accidental"/>
        </xsl:variable>
        <xsl:variable name="width" select="$scaleStepSize * ($noteSpace * count(descendant::mei:note) + $accidentalSpace * (string-length($accidentals) - string-length($accidentalOnFirstNote)))"/>
        
        <svg:svg width="{$width}px" height="{$musicAreaHeight}px" 
            viewBox="0 {-$scaleStepSize * ($spaceAboveStaff + 4)} {$width} {$musicAreaHeight}" class="slur">
          <xsl:variable name="startNoteheadStep">
            <xsl:apply-templates select="descendant::mei:note[1]" mode="get-notehead-step"/>
          </xsl:variable>
          <xsl:variable name="endNoteheadStep">
            <xsl:apply-templates select="descendant::mei:note[last()]" mode="get-notehead-step"/>
          </xsl:variable>
          <svg:path transform="translate({$scaleStepSize * $accidentalSpace * string-length($accidentalOnFirstNote)},{-.5*$scaleStepSize * $noteSpace})"
              d="M{.5*$noteSpace * $scaleStepSize} {$startNoteheadStep * $scaleStepSize}
                 C{$width*.25} {(2*$startNoteheadStep + $endNoteheadStep)*$scaleStepSize div 3 - ($noteSpace*$scaleStepSize+$width)div$noteSpace div $scaleStepSize *4} 
                  {$width*.75} {(2*$endNoteheadStep + $startNoteheadStep)*$scaleStepSize div 3 - ($noteSpace*$scaleStepSize+$width)div$noteSpace div $scaleStepSize *4}
                  {$width - .5*$noteSpace * $scaleStepSize} {$endNoteheadStep * $scaleStepSize}" />
        </svg:svg>
      </xsl:if>
      
      <xsl:apply-templates select="*"/>
    </div>
  </xsl:template>
  
  <!-- notehead step of b4 will be 0 because it's in the center of the staff (symmetry makes things easier) -->
  <xsl:template mode="get-notehead-step" match="mei:note[@pname and @oct]">
    <xsl:copy-of select="-(number(translate(@pname,'cdefgab','01234567')) + 7*number(@oct) - 34)"/>
  </xsl:template>
  <!-- Notes without clear pitch orient themselves by their preceding note -->
  <xsl:template mode="get-notehead-step" match="mei:note[@intm='u' or @intm='d'][not(@pname)]">
    <xsl:apply-templates select="preceding::mei:note[1]" mode="get-notehead-step"/>
  </xsl:template>
  
  <xsl:template match="mei:note">
    <div class="_mei note {@label} {@mfunc}">
      <xsl:apply-templates select="@xml:id"/>
      
      <xsl:variable name="noteheadStep"><!-- $noteheadStep = 0 means note is on center line (i.e. a "b") -->
        <xsl:apply-templates mode="get-notehead-step" select="."/>
      </xsl:variable>
      <xsl:variable name="accidental"> <!-- This will hold the unicode char for the to be rendered accidental (or nothing) -->
        <xsl:apply-templates select="." mode="get-accidental"/>
      </xsl:variable>
      <xsl:variable name="requiredAccidentalSpace" select="$scaleStepSize * $accidentalSpace * string-length($accidental)"/>
      
      <svg:svg width="{$noteSpace * $scaleStepSize + $requiredAccidentalSpace}px" height="{$musicAreaHeight}px" 
          viewBox="{-.5*$noteSpace * $scaleStepSize - $requiredAccidentalSpace} {-$scaleStepSize*(4 + $spaceAboveStaff)} {$noteSpace * $scaleStepSize + $requiredAccidentalSpace} {$musicAreaHeight}">
        <!-- Choose if and where to draw ledger lines. Ledgerlines will be styled with dash pattern. -->
        <xsl:choose>
          <xsl:when test="not(@pname) and (@intm='u' or @intm='d')"/>
          <xsl:when test="$noteheadStep &lt; -5">
            <svg:line y1="{($ledgerLineWidth - 6)*$scaleStepSize}" y2="{(-.5 + $noteheadStep) * $scaleStepSize}" class="ledgerlines"/>
          </xsl:when>
          <xsl:when test="$noteheadStep &gt; 5">
            <svg:line y1="{(6 - $ledgerLineWidth)*$scaleStepSize}" y2="{( .5 + $noteheadStep) * $scaleStepSize}" class="ledgerlines"/>
          </xsl:when>
        </xsl:choose>
        
        <xsl:if test="$requiredAccidentalSpace &gt; 0"> <!-- if > 0, we have an accidental -->
          <svg:text class="accidental" x="{$scaleStepSize * (-.5*$noteSpace - $accidentalSpace)}" y="{$noteheadStep + 4}">
            <xsl:value-of select="$accidental"/>
          </svg:text>
          <!-- TODO: Don't use unicode glyphs. We have no guaranteed size or base line choice -->
        </xsl:if>
        
        <xsl:variable name="noteheadType">
          <xsl:apply-templates select="." mode="get-notehead-type"/>
        </xsl:variable>
        <svg:use xlink:href="#{$idPrefix}{$noteheadType}Notehead">
          <xsl:attribute name="transform">
            translate(0,<xsl:value-of select="$noteheadStep * $scaleStepSize"/>)
            <xsl:if test="@mfunc='liquescent'">
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
  <xsl:template match="*[not(@pname)][@intm='d' or @intm='u']" mode="get-notehead-type">
    <xsl:value-of select="@intm"/>
  </xsl:template>
  <xsl:template match="*[@label='oriscus' or @label='quilisma' or @label='apostropha']" mode="get-notehead-type">
    <xsl:value-of select="@label"/>
  </xsl:template>
  
  <xsl:template match="mei:note[@accid.ges='s' or @accid='s']" mode="get-accidental">
    <xsl:value-of select="'&#9839;'"/>
  </xsl:template>
  <xsl:template match="mei:note[@accid.ges='f' or @accid='f']" mode="get-accidental">
    <xsl:value-of select="'&#9837;'"/>
  </xsl:template>
  <xsl:template match="mei:note[@accid.ges='n' or @accid='n']" mode="get-accidental">
    <xsl:value-of select="'&#9838;'"/>
  </xsl:template>
  
</xsl:stylesheet>

