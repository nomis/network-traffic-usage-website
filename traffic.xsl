<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.0">
	<xsl:output method="html" version="5.0" encoding="UTF-8" indent="yes"/>
	<xsl:template match="traffic">
		<html>
			<head>
				<title><xsl:value-of select="usage/@name"/></title>
				<link rel="stylesheet" href="/traffic.css" type="text/css"/>
			</head>
			<body>
				<xsl:apply-templates select="usage"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="usage">
		<h1><xsl:value-of select="@name"/></h1>
		<xsl:apply-templates select="periods"/>
	</xsl:template>

	<xsl:template match="periods">
		<table class="usage">
			<tr>
				<th class="name"><xsl:value-of select="@type"/></th>
				<th class="rx">Receive</th>
				<th class="tx">Transmit</th>
				<th class="total">Total</th>
			</tr>
			<xsl:apply-templates select="period"/>
		</table>
	</xsl:template>

	<xsl:template match="period">
		<tr>
			<td class="name"><xsl:value-of select="@name"/></td>
			<td class="rx"><xsl:value-of select="@rx_bytes"/></td>
			<td class="tx"><xsl:value-of select="@tx_bytes"/></td>
			<td class="total"><xsl:value-of select="@rx_bytes + @tx_bytes"/></td>
		</tr>
	</xsl:template>
</xsl:stylesheet>
