<?xml version="1.0" encoding="UTF-8"?>
<!--
    ============================================
    FILE:    stylesheet_9.xsl
    PURPOSE: Transform SportsClub XML → Bookings JSON
    SCENARIO: Export all booking records as a JSON array,
              suitable for REST APIs, mobile applications,
              or JavaScript front-end consumption.
    OUTPUT:  output_9.json (bookings.json)
    MEMBER:  Member 3 — Format Transformation Specialist
    TECHNIQUE: Recursive named template (write-booking-array)
               called via xsl:call-template to process each
               Booking node, replacing a flat for-each loop.
    ============================================
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Output as plain text (JSON is text, not XML) -->
    <xsl:output method="text" encoding="UTF-8"/>

    <!-- =====================================================
         KEY DECLARATIONS
         Used to resolve member and facility names from IDs
         inside the JSON output for richer export data.
         ===================================================== -->
    <xsl:key name="memberByID"   match="Member"   use="@memberID"/>
    <xsl:key name="facilityByID" match="Facility" use="@facilityID"/>

    <!-- =====================================================
         ROOT TEMPLATE
         Opens the JSON object, writes the "bookings" array
         key, then calls the recursive named template to
         process each Booking node one by one.
         ===================================================== -->
    <xsl:template match="/">
        <!-- Begin the JSON root object -->
        <xsl:text>{&#10;</xsl:text>

        <!--
            Metadata field: total booking count.
            Useful for API consumers to know array length
            without iterating the full array.
        -->
        <xsl:text>  "totalBookings": </xsl:text>
        <xsl:value-of select="count(//Bookings/Booking)"/>
        <xsl:text>,&#10;</xsl:text>

        <!-- Open the bookings array -->
        <xsl:text>  "bookings": [&#10;</xsl:text>

        <!--
            Call the recursive named template to process
            all Booking nodes. The template receives the
            full node-set and handles comma separation
            between items recursively.
        -->
        <xsl:call-template name="write-booking-array">
            <xsl:with-param name="nodes"
                select="//Bookings/Booking"/>
            <xsl:with-param name="index" select="1"/>
        </xsl:call-template>

        <!-- Close the bookings array and root object -->
        <xsl:text>  ]&#10;</xsl:text>
        <xsl:text>}&#10;</xsl:text>
    </xsl:template>

    <!-- =====================================================
         NAMED RECURSIVE TEMPLATE: write-booking-array
         Processes Booking nodes one at a time using recursion.
         Parameters:
           - nodes : the full node-set of Booking elements
           - index : current position (1-based)

         Base case: index > count(nodes) → stop recursion.
         Recursive case: output current node, then call self
         with index+1.

         This recursive approach replaces a flat xsl:for-each
         and demonstrates proper XSL recursive programming style.
         ===================================================== -->
    <xsl:template name="write-booking-array">
        <xsl:param name="nodes"/>
        <xsl:param name="index"/>

        <!-- Base case: no more nodes to process → return -->
        <xsl:if test="$index &lt;= count($nodes)">

            <!-- Select the current Booking node by position -->
            <xsl:variable name="booking" select="$nodes[$index]"/>

            <!--
                Resolve MemberRef to the member's full name
                using the memberByID key for O(1) lookup.
            -->
            <xsl:variable name="memberName"
                select="key('memberByID', $booking/MemberRef)/Name"/>

            <!--
                Resolve FacilityRef to the facility's full name
                using the facilityByID key for O(1) lookup.
            -->
            <xsl:variable name="facilityName"
                select="key('facilityByID', $booking/FacilityRef)/Name"/>

            <!-- Open booking JSON object -->
            <xsl:text>    {&#10;</xsl:text>

            <!-- Booking unique identifier -->
            <xsl:text>      "bookingID": "</xsl:text>
            <xsl:value-of select="$booking/@bookingID"/>
            <xsl:text>",&#10;</xsl:text>

            <!-- Member reference ID and resolved name -->
            <xsl:text>      "memberID": "</xsl:text>
            <xsl:value-of select="$booking/MemberRef"/>
            <xsl:text>",&#10;</xsl:text>

            <xsl:text>      "memberName": "</xsl:text>
            <xsl:value-of select="$memberName"/>
            <xsl:text>",&#10;</xsl:text>

            <!-- Facility reference ID and resolved name -->
            <xsl:text>      "facilityID": "</xsl:text>
            <xsl:value-of select="$booking/FacilityRef"/>
            <xsl:text>",&#10;</xsl:text>

            <xsl:text>      "facilityName": "</xsl:text>
            <xsl:value-of select="$facilityName"/>
            <xsl:text>",&#10;</xsl:text>

            <!-- Booking date (xs:date format) -->
            <xsl:text>      "date": "</xsl:text>
            <xsl:value-of select="$booking/Date"/>
            <xsl:text>",&#10;</xsl:text>

            <!-- Start and end time of the booking slot -->
            <xsl:text>      "startTime": "</xsl:text>
            <xsl:value-of select="$booking/StartTime"/>
            <xsl:text>",&#10;</xsl:text>

            <xsl:text>      "endTime": "</xsl:text>
            <xsl:value-of select="$booking/EndTime"/>
            <xsl:text>",&#10;</xsl:text>

            <!-- Booking status: Confirmed / Pending / Cancelled -->
            <xsl:text>      "status": "</xsl:text>
            <xsl:value-of select="$booking/Status"/>
            <xsl:text>"&#10;</xsl:text>

            <!-- Close booking JSON object -->
            <xsl:text>    }</xsl:text>

            <!--
                JSON comma rule: add comma after every item
                except the last one. Checked by comparing
                current index to total count.
            -->
            <xsl:if test="$index &lt; count($nodes)">
                <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:text>&#10;</xsl:text>

            <!--
                RECURSIVE CALL: process the next Booking node
                by incrementing the index by 1.
            -->
            <xsl:call-template name="write-booking-array">
                <xsl:with-param name="nodes"  select="$nodes"/>
                <xsl:with-param name="index"  select="$index + 1"/>
            </xsl:call-template>

        </xsl:if>
        <!-- End of base case: recursion terminates here -->
    </xsl:template>

</xsl:stylesheet>
