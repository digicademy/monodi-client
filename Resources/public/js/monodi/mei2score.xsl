<?xml version="1.0" encoding="UTF-8"?><stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" xmlns:mei="http://www.music-encoding.org/ns/mei" version="1.0">
  
  <!-- This stylesheet creates a Score macro file.
       It is not strictly a PMX file because it does not only store item parameters,
       it also contains commands for saving files and continuing on a new page. -->

  <import href="mei2xhtml.xsl"/>
  
  <key name="typesetterAnnotStart" match="mei:annot[@type='typesetter']" use="substring(@startid,2)"/>
  <key name="typesetterAnnotEnd" match="mei:annot[@type='typesetter']" use="substring(@endid,  2)"/>
  
  <output method="text"/>
  
  <param name="staffSize" select=".58"/>
  <param name="maxStaffsPerPage" select="14"/>
  <param name="staffP3" select="10"/>
  <param name="combineBaseChantsOnOneStaff" select="1"/><!-- 1 for true, 0 for false -->
  <param name="advance" select="3"/>
  <param name="marginaliaP4" select="5"/>
  <param name="rubricTitleP4" select="20"/>
  <param name="overviewLineP4" select="30"/>
  <param name="lyricsP4" select="-5"/>
  <param name="hyphenP4" select="-4"/>
  <param name="hyphenP17" select="1"/>
  <param name="hyphenP18" select="2"/>
  <param name="slurP4" select="15"/>
  <param name="slurP9" select="4"/>
  <param name="liquescentP15" select=".65"/>
  <param name="lineNumberP3" select=".01"/>
  <param name="standardFont" select="'_80'"/>
  <param name="smallCapsFont" select="'_85'"/>
  <param name="standardAnnotP4" select="18"/>
  <param name="lyricsAnnotP4" select="$lyricsP4 - 4"/>
  <param name="annotP5toP7" select="'.9 .55 1'"/>
  
  <variable name="capitalLetters" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>

  <template mode="mei2score" match="text()"/>
  
  <template match="/">
    <for-each select="//mei:work[1]">
      <value-of select="concat('t ',$maxStaffsPerPage,' ',$lineNumberP3,' ',$overviewLineP4,'&#10;')"/>
      <value-of select="concat($standardFont, @n, '&#10;')"/>
      <value-of select="concat('t ',$maxStaffsPerPage,' ',$lineNumberP3,' ',$overviewLineP4,' 0 0 0 0 0 0 ',$staffP3,'&#10;')"/>
      <value-of select="$standardFont"/>
      <value-of select="normalize-space(mei:classification/mei:termList[@label='liturgicFunction'])"/>
      <apply-templates mode="list-line-numbers" select="(//mei:sb[not(@source)]/@n[not(.='')])[1]"/>
      <variable name="textEditionString" select="normalize-space(//mei:biblList[@type='textEditions'])"/>
      <if test="$textEditionString != ''">
        <value-of select="concat(' (',$textEditionString,')')"/>
      </if>
      <value-of select="'&#10;'"/>
    </for-each>
    
    <!-- We convert one line after the other because we need to keep track of
         to how many line Score breaks an individual mei:sb translates to.
         $maxStaffsPerPage is then used to determine when we need to start a new Score file. -->
    <apply-templates mode="mei2score" select="//mei:sb[not(@source)][1]"/>
  </template>
  
  <template match="mei:sb[not(@source)]/@n" mode="list-line-numbers">
    <param name="precedingLineNumber"/>
    
    <if test="$precedingLineNumber = '' or not(contains($capitalLetters, .)) or not(contains($capitalLetters, $precedingLineNumber))">
      <value-of select="' '"/>
    </if>
    <value-of select="."/>
    
    <apply-templates select="(../following-sibling::mei:sb[not(@source)]/@n[not(.='')])[1]" mode="list-line-numbers">
      <with-param name="precedingLineNumber" select="."/>
    </apply-templates>
  </template>
  

  <template mode="mei2score" match="mei:sb[not(@source)]">
    <!-- P2 is actually the "previous P2", so for the call to this template, we use $maxStaffsPerPage + 1 -->
    <param name="P2" select="$maxStaffsPerPage + 1"/>
    <param name="P3" select="$staffP3"/>
    
    <variable name="precedingLineNumber" select="preceding-sibling::mei:sb[not(@source)][1]/@n"/>
    <variable name="followingLineNumber" select="following-sibling::mei:pb[not(@source)][1]/@n"/>
    
    <variable name="newP2">
      <choose>
        <!-- If we have sequential base chants, we stay on the same line. -->
        <when test="$precedingLineNumber != '' and contains($capitalLetters, $precedingLineNumber) 
                                  and @n != '' and contains($capitalLetters, @n)">
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
        <when test="$newP2 = $P2">
          <copy-of select="$P3 + $advance"/>
        </when>
        <otherwise>
          <copy-of select="$staffP3"/>
        </otherwise>
      </choose>
    </variable>
    
    <!-- Check whether we went beyond the bottom staff, so we have to move on to the next page. -->
    <if test="$P2 &lt; $newP2">
      sm
      snx
      if p1 > 0 then de
    </if>
    
    <apply-templates select="@xml:id" mode="handle-typesetter-annotations">
      <with-param name="P3" select="$newP3"/>
      <with-param name="P2" select="$newP2"/>
    </apply-templates>

    <!-- Draw staff -->
    <value-of select="concat('8 ',$newP2,' ',$newP3,' 0 ',$staffSize,'&#10;')"/>
    
    <!-- On the first line in the chant, we place a clef -->
    <if test="not(preceding-sibling::mei:sb)">
      <value-of select="concat('3 ',$newP2,' ',$newP3 + $advance,' 0 500&#10;')"/>
    </if>
    
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
      <when test="contains($capitalLetters, .) and           string($followingLineNumber) != '' and contains($capitalLetters, $followingLineNumber)">
        <apply-templates mode="mei2score" select="$followingLineNumber">
          <with-param name="P2" select="$P2"/>
          <with-param name="concatenatedLineNumbers" select="concat($concatenatedLineNumbers, .)"/>
        </apply-templates>
      </when>
      <otherwise>
        <value-of select="concat('t ',$P2,' ',$lineNumberP3,' ',$marginaliaP4,'&#10;')"/>
        <value-of select="concat($standardFont, $concatenatedLineNumbers, ., '&#10;')"/>
      </otherwise>
    </choose>
  </template>


  <!-- Rubrics -->
  <template mode="mei2score" match="mei:sb[not(@source)]/@label[not(.='')]">
    <param name="P2"/>
    
    <value-of select="concat('t ',$P2,' ',$lineNumberP3,' ',$rubricTitleP4,' 0 0 0 0 0 0 ',$staffP3,'&#10;')"/>
    <value-of select="concat($standardFont, string() ,'&#10;')"/>
  </template>


  <template match="mei:sb" mode="get-syllable-font">
    <value-of select="$standardFont"/>
  </template>
  <template match="mei:sb[contains('ABCDEFGHIJKLMNOPQRSTUVWXYZ', @n)]" mode="get-syllable-font">
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

    <variable name="syl">
      <call-template name="generate-score-escaped-string">
        <with-param name="string" select="normalize-space(mei:syl)"/>
        <with-param name="trailingCharactersToOmit" select="'-'"/>
      </call-template>
    </variable>

    <variable name="font">
      <apply-templates select="preceding-sibling::mei:sb[1]" mode="get-syllable-font"/>
    </variable>
    
    <value-of select="concat('t ',$P2,' ',$newP3,' ',$lyricsP4,'&#10;')"/>
    <value-of select="concat($font, $syl,'&#10;')"/>
    
    <if test="@wordpos='i' or @wordpos='m' or contains(mei:syl, '-')">
      <value-of select="concat('4 ',$P2,' ',$newP3,' ',$hyphenP4,' ',$hyphenP4,' ',$newP3,' 0 0 0 0 0 0 0 0 0 1 0 ',$hyphenP17,' ',$hyphenP18)"/>
    </if>
    
    <apply-templates mode="mei2score" select="($leadingBreakMarkers|mei:ineume|following::*)[1]">
      <with-param name="P2" select="$P2"/>
      <with-param name="P3" select="$newP3 - $advance * count($leadingBreakMarkers)"/>
    </apply-templates>
  </template>
  
  
  <template name="generate-score-escaped-string">
    <param name="string"/>
    <param name="trailingCharactersToOmit" select="''"/>
    
    <if test="string-length($string) > 0 and $string != $trailingCharactersToOmit">
      <variable name="char" select="substring($string,1,1)"/>
      <variable name="firstTwoChars" select="substring($string,1,2)"/>
      <!-- The Score manual does not list "~" among the unescaped characters, but we do -->
      <variable name="unescapedChars">abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,():;?!+-*=@#$%&amp;&lt;&gt;`'"~</variable>
      
      <choose>
        <when test="normalize-space($firstTwoChars) != '' and contains(             ' &lt;&lt; &gt;&gt; ^^ %% ##                ?\ ?| ?[ ?] ?{ ?} ?- ?a ?A ?c ?e ?E ?f ?l ?L ?m ?o ?O ?r ?s ?t                !0 !1 !2 !3 !4 !5 !6 !7 !8 !9 !a !A !d !D !e !f !g !h !i !j !k !l !m !n !p !q !s !S !y !z !Z                ~a ~A ~n ~N ~o ~O                ?1 ?2 ?3 ?d ?0 ?8 ?9 ',             concat(' ',$firstTwoChars,' ')           )">
          <value-of select="concat($char,' ')"/>
          <message>
            WARNING: Text from the mono:di data contained "<value-of select="$firstTwoChars"/>".
            To prevent Score from interpreting this as an escape sequences, a space was inserted.
          </message>
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
            '\|[]{}−æÆ©œŒªłŁºøØ®ß™♭♯♮𝅭',
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
        <otherwise>
          <value-of select="'?'"/>
          <message>
            WARNING:
            Unsupported character: "<value-of select="$char"/>"
            Rest of string: "<value-of select="$string"/>"
          </message>
        </otherwise>
      </choose>
      
      <call-template name="generate-score-escaped-string">
        <with-param name="string" select="substring($string,2)"/>
        <with-param name="trailingCharactersToOmit" select="$trailingCharactersToOmit"/>
      </call-template>
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
    
    <value-of select="concat('t ',$P2,' ',$P3,' ',$lyricsP4,'&#10;')"/>
    <value-of select="concat($standardFont, '?|')"/>
    <!-- For page breaks, we need a second pipe and the folio number -->
    <if test="self::mei:pb">
      <text>?|&#10;</text>
      <value-of select="concat('t ',$P2,' ',200,' ',$marginaliaP4,'&#10;')"/>
      <value-of select="concat($standardFont, '?|?| ',@n)"/>
      <if test="@func='verso'">
        <text>v</text>
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
      <call-template name="generate-score-escaped-string">
        <with-param name="string" select="concat(@label,';  ',normalize-space())"/>
      </call-template>
      <value-of select="'&#10;'"/>
    </for-each>

    <!-- We create an annotation ending marker -->
    <for-each select="key('typesetterAnnotEnd',.)[@startid != @endid]">
      <value-of select="concat('t ',$P2,' ',$P3,' ',$P4 - 4,' ',$annotP5toP7,'&#10;')"/>
      <value-of select="'_99%@'"/>
      <call-template name="generate-score-escaped-string">
        <with-param name="string" select="@label"/>
      </call-template>
      <value-of select="'?]?]&#10;'"/>
    </for-each>
  </template>
</stylesheet>