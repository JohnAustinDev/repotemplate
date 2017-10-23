<?xml version="1.0" encoding="UTF-8" ?>
<stylesheet version="2.0"
 xpath-default-namespace="http://www.bibletechnologies.net/2003/OSIS/namespace"
 xmlns="http://www.w3.org/1999/XSL/Transform"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 
  <param name="KeepGlossaryDuplicates" select="'no'"/>

  <!-- Transforms OSIS files created by usfm2osis.py for use in making SWORD modules !-->
  
  <template match="node()|@*" name="identity">
    <copy>
       <apply-templates select="node()|@*"/>
    </copy>
  </template>
  
  <!-- use two passes !-->
  <template match="/">
    <variable name="Pass1">
      <apply-templates/>
    </variable>

    <apply-templates mode="Pass2" select="$Pass1"/>
  </template>

  <!-- remove runningHead titles which should only appear on print-like editions !-->
  <template match="title[@type='runningHead']"/>
  
  <!-- remove USFM chapter labels, which appear as introductions in SWORD, and are auto-generated by front-ends !-->
  <template match="title[@type='x-chapterLabel']"/>

  <!-- remove annotateRefs, which are auto-generated by SWORD front-ends, to prevent duplication !-->
  <template match="reference[@type='annotateRef']" priority="2"/>
  
  <!-- remove introduction elements that shouldn't appear in SWORD introductions !-->
  <template match="milestone[@type='x-usfm-toc1']"/>
  <template match="milestone[@type='x-usfm-toc2']"/>
  <template match="milestone[@type='x-usfm-toc3']"/>
  
  <template match="lb[@type='x-optional']"/>
  
  <!-- remove comments !-->
  <template match="comment()" priority="1"/>

  <!-- show introduction <head> tags as secondary titles !-->
  <template match="head">
    <title level="2" type="main" subType="x-introduction" xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">
      <xsl:apply-templates/>
    </title>
  </template>
  
  <!-- make parallel passage titles secondary titles !-->
  <template match="title[@type='parallel']">
    <copy><attribute name="level">2</attribute><apply-templates/></copy>
  </template>

  <!-- scope title references should not appear as reference links !-->
  <template match="title[@type='scope']//reference">
    <apply-templates/>
  </template>
  
  <!-- remove <reference> tags that lack osisRef attributes !-->
  <template match="reference[not(@osisRef)]" priority="1">
    <apply-templates/>
  </template>
  
  <!-- OSIS <list> and <item> are not milestonable and thus cause SWORD import warnings 
  and improper rendering by SWORD front-ends any time a list contains multiple verses 
  (which is usually the case). The only way to render these is to replace them with 
  milestonable elements, so <lg> and <l> are the natural replacements !-->
  <template match="list[.//verse]">
    <element name="lg" namespace="http://www.bibletechnologies.net/2003/OSIS/namespace">
      <attribute name="subType">x-list</attribute>
      <apply-templates select="node()|@*"/>
    </element>
  </template>
  <template match="list[.//verse]//item">
    <element name="l" namespace="http://www.bibletechnologies.net/2003/OSIS/namespace">
      <attribute name="subType">x-item</attribute>
      <apply-templates select="node()|@*"/>
    </element>
  </template>
    
  <!-- For the moment osis2mod.cpp is by default interpereting majorTitles as introductory material, so  this 
  forces osis2mod.cpp to import majorSection titles as regular preverse titles, which is the more common need !-->
  <template match="div[@type='majorSection']/title[not(@type)][1]">
    <copy><attribute name="type">majorSection</attribute><apply-templates/></copy>
  </template>

  <!-- usfm2osis.py follows the OSIS manual recommendation for selah as a line element which differs from the USFM recommendation for selah.
  According to USFM 2.4 spec, selah is: "A character style. This text is frequently right aligned, and rendered on the same line as the previous poetic text..." !-->
  <template match="l">
    <choose>
      <when test="@type = 'selah'"/>
      <when test="following-sibling::l[1][@type='selah']">
        <copy>
          <apply-templates select="node()|@*"/>
          <element name="hi" namespace="http://www.bibletechnologies.net/2003/OSIS/namespace">
            <attribute name="type">italic</attribute>
            <attribute name="subType">x-selah</attribute>
            <for-each select="following-sibling::l[@type='selah']
                [count(preceding-sibling::l[@type='selah'][. &#62;&#62; current()]) = count(preceding-sibling::l[. &#62;&#62; current()])]">
              <text> </text><apply-templates select="child::node()"/>
            </for-each>
          </element>
        </copy>
      </when>
      <otherwise><copy><apply-templates select="node()|@*"/></copy></otherwise>
    </choose>
  </template>
  
  <template match="*[@subType='x-glossary-duplicate']">
    <if test="$KeepGlossaryDuplicates != 'no'"><apply-templates select="."/></if>
  </template>
  
  <!-- A second pass is needed to handle all <l> tags, including 
  those converted from <item> during the first pass !-->
  <template match="node()|@*" mode="Pass2">
    <copy>
       <apply-templates mode="Pass2" select="node()|@*"/>
    </copy>
  </template>
  
  <!-- Due to the way <l> may be rendered by front-ends, <l> elements must not contain <verse> tags 
  otherwise these would be broken into multiple lines. The fix is to remove all verse tags within 
  <l> elements, and make the previous/following verse tags span the entire element. !-->
  <template match="verse[parent::l]" mode="Pass2" priority="2"/>
  <!-- Modify attribs of each verse that starts outside <l> but the following verse starts within <l> !-->
  <template match="verse[@sID][not(parent::l)][following::verse[@sID][1][parent::l]]" mode="Pass2">
    <variable name="groupend" select="./following::verse[@sID][not(parent::l)][1]" />
    <copy>
      <attribute name="osisID">
        <value-of select="string-join((./@osisID, ./following::verse[@sID][. &lt;&lt; $groupend]/@osisID), ' ')"/>
      </attribute>
      <attribute name="sID">
        <value-of select="string-join((./@sID, ./following::verse[@sID][. &lt;&lt; $groupend]/@sID), ' ')"/>
      </attribute>
    </copy>
  </template>
  <!-- Modify attribs of each verse that ends outside <l> but the preceding verse ends within <l> !-->
  <template match="verse[@eID][not(parent::l)][preceding::verse[@eID][1][parent::l]]" mode="Pass2">
    <variable name="groupend" select="./preceding::verse[@eID][not(parent::l)][1]" />
    <copy>
      <attribute name="eID">
        <value-of select="string-join((./preceding::verse[@eID][$groupend &lt;&lt; .]/@eID, ./@eID), ' ')"/>
      </attribute>
    </copy>
  </template>

</stylesheet>
