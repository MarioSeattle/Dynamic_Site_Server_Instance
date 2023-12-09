<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:msxsl="urn:schemas-microsoft-com:xslt"
	xmlns:igxlib="urn:igxlibns"
	exclude-result-prefixes="msxsl igxlib"
	version="1.0">
	<xsl:output method="html" omit-xml-declaration="yes" encoding="utf-8"/>

	<xsl:include href="../include-formbuilder.xsl"/>

	<xsl:template match="/">
		<xsl:apply-templates select="FormField_Button" mode="root" />
	</xsl:template>

	<xsl:template match="FormField_Button" mode="root">
		<xsl:apply-templates select="FormField_Button" mode="form"/>
	</xsl:template>

</xsl:stylesheet>