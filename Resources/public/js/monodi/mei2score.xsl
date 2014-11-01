<?xml version="1.0" encoding="UTF-8"?>
<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" xmlns:mei="http://www.music-encoding.org/ns/mei" version="1.0">
  
  <!-- This stylesheet creates a Score macro file.
       It is not strictly a PMX file because it does not only store item parameters,
       it also contains commands for saving files and continuing on a new page. -->

  <import href="mei2xhtml.xsl"/>
  
  <key name="typesetterAnnotStart" match="mei:annot[@type='typesetter']" use="substring(@startid,2)"/>
  <key name="typesetterAnnotEnd"   match="mei:annot[@type='typesetter']" use="substring(@endid,  2)"/>
  <key name="diacriticalMarkingAnnotStart" match="mei:annot[@type='diacriticalMarking']" use="substring(@startid, 2)"/>
  <key name="appAnnotStart" match="mei:annot[normalize-space(@label)='App']" use="substring(@startid, 2)"/>
<!--  <key name="appAnnotByLineStartId" match="mei:annot[normalize-space(@label)='App']" use="
    ancestor::mei:mei[1]//@xml:id[
      .=substring(current()/@startid,2)
    ]/ancestor::*[
      self::mei:sb[not(@source) or self::mei:syllable]
    ][1]"/>
-->  
  <output method="text"/>
  
  <!-- When converting snippets for the apparatus that will eventually be compiled in InDesign,
       we don't want Übersichtszeilen and line labels (both will be done in InDesign).
       That's why we need a flag here -->
  <!-- TODO: Replace typsetApparatusSnippets by following parameter $target -->
  <param name="target" select="'edition'"/><!-- Can also be set to apparatus -->
  <param name="sourcesTableFile"/><!-- This is an XML file that contains a list of sources in the following form:
    <sources abteilung="2" band="2">
        <source id="Ut 417" number="01a"/>
        <source id="Aa 13" number="02a"/>
        ...
    </sources> 
  If provided, file names will be generated according to the data found there:
    2201a_aa.mus
    2201a_ab.mus
  etc. for Ut 417,
    2202a_aa.mus
  etc. for Aa 13
  -->
  <param name="maxStaffsPerPage">
    <choose>
      <when test="$target='apparatus'">1</when>
      <when test="$target='edition'">14</when>
      <otherwise>
        <message terminate="yes">
          <text>Parameter "target" can be set to "edition" and "apparatus", but not </text>
          <value-of select="concat('&quot;', $target, '&quot;')"/>
        </message>
      </otherwise>
    </choose>
  </param>
  
  <param name="staffSize" select=".58"/>
  <param name="staffP3" select="10"/>
  <!--<param name="combineBaseChantsOnOneStaff" select="1"/>--><!-- 1 for true, 0 for false -->
  <param name="advance" select="3"/>
  <param name="marginaliaP4" select="5"/>
  <param name="rubricP4" select="20"/>
  <param name="mainSourceHeadingP4" select="60"/>
  <param name="secondarySourceHeadingP4" select="53"/>
  <param name="sourceDescriptionP4" select="48"/>
  <param name="P4distanceBetweenRubrics" select="4"/>
  <param name="uebersichtszeileP4" select="30"/>
  <param name="lyricsP4" select="-5"/>
  <param name="hyphenP4" select="-4"/>
  <param name="hyphenP17" select="1"/>
  <param name="hyphenP18" select="2"/>
  <param name="slurP4" select="15"/>
  <param name="slurP9" select="4"/>
  <param name="liquescentP15" select=".65"/>
  <param name="lineNumberP3" select=".01"/>
  <param name="highlightBoxP4" select="-1"/>
  <param name="highlightBoxHeight" select="16"/>

  <param name="standardFont" select="'_80'"/>
  <param name="smallCapsFont" select="'_85'"/>
  <param name="corpusMonodicumFont" select="'_79'"/>
  <param name="corpusMonodicumSymbolFont" select="'_86'"/>
  
  <param name="standardAnnotP4" select="18"/>
  <param name="standardDiacriticalMarkingP4" select="$standardAnnotP4"/>
  <param name="lyricsAnnotP4" select="$lyricsP4 - 4"/>
  <param name="annotP5toP7" select="'.9 .55 1'"/>
  
  <variable name="capitalLetters" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
  <variable name="untreatedChars">abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,():;+-*=@$&amp;`'"</variable>
  <variable name="unescapedChars" select="concat($untreatedChars, '?!#%&lt;&gt;')"></variable>
  <variable name="symbolFontChars"           >ęĘαβχδεφγηιφκλμνοπθρστυπωξψζ</variable>
  <variable name="symbolFontCharTranslations">'"abcdefghijklmnopqrstuvwxyz</variable>
  
  <!-- This stylesheet can either be applied to an MEI file or a list file of a form like
      <list>
        <file>a.mei</file>
        <file>b.mei</file>
      </list>
    (node names don't matter).
  -->
  <variable name="documents" select="document(/*[not(self::mei:mei)]/*) | /mei:mei/.."/>
  <variable name="sourcesTable" select="document($sourcesTableFile)"/>
  
  <variable name="documentSourceIdAttributes" select="$documents/mei:mei/mei:meiHead[1]/mei:fileDesc[1]/mei:sourceDesc[1]/mei:source[1]/@label"/>
  <variable name="listSourceIdAttributes" select="$sourcesTable//source/@id"/>
  
  <template mode="mei2score" match="text()"/>

  
  <template name="check-source-id-consistency">
    <if test="$sourcesTable//source[not(@id)]">
      <message terminate="yes">
        <value-of select="concat('Source lacking ID attribute in source list file ', $sourcesTableFile)"/>
      </message>
    </if>

    <for-each select="$listSourceIdAttributes">
      <!-- We also check for the correct format of the source number (two digits followed by one letter) -->
      <variable name="sourceNumberLetter" select="translate(../@number, '1234567890', '')"/>
      <variable name="sourceNumberDigits" select="substring-before(../@number, $sourceNumberLetter)"/>
      
      <if test="string-length($sourceNumberDigits) != 2 or string-length($sourceNumberLetter) != 1 or concat($sourceNumberDigits, $sourceNumberLetter) != ../@number">
        <message terminate="yes">
          <value-of select="concat('Invalid source number ', ../@number, ' in the source list file ', $sourcesTableFile, '.&#10;')"/>
          <value-of select="'Convention is two digits and one letter.'"/>
        </message>
      </if>
      
      <if test="not($documentSourceIdAttributes[. = current()])">
        <message terminate="yes">
          <value-of select="concat('ID ', ., ' present in the source list file ', $sourcesTableFile, ', but not in any supplied MEI document')"/>
        </message>
      </if>
    </for-each>
    
    <for-each select="$documentSourceIdAttributes">
      <if test="not($listSourceIdAttributes[. = current()])">
        <message terminate="yes">
          <value-of select="concat('ID ', ., ' present in an MEI document, but not in the the source list file ', $sourcesTableFile)"/>
        </message>
      </if>
    </for-each>
    
  </template>
  
  
  <template name="process-sources" match="/">
    <param name="sourceIdAttributes" select="$listSourceIdAttributes | $documentSourceIdAttributes"/>

    <if test="$sourcesTableFile">
      <call-template name="check-source-id-consistency"/>
    </if>
    
    <for-each select="$sourceIdAttributes">
      <apply-templates mode="process-source"
        select="self::node()[generate-id($sourceIdAttributes[.=current()][1]) = generate-id()]"/>
    </for-each>    
  </template>


  <template name="process-source" mode="process-source" match="@*">
    <param name="sourceId" select="."/>
    <param name="meiElements" select="$documentSourceIdAttributes[. = $sourceId]/ancestor::mei:mei"/>
    
    <variable name="filenamPrefix">
      <choose>
        <when test="$sourcesTable">
          <value-of select="concat($sourcesTable//@abteilung, $sourcesTable//@band)"/>
        </when>
        <otherwise>
          <value-of select="translate(substring($sourceId, 1, 6), 'äöüÄÖÜß ', 'aouAOUs')"/>
        </otherwise>
      </choose>
    </variable>
    
    <!-- We save as a name that consist of source ID (max 6 letters) and "00" for the apparatus
         and "aa" for the edition, so we have 26^2=676 possible sequential names for the edition of this source. -->
        
    <variable name="idsWithAppAnnots" select="$meiElements[$target = 'apparatus']//@xml:id[key('appAnnotStart', .)]"/>
    
    <!-- Now we can step through all the <sb>s and generate the lines.
         For the edition ($meiElements[$target='edition']/...):
            We put multiple consequent base chants (which frequently are short base chant incipits) onto one line,
            so we have to check whether a base chant <sb> (which has a capital letter in @n) is immediately preceded by another base chant <sb>.
            We have to prepend the @n with ' ' because contains() always returns true if the second argument is the empty string.
            A special case are transcription numbers that contain a P, like 10P. 
            Those documents only contain complete base chants, which we don't want to put on one line. 
         For the appratus ($idsWithAppAnnots/...) -->
    <apply-templates mode="generate-line" select="
      $meiElements[$target='edition']/mei:music[1]/mei:body[1]/mei:mdiv/mei:score/mei:section/mei:staff/mei:layer/mei:sb[not(@source)][
        not(contains($capitalLetters, substring(concat(@n,' '), 1, 1))) 
        or not(contains($capitalLetters, substring(concat(preceding-sibling::mei:sb[not(@source)][1]/@n, ' '), 1, 1)))
        or contains(ancestor::mei:mei[1]/mei:meiHead[1]/mei:workDesc[1]/mei:work[1]/@n, 'P')
      ] |
      $idsWithAppAnnots/ancestor::mei:syllable[1]/preceding-sibling::mei:sb[not(@source)][1] |
      $idsWithAppAnnots/ancestor::mei:sb[not(@source)][1]">
      <!-- We first sort numerically by ordering number of the containgin document, so that 1 will be before 10, 
           and if there's a P present, we have to also sort by string so that "10" will be before "10P".
           However, in most cases where we have transcription numbers with P, an ordering number will be given
           before a colon, so we'd have something like 42:10 43:10P or the like, 
           so we're only taking care of the P just in case.
           As the sorting is stable, the <sb>s from the same document will still be in document order. -->
      <sort select="substring-before(concat(ancestor::mei:mei[1]/mei:meiHead[1]/mei:workDesc[1]/mei:work[1]/@n, ':'), ':')" data-type="number"/>
      <sort select="ancestor::mei:mei[1]/mei:meiHead[1]/mei:workDesc[1]/mei:work[1]/@n"/>
      <with-param name="sourceId" select="$sourceId"/>
    </apply-templates>
  </template>
  
  
  <template match="mei:sb[not(@source)]" mode="generate-line">
    <param name="sourceId"/>
    
    <variable name="P2" select="$maxStaffsPerPage - ((position() - 1) mod $maxStaffsPerPage)"/>
    <!-- If we have a base chant, we combine it with consequent base chant lines, unless we have a document 
         with a "P" transcription number, which indicates we have a base-chant-only document.
         In these documents, we don't combine base chants lines. -->
    <variable name="combineWithConsequentBaseChants" select="
      $target = 'edition'
      and contains($capitalLetters, substring(concat(@n,' '), 1, 1))
      and not(contains(ancestor::mei:mei[1]/mei:meiHead[1]/mei:workDesc[1]/mei:work[1]/@n, 'P'))"/>
    
    <if test="$P2 = $maxStaffsPerPage">
      <variable name="fileName">
        <call-template name="get-mus-filename">
          <with-param name="pageNumber" select="(position() - 1) div $maxStaffsPerPage"/>
          <with-param name="sourceId" select="$sourceId"/>
        </call-template>
      </variable>
      <value-of select="concat('&#10;RS&#10;SA ', $fileName, '&#10;')"/>
    </if>
    
    <if test="$target='edition' and position() = 1">
      <!-- We put titles and the source ID on the first page -->
      <value-of select="concat('t ', $maxStaffsPerPage, ' ', $staffP3, ' ', $mainSourceHeadingP4, ' 0 2.5 0 -0.2&#10;')"/>
      <value-of select="concat($standardFont, '#. Source provenance&#10;')"/>
      <value-of select="concat('t ', $maxStaffsPerPage, ' ', $staffP3, ' ', $secondarySourceHeadingP4, ' 0 1.8 0 -0.3&#10;')"/>
      <value-of select="concat($standardFont, 'Source location&#10;')"/>
      <!-- We'll need at least two source description lines, so for convenience, create them right away -->
      <value-of select="concat('t ', $maxStaffsPerPage, ' ', $staffP3, ' ', $sourceDescriptionP4, ' 0 0 0 -0.5&#10;')"/>
      <value-of select="concat($standardFont, 'Source description line 1&#10;')"/>
      <value-of select="concat('t ', $maxStaffsPerPage, ' ', $staffP3, ' ', $sourceDescriptionP4 - 4, ' 0 0 0 -0.5&#10;')"/>
      <value-of select="concat($standardFont, 'Source description line 2&#10;')"/>
      
      <value-of select="concat('t ', $maxStaffsPerPage, ' 200 ', $uebersichtszeileP4, ' 0 0 0 -1.9&#10;')"/>
      <apply-templates mode="generate-score-escaped-string" select=".">
        <with-param name="string" select="$sourceId"/>
      </apply-templates>
    </if>
    
    <!-- The first <sb> in a transcription gets an Übersichtszeile -->
    <apply-templates mode="generate-uebersichtszeile"
      select="self::mei:sb[$target = 'edition'][not(preceding-sibling::mei:sb)]">
      <with-param name="P2" select="$P2"/>
    </apply-templates>
    
    <!-- If we have a <sb> of a base chant (with capital letter @n) with immediately following base chants,
           we combine them on one line, therefore in this case the next line start is not the next <sb> element. -->
    <variable name="followingLineStartId" select="generate-id(
      following-sibling::mei:sb[not(@source)][
        not($combineWithConsequentBaseChants and contains($capitalLetters, substring(concat(@n,' '), 1, 1)))
      ][1])"/>
    <variable name="syllablesAndEditionSbsInLine" select=".|following-sibling::*[not($followingLineStartId) or following-sibling::mei:sb[generate-id()=$followingLineStartId]]"/>
    <variable name="syllablesInLine" select="$syllablesAndEditionSbsInLine/self::mei:syllable"/>
    <variable name="lineLabels" select="$syllablesAndEditionSbsInLine/self::mei:sb/@n"/>
    
    <if test="$target = 'edition' and $lineLabels[string() != '']">
      <value-of select="concat('t ',$P2,' ',$lineNumberP3,' ',$marginaliaP4,' 0 0 0 -2.1 &#10;')"/>
      <apply-templates select="." mode="generate-score-escaped-string">
        <with-param name="string">
          <for-each select="$lineLabels">
            <value-of select="."/>
          </for-each>
        </with-param>
      </apply-templates>
    </if>

    <apply-templates mode="create-apparatus-highlight-box"
      select="$syllablesInLine//@xml:id[key('appAnnotStart', .)]"/>
    
    <variable name="stafflessSyllables" select="$syllablesInLine[not($syllablesInLine//mei:ineume)]"/>
    
    <!-- If we have no ineumes, we have a staffless system. 
         In this case, combine all syllables and sb/pb markers in one text string.
         For this purpose, we only apply the template to the first element in the line
         and tell him what elements it should combine with the help of $stafflessSyllables -->
    <apply-templates mode="mei2score" select="
        $syllablesAndEditionSbsInLine/self::mei:sb[not(@source)] |
        $syllablesInLine[not($stafflessSyllables) or preceding-sibling::*[1]/self::mei:sb[not(@source)]] |
        $syllablesInLine[not($stafflessSyllables)]/mei:*[@source][self::mei:sb or self::mei:pb] |
        $syllablesInLine/mei:ineume[preceding-sibling::*[1]/self::mei:ineume] |
        $syllablesInLine/mei:ineume/mei:uneume/mei:note[@pname and @oct or not(preceding-sibling::mei:note)]">
      <!-- We don't select <uneumes> here. 
           We make the first note inside a uneume responsible for drawing slurs (if necessary).
           Like this, we don't waste space for <uneume> elements as we derive the P3 value
           from the position() in the selected elements. 
           Ineumes are responsible for creating distance lines and accidentals before groups.
           Notes without pitch are combined into one symbol with their preceding notes. -->
      <with-param name="P2" select="$P2"/>
      <!-- If we don't have music on this system, we make the staff insivible -->
      <with-param name="stafflessSyllables" select="$stafflessSyllables"/>
    </apply-templates>
    
    <if test="$P2 = 1 or position() = last()">
      <!-- Save file if we're at the last staff on the page (P2=1) or in the source -->
      SM
    </if>
  </template> 
  

  <template match="mei:sb[not(@source)]" mode="generate-uebersichtszeile">
    <param name="P2"/>
    <variable name="mei" select="ancestor::mei:mei[1]"/>
    <variable name="workN" select="$mei/mei:meiHead[1]/mei:workDesc[1]/mei:work[1]/@n"/>
    <variable name="transcriptionNumber">
      <value-of select="substring-after($workN, ':')"/>
      <if test="not(contains($workN, ':'))">
        <value-of select="$workN"/>
      </if>
    </variable>
    
    <!-- Transcription number: Text and box -->
    <value-of select="concat('t ',$P2,' ',$lineNumberP3,' ',$uebersichtszeileP4,' 0 0 0 -1.1 &#10;')"/>
    <apply-templates select="." mode="generate-score-escaped-string">
      <with-param name="string" select="$transcriptionNumber"/>
    </apply-templates>
    <value-of select="concat('12 ',$P2,' ',$lineNumberP3,' ',$uebersichtszeileP4,' 0 10&#10;')"/>
    
    <variable name="uebersichtszeile">
      <for-each select="
        $mei/mei:meiHead[1]/mei:workDesc[1]/mei:work[1]/mei:classification[1]/mei:termList[@label='liturgicFunction'] |
        $mei[not(contains($transcriptionNumber, 'P'))]/mei:music[1]/mei:body[1]/mei:mdiv/mei:score/mei:section/mei:staff/mei:layer/mei:sb/@n">
        <!-- We do not list line numbers for transcriptions that only have "Primärgesänge". 
            Those transcriptions have a trailing "P" in their transcription number (like "10P"). 
            We'll normalize-space() later, so it doesn't matter if we add too many spaces. -->
        <value-of select="concat(., ' ')"/>
      </for-each>
    </variable>
    
    <!-- Übersichtszeile -->
    <value-of select="concat('&#10;t ',$P2,' ',$staffP3,' ',$uebersichtszeileP4,' 0 0 0 -1.2 0 0&#10;')"/>
    <apply-templates select="." mode="generate-score-escaped-string">
      <with-param name="string" select="normalize-space($uebersichtszeile)"/>
    </apply-templates>
    <value-of select="'&#10;'"/>
  </template>


  <template match="mei:sb[not(@source)]" mode="mei2score">
    <param name="P2"/>
    <param name="P3" select="$advance * position()"/>
    <param name="stafflessSyllables" select="true()"/>
    
    <apply-templates mode="handle-typesetter-annotations" select="@xml:id">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$P3"/>
    </apply-templates>

    <!-- Draw staff and clef (clef only for edition) -->
    <value-of select="concat('8 ',$P2,' ',$P3,' 0 ',$staffSize)"/>
    <!-- We only show staff lines and clef if there are notes before the next system break -->
    <choose>
      <when test="$stafflessSyllables">
        <!-- p7=-1 hides staff lines if there are no notes -->
        <value-of select="' 0 -1'"/>
      </when>
      <when test="$target='edition' and not(preceding-sibling::mei:sb[not(@source)])">
        <!-- On the first line in the chant, we place a clef; 500 is the clef symbol in the library -->
        <value-of select="concat('&#10;3 ',$P2,' ',$P3 + .3 * $advance,' 0 500')"/>
      </when>
    </choose>
    <value-of select="'&#10;'"/>

    <!-- Write rubrics (only for edition) -->
    <apply-templates select="@label[$target = 'edition']" mode="mei2score">
      <with-param name="P2" select="$P2"/>
    </apply-templates>
  </template>
  

  <template match="mei:annot[@label='App']" mode="mei2scoreApparatus">
    <param name="index"/>
    <variable name="startElement" select="key('id', substring(@startid,2))"/>
    <apply-templates select="(($startElement/preceding::mei:sb|$startElement/self::mei:sb)[not(@source)])[last()]" mode="mei2score">
      <with-param name="P2">
        <choose>
          <!-- $index tells us whether we dealing with the first annot in a file.
               If we have the first annot, -->
          <when test="$index = 1">2</when>
          <otherwise>1</otherwise>
        </choose>
      </with-param>
    </apply-templates>
  </template>
  
  
  <template match="@xml:id" mode="create-apparatus-highlight-box">
    <param name="P2" select="1"/>
    <variable name="startElement" select=".."/>
    
    <for-each select="key('appAnnotStart', .)">
      <variable name="endElement" select="key('id', substring(@endid, 2))"/>

      <value-of select="concat('4 ', $P2, ' ')"/>
      <apply-templates select="$startElement" mode="get-p3"/>
      <value-of select="concat(' ',$highlightBoxP4,' ',$highlightBoxP4,' ')"/>
      <apply-templates select="$endElement" mode="get-p3"/>
      <!-- Params 7-15; We "misuse" P8=-2 to classify this as highlight box -->
      <value-of select="concat(' 0 -2 0 0 ',$highlightBoxHeight,' ',$highlightBoxHeight,' 0 0 0 ')"/>
      <!-- Params 16-18 (offsets) -->
      <value-of select="concat(' 1 ', -.2*$advance,' ', .6*$advance, '&#10;')"/>
    </for-each>
  </template>


  <!-- Rubrics; There may be multiple rubrics on one line, separated by #. We process them recursively -->
  <template mode="mei2score" match="mei:sb[not(@source)]/@label[not(.='')]">
    <param name="P2"/>
    <param name="rubricText" select="normalize-space()"/>
    <param name="P4" select="$rubricP4 + $P4distanceBetweenRubrics * (string-length($rubricText) - string-length(translate($rubricText, '#', '')))"/>
    
    <variable name="rubricTextWithoutFolio" select="substring-before(concat(translate($rubricText, '(', '#'), '#'), '#')"/>
    <variable name="folioNumber" select="substring-before(substring-after($rubricText, '('), ')')"/>
    
    <value-of select="concat('t ',$P2,' ',$staffP3,' ',$P4,' 0 0 0 -2.2&#10;')"/>
    <apply-templates select="." mode="generate-score-escaped-string">
      <with-param name="string" select="normalize-space($rubricTextWithoutFolio)"/>
      <with-param name="allCaps" select="true()"/>
    </apply-templates>
   
    <if test="$folioNumber != ''">
      <value-of select="concat('t ',$P2,' 200 ',$P4,' 0 0 0 -2.9&#10;')"/>
      <apply-templates select="." mode="generate-score-escaped-string">
        <with-param name="string" select="normalize-space($folioNumber)"/>
      </apply-templates>
    </if>
    
    <if test="contains($rubricText,'#')">
      <apply-templates mode="mei2score" select=".">
        <with-param name="P2" select="$P2"/>
        <with-param name="rubricText" select="substring-after($rubricText, '#')"/>
      </apply-templates>
    </if>
  </template>


  <template match="mei:syllable" mode="get-syllable-font">
    <value-of select="$standardFont"/>
  </template>
  <!-- Base chants are written in small caps and have a capital letter line label OR a P in the transcription number -->
  <template mode="get-syllable-font" match="mei:syllable[
        contains('ABCDEFGHIJKLMNOPQRSTUVWXYZ+', substring(preceding-sibling::mei:sb[string-length(@n)>0][1]/@n, 1, 1))
        or contains(ancestor::mei:mei[1]/mei:meiHead[1]/mei:workDesc[1]/mei:work[1]/@n, 'P')
      ]">
    <value-of select="$smallCapsFont"/>
  </template>
  
  
  <template mode="mei2score" match="mei:syllable">
    <param name="P2"/>
    <!-- We want the syllable and the first note to align, so we need to check whether we have music (i.e. an <ineume>).
         We also have to account for leading <sb>/<pb>s -->
    <param name="P3" select="$advance * (position() + count(mei:ineume[1] | mei:ineume[1]/preceding-sibling::*[not(self::mei:syl)]))"/>
    <param name="syllablesAndEditionSbsInLine"/>
    <param name="stafflessSyllables"/>
    
    <apply-templates mode="handle-typesetter-annotations" select="(. | $stafflessSyllables)/@xml:id | (. | $stafflessSyllables)/mei:syl/@xml:id">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$P3"/>
      <with-param name="P4" select="$lyricsAnnotP4"/>
    </apply-templates>

    <variable name="font">
      <apply-templates select="." mode="get-syllable-font"/>
    </variable>
    
    <variable name="P8textClass">
      <choose>
        <when test="$font = $smallCapsFont">-2.4</when>
        <otherwise>-2.3</otherwise>
      </choose>
    </variable>
    
    <value-of select="concat('t ',$P2,' ',$P3,' ',$lyricsP4,' 0 0 0 ', $P8textClass, '&#10;')"/>
    <apply-templates mode="generate-score-escaped-string" select=".">
      <with-param name="string">
        <!-- If we have a staffless system, we combine all syllables and line breaks in one text item -->
        <for-each select=". | $stafflessSyllables">
          <value-of select="concat(
              substring('|| ',  2*count(mei:sb[1]), 4*count((mei:sb | mei:pb)[$stafflessSyllables])),
              translate(normalize-space(mei:syl),'-',''),
              ' '
            )"/>
        </for-each>
      </with-param>
      <with-param name="font" select="$font"/>
    </apply-templates>
    
    <if test="@wordpos='i' or @wordpos='m' or contains(mei:syl, '-')">
      <!-- We "misuse" P8 = -1 for classifying this as a hyphen -->
      <value-of select="concat('4 ',$P2,' ',$P3,' ',$hyphenP4,' ',$hyphenP4,' ',$P3,' 0 -1 0 0 0 0 0 0 0 1 0 ',$hyphenP17,' ',$hyphenP18,'&#10;')"/>
    </if>
  </template>
  
  
  <template name="get-mus-filename">
    <param name="pageNumber"/>
    <param name="sourceId"/>
    
    <if test="not($pageNumber &lt; 1000 and translate($pageNumber, '+-.', '') = $pageNumber)">
      <message terminate="yes">
        <value-of select="concat('Page number ', $pageNumber, ' is malformed or two high.')"/>
      </message>
    </if>
    <variable name="paddedPageNumber" select="substring(concat('00', $pageNumber), string-length($pageNumber), 3)"/>
    
    <choose>
      <when test="$sourcesTableFile">
        <!-- For the PPMX file, we format the file names as follows:
            ABCCaDDD.mus
          * "A" is the number of the "Abteilung"
          * "B" number of "Band"
          * "CC" source number
          * "a" letter to distinguish when there are multiple sources with the same number (usually only "a")
          * "DDD" page number -->
        <value-of select="concat(
            $sourcesTable//@abteilung,
            $sourcesTable//@band,
            $sourcesTable//source[@id=$sourceId]/@number,
            $paddedPageNumber
          )"/>
      </when>

      <otherwise>
        <!-- If we don't have a list of sources, we generate the filename from the source's ID.
          TODO: There is a risk that we generate non-unique filenames here. -->
        <variable name="asciiSourceId" select="translate($sourceId, 'äöüÄÖÜß ', 'aouAOUs')"/>
        <if test="translate($asciiSourceId, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_', '') != ''">
          <message terminate="yes">
            <value-of select="concat('Invalid file name generation for source ID &quot;', $sourceId, '&quot; (', $asciiSourceId, ')&#10;')"/>
            <value-of select='"Please report this ID to the software&apos;s maintainer."'/>
          </message>
        </if>
        <value-of select="substring($asciiSourceId, 1, 5)"/>
        <value-of select="$paddedPageNumber"/>
      </otherwise>
    </choose>
    
    <choose>
      <when test="$target = 'apparatus'">.app</when>
      <otherwise>.edi</otherwise>
    </choose>
  </template>


  <template mode="generate-score-escaped-string" match="node()|@*">
    <!-- TODO: Improve support for Symbol font characters, i.e. complete conversion of the available character set. -->
    <!-- TODO: Check whether straightforward output of unproblematic strings can significantly speed up the whole transformation.
              Unproblematic characters are: abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,():;+-*=@$&amp;`'" 
              A string can be checked for characters that need special treatment by translating all unproblematic characters to ''. 
              This could be done in each iteration, directly writing the unproblematic part and treating the first char in the 
              part needing special treatment in the <choose> statement like we do now.
              Like this, we could bypass many iterations and <choose> statements. -->
    <param name="string" select="normalize-space(.)"/>
    <param name="allCaps" select="false()"/>
    <param name="font" select="$standardFont"/>
    <param name="firstIteration" select="true()"/>
    
    
    <if test="$firstIteration">
      <value-of select="$font"/>
    </if>
    
    <variable name="firstTreatedChar" select="substring(translate($string, $untreatedChars, ''), 1, 1)"/>
    <variable name="leadingUntreatedStringPart" select="substring-before($string, $firstTreatedChar)"/>
    <variable name="remainingStringPart" select="substring-after($string, $firstTreatedChar)"/>
    
    <value-of select="$leadingUntreatedStringPart"/>
    <if test="not($firstTreatedChar)">
      <value-of select="concat($string, '&#10;')"/>
    </if>
    
    <if test="$firstTreatedChar">
      <variable name="char" select="$firstTreatedChar"/>
      <variable name="firstTwoChars" select="concat($char, substring($remainingStringPart, 1, 1))"/>
      
      <variable name="escapedChar">
        <choose>
          <!--  We replace < and > with these characters from the Corpus Monodicum font -->
          <when test="contains('&lt;>',$char)">
            <value-of select="concat($corpusMonodicumFont, $char, $font)"/>
          </when>
          <!-- Certain sequences of characters are interpreted as escape sequences in Score.
               To prevent that, we insert a redundant font definition.
               e.g. "~n" becomes "~_00n", assuming that _00 is the current font. -->
          <when test="string-length(normalize-space($firstTwoChars)) = 2 and contains(
              ' &lt;&lt; &gt;&gt; ^^ %% ## 
              ?\ ?| ?[ ?] ?{ ?} ?- ?a ?A ?c ?e ?E ?f ?l ?L ?m ?o ?O ?r ?s ?t 
              !0 !1 !2 !3 !4 !5 !6 !7 !8 !9 !a !A !d !D !e !f !g !h !i !j !k !l !m !n !p !q !s !S !y !z !Z 
              ~a ~A ~n ~N ~o ~O 
              ?1 ?2 ?3 ?d ?0 ?8 ?9 ',
              concat(' ',$firstTwoChars,' ')
            )">
            <value-of select="concat($char, $font)"/> <!-- The second character will be added in the next iteration -->
          </when>
          <when test="contains($unescapedChars,$char)">
            <value-of select="$char"/>
          </when>
          <when test="contains('ÄäËëÏïÖöÜüŸÿ',$char)">
            <value-of select="concat('%%',translate($char,
              'ÄäËëÏïÖöÜüŸÿ',
              'AaEeIiOoUuYy'))"/>
          </when>
          <when test="contains('ÁáÉéÍíÓóÚú',$char)">
            <value-of select="concat('&lt;&lt;',translate($char,
              'ÁáÉéÍíÓóÚú',
              'AaEeIiOoUu'))"/>
          </when>
          <when test="contains('ÀàÈèÌìÒòÙù',$char)">
            <value-of select="concat('&lt;&lt;',translate($char,
              'ÀàÈèÌìÒòÙù',
              'AaEeIiOoUu'))"/>
          </when>
          <when test="contains('ÂâÊêÎîÔôÛû',$char)">
            <value-of select="concat('^^',translate($char,
              'ÂâÊêÎîÔôÛû',
              'AaEeIiOoUu'))"/>
          </when>
          <when test="contains('Çç',$char)">
            <value-of select="concat('##',translate($char,
              'Çç',
              'Cc'))"/>
          </when>
          <when test="contains('\|[]{}−æÆ©œŒªłŁºøØ®ß™\♭♯♮𝅭',$char)">
            <value-of select="concat('?',translate($char,
              '\|[]{}−æÆ©œŒªłŁºøØ®ß™♭♯♮&#x1D16D;',
              '\|[]{}-aAceEflLmoOrst123d'))"/>
          </when>
          <when test="contains('•„”¡¢£§¤“åÅ†‡…ƒ«»ﬁ‹›ﬂ—–¶¿šŠ¥žŽ',$char)">
            <value-of select="concat('!',translate($char,
              '•„”¡¢£§¤“åÅ†‡…ƒ«»ﬁ‹›ﬂ—–¶¿šŠ¥žŽ',
              '012345679aAdDefghijklmnpqsSyzZ'))"/>
          </when>
          <when test="contains('ãÃñÑõÕ',$char)">
            <value-of select="concat('~',translate($char,
              'ãÃñÑõÕ',
              'aAnNoO'))"/>
          </when>
          <when test="contains('𝅘𝅥𝅗𝅥𝅘𝅥𝅮𝅘𝅥𝅯𝅝/',$char)">
            <value-of select="translate($char,
              '𝅘𝅥𝅗𝅥𝅘𝅥𝅮𝅘𝅥𝅯𝅝/',
              '[]{}|\')"/>
          </when>
          <when test="$char='°'">\\312</when>
          <when test="$char='‰'">\\275</when>
          <when test="$char='⁄'">\\244</when><!-- fraction (this is not the simple slash) -->
          <when test="$char='_'">\\374</when>
          <when test="$char='¼'">\\362</when>
          <when test="$char='½'">\\363</when>
          <when test="$char='¾'">\\364</when>
          <when test="$char='¹'">\\365</when>
          <when test="$char='²'">\\366</when>
          <when test="$char='³'">\\367</when>
          <when test="$char='^'">\\303</when>
          <when test="$char='~'">\\304</when>
          <when test="$char='&#160;'"> </when><!-- "&nbsp;" -->
          <when test="$char='ę' and $font = $smallCapsFont">
            <value-of select="concat($corpusMonodicumSymbolFont, '@', $font)"/>
          </when>
          <when test="contains($symbolFontChars, $char)">
            <value-of select="concat(
              $corpusMonodicumSymbolFont,
              translate($char, $symbolFontChars, $symbolFontCharTranslations),
              $font)"/>
          </when>
          <otherwise>
            <value-of select="'?'"/>
            <message>
              WARNING:
              Unsupported character: "<value-of select="$char"/>"
              Rest of string: "<value-of select="$remainingStringPart"/>"
            </message>
          </otherwise>
        </choose>
      </variable>
      
      <choose>
        <!-- Score translates accented/special characters to escape sequences that are 
             similar for the capital and small letters, e.g. ã becomes ~æ and Ã becomes ~A.
             This means, if we want to convert everything to allCaps, we can take the escaped output 
             and translate ASCII unaccented minuscules in to majuscules.
             However, there are some characters whose escaped variant contains a small letter,
             but the original symbol is not a letter itself that can be capitalized.
             For example, © becomes ?c, and there is no captialized variant of ©.
             So we check for those non-capitalizable chars before capitalizing the escaped char. -->
        <when test="$allCaps and not(contains('©ªº®ß™&#x1D16D;†‡…ƒ«»ﬁ‹›ﬂ—–¶¿>&lt;', $char))">
          <value-of select="translate($escapedChar, 
            'abcdefghijklmnopqrstuvwxyz;',
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
        </when>
        <when test="$allCaps and contains('>&lt;', $char) and starts-with($escapedChar, $corpusMonodicumFont)">
          <!-- We have a larger variant of the angle brackets for allCaps in the Corpus monodicum font,
               which are placed in the slot for { and }. Those have to be escaped like ?{ and ?} -->
          <value-of select="concat($corpusMonodicumFont, '?', translate($char, '&lt;>', '{}'), $font)"/>
        </when>
        <otherwise>
          <value-of select="$escapedChar"/>
        </otherwise>
      </choose>
      
      <apply-templates select="." mode="generate-score-escaped-string">
        <with-param name="string" select="$remainingStringPart"/>
        <with-param name="allCaps" select="$allCaps"/>
        <with-param name="font" select="$font"/>
        <with-param name="firstIteration" select="false()"/>
      </apply-templates>
    </if>
  </template>
  
  
  <template mode="mei2score" match="mei:ineume">
    <param name="P2"/>
    <param name="P3" select="$advance * position()"/>
    
    <if test="preceding-sibling::*[1]/self::mei:ineume">
      <value-of select="concat('14 ',$P2,' ',$P3,' -1 &#10;')"/>
    </if>
  </template>


  <template mode="mei2score" match="mei:note[@pname and @oct]">
    <param name="P2"/>
    <param name="P3" select="$advance * position()"/>
    
    <variable name="P4">
      <apply-templates select="." mode="get-notehead-p4"/>
    </variable>
    <variable name="P6">
      <!-- This also handles stemlets representing following liquescents without known pitch -->
      <apply-templates select="." mode="get-note-p6"/>
    </variable>
    
    <apply-templates mode="handle-typesetter-annotations" select="@xml:id">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$P3"/>
    </apply-templates>
    <apply-templates mode="handle-diacriticalMarking-annotations" select="@xml:id">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$P3"/>
    </apply-templates>

    <!-- Accidentals are aligned with the first note in a an ineume -->
    <apply-templates mode="mei2score" select="
        self::*[not(preceding-sibling::mei:note)]/
        parent::*[not(preceding-sibling::mei:uneume)]/
        parent::*/*/*/@accid">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$P3"/>
    </apply-templates>
    
    <!-- If this is the first note in a multi-note <uneume>, we draw a slur -->
    <if test="not(preceding-sibling::mei:note) and following-sibling::mei:note[@pname and not(@intm)]">
      <value-of select="concat('5 ',$P2,' ',$P3,' ',$slurP4,' ',$slurP4,' ',$P3 + count(following-sibling::mei:note) * $advance, ' 2 -1 ',$slurP9,'&#10;')"/>
    </if>
    
    <value-of select="concat('1 ',$P2,' ',$P3,' ',$P4,' 0 ',$P6)"/>
    <if test="contains(concat(' ',@label,' '), ' liquescent ')">
      <value-of select="concat(' 0 0 0 0 0 0 0 0 ',$liquescentP15)"/>
    </if>
    <value-of select="'&#10;'"/>
  </template>
  
  
  <template mode="mei2score" match="@accid">
    <param name="P2"/>
    <param name="P3"/>
    
    <variable name="P4">
      <apply-templates select=".." mode="get-notehead-p4"/>
    </variable>
    <variable name="P5">
      <value-of select="translate(.,'fsn','678')"/>
    </variable>
    
    <value-of select="concat('9 ',$P2,' ',$P3,' ',$P4,' ',$P5,' .25&#10;')"/>
  </template>
  
  
  <template match="mei:note"                      mode="get-note-p6">511</template>
  <template match="mei:note[@label='apostropha']" mode="get-note-p6">512</template>
  <template match="mei:note[@label='quilisma']"   mode="get-note-p6">513</template>
  <template match="mei:note[@label='oriscus']"    mode="get-note-p6">514</template>
  <template match="mei:note[following-sibling::mei:note[1][not(@pname and @oct)][@intm]]" mode="get-note-p6">
    <value-of select="concat('51',translate(following-sibling::mei:note[1]/@intm,'ud','56'))"/>
  </template>
  
  
  <template match="mei:note" mode="get-notehead-p4">
    <variable name="monodiStep">
      <!-- The get-notehead-step template is imported from mei2xhtml.xsl -->
      <apply-templates select="." mode="get-notehead-step"/>
    </variable>
    
    <copy-of select="7 - $monodiStep"/>
  </template>


  <!-- Line and page break markers (marking breaks in the source) -->
  <template mode="mei2score" match="mei:sb[@source]|mei:pb">
    <param name="P2"/>
    <!-- If a break marker is the first element in a syllable, it must not coincide with the syllable.
         Therefore, we move it to the left by half a p3 advance step. -->
    <param name="P3" select="$advance * (position() - 1 + count(preceding-sibling::mei:*[not(self::mei:syl)][1]))"/>
    
    <apply-templates mode="handle-typesetter-annotations" select="@xml:id">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$P3"/>
    </apply-templates>
    
    <value-of select="concat('t ',$P2,' ',$P3,' ',$lyricsP4,' 0 0 0 -2.5 &#10;')"/>
    
    <apply-templates select="." mode="generate-score-escaped-string">
      <with-param name="string">
        <value-of select="'|'"/>
        <if test="self::mei:pb">|</if>
      </with-param>
    </apply-templates>
    
    <!-- For page breaks, we need to write the folio number -->
    <if test="self::mei:pb and $target='edition'">
      <value-of select="concat('t ',$P2,' 200 ',$marginaliaP4,' 0 0 0 -2.9 &#10;')"/>
      <apply-templates select="." mode="generate-score-escaped-string">
        <with-param name="string">
          <value-of select="concat('|| f. ',@n)"/>
          <if test="@func='verso'">v</if>
        </with-param>
      </apply-templates>
    </if>
  </template>


  <template match="@xml:id" mode="handle-typesetter-annotations">
    <param name="P2"/>
    <param name="P3"/>
    <param name="P4" select="$standardAnnotP4"/>
    
    <for-each select="key('typesetterAnnotStart',.)">
      <value-of select="concat('t ',$P2,' ',$P3,' ',$P4,' ',$annotP5toP7,'&#10;')"/>
      <apply-templates select="." mode="generate-score-escaped-string">
        <with-param name="string">
          <value-of select="'%@'"/>
          <!-- If the annotation spans different elements, we create a start marker -->
          <if test="@startid != @endid">[[</if>
          <value-of select="concat(@label,';  ',normalize-space())"/>
        </with-param>
        <with-param name="font" select="'_99'"/>
      </apply-templates>
    </for-each>
    
    <!-- We create an annotation ending marker -->
    <for-each select="key('typesetterAnnotEnd',.)[@startid != @endid]">
      <value-of select="concat('t ',$P2,' ',$P3,' ',$P4 - 4,' ',$annotP5toP7,'&#10;')"/>
      <apply-templates select="." mode="generate-score-escaped-string">
        <with-param name="string" select="concat('%@', normalize-space(@label), ']]')"/>
        <with-param name="font" select="'_99'"/>
      </apply-templates>
    </for-each>
  </template>


  <template match="@xml:id" mode="handle-diacriticalMarking-annotations">
    <param name="P2"/>
    <param name="P3"/>
    <param name="P4" select="$standardDiacriticalMarkingP4"/>
    
    <for-each select="key('diacriticalMarkingAnnotStart',.)">
      <value-of select="concat('t ',$P2,' ',$P3,' ',$P4,' 0 0 0 -2.7 &#10;')"/>
      <apply-templates select="@label" mode="generate-score-escaped-string"/>
    </for-each>
  </template>
  
  <template match="mei:note|mei:syllable|mei:sb[@source]|mei:pb" mode="get-p3">
    <variable name="precedingSpacingElement" select="(
        preceding::mei:note |
        preceding::mei:syllable |
        ancestor::mei:syllable |
        preceding::mei:sb |
        preceding::mei:pb
      )[last()]"/>
    <variable name="precedingP3">
      <apply-templates select="$precedingSpacingElement" mode="get-p3"/>
    </variable>

    <!-- Every spacing element (notes, syllables, sbs, pbs) gets one $advance space.
         However, in order to make the first element in a syllable and the syllable text to align,
         the syllable text gets an additional $advance space.
         We have to subtract that additional space for the next spacing item. -->
    <copy-of select="$precedingP3 + $advance * (1 + count(self::mei:syllable) - count($precedingSpacingElement/self::mei:syllable))"/>
  </template>
  
  <template match="mei:sb[not(@source)]" mode="get-p3">
    <!-- This is only meant for apparatus snippets where we don't have multi-staff systems,
         so all <pb>s without @source start a new system -->
    <copy-of select="$advance"/>
  </template>
</stylesheet>