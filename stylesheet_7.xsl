<?xml version="1.0" encoding="UTF-8"?>
<!--
    ============================================
    FILE:    stylesheet_7.xsl
    PURPOSE: Transform SportsClub XML → Member Contact List XML
    SCENARIO: Export a clean contact directory of all members
              in a simplified XML format suitable for external
              systems (e.g. email clients, CRM tools).
    OUTPUT:  output_7.xml (contacts.xml)
    MEMBER:  Member 3 — Format Transformation Specialist
    TECHNIQUE: Recursive xsl:apply-templates with named templates
    ============================================
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Output as well-formed XML with UTF-8 encoding and indentation -->
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

    <!-- =====================================================
         KEY DECLARATION
         Allows fast O(1) lookup of a Member by its memberID
         attribute, used in cross-reference resolution.
         ===================================================== -->
    <xsl:key name="memberByID" match="Member" use="@memberID"/>

    <!-- =====================================================
         ROOT TEMPLATE
         Matches the document root and creates the top-level
         <ContactList> wrapper element, then delegates
         processing of each Member to apply-templates.
         ===================================================== -->
    <xsl:template match="/">
        <!-- Root container for the exported contact list -->
        <ContactList>
            <!-- Metadata attribute: total number of contacts -->
            <xsl:attribute name="totalContacts">
                <xsl:value-of select="count(//Members/Member)"/>
            </xsl:attribute>
            <!-- Metadata attribute: export date (static for this dataset) -->
            <xsl:attribute name="exportedFor">SportsClub A25</xsl:attribute>

            <!--
                Apply the Member template to every Member node.
                Sorted alphabetically by member Name.
                Using apply-templates (recursive dispatch) rather
                than a flat for-each loop, so each Member element
                is processed by its own dedicated template below.
            -->
            <xsl:apply-templates select="//Members/Member">
                <xsl:sort select="Name"/>
            </xsl:apply-templates>
        </ContactList>
    </xsl:template>

    <!-- =====================================================
         MEMBER TEMPLATE
         Processes a single <Member> element and outputs a
         <Contact> element with all relevant contact fields.
         Called recursively by apply-templates above.
         ===================================================== -->
    <xsl:template match="Member">
        <!-- One <Contact> block per member -->
        <Contact>
            <!-- memberID carried as an attribute for easy lookup -->
            <xsl:attribute name="id">
                <xsl:value-of select="@memberID"/>
            </xsl:attribute>

            <!-- Full name of the member -->
            <Name><xsl:value-of select="Name"/></Name>

            <!-- Email address -->
            <Email><xsl:value-of select="Email"/></Email>

            <!-- Phone number -->
            <Phone><xsl:value-of select="Phone"/></Phone>

            <!--
                Address is optional (minOccurs=0 in XSD).
                Output the element only if the Address node exists
                and is non-empty; otherwise emit a placeholder.
            -->
            <Address>
                <xsl:choose>
                    <xsl:when test="Address and Address != ''">
                        <xsl:value-of select="Address"/>
                    </xsl:when>
                    <xsl:otherwise>N/A</xsl:otherwise>
                </xsl:choose>
            </Address>

            <!-- Join date for reference -->
            <JoinDate><xsl:value-of select="JoinDate"/></JoinDate>
        </Contact>
    </xsl:template>

</xsl:stylesheet>
