<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.0">
	<xsl:output method="html" version="5.0" encoding="UTF-8" indent="yes" doctype-system="about:legacy-compat"/>
	<xsl:template match="traffic">
		<html>
			<head>
				<title><xsl:value-of select="usage/@name"/></title>
				<link rel="stylesheet" href="/normalize.css" type="text/css"/>
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

	<xsl:template name="median">
		<xsl:param name="nodes"/>
		<xsl:param name="attr"/>
		<xsl:variable name="count" select="count($nodes/@*[local-name()=$attr])"/>
		<xsl:variable name="middle" select="ceiling($count div 2)"/>
		<xsl:variable name="even" select="not($count mod 2)"/>

		<xsl:variable name="m1">
			<xsl:for-each select="$nodes/@*[local-name()=$attr]">
				<xsl:sort data-type="number"/>
				<xsl:if test="position() = $middle">
					<xsl:value-of select=". + ($even * ../following-sibling::*[1]/@*[local-name()=$attr])"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<xsl:value-of select="$m1 div ($even + 1)"/>
	</xsl:template>

	<xsl:template match="periods">
		<xsl:variable name="max_bytes">
			<xsl:for-each select="period">
				<xsl:sort select="@rx_bytes + @tx_bytes" data-type="number" order="descending"/>
				<xsl:if test="position() = 1"><xsl:value-of select="@rx_bytes"/></xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="units_name">
			<xsl:choose>
				<xsl:when test="$max_bytes &lt; 10240">B</xsl:when>
				<xsl:when test="$max_bytes &lt; 10485760">KB</xsl:when>
				<xsl:when test="$max_bytes &lt; 10737418240">MB</xsl:when>
				<xsl:otherwise>GB</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="units_div">
			<xsl:choose>
				<xsl:when test="$units_name = 'B'">1</xsl:when>
				<xsl:when test="$units_name = 'KB'">1024</xsl:when>
				<xsl:when test="$units_name = 'MB'">1048576</xsl:when>
				<xsl:when test="$units_name = 'GB'">1073741824</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="rx_median">
			<xsl:call-template name="median">
				<xsl:with-param name="nodes" select="period"/>
				<xsl:with-param name="attr" select="'rx_bytes'"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="tx_median">
			<xsl:call-template name="median">
				<xsl:with-param name="nodes" select="period"/>
				<xsl:with-param name="attr" select="'tx_bytes'"/>
			</xsl:call-template>
		</xsl:variable>
		<table class="usage">
			<thead>
				<tr>
					<th scope="col" class="name"><xsl:value-of select="@type"/></th>
					<th scope="col" class="rx">Receive (<xsl:value-of select="$units_name"/>)</th>
					<th scope="col" class="tx">Transmit (<xsl:value-of select="$units_name"/>)</th>
					<th scope="col" class="total">Total (<xsl:value-of select="$units_name"/>)</th>
				</tr>
			</thead>
			<tbody>
				<xsl:apply-templates select="period/@rx_bytes/..">
					<xsl:with-param name="units_div" select="$units_div"/>
				</xsl:apply-templates>
			</tbody>
			<tfoot>
				<tr class="summary average">
					<th scope="row" class="name">Average</th>
					<td class="rx"><xsl:value-of select="format-number(sum(period/@rx_bytes) div count(period/@rx_bytes) div $units_div, '#,##0.00')"/></td>
					<td class="tx"><xsl:value-of select="format-number(sum(period/@tx_bytes) div count(period/@tx_bytes) div $units_div, '#,##0.00')"/></td>
					<td class="total"><xsl:value-of select="format-number((sum(period/@rx_bytes) + sum(period/@tx_bytes)) div count(period/@rx_bytes) div $units_div, '#,##0.00')"/></td>
				</tr>
				<tr class="summary median">
					<th scope="row" class="name">Median</th>
					<td class="rx"><xsl:value-of select="format-number($rx_median div $units_div, '#,##0.00')"/></td>
					<td class="tx"><xsl:value-of select="format-number($tx_median div $units_div, '#,##0.00')"/></td>
					<td class="total"><xsl:value-of select="format-number(($rx_median + $tx_median) div $units_div, '#,##0.00')"/></td>
				</tr>
				<tr class="summary total">
					<th scope="row" class="name">Total</th>
					<td class="rx"><xsl:value-of select="format-number(sum(period/@rx_bytes) div $units_div, '#,##0.00')"/></td>
					<td class="tx"><xsl:value-of select="format-number(sum(period/@tx_bytes) div $units_div, '#,##0.00')"/></td>
					<td class="total"><xsl:value-of select="format-number((sum(period/@rx_bytes) + sum(period/@tx_bytes)) div $units_div, '#,##0.00')"/></td>
				</tr>
			</tfoot>
		</table>
	</xsl:template>

	<xsl:template match="period">
		<xsl:param name="units_div"/>
		<tr>
			<th scope="row" class="name"><xsl:value-of select="@name"/></th>
			<td class="rx"><xsl:value-of select="format-number(@rx_bytes div $units_div, '#,##0.00')"/></td>
			<td class="tx"><xsl:value-of select="format-number(@tx_bytes div $units_div, '#,##0.00')"/></td>
			<td class="total"><xsl:value-of select="format-number((@rx_bytes + @tx_bytes) div $units_div, '#,##0.00')"/></td>
		</tr>
	</xsl:template>
</xsl:stylesheet>
