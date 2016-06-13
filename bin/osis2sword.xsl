<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:osis="http://www.bibletechnologies.net/2003/OSIS/namespace">

 <!-- Transforms OSIS files created by usfm2osis.py for use in making SWORD modules !-->
  
  <xsl:template match="node()|@*" name="identity">
    <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <!-- remove runningHead titles which should only appear on print-like editions !-->
  <xsl:template match="osis:title[@type='runningHead']"/>
  
  <!-- remove USFM chapter labels, which appear as introductions in SWORD, and are auto-generated by front-ends !-->
  <xsl:template match="osis:title[@type='x-chapterLabel']"/>

  <!-- remove annotateRefs, which are auto-generated by SWORD front-ends, to prevent duplication !-->
  <xsl:template match="osis:reference[@type='annotateRef']" priority="2"/>
  
  <!-- remove introduction elements that shouldn't appear in SWORD introductions !-->
  <xsl:template match="osis:milestone[@type='x-usfm-toc1']"/>
  <xsl:template match="osis:milestone[@type='x-usfm-toc2']"/>
  <xsl:template match="osis:milestone[@type='x-usfm-toc3']"/>
  
  <xsl:template match="osis:lb[@type='x-optional']"/>
  
  <!-- remove comments !-->
  <xsl:template match="comment()" priority="1"/>

  <!-- show introduction <head> tags as secondary titles !-->
  <xsl:template match="osis:head">
    <title level="2" type="main" subType="x-introduction"><xsl:apply-templates/></title>
  </xsl:template>
  
  <!-- make parallel passage titles secondary titles !-->
  <xsl:template match="osis:title[@type='parallel']">
    <xsl:copy><xsl:attribute name="level">2</xsl:attribute><xsl:apply-templates/></xsl:copy>
  </xsl:template>

  <!-- scope title references should not appear as reference links !-->
  <xsl:template match="osis:title[@type='scope']/osis:reference">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- remove <reference> tags that lack osisRef attributes !-->
  <xsl:template match="osis:reference[not(@osisRef)]" priority="1">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- For the moment osis2mod.cpp is by default interpereting majorTitles as introductory material, so  this 
  forces osis2mod.cpp to import majorSection titles as regular preverse titles, which is the more common need !-->
  <xsl:template match="osis:div[@type='majorSection']/osis:title[not(@type)][1]">
    <xsl:copy><xsl:attribute name="type">majorSection</xsl:attribute><xsl:apply-templates/></xsl:copy>
  </xsl:template>

  <!-- usfm2osis.py follows the OSIS manual recommendation for selah as a line element which differs from the USFM recommendation for selah.
  According to USFM 2.35 spec, selah is: "A character style. This text is frequently right aligned, and rendered on the same line as the previous poetic text..." !-->
  <xsl:template match="osis:l">
    <xsl:choose>
      <xsl:when test="@type = 'selah'"/>
      <xsl:when test="following-sibling::osis:l[1]/@type = 'selah'">
        <xsl:copy>
          <xsl:apply-templates select="node()|@*"/>
          <xsl:element name="hi" namespace="http://www.bibletechnologies.net/2003/OSIS/namespace">
            <xsl:attribute name="type">italic</xsl:attribute>
            <xsl:attribute name="subType">x-selah</xsl:attribute>
            <xsl:text> </xsl:text>
            <xsl:value-of select="following-sibling::osis:l[1]"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="following-sibling::osis:l[2][@type = 'selah']"/>
          </xsl:element>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="identity"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
