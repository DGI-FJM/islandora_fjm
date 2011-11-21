<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: demoFoxmlToLucene.xslt 5734 2006-11-28 11:20:15Z gertsp $ -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exts="xalan://dk.defxws.fedoragsearch.server.GenericOperationsImpl"
  xmlns:islandora-exts="xalan://ca.upei.roblib.DataStreamForXSLT"
    		exclude-result-prefixes="exts"
  xmlns:zs="http://www.loc.gov/zing/srw/"
  xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
  xmlns:mods="http://www.loc.gov/mods/v3"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
  xmlns:fedora="info:fedora/fedora-system:def/relations-external#"
  xmlns:rel="info:fedora/fedora-system:def/relations-external#"
  xmlns:dwc="http://rs.tdwg.org/dwc/xsd/simpledarwincore/"
  xmlns:fedora-model="info:fedora/fedora-system:def/model#"
  xmlns:uvalibdesc="http://dl.lib.virginia.edu/bin/dtd/descmeta/descmeta.dtd"
  xmlns:uvalibadmin="http://dl.lib.virginia.edu/bin/admin/admin.dtd/"
  xmlns:eaccpf="urn:isbn:1-931666-33-4">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  <!-- FIXME:  I figure relative URLs should work...  They didn't want to work, and absolute ones aren't nice -->
  <xsl:include href="file:/var/www/drupal/sites/default/modules/islandora_fjm/xsl/basicFJMToSolr.xslt"/>

  <xsl:param name="REPOSITORYNAME" select="repositoryName"/>
  <xsl:param name="FEDORASOAP" select="repositoryName"/>
  <xsl:param name="FEDORAUSER" select="repositoryName"/>
  <xsl:param name="FEDORAPASS" select="repositoryName"/>
  <xsl:param name="TRUSTSTOREPATH" select="repositoryName"/>
  <xsl:param name="TRUSTSTOREPASS" select="repositoryName"/>

  <!-- Test of adding explicit parameters to indexing -->
  <xsl:param name="EXPLICITPARAM1" select="defaultvalue1"/>
  <xsl:param name="EXPLICITPARAM2" select="defaultvalue2"/>
<!--
	 This xslt stylesheet generates the IndexDocument consisting of IndexFields
     from a FOXML record. The IndexFields are:
       - from the root element = PID
       - from foxml:property   = type, state, contentModel, ...
       - from oai_dc:dc        = title, creator, ...
     The IndexDocument element gets a PID attribute, which is mandatory,
     while the PID IndexField is optional.
     Options for tailoring:
       - IndexField types, see Lucene javadoc for Field.Store, Field.Index, Field.TermVector
       - IndexField boosts, see Lucene documentation for explanation
       - IndexDocument boosts, see Lucene documentation for explanation
       - generation of IndexFields from other XML metadata streams than DC
         - e.g. as for uvalibdesc included above and called below, the XML is inline
         - for not inline XML, the datastream may be fetched with the document() function,
           see the example below (however, none of the demo objects can test this)
       - generation of IndexFields from other datastream types than XML
         - from datastream by ID, text fetched, if mimetype can be handled
         - from datastream by sequence of mimetypes,
           text fetched from the first mimetype that can be handled,
           default sequence given in properties.
-->

  <xsl:template match="/">
    <xsl:variable name="PID" select="/foxml:digitalObject/@PID"/>
    <add>
      <!-- The following allows only active FedoraObjects to be indexed. -->
      <xsl:if test="foxml:digitalObject/foxml:objectProperties/foxml:property[@NAME='info:fedora/fedora-system:def/model#state' and @VALUE='Active']">
        <xsl:if test="not(foxml:digitalObject/foxml:datastream[@ID='METHODMAP' or @ID='DS-COMPOSITE-MODEL'])">
          <xsl:choose>
            <xsl:when test="starts-with($PID,'atm')">
              <xsl:call-template name="fjm-atm">
                <xsl:with-param name="pid" select="$PID"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="/foxml:digitalObject" mode="activeFedoraObject">
                <xsl:with-param name="PID" select="$PID"/>
              </xsl:apply-templates>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
      </xsl:if>
    </add>
  </xsl:template>

  <xsl:template match="/foxml:digitalObject" mode="activeFedoraObject">
    <xsl:param name="PID"/>

    <doc>
      <field name="PID" boost="2.5">
        <xsl:value-of select="$PID"/>
      </field>
      <xsl:for-each select="foxml:objectProperties/foxml:property">
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat('fgs.', substring-after(@NAME,'#'))"/>
          </xsl:attribute>
          <xsl:value-of select="@VALUE"/>
        </field>
      </xsl:for-each>

      <!-- index DC -->
      <xsl:apply-templates mode="simple_set" select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/oai_dc:dc/*">
        <xsl:with-param name="prefix">dc.</xsl:with-param>
        <xsl:with-param name="suffix"></xsl:with-param>
      </xsl:apply-templates>

      <!-- index REFWORKS...  Should probably select a particular DS?
      <xsl:apply-templates mode="simple_set" select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/reference/*">
        <xsl:with-param name="prefix">refworks.</xsl:with-param>
        <xsl:with-param name="suffix"></xsl:with-param>
      </xsl:apply-templates> -->

      <xsl:for-each select="foxml:datastream[@ID='RIGHTSMETADATA']/foxml:datastreamVersion[last()]/foxml:xmlContent//access/human/person">
        <field>
          <xsl:attribute name="name">access.person</xsl:attribute>
          <xsl:value-of select="text()"/>
        </field>
      </xsl:for-each>
      <xsl:for-each select="foxml:datastream[@ID='RIGHTSMETADATA']/foxml:datastreamVersion[last()]/foxml:xmlContent//access/human/group">
        <field>
          <xsl:attribute name="name">access.group</xsl:attribute>
          <xsl:value-of select="text()"/>
        </field>
      </xsl:for-each>
      <xsl:for-each select="foxml:datastream[@ID='TAGS']/foxml:datastreamVersion[last()]/foxml:xmlContent//tag">
            <!--<xsl:for-each select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent//tag">-->
        <field>
          <xsl:attribute name="name">tag</xsl:attribute>
          <xsl:value-of select="text()"/>
        </field>
        <field>
          <xsl:attribute name="name">tagUser</xsl:attribute>
          <xsl:value-of select="@creator"/>
        </field>
      </xsl:for-each>

      <!-- Index the Rels-ext (using match="rdf:RDF") -->
      <xsl:apply-templates select="foxml:datastream[@ID='RELS-EXT']/foxml:datastreamVersion[last()]/foxml:xmlContent/rdf:RDF">
        <xsl:with-param name="prefix">rels.</xsl:with-param>
        <xsl:with-param name="suffix"></xsl:with-param>
      </xsl:apply-templates>

        <!--*************************************************************full text************************************************************************************-->
        <!--  Filter added to ensure OCR streams for ilives books are NOT included -->
      <xsl:for-each select="foxml:datastream[@ID='OCR']/foxml:datastreamVersion[last()]">
        <xsl:if test="not(starts-with($PID,'ilives'))">
          <field>
            <xsl:attribute name="name">
              <xsl:value-of select="concat('OCR.', 'OCR')"/>
            </xsl:attribute>
            <xsl:value-of select="islandora-exts:getDatastreamTextRaw($PID, $REPOSITORYNAME, 'OCR', $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/>
          </field>
        </xsl:if>
      </xsl:for-each>
        <!--  Filter added to ensure OCR streams for ilives books are NOT included -->
      <xsl:for-each select="foxml:datastream[@ID='OBJ']/foxml:datastreamVersion[last()]">
        <xsl:if test="starts-with($PID,'ir')">
          <field>
            <xsl:attribute name="name">
              <xsl:value-of select="concat('dsm.', 'text')"/>
            </xsl:attribute>
            <xsl:value-of select="islandora-exts:getDatastreamText($PID, $REPOSITORYNAME, 'OCR', $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/>
          </field>
        </xsl:if>
      </xsl:for-each>
        <!--***********************************************************end full text********************************************************************************-->
      <xsl:variable name="pageCModel">
        <xsl:text>info:fedora/ilives:pageCModel</xsl:text>
      </xsl:variable>
      <xsl:variable name="thisCModel">
        <xsl:value-of select="//fedora-model:hasModel/@rdf:resource"/>
      </xsl:variable>
        <!-- why was this being output here?:
        <xsl:value-of select="$thisCModel"/>-->

        <!--********************************************Darwin Core**********************************************************************-->
      <xsl:apply-templates mode="simple_set" select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/dwc:SimpleDarwinRecordSet/dwc:SimpleDarwinRecord/*[normalize-space(text())]">
        <xsl:with-param name="prefix">dwc.</xsl:with-param>
        <xsl:with-param name="suffix"></xsl:with-param>
      </xsl:apply-templates>
        <!--***************************************** END Darwin Core ******************************************-->


        <!-- a managed datastream is fetched, if its mimetype
                 can be handled, the text becomes the value of the field. -->
        <!--<xsl:for-each select="foxml:datastream[@CONTROL_GROUP='M']">
                <field>
                    <xsl:attribute name="name">
                        <xsl:value-of select="concat('dsm.', @ID)"/>
                    </xsl:attribute>
                    <xsl:value-of select="exts:getDatastreamText($PID, $REPOSITORYNAME, @ID, $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/>
                </field>
            </xsl:for-each>-->


        <!--************************************ BLAST ******************************************-->
        <!-- Blast -->
      <xsl:apply-templates mode="simple_set" select="foxml:datastream[@ID='BLAST']/foxml:datastreamVersion[last()]/foxml:xmlContent//Hit/Hit_hsps/Hsp/*[normalize-space(text())]">
        <xsl:with-param name="prefix">blast.</xsl:with-param>
        <xsl:with-param name="suffix"></xsl:with-param>
      </xsl:apply-templates>
        <!--********************************** End BLAST ******************************************-->

        <!-- Names and Roles -->
      <xsl:apply-templates select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:mods" mode="default">
        <xsl:with-param name="prefix">mods.</xsl:with-param>
        <xsl:with-param name="suffix"></xsl:with-param>
      </xsl:apply-templates>

      <xsl:apply-templates select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:mods" mode="CoH">
        <xsl:with-param name="prefix">coh_search_</xsl:with-param>
        <xsl:with-param name="suffix"></xsl:with-param>
      </xsl:apply-templates>

      <xsl:apply-templates select="foxml:datastream[@ID='EAC-CPF']/foxml:datastreamVersion[last()]/foxml:xmlContent//eaccpf:eac-cpf">
      </xsl:apply-templates>
    </doc>
  </xsl:template>

  <!-- Basic MODS -->
  <xsl:template match="mods:mods" name="index_mods" mode="default">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_t</xsl:param>

    <!--************************************ MODS subset for Bibliographies ******************************************-->

    <!-- Main Title, with non-sorting prefixes -->
    <!-- ...specifically, this avoids catching relatedItem titles -->
    <xsl:for-each select="./mods:titleInfo/mods:title[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:if test="../mods:nonSort">
          <xsl:value-of select="../mods:nonSort/text()"/>
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Sub-title -->
    <xsl:for-each select="./mods:titleInfo/mods:subTitle[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Abstract -->
    <xsl:for-each select=".//mods:abstract[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Genre (a.k.a. specific doctype) -->
    <xsl:for-each select=".//mods:genre[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!--  Resource Type (a.k.a. broad doctype) -->
    <xsl:for-each select="./mods:typeOfResource[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'resource_type', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- DOI, ISSN, ISBN, and any other typed IDs -->
    <xsl:for-each select="./mods:identifier[@type][normalize-space(text())]">
    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, @type, $suffix)"/>
      </xsl:attribute>
      <xsl:value-of select="text()"/>
    </field>
    </xsl:for-each>

      <!-- Names and Roles -->
    <xsl:for-each select=".//mods:roleTerm[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'name_', text(), $suffix)"/>
        </xsl:attribute>
        <xsl:for-each select="../../mods:namePart[@type='given']">
          <xsl:value-of select="text()"/>
          <xsl:if test="string-length(text())=1">
            <xsl:text>.</xsl:text>
          </xsl:if>
          <xsl:text> </xsl:text>
        </xsl:for-each>
        <xsl:for-each select="../../mods:namePart[not(@type='given')]">
          <xsl:value-of select="text()"/>
          <xsl:if test="position()!=last()">
            <xsl:text> </xsl:text>
          </xsl:if>
        </xsl:for-each>
      </field>
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'rname_', text(), $suffix)"/>
        </xsl:attribute>
        <xsl:for-each select="../../mods:namePart[not(@type='given')]">
          <xsl:value-of select="text()"/>
          <xsl:if test="@type='given'">
            <xsl:text> </xsl:text>
          </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="../../mods:namePart[@type='given']">
          <xsl:if test="position()=1">
            <xsl:text>, </xsl:text>
          </xsl:if>
          <xsl:value-of select="text()"/>
          <xsl:if test="string-length(text())=1">
            <xsl:text>.</xsl:text>
          </xsl:if>
          <xsl:if test="position()!=last()">
            <xsl:text> </xsl:text>
          </xsl:if>
        </xsl:for-each>
      </field>
    </xsl:for-each>

      <!-- Notes -->
    <xsl:for-each select=".//mods:note[normalize-space(text())]">
          <!--don't bother with empty space-->
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Subjects / Keywords -->
    <xsl:for-each select=".//mods:subject/*[normalize-space(text())]">
              <!--don't bother with empty space-->
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'subject', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Country -->
      <!-- Herein follows a bunch of MODS
           stuff I didn't think was necessary for bibliographic
           records.  But you might still want it for
           other MODS stuff.
      <xsl:for-each select=".//mods:country[normalize-space(text())]">
        <!-\-don't bother with empty space-\->
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
          </xsl:attribute>
          <xsl:value-of select="text()"/>
        </field>
      </xsl:for-each>

      <xsl:for-each select=".//mods:province[normalize-space(text())]">
        <!-\-don't bother with empty space-\->
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
          </xsl:attribute>
          <xsl:value-of select="text()"/>
        </field>
      </xsl:for-each>
      <xsl:for-each select=".//mods:county[normalize-space(text())]">
          <!-\-don't bother with empty space-\->
          <field>
              <xsl:attribute name="name">
                  <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
              </xsl:attribute>
              <xsl:value-of select="text()"/>
          </field>
      </xsl:for-each>
      <xsl:for-each select=".//mods:region[normalize-space(text())]">
          <!-\-don't bother with empty space-\->
          <field>
              <xsl:attribute name="name">
                  <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
              </xsl:attribute>
              <xsl:value-of select="text()"/>
          </field>
      </xsl:for-each>
      <xsl:for-each select=".//mods:city[normalize-space(text())]">
        <!-\-don't bother with empty space-\->
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
          </xsl:attribute>
          <xsl:value-of select="text()"/>
        </field>
      </xsl:for-each>
      <xsl:for-each select=".//mods:citySection[normalize-space(text())]">
        <!-\-don't bother with empty space-\->
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
          </xsl:attribute>
          <xsl:value-of select="text()"/>
        </field>
      </xsl:for-each>
      -->

      <!-- Host Name (i.e. journal/newspaper name) -->
    <xsl:for-each select=".//mods:relatedItem[@type='host']/mods:titleInfo/mods:title[normalize-space(text())]">
          <!--don't bother with empty space-->
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'host_title', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Series Name (this means, e.g. a lecture series and is rarely used) -->
    <xsl:for-each select=".//mods:relatedItem[@type='series']/mods:titleInfo/mods:title[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'series_title', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Volume (e.g. journal vol) -->
    <xsl:for-each select=".//mods:mods/mods:part/mods:detail[@type='volume']/*[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'volume', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Issue (e.g. journal vol) -->
    <xsl:for-each select=".//mods:mods/mods:part/mods:detail[@type='issue']/*[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'issue', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Subject Names - not necessary for our MODS citations -->
    <xsl:for-each select=".//mods:subject/mods:name/mods:namePart/*[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'subject', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Physical Description - not necessary for our MODS citations -->
    <xsl:for-each select=".//mods:physicalDescription/*[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Place of publication -->
    <xsl:for-each select=".//mods:originInfo/mods:place/mods:placeTerm[@type='text'][normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'place_of_publication', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Publisher's Name -->
    <xsl:for-each select=".//mods:originInfo/mods:publisher[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Edition (Book) -->
    <xsl:for-each select=".//mods:originInfo/mods:edition[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Date Issued (i.e. Journal Pub Date) -->
    <xsl:for-each select=".//mods:originInfo/mods:dateIssued[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Copyright Date (is an okay substitute for Issued Date in many circumstances) -->
    <xsl:for-each select=".//mods:originInfo/mods:copyrightDate[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Issuance (i.e. ongoing, monograph, etc. ) -->
    <xsl:for-each select=".//mods:originInfo/mods:issuance[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

      <!-- Languague Term -->
    <xsl:for-each select=".//mods:language/mods:languageTerm[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
  </xsl:template>
  <!-- End Basic MODS -->

  <!-- *** COH *** -->
  <xsl:template match="mods:mods" mode="CoH" name="index_mods_for_CoH" >
    <!-- defaults -->
    <xsl:param name="prefix">coh_search_</xsl:param>
    <xsl:param name="suffix"></xsl:param>

    <!-- Topic and Notes -->
    <xsl:for-each select="./mods:subject/mods:topic[not(@type)][normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'topic_and_notes', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <xsl:for-each select="./mods:note[not(@type)][normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'topic_and_notes', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <xsl:for-each select="./mods:subject/mods:name[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'topic_and_notes', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Book Authors -->
    <xsl:for-each select="./mods:relatedItem[@type='host']/mods:name/mods:role/mods:roleTerm['author']/../../mods:namePart[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'book_authors', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Conference -->
    <xsl:for-each select="./mods:titleInfo[@type='conference']/mods:title[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'conference', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Editor  -->
    <xsl:for-each select="./mods:name[@type='personal']/mods:role[roleTerm='editor']/../mods:namePart[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'editor', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Full Journal Title -->
    <xsl:for-each select="./mods:relatedItem[@type='host']/mods:titleInfo[not(@type)]/mods:title[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'full_journal_title', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- MeSH -->
    <xsl:for-each select="./mods:subject[@authority='mesh']/mods:topic[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'mesh_terms', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Peer Review -->
    <xsl:for-each select="./mods:note[@type='peer reviewed'][normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'peer_reviewed', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Keywords -->
    <xsl:for-each select="./mods:subject[not(@type)]/mods:topic[not(@type)][normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'keywords', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <xsl:for-each select="./mods:subject[not(@type)]/mods:name[not(@type)][normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'keywords', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Secondary Source ID -->
    <xsl:for-each select="./mods:identifier[@displayLabel='Accession Number'][normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'secondary_source_id', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Status -->
    <xsl:for-each select="./mods:note[@type='pubmedStatus'][normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'status', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Funding Agency -->
    <xsl:for-each select="./mods:name[@type='corporate']/mods:role[mods:roleTerm[@type='text']='funding agency']/../mods:namePart[normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'funding_agency', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Grant Number -->
    <xsl:for-each select="./mods:name[@type='corporate']/mods:role[mods:roleTerm[@type='text']='funding agency']/../mods:description[@type='grant number'][normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'grant_number', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>

    <!-- Cores -->
    <xsl:for-each select="./mods:note[@type='core facilities'][normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'cores', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
  </xsl:template>
  <!-- *** End COH *** -->

  <xsl:template match="rdf:RDF">
    <xsl:param name="prefix">rels_</xsl:param>
    <xsl:param name="suffix">_s</xsl:param>

    <xsl:for-each select=".//rdf:description/*[@rdf:resource]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="@rdf:resource"/>
      </field>
    </xsl:for-each>
    <xsl:for-each select=".//rdf:description/*[not(@rdf:resource)][normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), '_literal', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
  </xsl:template>

  <!-- Basic EAC-CPF -->
  <xsl:template match="eaccpf:eac-cpf">
        <xsl:param name="pid"/>
        <xsl:param name="dsid" select="'EAC-CPF'"/>
        <xsl:param name="prefix" select="'eaccpf_'"/>
        <xsl:param name="suffix" select="'_et'"/> <!-- 'edged' (edge n-gram) text, for auto-completion -->

        <xsl:variable name="cpfDesc" select="eaccpf:cpfDescription"/>
        <xsl:variable name="identity" select="$cpfDesc/eaccpf:identity"/>
        <xsl:variable name="name_prefix" select="concat($prefix, 'name_')"/>
        <!-- ensure that the primary is first -->
        <xsl:apply-templates select="$identity/eaccpf:nameEntry[@localType='primary']">
            <xsl:with-param name="pid" select="$pid"/>
            <xsl:with-param name="prefix" select="$name_prefix"/>
            <xsl:with-param name="suffix" select="$suffix"/>
        </xsl:apply-templates>

        <!-- place alternates (non-primaries) later -->
        <xsl:apply-templates select="$identity/eaccpf:nameEntry[not(@localType='primary')]">
            <xsl:with-param name="pid" select="$pid"/>
            <xsl:with-param name="prefix" select="$name_prefix"/>
            <xsl:with-param name="suffix" select="$suffix"/>
        </xsl:apply-templates>
    </xsl:template>

  <xsl:template match="eaccpf:nameEntry">
    <xsl:param name="pid"/>
    <xsl:param name="prefix">eaccpf_name_</xsl:param>
    <xsl:param name="suffix">_et</xsl:param>

    <!-- fore/first name -->
    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, 'given', $suffix)"/>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="part[@localType='middle']">
          <xsl:value-of select="normalize-space(concat(eaccpf:part[@localType='forename'], ' ', eaccpf:part[@localType='middle']))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="normalize-space(eaccpf:part[@localType='forename'])"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
    
    <!-- sur/last name -->
    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, 'family', $suffix)"/>
      </xsl:attribute>
      <xsl:value-of select="normalize-space(eaccpf:part[@localType='surname'])"/>
    </field>
    
    <!-- id -->
    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, 'id', $suffix)"/>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="@id">
          <xsl:value-of select="concat($pid, '/', @id)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($pid,'/name_position:', position())"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>

    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, 'complete', $suffix)"/>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="normalize-space(part[@localType='middle'])">
          <xsl:value-of select="normalize-space(concat(eaccpf:part[@localType='surname'], ', ', eaccpf:part[@localType='forename'], ' ', eaccpf:part[@localType='middle']))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="normalize-space(concat(eaccpf:part[@localType='surname'], ', ', eaccpf:part[@localType='forename']))"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
  </xsl:template>

  <!-- Create fields for the set of selected elements, named according to the 'local-name' and containing the 'text' -->
  <xsl:template match="*" mode="simple_set">
    <xsl:param name="prefix">changeme_</xsl:param>
    <xsl:param name="suffix">_t</xsl:param>

    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
      </xsl:attribute>
      <xsl:value-of select="text()"/>
    </field>
  </xsl:template>
</xsl:stylesheet>
