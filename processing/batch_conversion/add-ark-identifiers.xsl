<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei"
    version="2.0">
    
    <!--
    USAGE EXAMPLE:
    java -Xmx1G -cp ../saxon/saxon9he.jar net.sf.saxon.Transform -xsl:add-ark-identifiers.xsl \
    -it:main folderpath=../../collections/Barocci arkidsfile=/tmp/arkids-for-barocci.txt
    -->
    
    <xsl:param name="folderpath" as="xs:string" required="yes"/>
    <xsl:param name="arkidsfile" as="xs:string" required="yes"/>
    
    <xsl:variable name="arkids" as="xs:string*" select="tokenize(unparsed-text($arkidsfile, 'utf-8'), '\r?\n')"/>
    <xsl:variable name="newline" as="xs:string" select="'&#10;'"/>
    
    <xsl:template name="main">
        <xsl:for-each select="collection(concat($folderpath,'/?select=*.xml;recurse=yes'))">
            <xsl:variable name="counter" select="position()"/>
            <xsl:choose>
                <xsl:when test="exists($arkids[$counter])">
                    <xsl:result-document href="{document-uri(.)}" method="xml">
                        <xsl:apply-templates>
                            <xsl:with-param as="xs:string" name="arkid" select="$arkids[$counter]"/>
                        </xsl:apply-templates>
                    </xsl:result-document>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">Run out of ARK IDs</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="tei:TEI">
        <xsl:param name="arkid" as="xs:string*"/>
        <xsl:value-of select="$newline"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates>
                <xsl:with-param as="xs:string*" name="arkid" select="$arkid"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*">
        <xsl:param name="arkid" as="xs:string*"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates>
                <xsl:with-param as="xs:string*" name="arkid" select="$arkid"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="comment()|processing-instruction()"><xsl:copy/></xsl:template>
    
    <xsl:template match="tei:msDesc/tei:msIdentifier[not(tei:altIdentifier/tei:idno[starts-with(string(), 'ark:')])]">
        <xsl:param name="arkid" as="xs:string"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="*|processing-instruction()|comment()|text()[not(position()=last())]">
                <xsl:with-param as="xs:string" name="arkid" select="$arkid"/>
            </xsl:apply-templates>
            <xsl:copy-of select="text()[position()=last()-1]"/>
            <xsl:element name="altIdentifier" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:element name="idno" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:attribute name="type" select="'ARK'"/>
                    <xsl:text>ark:</xsl:text>
                    <xsl:value-of select="$arkid"/>
                </xsl:element>
            </xsl:element>
            <xsl:apply-templates select="text()[position()=last()]"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:msPart[not(@xml:id)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="xml:id" select="generate-id(.)"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>