<?xml version="1.0" encoding="UTF-8"?>
<!--
    ============================================
    FILE:    stylesheet_8.xsl
    PURPOSE: Transform SportsClub XML → Training Session Schedule XML
    SCENARIO: Export a structured schedule of all training sessions
              with resolved coach and facility names (not just IDs),
              suitable for display boards or calendar integrations.
    OUTPUT:  output_8.xml (schedule_export.xml)
    MEMBER:  Member 3 — Format Transformation Specialist
    TECHNIQUE: Recursive xsl:apply-templates + xsl:key for
               cross-entity reference resolution (O(1) lookups)
    ============================================
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Output as well-formed XML, indented, UTF-8 encoded -->
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

    <!-- =====================================================
         KEY DECLARATIONS
         These enable fast XPath lookups by ID without needing
         nested for-each loops (avoids O(n²) traversal).
         ===================================================== -->

    <!-- Lookup a Coach element by its coachID attribute -->
    <xsl:key name="coachByID"    match="Coach"    use="@coachID"/>

    <!-- Lookup a Facility element by its facilityID attribute -->
    <xsl:key name="facilityByID" match="Facility" use="@facilityID"/>

    <!-- =====================================================
         ROOT TEMPLATE
         Creates the <ScheduleExport> root element, adds
         metadata attributes, then delegates each session
         to the TrainingSession template via apply-templates.
         ===================================================== -->
    <xsl:template match="/">
        <!-- Top-level wrapper for the exported schedule -->
        <ScheduleExport>
            <!-- Total number of sessions exported -->
            <xsl:attribute name="totalSessions">
                <xsl:value-of select="count(//TrainingSessions/TrainingSession)"/>
            </xsl:attribute>
            <xsl:attribute name="source">SportsClub A25 — Data Pipeline 1</xsl:attribute>

            <!--
                Dispatch each TrainingSession to its own template.
                Sessions are sorted chronologically by Date, then
                by StartTime within the same day.
                apply-templates (recursive dispatch) is used so
                each session is handled by a dedicated template.
            -->
            <xsl:apply-templates select="//TrainingSessions/TrainingSession">
                <xsl:sort select="Date"/>
                <xsl:sort select="StartTime"/>
            </xsl:apply-templates>
        </ScheduleExport>
    </xsl:template>

    <!-- =====================================================
         TRAININGSESSION TEMPLATE
         Processes a single <TrainingSession> element.
         Resolves CoachRef and FacilityRef to full names
         using xsl:key lookups for efficiency.
         Called recursively by apply-templates above.
         ===================================================== -->
    <xsl:template match="TrainingSession">
        <Session>
            <!-- Session unique identifier as attribute -->
            <xsl:attribute name="id">
                <xsl:value-of select="@sessionID"/>
            </xsl:attribute>

            <!-- Human-readable title of the session -->
            <Title><xsl:value-of select="Title"/></Title>

            <!-- Date of the session (xs:date format YYYY-MM-DD) -->
            <Date><xsl:value-of select="Date"/></Date>

            <!-- Time range block -->
            <TimeRange>
                <Start><xsl:value-of select="StartTime"/></Start>
                <End><xsl:value-of select="EndTime"/></End>
            </TimeRange>

            <!--
                Resolve CoachRef ID to the coach's full name
                using the coachByID key (O(1) lookup).
                Both the ID and the resolved name are exported.
            -->
            <Coach>
                <xsl:attribute name="ref">
                    <xsl:value-of select="CoachRef"/>
                </xsl:attribute>
                <xsl:value-of select="key('coachByID', CoachRef)/Name"/>
            </Coach>

            <!--
                Resolve FacilityRef ID to the facility's full name
                using the facilityByID key (O(1) lookup).
                Both the ID and the resolved name are exported.
            -->
            <Facility>
                <xsl:attribute name="ref">
                    <xsl:value-of select="FacilityRef"/>
                </xsl:attribute>
                <xsl:value-of select="key('facilityByID', FacilityRef)/Name"/>
            </Facility>

            <!-- Maximum number of participants allowed -->
            <MaxCapacity><xsl:value-of select="MaxCapacity"/></MaxCapacity>
        </Session>
    </xsl:template>

</xsl:stylesheet>
