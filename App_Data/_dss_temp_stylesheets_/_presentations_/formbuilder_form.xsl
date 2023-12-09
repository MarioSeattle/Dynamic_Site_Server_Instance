<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:msxsl="urn:schemas-microsoft-com:xslt"
	xmlns:igxlib="urn:igxlibns"
	exclude-result-prefixes="msxsl igxlib"
	version="1.0">
	<xsl:output method="html" omit-xml-declaration="yes" encoding="utf-8"/>

	<xsl:include href="../include-formbuilder.xsl"/>

	<xsl:template match="/">
		<xsl:apply-templates select="FormBuilder_Form" mode="root"/>
	</xsl:template>

	<xsl:template match="FormBuilder_Form" mode="root">
		<div>
			<xsl:call-template name="initForm">
				<!-- include css & jquery (this isn't really needed, as they default to true) -->
				<xsl:with-param name="includeCSS" select="true()"/>
				<xsl:with-param name="includeJquery" select="true()"/>
				<xsl:with-param name="forms" select="." />
			</xsl:call-template>			
			<xsl:apply-templates select="FormBuilder_Form" mode="form"/>
		</div>
	</xsl:template>
</xsl:stylesheet>