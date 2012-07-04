<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
  <xsl:import href="../../utils/docbook-xsl/htmlhelp/htmlhelp.xsl"/>
  <xsl:param name="generate.legalnotice.link" select="1"/>
  <xsl:param name="suppress.navigation" select="0"/>
  <xsl:param name="html.stylesheet" select="'reference.css'"/>
  <xsl:param name="htmlhelp.chm" select="'manual.chm'"/>
  <xsl:param name="htmlhelp.hhc.binary" select="0"/>
  <xsl:param name="htmlhelp.hhc.folders.instead.books" select="0"/>
  <xsl:param name="toc.section.depth" select="4"/>
</xsl:stylesheet>
