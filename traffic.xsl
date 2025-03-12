<?xml version="1.0" encoding="UTF-8"?>
<!--
network-traffic-usage-website - Display network traffic usage using XSLT
Copyright 2016,2021,2025  Simon Arlott

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
-->
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
		<xsl:variable name="units_name">
			<xsl:choose>
				<xsl:when test="$max_bytes &lt; 10000">B</xsl:when>
				<xsl:when test="$max_bytes &lt; 10000000">KB</xsl:when>
				<xsl:when test="$max_bytes &lt; 10000000000">MB</xsl:when>
				<xsl:when test="$max_bytes &lt; 10000000000000">GB</xsl:when>
				<xsl:otherwise>TB</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="units_div">
			<xsl:choose>
				<xsl:when test="$units_name = 'B'">1</xsl:when>
				<xsl:when test="$units_name = 'KB'">1000</xsl:when>
				<xsl:when test="$units_name = 'MB'">1000000</xsl:when>
				<xsl:when test="$units_name = 'GB'">1000000000</xsl:when>
				<xsl:when test="$units_name = 'TB'">1000000000000</xsl:when>
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
		<xsl:apply-templates select="periods" mode="graph">
			<xsl:with-param name="max_bytes"><xsl:value-of select="$max_bytes"/></xsl:with-param>
			<xsl:with-param name="units_name"><xsl:value-of select="$units_name"/></xsl:with-param>
			<xsl:with-param name="units_div"><xsl:value-of select="$units_div"/></xsl:with-param>
		</xsl:apply-templates>
		<xsl:apply-templates select="periods" mode="table">
			<xsl:with-param name="units_name"><xsl:value-of select="$units_name"/></xsl:with-param>
			<xsl:with-param name="units_div"><xsl:value-of select="$units_div"/></xsl:with-param>
		</xsl:apply-templates>
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
					<xsl:value-of select="."/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="m2">
			<xsl:for-each select="$nodes/@*[local-name()=$attr]">
				<xsl:sort data-type="number"/>
				<xsl:if test="position() = $middle + 1">
					<xsl:value-of select="."/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="$even">
				<xsl:value-of select="($m1 + $m2) div 2"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$m1"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="periods" mode="table">
		<xsl:param name="units_name"/>
		<xsl:param name="units_div"/>
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
				<xsl:apply-templates select="period/@rx_bytes/.." mode="table">
					<xsl:with-param name="units_div" select="$units_div"/>
				</xsl:apply-templates>
			</tbody>
			<tfoot>
				<xsl:if test="count(period/@rx_bytes) > 1">
					<tr class="summary average">
						<th scope="row" class="name">Average</th>
						<td class="rx"><xsl:value-of select="format-number(sum(period/@rx_bytes) div count(period/@rx_bytes) div $units_div, '#,##0.00')"/></td>
						<td class="tx"><xsl:value-of select="format-number(sum(period/@tx_bytes) div count(period/@tx_bytes) div $units_div, '#,##0.00')"/></td>
						<td class="total"><xsl:value-of select="format-number((sum(period/@rx_bytes) + sum(period/@tx_bytes)) div count(period/@rx_bytes) div $units_div, '#,##0.00')"/></td>
					</tr>
				</xsl:if>
				<xsl:if test="count(period/@rx_bytes) > 2">
					<tr class="summary median">
						<th scope="row" class="name">Median</th>
						<td class="rx"><xsl:value-of select="format-number($rx_median div $units_div, '#,##0.00')"/></td>
						<td class="tx"><xsl:value-of select="format-number($tx_median div $units_div, '#,##0.00')"/></td>
						<td class="total"><xsl:value-of select="format-number(($rx_median + $tx_median) div $units_div, '#,##0.00')"/></td>
					</tr>
				</xsl:if>
				<tr class="summary total">
					<th scope="row" class="name">Total</th>
					<td class="rx"><xsl:value-of select="format-number(sum(period/@rx_bytes) div $units_div, '#,##0.00')"/></td>
					<td class="tx"><xsl:value-of select="format-number(sum(period/@tx_bytes) div $units_div, '#,##0.00')"/></td>
					<td class="total"><xsl:value-of select="format-number((sum(period/@rx_bytes) + sum(period/@tx_bytes)) div $units_div, '#,##0.00')"/></td>
				</tr>
			</tfoot>
		</table>
	</xsl:template>

	<xsl:template match="period" mode="table">
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

	<xsl:template match="periods" mode="graph">
		<xsl:param name="max_bytes"/>
		<xsl:param name="units_name"/>
		<xsl:param name="units_div"/>
		<xsl:variable name="svg_width" select="1000"/>
		<xsl:variable name="svg_height" select="400"/>
		<xsl:variable name="x_text_height" select="16"/>
		<xsl:variable name="y_text_height" select="12"/>
		<xsl:variable name="x_label_height" select="30"/>
		<xsl:variable name="x_tick_height" select="5"/>
		<xsl:variable name="y_label_width" select="70"/>
		<xsl:variable name="x_period_width" select="($svg_width - $y_label_width) div count(period)"/>
		<xsl:variable name="y_steps" select="10"/>
		<xsl:variable name="y_tick_width" select="5"/>
		<xsl:variable name="y_step_height" select="($svg_height - $x_label_height) div $y_steps"/>
		<xsl:variable name="bar_width" select="0.75"/>

		<svg xmlns="http://www.w3.org/2000/svg" version="1.1">
			<xsl:attribute name="width"><xsl:value-of select="$svg_width"/></xsl:attribute>
			<xsl:attribute name="height"><xsl:value-of select="$svg_height + $y_text_height"/></xsl:attribute>
			<xsl:attribute name="viewBox" xml:space="preserve">0 <xsl:value-of select="-($y_text_height)"/> <xsl:value-of select="$svg_width"/> <xsl:value-of select="$svg_height + $y_text_height"/></xsl:attribute>

			<g stroke="grey" stroke-width="1">
				<xsl:for-each select="period">
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
				<xsl:for-each select="period">
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
						<xsl:attribute name="x2"><xsl:value-of select="$y_label_width"/></xsl:attribute>
						<xsl:attribute name="y1"><xsl:value-of select="floor($y_step_height * (position() - 1)) - 0.5"/></xsl:attribute>
						<xsl:attribute name="y2"><xsl:value-of select="floor($y_step_height * (position() - 1)) - 0.5"/></xsl:attribute>
					</line>
				</xsl:for-each>
			</g>

			<!-- X axis labels -->
			<xsl:for-each select="period">
				<text text-anchor="middle" dy="0.3em">
					<xsl:attribute name="font-size"><xsl:value-of select="$x_text_height"/></xsl:attribute>
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

			<!-- Y axis labels -->
			<xsl:for-each select="(//node())[$y_steps >= position() - 1]">
				<text text-anchor="end" dy="0.3em">
					<xsl:attribute name="font-size"><xsl:value-of select="$y_text_height"/></xsl:attribute>
					<xsl:attribute name="x"><xsl:value-of select="$y_label_width - $y_tick_width"/></xsl:attribute>
					<xsl:attribute name="y"><xsl:value-of select="floor($y_step_height * (position() - 1))"/></xsl:attribute>
					<xsl:value-of select="format-number(($y_steps - (position() - 1)) div $y_steps * $max_bytes div $units_div, '#,##0.0')"/>
				</text>
			</xsl:for-each>

			<!-- Y axis type -->
			<text text-anchor="middle" style="writing-mode: tb">
				<xsl:variable name="x"><xsl:value-of select="$y_text_height"/></xsl:variable>
				<xsl:variable name="y"><xsl:value-of select="($svg_height - $x_label_height) div 2"/></xsl:variable>
				<xsl:attribute name="font-size"><xsl:value-of select="$y_text_height"/></xsl:attribute>
				<xsl:attribute name="x"><xsl:value-of select="$x"/></xsl:attribute>
				<xsl:attribute name="y"><xsl:value-of select="$y"/></xsl:attribute>
				<xsl:attribute name="transform" xml:space="preserve">rotate(180 <xsl:value-of select="$x"/> <xsl:value-of select="$y"/>)</xsl:attribute>
				<xsl:value-of select="$units_name"/>
			</text>
		</svg>
	</xsl:template>
</xsl:stylesheet>
