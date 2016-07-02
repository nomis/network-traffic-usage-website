<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.0" exclude-result-prefixes="xsl xsi">
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
		<xsl:variable name="svg_width" select="1000"/>
		<xsl:variable name="svg_height" select="400"/>
		<xsl:variable name="text_height" select="16"/>
		<xsl:variable name="x_label_height" select="30"/>
		<xsl:variable name="x_tick_height" select="5"/>
		<xsl:variable name="y_label_width" select="50"/>
		<xsl:variable name="x_period_width" select="($svg_width - $y_label_width) div count(periods/period)"/>
		<xsl:variable name="y_steps" select="10"/>
		<xsl:variable name="y_tick_width" select="5"/>
		<xsl:variable name="y_step_height" select="($svg_height - $x_label_height) div $y_steps"/>
		<xsl:variable name="bar_width" select="0.75"/>
		<xsl:variable name="max_bytes">
			<xsl:variable name="max_rx_bytes">
				<xsl:for-each select="periods/period">
					<xsl:sort select="@rx_bytes" data-type="number" order="descending"/>
					<xsl:if test="position() = 1"><xsl:value-of select="@rx_bytes"/></xsl:if>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="max_tx_bytes">
				<xsl:for-each select="periods/period">
					<xsl:sort select="@tx_bytes" data-type="number" order="descending"/>
					<xsl:if test="position() = 1"><xsl:value-of select="@tx_bytes"/></xsl:if>
				</xsl:for-each>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$max_rx_bytes > $max_tx_bytes"><xsl:value-of select="$max_rx_bytes"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$max_tx_bytes"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="parent">
				<h1>
					<a>
						<xsl:attribute name="href"><xsl:value-of select="parent/@uri"/></xsl:attribute>
						<xsl:value-of select="substring(@name, 1, string-length(parent/@name))"/>
					</a>
					<xsl:value-of select="substring(@name, string-length(parent/@name) + 1)"/>
				</h1>
			</xsl:when>
			<xsl:otherwise>
				<h1><xsl:value-of select="@name"/></h1>
			</xsl:otherwise>
		</xsl:choose>
		<svg xmlns="http://www.w3.org/2000/svg" version="1.1">
			<xsl:attribute name="width"><xsl:value-of select="$svg_width"/></xsl:attribute>
			<xsl:attribute name="height"><xsl:value-of select="$svg_height + $text_height div 2"/></xsl:attribute>
			<xsl:attribute name="viewBox" xml:space="preserve">0 <xsl:value-of select="-($text_height div 2)"/> <xsl:value-of select="$svg_width"/> <xsl:value-of select="$svg_height + $text_height div 2"/></xsl:attribute>

			<g stroke="grey" stroke-width="1">
				<xsl:for-each select="periods/period">
					<!-- bars -->
					<xsl:if test="@rx_bytes">
						<rect fill="crimson">
							<xsl:attribute name="x"><xsl:value-of select="$y_label_width + 0.5 + floor(($x_period_width div 2) * (2 * position() - 2) + ($x_period_width - ($x_period_width * $bar_width)) div 3)"/></xsl:attribute>
							<xsl:attribute name="y"><xsl:value-of select="0.5 + ($svg_height - $x_label_height - 1) - floor(($svg_height - $x_label_height - 1) * @rx_bytes div $max_bytes)"/></xsl:attribute>
							<xsl:attribute name="width"><xsl:value-of select="floor($x_period_width div 2 * $bar_width)"/></xsl:attribute>
							<xsl:attribute name="height"><xsl:value-of select="floor(($svg_height - $x_label_height - 1) * @rx_bytes div $max_bytes)"/></xsl:attribute>
						</rect>
					</xsl:if>
					<xsl:if test="@tx_bytes">
						<rect fill="mediumseagreen">
							<xsl:attribute name="x"><xsl:value-of select="$y_label_width + 0.5 + floor(($x_period_width div 2) * (2 * position() - 1) + ($x_period_width - ($x_period_width * $bar_width)) div 6)"/></xsl:attribute>
							<xsl:attribute name="y"><xsl:value-of select="0.5 + ($svg_height - $x_label_height - 1) - floor(($svg_height - $x_label_height - 1) * @tx_bytes div $max_bytes)"/></xsl:attribute>
							<xsl:attribute name="width"><xsl:value-of select="floor($x_period_width div 2 * $bar_width)"/></xsl:attribute>
							<xsl:attribute name="height"><xsl:value-of select="floor(($svg_height - $x_label_height - 1) * @tx_bytes div $max_bytes)"/></xsl:attribute>
						</rect>
					</xsl:if>
				</xsl:for-each>
			</g>

			<g stroke="black" stroke-width="1">
				<!-- X axis -->
				<line>
					<xsl:attribute name="x1"><xsl:value-of select="$y_label_width"/></xsl:attribute>
					<xsl:attribute name="x2"><xsl:value-of select="$svg_width"/></xsl:attribute>
					<xsl:attribute name="y1"><xsl:value-of select="$svg_height - $x_label_height - 0.5"/></xsl:attribute>
					<xsl:attribute name="y2"><xsl:value-of select="$svg_height - $x_label_height - 0.5"/></xsl:attribute>
				</line>

				<!-- Y axis -->
				<line stroke="black" stroke-width="1">
					<xsl:attribute name="x1"><xsl:value-of select="$y_label_width - 0.5"/></xsl:attribute>
					<xsl:attribute name="x2"><xsl:value-of select="$y_label_width - 0.5"/></xsl:attribute>
					<xsl:attribute name="y1">0</xsl:attribute>
					<xsl:attribute name="y2"><xsl:value-of select="$svg_height - $x_label_height"/></xsl:attribute>
				</line>

				<!-- X ticks -->
				<line>
					<xsl:attribute name="x1"><xsl:value-of select="$y_label_width - 0.5"/></xsl:attribute>
					<xsl:attribute name="x2"><xsl:value-of select="$y_label_width - 0.5"/></xsl:attribute>
					<xsl:attribute name="y1"><xsl:value-of select="$svg_height - $x_label_height - $x_tick_height div 2 - 0.5"/></xsl:attribute>
					<xsl:attribute name="y2"><xsl:value-of select="$svg_height - $x_label_height + $x_tick_height div 2 - 0.5"/></xsl:attribute>
				</line>
				<xsl:for-each select="periods/period">
					<line>
						<xsl:attribute name="x1"><xsl:value-of select="$y_label_width - 0.5 + floor($x_period_width * position())"/></xsl:attribute>
						<xsl:attribute name="x2"><xsl:value-of select="$y_label_width - 0.5 + floor($x_period_width * position())"/></xsl:attribute>
						<xsl:attribute name="y1"><xsl:value-of select="$svg_height - $x_label_height - $x_tick_height div 2 - 0.5"/></xsl:attribute>
						<xsl:attribute name="y2"><xsl:value-of select="$svg_height - $x_label_height + $x_tick_height div 2 - 0.5"/></xsl:attribute>
					</line>
				</xsl:for-each>

				<!-- Y ticks -->
				<xsl:for-each select="(//node())[$y_steps >= position() - 1]">
					<line>
						<xsl:attribute name="x1"><xsl:value-of select="$y_label_width - $y_tick_width div 2 - 0.5"/></xsl:attribute>
						<xsl:attribute name="x2"><xsl:value-of select="$y_label_width + $y_tick_width div 2 - 0.5"/></xsl:attribute>
						<xsl:attribute name="y1"><xsl:value-of select="floor($y_step_height * (position() - 1)) - 0.5"/></xsl:attribute>
						<xsl:attribute name="y2"><xsl:value-of select="floor($y_step_height * (position() - 1)) - 0.5"/></xsl:attribute>
					</line>
				</xsl:for-each>
			</g>

			<!-- X axis label -->
			<xsl:for-each select="periods/period">
				<text text-anchor="middle" font-size="16" dy="0.3em">
					<xsl:attribute name="x"><xsl:value-of select="$y_label_width - 0.5 + floor($x_period_width * (position() - 0.5))"/></xsl:attribute>
					<xsl:attribute name="y"><xsl:value-of select="$svg_height - $x_label_height div 2"/></xsl:attribute>
					<xsl:choose>
						<xsl:when test="@short_name">
							<xsl:value-of select="@short_name"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@name"/>
						</xsl:otherwise>
					</xsl:choose>
				</text>
			</xsl:for-each>

			<!-- Y axis label -->
			<xsl:for-each select="(//node())[$y_steps >= position() - 1]">
				<text text-anchor="end" font-size="16" dy="0.3em">
					<xsl:attribute name="x"><xsl:value-of select="$y_label_width - $y_tick_width"/></xsl:attribute>
					<xsl:attribute name="y"><xsl:value-of select="floor($y_step_height * (position() - 1))"/></xsl:attribute>
					<xsl:value-of select="$y_steps - (position() - 1)"/>
				</text>
			</xsl:for-each>
		</svg>
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
				<xsl:if test="position() = 1"><xsl:value-of select="@rx_bytes + @tx_bytes"/></xsl:if>
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
			<th scope="row" class="name">
				<xsl:choose>
					<xsl:when test="@uri">
						<a>
							<xsl:attribute name="href"><xsl:value-of select="@uri"/></xsl:attribute>
							<xsl:value-of select="@name"/>
						</a>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="@name"/>
					</xsl:otherwise>
				</xsl:choose>
			</th>
			<td class="rx"><xsl:value-of select="format-number(@rx_bytes div $units_div, '#,##0.00')"/></td>
			<td class="tx"><xsl:value-of select="format-number(@tx_bytes div $units_div, '#,##0.00')"/></td>
			<td class="total"><xsl:value-of select="format-number((@rx_bytes + @tx_bytes) div $units_div, '#,##0.00')"/></td>
		</tr>
	</xsl:template>
</xsl:stylesheet>
