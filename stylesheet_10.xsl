<?xml version="1.0" encoding="UTF-8"?>
<!--
    ============================================
    FILE:    stylesheet_10.xsl
    PURPOSE: Transform SportsClub XML → Equipment Inventory JSON
    SCENARIO: Export the full equipment inventory as a JSON array,
              with resolved facility names, grouped logically.
              Suitable for stock management tools or dashboards.
    OUTPUT:  output_10.json (equipment.json)
    MEMBER:  Member 3 — Format Transformation Specialist
    TECHNIQUE: Recursive named template (write-equipment-array)
               called via xsl:call-template. Processes each
               Equipment/Item node recursively with index tracking,
               replacing a flat for-each loop entirely.
    ============================================
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Output as plain text because JSON is not XML -->
    <xsl:output method="text" encoding="UTF-8"/>

    <!-- =====================================================
         KEY DECLARATION
         Enables O(1) lookup of a Facility by facilityID,
         used to resolve FacilityRef values to full names.
         ===================================================== -->
    <xsl:key name="facilityByID" match="Facility" use="@facilityID"/>

    <!-- =====================================================
         ROOT TEMPLATE
         Writes the JSON root object with metadata, opens the
         equipment array, then calls the recursive named
         template to process all Item nodes.
         ===================================================== -->
    <xsl:template match="/">
        <!-- Open the JSON root object -->
        <xsl:text>{&#10;</xsl:text>

        <!--
            Metadata: total number of equipment items.
            Helps API consumers validate the array length.
        -->
        <xsl:text>  "totalItems": </xsl:text>
        <xsl:value-of select="count(//Equipment/Item)"/>
        <xsl:text>,&#10;</xsl:text>

        <!--
            Metadata: sum of all quantities across all items.
            Useful for warehouse/stock overview dashboards.
        -->
        <xsl:text>  "totalQuantity": </xsl:text>
        <xsl:value-of select="sum(//Equipment/Item/Quantity)"/>
        <xsl:text>,&#10;</xsl:text>

        <!-- Open the equipment items array -->
        <xsl:text>  "equipment": [&#10;</xsl:text>

        <!--
            Call the recursive named template.
            Passes the full node-set of Item elements
            and starts the index counter at 1.
        -->
        <xsl:call-template name="write-equipment-array">
            <xsl:with-param name="nodes"
                select="//Equipment/Item"/>
            <xsl:with-param name="index" select="1"/>
        </xsl:call-template>

        <!-- Close the equipment array and root object -->
        <xsl:text>  ]&#10;</xsl:text>
        <xsl:text>}&#10;</xsl:text>
    </xsl:template>

    <!-- =====================================================
         NAMED RECURSIVE TEMPLATE: write-equipment-array
         Processes Equipment/Item nodes one at a time.
         Parameters:
           - nodes : full node-set of Item elements
           - index : current 1-based position counter

         Base case: index > count(nodes) → stop.
         Recursive case: output current item as JSON object,
         then call self with index + 1.

         This replaces a flat xsl:for-each with a proper
         recursive XSL programming pattern as required by
         the project specification.
         ===================================================== -->
    <xsl:template name="write-equipment-array">
        <xsl:param name="nodes"/>
        <xsl:param name="index"/>

        <!-- Base case guard: stop when all nodes are processed -->
        <xsl:if test="$index &lt;= count($nodes)">

            <!-- Select the Item node at the current index position -->
            <xsl:variable name="item" select="$nodes[$index]"/>

            <!--
                Resolve FacilityRef to the facility's full name
                using the facilityByID xsl:key (O(1) lookup).
                This avoids an O(n) nested search.
            -->
            <xsl:variable name="facilityName"
                select="key('facilityByID', $item/FacilityRef)/Name"/>

            <!-- Open JSON object for this equipment item -->
            <xsl:text>    {&#10;</xsl:text>

            <!-- Equipment unique identifier -->
            <xsl:text>      "equipmentID": "</xsl:text>
            <xsl:value-of select="$item/@equipmentID"/>
            <xsl:text>",&#10;</xsl:text>

            <!-- Human-readable equipment name -->
            <xsl:text>      "name": "</xsl:text>
            <xsl:value-of select="$item/Name"/>
            <xsl:text>",&#10;</xsl:text>

            <!-- Equipment category (e.g. Ball Sports, Fitness) -->
            <xsl:text>      "category": "</xsl:text>
            <xsl:value-of select="$item/Category"/>
            <xsl:text>",&#10;</xsl:text>

            <!--
                Quantity is a number in JSON (no quotes).
                Using xsl:value-of directly gives the integer value.
            -->
            <xsl:text>      "quantity": </xsl:text>
            <xsl:value-of select="$item/Quantity"/>
            <xsl:text>,&#10;</xsl:text>

            <!-- Physical condition of the item -->
            <xsl:text>      "condition": "</xsl:text>
            <xsl:value-of select="$item/Condition"/>
            <xsl:text>",&#10;</xsl:text>

            <!-- Facility reference ID -->
            <xsl:text>      "facilityID": "</xsl:text>
            <xsl:value-of select="$item/FacilityRef"/>
            <xsl:text>",&#10;</xsl:text>

            <!--
                Resolved facility name (last field, no trailing comma).
                Uses the key lookup defined above.
            -->
            <xsl:text>      "facilityName": "</xsl:text>
            <xsl:value-of select="$facilityName"/>
            <xsl:text>"&#10;</xsl:text>

            <!-- Close the JSON object for this item -->
            <xsl:text>    }</xsl:text>

            <!--
                Comma rule: add trailing comma after every item
                except the last one (JSON array syntax).
            -->
            <xsl:if test="$index &lt; count($nodes)">
                <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:text>&#10;</xsl:text>

            <!--
                RECURSIVE CALL: advance to the next Item node.
                Increments index by 1 each time until base case.
            -->
            <xsl:call-template name="write-equipment-array">
                <xsl:with-param name="nodes"  select="$nodes"/>
                <xsl:with-param name="index"  select="$index + 1"/>
            </xsl:call-template>

        </xsl:if>
        <!-- Recursion terminates when index exceeds node count -->
    </xsl:template>

</xsl:stylesheet>
