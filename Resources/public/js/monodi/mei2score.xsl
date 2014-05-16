<?xml version="1.0" encoding="UTF-8"?>
<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" xmlns:mei="http://www.music-encoding.org/ns/mei" version="1.0">
  
  <!-- This stylesheet creates a Score macro file.
       It is not strictly a PMX file because it does not only store item parameters,
       it also contains commands for saving files and continuing on a new page. -->

  <import href="mei2xhtml.xsl"/>
  
  <key name="typesetterAnnotStart" match="mei:annot[@type='typesetter']" use="substring(@startid,2)"/>
  <key name="typesetterAnnotEnd"   match="mei:annot[@type='typesetter']" use="substring(@endid,  2)"/>
  <key name="diacriticalMarkingAnnot" match="mei:annot[@type='diacriticalMarking']" use="substring(@startid, 2)"/>
  
  <output method="text"/>
  
  <!-- When converting snippets for the apparatus that will eventually be compiled in InDesign,
       we don't want Übersichtszeilen and line labels (both will be done in InDesign).
       That's why we need a flag here -->
  <param name="typesetApparatusSnippets" select="'false'"/>
  <param name="maxStaffsPerPage">
    <choose>
      <when test="$typesetApparatusSnippets='true'">1</when>
      <otherwise>14</otherwise>
    </choose>
  </param>
  <param name="alwaysOutputSourceId">
    <choose>
      <when test="$typesetApparatusSnippets">false</when>
      <otherwise>true</otherwise>
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
  <param name="rightColumnP3" select="170"/>

  <param name="standardFont" select="'_80'"/>
  <param name="smallCapsFont" select="'_85'"/>
  <param name="corpusMonodicumFont" select="'_79'"/>

  <param name="standardAnnotP4" select="18"/>
  <param name="standardDiacriticalMarkingP4" select="$standardAnnotP4"/>
  <param name="lyricsAnnotP4" select="$lyricsP4 - 4"/>
  <param name="annotP5toP7" select="'.9 .55 1'"/>
  
  <param name="fileNaming" select="'sequential'"/> <!-- Second option is sourceIdAndTranscriptionNumber -->
  

  <variable name="capitalLetters" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
  <variable name="transcriptionNumber" select="substring(translate(//mei:work/@n,':',''), string-length(substring-before(@n,':')) + 1)"/>


  <template mode="mei2score" match="text()"/>
  
  <template match="/">
    <for-each select="//mei:work[1]">
      <!-- Transcription number may sometimes contain a colon, like "3:4". 
           The number before the colon is an auxiliary number used for ordering transcriptions
           if the actual transcription numbers (in this case found after the colon)
           aren't in ascending order. We're only interested in the number after the colon. -->
      <variable name="sourceId" select="//mei:sourceDesc/mei:source/@label"/>
      <variable name="orderingNumber" select="substring-before(concat(@n, ':'), ':')"/>
      
      <choose>
        <when test="$fileNaming = 'sequential'">
          <!-- We start/go on with whatever filename the current document in Score has. 
               This is especially useful if we concatenate multiple files that were generated by this conversion to
               let Score create a consecutively named sequence of files that can be navigated using nx/nb commands -->
          <value-of select="'if p1 > 0 then de&#10;'"/>
        </when>
        <when test="$fileNaming = 'sourceIdAndTranscriptionNumber'">
          <!-- We give the file a name, composed of
           - sourceId (maximum 5 letters)
           - ordering number (two letters)
           - a single letter that we can increment for multi-page transcriptions
             ("a" first page, "b" second page etc.) -->
          <value-of select="'rs&#10;'"/>
          <value-of select="'sa '"/>
          <!-- We shorten sourceId to a maximum of five characters so that the total file name length is within DOS limits 
           In case the ordering number is longer than two characters, we need to shorten it even further -->
          <value-of select="substring(substring(translate($sourceId,' ',''), 1, 5), 1, 7 - string-length($orderingNumber))"/>
          <!-- We need to turn e.g. "1" into "01" to get nice ordering in file manager and for Score4 F3/F4 commands -->
          <value-of select="concat(substring('0', 1, 2 - string-length($orderingNumber)), $orderingNumber)"/>
          <value-of select="'a.mus&#10;'"/>
        </when>
        <otherwise>
          <message terminate="yes">
            Parameter fileNaming can be set to 'sequential' or 'sourceIdAndTranscriptionNumber', but found '<value-of select="$fileNaming"/>'
          </message>
        </otherwise>
      </choose>

      <choose>
        <when test="$typesetApparatusSnippets='false'">
          <value-of select="concat('t ',$maxStaffsPerPage,' ',$lineNumberP3,' ',$uebersichtszeileP4,' 0 0 0 -1.1 &#10;')"/>
          <value-of select="concat($standardFont, $transcriptionNumber, '&#10;')"/>
          <!-- Box for transcription number -->
          <value-of select="concat('12 ',$maxStaffsPerPage,' ',$lineNumberP3,' ',$uebersichtszeileP4,' 0 10&#10;')"/>
          
          <!-- Übersichtszeile -->
          <value-of select="concat('t ',$maxStaffsPerPage,' ',$staffP3,' ',$uebersichtszeileP4,' 0 0 0 -1.2 0 0&#10;')"/>
          <value-of select="$standardFont"/>
          <value-of select="normalize-space(mei:classification/mei:termList[@label='liturgicFunction'])"/>
        </when>
        <when test="$typesetApparatusSnippets!='true'">
          <message terminate="yes">
            Parameter typesetApparatusSnippets can be set to 'true' or 'false', but found '<value-of select="$fileNaming"/>'
          </message>
        </when>
      </choose>

      <!-- We do not list line numbers for transcriptions that only have "Primärgesänge". 
           Those transcrptions have a trailing "P" in their transcription number (like "10P"). 
           Also, snippets for the Apparatus will not have line numbers. -->
      <if test="not(contains(@n, 'P')) and $typesetApparatusSnippets='false'">
        <for-each select="//mei:sb[not(@source)]/@n[not(.='')]">
          <value-of select="concat(' ',.)"/>
        </for-each>
      </if>
      <variable name="textEditionString" select="normalize-space(//mei:biblList[@type='textEditions'])"/>
      <if test="$textEditionString != ''">
        <value-of select="concat(' (',$textEditionString,')')"/>
      </if>
      <value-of select="'&#10;'"/>
      
      <!-- SourceId (e.g. "Wü 165").  We only need to print this for the first transcription in a source, but
           as I'm not sure whether we can rely on $transcriptionNumber always being 1 in that case and e.g. in
           the case of Aachen we have the source ID twice, once for the tropes and once for the base chants,
           we create them for all transcriptions and later delete them while processing the Score data if
           parameter alwaysOutputSourceId is left at its default. -->
      <if test="($alwaysOutputSourceId='true' or $transcriptionNumber = '1') and string-length($sourceId) > 0">
        <value-of select="concat('t ', $maxStaffsPerPage, ' ', $rightColumnP3, ' ', $uebersichtszeileP4, ' 0 0 0 -1.9&#10;')"/>
        <value-of select="$standardFont"/>
        <apply-templates mode="generate-score-escaped-string" select="$sourceId"/>
        <value-of select="'&#10;'"/>
        <choose>
          <when test="$transcriptionNumber = 1">
            <!-- We assume there has to be a title on this page -->
            <value-of select="concat('t ', $maxStaffsPerPage, ' ', $staffP3, ' ', $mainSourceHeadingP4, ' 0 2.5 0 -0.2&#10;')"/>
            <value-of select="concat($standardFont, '#. Source provenance&#10;')"/>
            <value-of select="concat('t ', $maxStaffsPerPage, ' ', $staffP3, ' ', $secondarySourceHeadingP4, ' 0 1.8 0 -0.3&#10;')"/>
            <value-of select="concat($standardFont, 'Source location&#10;')"/>
            <value-of select="concat('t ', $maxStaffsPerPage, ' ', $staffP3, ' ', $sourceDescriptionP4, ' 0 0 0 -0.5&#10;')"/>
            <value-of select="concat($standardFont, 'Source description&#10;')"/>
          </when>
          <when test="$typesetApparatusSnippets='false'">
            <!-- For most cases, the transcription number will have to be deleted, therefore we place a marker -->
            <value-of select="concat('t ', $maxStaffsPerPage, ' ', $rightColumnP3, ' ', $uebersichtszeileP4 + 5, ' 0 .8 0 -1.9&#10;')"/>
            <value-of select="'_99%! Delete source ID or this comment!&#10;'"/>
          </when>
        </choose>
      </if>
    </for-each>
    
    <!-- We convert one line after the other because we need to keep track of
         how many Score line breaks an individual mei:sb translates to.
         $maxStaffsPerPage is then used to determine when we need to start a new Score file. -->
    <apply-templates mode="mei2score" select="//mei:sb[not(@source)][1]"/>

    <value-of select="'sm&#10;'"/>
    <if test="$fileNaming = 'sequential'">
      <value-of select="'snx&#10;'"/>
    </if>
  </template>


  <template mode="mei2score" match="mei:sb[not(@source)]">
    <!-- P2 is actually the "previous P2", so for the initial call to this template, we use $maxStaffsPerPage + 1 -->
    <param name="P2" select="$maxStaffsPerPage + 1"/>
    <param name="P3" select="$staffP3"/>
    
    <variable name="followingSb" select="(following-sibling::mei:sb[not(@source)])[1]"/>
    <variable name="precedingLineNumber" select="preceding-sibling::mei:sb[not(@source)][1]/@n"/>
    <variable name="followingLineNumber" select="following-sibling::mei:sb[not(@source)][1]/@n"/>
    <variable name="continueOnSameStaffForConsecutiveBaseChant" 
      select="$precedingLineNumber != '' and contains($capitalLetters, $precedingLineNumber) 
              and @n != '' and contains($capitalLetters, @n)
              and @label = ''
              and $typesetApparatusSnippets='false'
              and not(contains($transcriptionNumber, 'P'))"/>
    
    <variable name="newP2">
      <choose>
        <when test="$continueOnSameStaffForConsecutiveBaseChant">
          <value-of select="$P2"/>
        </when>
        <when test="$P2 > 1">
          <value-of select="$P2 - 1"/>
        </when>
        <otherwise>
          <value-of select="$maxStaffsPerPage"/>
        </otherwise>
      </choose>
    </variable>
    
    <variable name="newP3">
      <choose>
        <when test="$continueOnSameStaffForConsecutiveBaseChant">
          <copy-of select="$P3 + $advance"/>
        </when>
        <otherwise>
          <copy-of select="$staffP3"/>
        </otherwise>
      </choose>
    </variable>
    
    <!-- Check whether we went beyond the bottom staff, so we have to move on to the next page. -->
    <if test="$P2 &lt;= $newP2 and not($continueOnSameStaffForConsecutiveBaseChant)">
      sm
      if p1 > 0 then de
      snx
    </if>
    
    <apply-templates select="@xml:id" mode="handle-typesetter-annotations">
      <with-param name="P3" select="$newP3"/>
      <with-param name="P2" select="$newP2"/>
    </apply-templates>

    <!-- Draw staff and clef -->
    <value-of select="concat('8 ',$newP2,' ',$newP3,' 0 ',$staffSize)"/>
    <!-- We only show staff lines and clef if there are notes beore the next system break -->
    <choose>
      <when test="not(following-sibling::mei:syllable[following-sibling::mei:sb/@xml:id = $followingSb/@xml:id][.//mei:note])">
        <!-- p7=-1 hides staff lines if there are no notes -->
        <value-of select="' 0 -1'"/>
      </when>
      <when test="not(preceding-sibling::mei:sb) and $typesetApparatusSnippets='false'">
        <!-- On the first line in the chant, we place a clef -->
        <value-of select="concat('&#10;3 ',$newP2,' ',$newP3 + $advance,' 0 500')"/>
      </when>
    </choose>
    <value-of select="'&#10;'"/>
    
    
    <!-- If we didn't proceed to the next line, we don't draw a new line label -->
    <!-- We draw notes etc. one after the other because we need to keep track of 
         how much space each individual element takes up -->
    <apply-templates mode="mei2score" select="@n[$P2 != $newP2]|@label|following-sibling::*[1]">
      <with-param name="P2" select="$newP2"/>
      <with-param name="P3" select="$newP3 + $advance"/>
    </apply-templates>

  </template>


  <!-- Line numbers -->
  <template mode="mei2score" match="mei:sb[not(@source)]/@n[not(.='')]">
    <param name="P2"/>
    <param name="concatenatedLineNumbers"/>
    
    <param name="followingLineNumber" select="../following-sibling::mei:sb[not(@source)][1]/@n"/>
    
    <choose>
      <!-- As we write multiple lines for consequent base chant cues, we have to write multiple line labels.
           We do so recursively. -->
      <when test="contains($capitalLetters, .) and           
                  string($followingLineNumber) != '' and 
                  contains($capitalLetters, $followingLineNumber and
                  string($followingLineNumber/../@label) != '')">
        <apply-templates mode="mei2score" select="$followingLineNumber">
          <with-param name="P2" select="$P2"/>
          <with-param name="concatenatedLineNumbers" select="concat($concatenatedLineNumbers, .)"/>
        </apply-templates>
      </when>
      <when test="$typesetApparatusSnippets='false'">
        <value-of select="concat('t ',$P2,' ',$lineNumberP3,' ',$marginaliaP4,' 0 0 0 -2.1 &#10;')"/>
        <value-of select="concat($standardFont, $concatenatedLineNumbers, ., '&#10;')"/>
      </when>
    </choose>
  </template>


  <!-- Rubrics -->
  <template mode="mei2score" match="mei:sb[not(@source)]/@label[not(.='')]">
    <param name="P2"/>
    <param name="P4" select="$rubricP4"/>
    <param name="rubricText" select="."/>
    
    <!-- Multiple rubrics are separated by a "#" and we need to split them -->
    <value-of select="concat('t ',$P2,' ',$staffP3,' ',$P4,' 0 0 0 -2.2&#10;')"/>
    <value-of select="$standardFont"/>
    <apply-templates select="." mode="generate-score-escaped-string">
      <with-param name="string" select="normalize-space(substring-before(concat($rubricText,'#'),'#'))"/>
      <with-param name="allCaps" select="true()"/>
    </apply-templates>
    <value-of select="'&#10;'"/>
    
    <if test="contains($rubricText,'#')">
      <apply-templates mode="mei2score" select=".">
        <with-param name="P2" select="$P2"/>
        <with-param name="P4" select="$P4 - $P4distanceBetweenRubrics"/>
        <with-param name="rubricText" select="substring-after($rubricText, '#')"/>
      </apply-templates>
    </if>
  </template>


  <template match="mei:sb" mode="get-syllable-font">
    <value-of select="$standardFont"/>
  </template>
  <template match="mei:sb[contains('ABCDEFGHIJKLMNOPQRSTUVWXYZ+', substring(@n,1,1))]" mode="get-syllable-font">
    <value-of select="$smallCapsFont"/>
  </template>
  
  
  <template mode="mei2score" match="mei:syllable">
    <param name="P2"/>
    <param name="P3"/>
    
    <variable name="leadingBreakMarkers" select="(mei:sb|mei:pb)[not(preceding-sibling::mei:ineume)]"/>
    
    <variable name="newP3" select="$P3 + $advance*(1 + count($leadingBreakMarkers))"/>

    <apply-templates mode="handle-typesetter-annotations" select="mei:syl/@xml:id">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$newP3"/>
      <with-param name="P4" select="$lyricsAnnotP4"/>
    </apply-templates>

    <variable name="font">
      <apply-templates select="preceding-sibling::mei:sb[string-length(@n)>0][1]" mode="get-syllable-font"/>
    </variable>
    
    <variable name="syl">
      <apply-templates mode="generate-score-escaped-string" select="mei:syl">
        <with-param name="trailingCharactersToOmit" select="'-'"/>
        <with-param name="font" select="$font"/>
      </apply-templates>
    </variable>

    <variable name="P8textClass">
      <choose>
        <when test="$font = $smallCapsFont">-2.4</when>
        <otherwise>-2.3</otherwise>
      </choose>
    </variable>
    
    <value-of select="concat('t ',$P2,' ',$newP3,' ',$lyricsP4,' 0 0 0 ', $P8textClass, '&#10;')"/>
    <value-of select="concat($font, $syl,'&#10;')"/>
    
    <if test="@wordpos='i' or @wordpos='m' or contains(mei:syl, '-')">
      <value-of select="concat('4 ',$P2,' ',$newP3,' ',$hyphenP4,' ',$hyphenP4,' ',$newP3,' 0 0 0 0 0 0 0 0 0 1 0 ',$hyphenP17,' ',$hyphenP18,'&#10;')"/>
    </if>
    
    <apply-templates mode="mei2score" select="($leadingBreakMarkers|mei:ineume|following::*)[1]">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$newP3 - $advance * count($leadingBreakMarkers)"/>
    </apply-templates>
  </template>
  
  
  <template mode="generate-score-escaped-string" match="node()|@*">
    <param name="string" select="normalize-space(.)"/>
    <param name="trailingCharactersToOmit" select="''"/>
    <param name="allCaps" select="false()"/>
    <param name="font" select="$standardFont"/>
    
    <if test="string-length($string) > 0 and $string != $trailingCharactersToOmit">
      <variable name="char" select="substring($string,1,1)"/>
      <variable name="firstTwoChars" select="substring($string,1,2)"/>
      <!-- The Score manual does not list "~" among the unescaped characters, but we do -->
      <variable name="unescapedChars">abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,():;?!+-*=@#$%&amp;&lt;&gt;`'"~</variable>

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
          <when test="$char='²'">\\366</when>
          <when test="$char='¹'">\\365</when>
          <when test="$char='¼'">\\362</when>
          <when test="$char='½'">\\363</when>
          <when test="$char='¾'">\\364</when>
          <when test="$char='¹'">\\365</when>
          <when test="$char='³'">\\367</when>
          <when test="$char='&#160;'"> </when><!-- "&nbsp;" -->
          <otherwise>
            <value-of select="'?'"/>
            <message>
              WARNING:
              Unsupported character: "<value-of select="$char"/>"
              Rest of string: "<value-of select="$string"/>"
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
        <with-param name="string" select="substring($string,2)"/>
        <with-param name="trailingCharactersToOmit" select="$trailingCharactersToOmit"/>
        <with-param name="allCaps" select="$allCaps"/>
        <with-param name="font" select="$font"/>
      </apply-templates>
    </if>
  </template>
  
  
  <template mode="mei2score" match="mei:ineume">
    <param name="P2"/>
    <param name="P3"/>
    
    <!-- We draw an invisible barline if we have two consequent ineumes -->
    <if test="preceding-sibling::mei:*[1]/self::mei:ineume">
      <value-of select="concat('14 ',$P2,' ',$P3 - .25*$advance,' -1 &#10;')"/>
    </if>
    
    <apply-templates mode="mei2score" select=".//mei:note/@accid">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$P3"/>
    </apply-templates>
    
    <apply-templates mode="mei2score" select="*[1]">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$P3"/>
    </apply-templates>
  </template>
  
  
  <template mode="mei2score" match="mei:uneume">
    <param name="P2"/>
    <param name="P3"/>
    
    <!-- We draw a connecting slur if there's more than one note inside this uneume -->
    <if test="count(mei:note) > 1">
      <value-of select="concat('5 ',$P2,' ',$P3,' ',$slurP4,' ',$slurP4,' ',$P3 + (count(mei:note) - 1)*$advance, ' 2 -1 ',$slurP9,'&#10;')"/>
    </if>
    
    <apply-templates mode="mei2score" select="*[1]">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$P3"/>
    </apply-templates>
  </template>
  
  
  <template mode="mei2score" match="mei:note">
    <param name="P2"/>
    <param name="P3"/>
    
    <if test="@pname and @oct">
      <variable name="P4">
        <apply-templates select="." mode="get-notehead-p4"/>
      </variable>
      <variable name="P6">
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
      
      <value-of select="concat('1 ',$P2,' ',$P3,' ',$P4,' 0 ',$P6)"/>
      <if test="@mfunc='liquescent'">
        <value-of select="concat(' 0 0 0 0 0 0 0 0 ',$liquescentP15)"/>
      </if>
      <value-of select="'&#10;'"/>
    </if>
    
    <apply-templates mode="mei2score" select="(*|following::*[1])">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$P3 + $advance"/>
    </apply-templates>
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
    <value-of select="concat('51',translate(@intm,'ud','56'))"/>
  </template>
  
  
  <template match="mei:note" mode="get-notehead-p4">
    <variable name="monodiStep">
      <!-- The get-notehead-step template is imported from mei2xhtml.xsl -->
      <apply-templates select="." mode="get-notehead-step"/>
    </variable>
    
    <copy-of select="7 - $monodiStep"/>
  </template>


  <template mode="mei2score" match="mei:sb[@source]|mei:pb">
    <param name="P2"/>
    <param name="P3"/>
    
    <apply-templates mode="handle-typesetter-annotations" select="@xml:id">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$P3"/>
    </apply-templates>
    
    <value-of select="concat('t ',$P2,' ',$P3,' ',$lyricsP4,' 0 0 0 -2.5 &#10;')"/>
    <value-of select="concat($standardFont, '?|')"/>
    <!-- For page breaks, we need a second pipe and the folio number -->
    <if test="self::mei:pb">
      <text>?|&#10;</text>
      <!-- For apparatus snippets, we don't want the folio number in the right margin -->
      <if test="$typesetApparatusSnippets='false'">
        <value-of select="concat('t ',$P2,' ',200,' ',$marginaliaP4,' 0 0 0 -2.9 &#10;')"/>
        <value-of select="concat($standardFont, '?|?| ',@n)"/>
        <if test="@func='verso'">
          <text>v</text>
        </if>
      </if>
    </if>
    <text>&#10;</text>
    
    <apply-templates mode="mei2score" select="following::*[1]">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$P3 + $advance"/>
    </apply-templates>
  </template>


  <template match="@xml:id" mode="handle-typesetter-annotations">
    <param name="P2"/>
    <param name="P3"/>
    <param name="P4" select="$standardAnnotP4"/>
    
    <for-each select="key('typesetterAnnotStart',.)">
      <value-of select="concat('t ',$P2,' ',$P3,' ',$P4,' ',$annotP5toP7,'&#10;')"/>
      <value-of select="'_99%@'"/>
      <!-- If the annotation spans different elements, we create a start marker -->
      <if test="@startid != @endid">
        <value-of select="'?[?['"/>
      </if>
      <apply-templates select="." mode="generate-score-escaped-string">
        <with-param name="string" select="concat(@label,';  ',normalize-space())"/>
        <with-param name="font" select="'_99'"/>
      </apply-templates>
      <value-of select="'&#10;'"/>
    </for-each>
    
    <!-- We create an annotation ending marker -->
    <for-each select="key('typesetterAnnotEnd',.)[@startid != @endid]">
      <value-of select="concat('t ',$P2,' ',$P3,' ',$P4 - 4,' ',$annotP5toP7,'&#10;')"/>
      <value-of select="'_99%@'"/>
      <apply-templates select="@label" mode="generate-score-escaped-string">
        <with-param name="font" select="'_99'"/>
      </apply-templates>
      <value-of select="'?]?]&#10;'"/>
    </for-each>
  </template>


  <template match="@xml:id" mode="handle-diacriticalMarking-annotations">
    <param name="P2"/>
    <param name="P3"/>
    <param name="P4" select="$standardDiacriticalMarkingP4"/>
    
    <for-each select="key('diacriticalMarkingAnnot',.)">
      <value-of select="concat('t ',$P2,' ',$P3,' ',$P4,' 0 0 0 -2.7 &#10;')"/>
      <value-of select="$standardFont"/>
      <apply-templates select="@label" mode="generate-score-escaped-string"/>
      <value-of select="'&#10;'"/>
    </for-each>
  </template>
</stylesheet>