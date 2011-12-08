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
  <xsl:include href="file:/var/www/drupal/sites/default/modules/islandora_fjm/xsl/escape_xml.xslt"/>

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
        <xsl:with-param name="prefix">rels_</xsl:with-param>
        <xsl:with-param name="suffix">_ms</xsl:with-param>
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
      <!--<xsl:variable name="pageCModel">
        <xsl:text>info:fedora/ilives:pageCModel</xsl:text>
      </xsl:variable>
      <xsl:variable name="thisCModel">
        <xsl:value-of select="//fedora-model:hasModel/@rdf:resource"/>
      </xsl:variable>
         why was this being output here?:
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
      <xsl:apply-templates select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:mods" mode="default"/>
      
      <!-- store an escaped copy of MODS... -->
      <field name="mods_fullxml_store">
        <xsl:apply-templates select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:mods" mode="escape"/>
      </field>

      <xsl:apply-templates select="foxml:datastream[@ID='EAC-CPF']/foxml:datastreamVersion[last()]/foxml:xmlContent//eaccpf:eac-cpf">
      </xsl:apply-templates>
      
      <xsl:for-each select="foxml:datastream[@ID][foxml:datastreamVersion[last()]]">
        <field name="fedora_datastreams_ms">
          <xsl:value-of select="@ID"/>
        </field>
      </xsl:for-each>
    </doc>
  </xsl:template>

  <!-- Basic MODS -->
  <xsl:template match="mods:mods" name="index_mods" mode="default">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <!-- Index stuff from the auth-module. -->
    <xsl:for-each select=".//*[@authorityURI='info:fedora'][@valueURI]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'related_object', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="@valueURI"/>
      </field>
    </xsl:for-each>

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

  <!-- Bake citeproc stuff?  Names seem difficult to handle.
  <xsl:template match="mods:mods" mode="citeproc">
    <xsl:param name="prefix">citeproc_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <!-/- BASIC; selecting first of each... -/->
    <!-/- abstract -/->
    <xsl:for-each select="./mods:abstract[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'abstract', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- call-number -/->
    <xsl:for-each select="./mods:classification[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'call-number', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- collection-title -/->
    <xsl:for-each select="./mods:relatedItem[@type='series']/mods:titleInfo/mods:title[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'collection-title', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- container-title -/->
    <xsl:for-each select="./mods:relatedItem[@type='host']/mods:titleInfo/mods:title[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'container-title', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- DOI -/->
    <xsl:for-each select="./mods:identifier[@type='doi'][1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'DOI', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- edition -/->
    <xsl:for-each select="./mods:originInfo/mods:edition[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'edition', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- ISBN -/->
    <xsl:for-each select="./mods:identifier[@type='isbn'][1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'ISBN', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- volume -/->
    <xsl:for-each select="./mods:part/mods:detail[@type='volume']/mods:number[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'volume', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- issue -/->
    <xsl:for-each select="./mods:part/mods:detail[@type='issue']/mods:number[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'issue', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- number -/->
    <xsl:for-each select="./mods:relatedItem[@type='series']/mods:titleInfo/mods:partNumber[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'number', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- publisher -/->
    <xsl:for-each select="./mods:originInfo/mods:publisher[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'publisher', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- URL -/->
    <xsl:for-each select="./mods:location/mods:url[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'URL', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- number-pmid -/->
    <xsl:for-each select="./mods:identifier[@type='pmid'][1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'number-pmid', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- number-pmcid -/->
    <xsl:for-each select="./mods:identifier[@type='pmcid'][1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'number-pmcid', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- number-nihmsid -/->
    <xsl:for-each select="./mods:identifier[@type='nihmsid'][1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'number-nigmsid', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    <!-/- /BASIC -/->
    
    <!-/- title; use the longest? -/->
    <xsl:call-template name="getLongest">
      <xsl:with-param name="nodeset" select="./mods:titleInfo/mods:title"/>
      <xsl:with-param name="current_longest" select="./mods:titleInfo/mods:title[1]"/>
      <xsl:with-param name="prefix"><xsl:value-of select="$prefix"/></xsl:with-param>
      <xsl:with-param name="suffix"><xsl:value-of select="$suffix"/></xsl:with-param>
      <xsl:with-param name="field_name">title</xsl:with-param>
    </xsl:call-template>
    
    <!-/- event; merged...  should work, not sure. -/->
    <xsl:for-each select=".[mods:genre[@authority='marcgt'][text()='conference publication'] | mods:genre[@authority='local'][text()='conferencePaper']]/mods:relatedItem/mods:titleInfo/mods:title[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'event', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    
    <!-/- event-place; similarly merge... (see around the pipe character) -/->
    <xsl:for-each select=".[mods:genre[@authority='marcgt'][text()='conference publication'] | mods:genre[@authority='local'][text()='conferencePaper']]/mods:originInfo/mods:place/mods:placeTerm[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'event-place', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    
    <!-/- notes...  blargh -/->
    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, 'note', $suffix)"/>
      </xsl:attribute>
      <xsl:for-each select="./mods:note">
        <xsl:value-of select="normalize-space(concat(position(), '. ', text(), ' '))"/>
      </xsl:for-each>
    </field>
    
    <!-/- pages... are gross. -/->
    <xsl:for-each select="./mods:part/mods:extent[@unit='pages' | @unit='page'][1]">
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, 'pages', $suffix)"/>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="./mods:total">
          <xsl:value-of select="./mods:total[1]/text()"/>
        </xsl:when>
        <xsl:when test="./mods:list">
          <xsl:value-of select="./mods:list[1]/text()"/>
        </xsl:when>
        <xsl:when test="./mods:start">
          <xsl:value-of select="./mods:start/text()"/>
          <xsl:if test="('./mods:end')">
            <xsl:value-of select="concat('-', ./mods:end/text())"/>
          </xsl:if>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
    
    <!-/- types -/->
    <xsl:for-each select="(./mods:genre[@authority='marcgt'] | ./mods:relatedItem/mods:genre[@authority='marcgt'] | ./mods:genre[not(@authority='marcgt')])[1]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'type', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
    
    <!-/- names -/->
    <xsl:for-each select="./mods:name[@type='personal']">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'name_role')"/>
        </xsl:attribute>
        <xsl:apply-templates select="./mods:role/mods:roleTerm" mode="citeproc_default">
          <xsl:with-param name='role'/>
        </xsl:apply-templates>
      </field>
      <field>
      </field>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template name="translate_coded_marcrelator">
    <xsl:param name="role">aut</xsl:param>

    <xsl:choose>
      <xsl:when test="$role='acp'">art copyist</xsl:when>
      <xsl:when test="$role='act'">actor</xsl:when>
      <xsl:when test="$role='adp'">adapter</xsl:when>
      <xsl:when test="$role='aft'">author of afterword, colophon, etc.</xsl:when>
      <xsl:when test="$role='anl'">analyst</xsl:when>
      <xsl:when test="$role='anm'">animator</xsl:when>
      <xsl:when test="$role='ann'">annotator</xsl:when>
      <xsl:when test="$role='ant'">bibliographic antecedent</xsl:when>
      <xsl:when test="$role='app'">applicant</xsl:when>
      <xsl:when test="$role='aqt'">author in quotations or text abstracts</xsl:when>
      <xsl:when test="$role='arc'">architect</xsl:when>
      <xsl:when test="$role='ard'">artistic director</xsl:when>
      <xsl:when test="$role='arr'">arranger</xsl:when>
      <xsl:when test="$role='art'">artist</xsl:when>
      <xsl:when test="$role='asg'">assignee</xsl:when>
      <xsl:when test="$role='asn'">associated name</xsl:when>
      <xsl:when test="$role='att'">attributed name</xsl:when>
      <xsl:when test="$role='auc'">auctioneer</xsl:when>
      <xsl:when test="$role='aud'">author of dialog</xsl:when>
      <xsl:when test="$role='aui'">author of introduction</xsl:when>
      <xsl:when test="$role='aus'">author of screenplay</xsl:when>
      <xsl:when test="$role='aut'">author</xsl:when>
      <xsl:when test="$role='bdd'">binding designer</xsl:when>
      <xsl:when test="$role='bjd'">bookjacket designer</xsl:when>
      <xsl:when test="$role='bkd'">book designer</xsl:when>
      <xsl:when test="$role='bkp'">book producer</xsl:when>
      <xsl:when test="$role='blw'">blurb writer</xsl:when>
      <xsl:when test="$role='bnd'">binder</xsl:when>
      <xsl:when test="$role='bpd'">bookplate designer</xsl:when>
      <xsl:when test="$role='bsl'">bookseller</xsl:when>
      <xsl:when test="$role='ccp'">conceptor</xsl:when>
      <xsl:when test="$role='chr'">choreographer</xsl:when>
      <xsl:when test="$role='clb'">collaborator</xsl:when>
      <xsl:when test="$role='cli'">client</xsl:when>
      <xsl:when test="$role='cll'">calligrapher</xsl:when>
      <xsl:when test="$role='clr'">colorist</xsl:when>
      <xsl:when test="$role='clt'">collotyper</xsl:when>
      <xsl:when test="$role='cmm'">commentator</xsl:when>
      <xsl:when test="$role='cmp'">composer</xsl:when>
      <xsl:when test="$role='cmt'">compositor</xsl:when>
      <xsl:when test="$role='cng'">cinematographer</xsl:when>
      <xsl:when test="$role='cnd'">conductor</xsl:when>
      <xsl:when test="$role='cns'">censor</xsl:when>
      <xsl:when test="$role='coe'">contestant-appellee</xsl:when>
      <xsl:when test="$role='col'">collector</xsl:when>
      <xsl:when test="$role='com'">compiler</xsl:when>
      <xsl:when test="$role='con'">conservator</xsl:when>
      <xsl:when test="$role='cos'">contestant</xsl:when>
      <xsl:when test="$role='cot'">contestant-appellant</xsl:when>
      <xsl:when test="$role='cov'">cover designer</xsl:when>
      <xsl:when test="$role='cpc'">copyright claimant</xsl:when>
      <xsl:when test="$role='cpe'">complainant-appellee</xsl:when>
      <xsl:when test="$role='cph'">copyright holder</xsl:when>
      <xsl:when test="$role='cpl'">complainant</xsl:when>
      <xsl:when test="$role='cpt'">complainant-appellant</xsl:when>
      <xsl:when test="$role='cre'">creator</xsl:when>
      <xsl:when test="$role='crp'">correspondent</xsl:when>
      <xsl:when test="$role='crr'">corrector</xsl:when>
      <xsl:when test="$role='csl'">consultant</xsl:when>
      <xsl:when test="$role='csp'">consultant to a project</xsl:when>
      <xsl:when test="$role='cst'">costume designer</xsl:when>
      <xsl:when test="$role='ctb'">contributor</xsl:when>
      <xsl:when test="$role='cte'">contestee-appellee</xsl:when>
      <xsl:when test="$role='ctg'">cartographer</xsl:when>
      <xsl:when test="$role='ctr'">contractor</xsl:when>
      <xsl:when test="$role='cts'">contestee</xsl:when>
      <xsl:when test="$role='ctt'">contestee-appellant</xsl:when>
      <xsl:when test="$role='cur'">curator</xsl:when>
      <xsl:when test="$role='cwt'">commentator for written text</xsl:when>
      <xsl:when test="$role='dfd'">defendant</xsl:when>
      <xsl:when test="$role='dfe'">defendant-appellee</xsl:when>
      <xsl:when test="$role='dft'">defendant-appellant</xsl:when>
      <xsl:when test="$role='dgg'">degree grantor</xsl:when>
      <xsl:when test="$role='dis'">dissertant</xsl:when>
      <xsl:when test="$role='dln'">delineator</xsl:when>
      <xsl:when test="$role='dnc'">dancer</xsl:when>
      <xsl:when test="$role='dnr'">donor</xsl:when>
      <xsl:when test="$role='dpb'">distribution place</xsl:when>
      <xsl:when test="$role='dpc'">depicted</xsl:when>
      <xsl:when test="$role='dpt'">depositor</xsl:when>
      <xsl:when test="$role='drm'">draftsman</xsl:when>
      <xsl:when test="$role='drt'">director</xsl:when>
      <xsl:when test="$role='dsr'">designer</xsl:when>
      <xsl:when test="$role='dst'">distributor</xsl:when>
      <xsl:when test="$role='dtc'">data contributor</xsl:when>
      <xsl:when test="$role='dte'">dedicatee</xsl:when>
      <xsl:when test="$role='dtm'">data manager</xsl:when>
      <xsl:when test="$role='dto'">dedicator</xsl:when>
      <xsl:when test="$role='dub'">dubious author</xsl:when>
      <xsl:when test="$role='edt'">editor</xsl:when>
      <xsl:when test="$role='egr'">engraver</xsl:when>
      <xsl:when test="$role='elg'">electrician</xsl:when>
      <xsl:when test="$role='elt'">electrotyper</xsl:when>
      <xsl:when test="$role='eng'">engineer</xsl:when>
      <xsl:when test="$role='etr'">etcher</xsl:when>
      <xsl:when test="$role='evp'">event place</xsl:when>
      <xsl:when test="$role='exp'">expert</xsl:when>
      <xsl:when test="$role='fac'">facsimilist</xsl:when>
      <xsl:when test="$role='fld'">field director</xsl:when>
      <xsl:when test="$role='flm'">film editor</xsl:when>
      <xsl:when test="$role='fmo'">former owner</xsl:when>
      <xsl:when test="$role='fpy'">first party</xsl:when>
      <xsl:when test="$role='fnd'">funder</xsl:when>
      <xsl:when test="$role='frg'">forger</xsl:when>
      <xsl:when test="$role='gis'">geographic information specialist</xsl:when>
      <xsl:when test="$role='hnr'">honoree</xsl:when>
      <xsl:when test="$role='hst'">host</xsl:when>
      <xsl:when test="$role='ill'">illustrator</xsl:when>
      <xsl:when test="$role='ilu'">illuminator</xsl:when>
      <xsl:when test="$role='ins'">inscriber</xsl:when>
      <xsl:when test="$role='inv'">inventor</xsl:when>
      <xsl:when test="$role='itr'">instrumentalist</xsl:when>
      <xsl:when test="$role='ive'">interviewee</xsl:when>
      <xsl:when test="$role='ivr'">interviewer</xsl:when>
      <xsl:when test="$role='lbr'">laboratory</xsl:when>
      <xsl:when test="$role='lbt'">librettist</xsl:when>
      <xsl:when test="$role='ldr'">laboratory director</xsl:when>
      <xsl:when test="$role='led'">lead</xsl:when>
      <xsl:when test="$role='lee'">libelee-appellee</xsl:when>
      <xsl:when test="$role='lel'">libelee</xsl:when>
      <xsl:when test="$role='len'">lender</xsl:when>
      <xsl:when test="$role='let'">libelee-appellant</xsl:when>
      <xsl:when test="$role='lgd'">lighting designer</xsl:when>
      <xsl:when test="$role='lie'">libelant-appellee</xsl:when>
      <xsl:when test="$role='lil'">libelant</xsl:when>
      <xsl:when test="$role='lit'">libelant-appellant</xsl:when>
      <xsl:when test="$role='lsa'">landscape architect</xsl:when>
      <xsl:when test="$role='lse'">licensee</xsl:when>
      <xsl:when test="$role='lso'">licensor</xsl:when>
      <xsl:when test="$role='ltg'">lithographer</xsl:when>
      <xsl:when test="$role='lyr'">lyricist</xsl:when>
      <xsl:when test="$role='mcp'">music copyist</xsl:when>
      <xsl:when test="$role='mfp'">manufacture place</xsl:when>
      <xsl:when test="$role='mfr'">manufacturer</xsl:when>
      <xsl:when test="$role='mdc'">metadata contact</xsl:when>
      <xsl:when test="$role='mod'">moderator</xsl:when>
      <xsl:when test="$role='mon'">monitor</xsl:when>
      <xsl:when test="$role='mrb'">marbler</xsl:when>
      <xsl:when test="$role='mrk'">markup editor</xsl:when>
      <xsl:when test="$role='msd'">musical director</xsl:when>
      <xsl:when test="$role='mte'">metal-engraver</xsl:when>
      <xsl:when test="$role='mus'">musician</xsl:when>
      <xsl:when test="$role='nrt'">narrator</xsl:when>
      <xsl:when test="$role='opn'">opponent</xsl:when>
      <xsl:when test="$role='org'">originator</xsl:when>
      <xsl:when test="$role='orm'">organizer of meeting</xsl:when>
      <xsl:when test="$role='oth'">other</xsl:when>
      <xsl:when test="$role='own'">owner</xsl:when>
      <xsl:when test="$role='pat'">patron</xsl:when>
      <xsl:when test="$role='pbd'">publishing director</xsl:when>
      <xsl:when test="$role='pbl'">publisher</xsl:when>
      <xsl:when test="$role='pdr'">project director</xsl:when>
      <xsl:when test="$role='pfr'">proofreader</xsl:when>
      <xsl:when test="$role='pht'">photographer</xsl:when>
      <xsl:when test="$role='plt'">platemaker</xsl:when>
      <xsl:when test="$role='pma'">permitting agency</xsl:when>
      <xsl:when test="$role='pmn'">production manager</xsl:when>
      <xsl:when test="$role='pop'">printer of plates</xsl:when>
      <xsl:when test="$role='ppm'">papermaker</xsl:when>
      <xsl:when test="$role='ppt'">puppeteer</xsl:when>
      <xsl:when test="$role='prc'">process contact</xsl:when>
      <xsl:when test="$role='prd'">production personnel</xsl:when>
      <xsl:when test="$role='prf'">performer</xsl:when>
      <xsl:when test="$role='prg'">programmer</xsl:when>
      <xsl:when test="$role='prm'">printmaker</xsl:when>
      <xsl:when test="$role='pro'">producer</xsl:when>
      <xsl:when test="$role='prp'">production place</xsl:when>
      <xsl:when test="$role='prt'">printer</xsl:when>
      <xsl:when test="$role='pta'">patent applicant</xsl:when>
      <xsl:when test="$role='pte'">plaintiff-appellee</xsl:when>
      <xsl:when test="$role='ptf'">plaintiff</xsl:when>
      <xsl:when test="$role='pth'">patent holder</xsl:when>
      <xsl:when test="$role='ptt'">plaintiff-appellant</xsl:when>
      <xsl:when test="$role='pup'">publication place</xsl:when>
      <xsl:when test="$role='rbr'">rubricator</xsl:when>
      <xsl:when test="$role='rce'">recording engineer</xsl:when>
      <xsl:when test="$role='rcp'">recipient</xsl:when>
      <xsl:when test="$role='red'">redactor</xsl:when>
      <xsl:when test="$role='ren'">renderer</xsl:when>
      <xsl:when test="$role='res'">researcher</xsl:when>
      <xsl:when test="$role='rev'">reviewer</xsl:when>
      <xsl:when test="$role='rps'">repository</xsl:when>
      <xsl:when test="$role='rpt'">reporter</xsl:when>
      <xsl:when test="$role='rpy'">responsible party</xsl:when>
      <xsl:when test="$role='rse'">respondent-appellee</xsl:when>
      <xsl:when test="$role='rsg'">restager</xsl:when>
      <xsl:when test="$role='rsp'">respondent</xsl:when>
      <xsl:when test="$role='rst'">respondent-appellant</xsl:when>
      <xsl:when test="$role='rth'">research team head</xsl:when>
      <xsl:when test="$role='rtm'">research team member</xsl:when>
      <xsl:when test="$role='sad'">scientific advisor</xsl:when>
      <xsl:when test="$role='sce'">scenarist</xsl:when>
      <xsl:when test="$role='scl'">sculptor</xsl:when>
      <xsl:when test="$role='scr'">scribe</xsl:when>
      <xsl:when test="$role='sds'">sound designer</xsl:when>
      <xsl:when test="$role='sec'">secretary</xsl:when>
      <xsl:when test="$role='sgn'">signer</xsl:when>
      <xsl:when test="$role='sht'">supporting host</xsl:when>
      <xsl:when test="$role='sng'">singer</xsl:when>
      <xsl:when test="$role='spk'">speaker</xsl:when>
      <xsl:when test="$role='spn'">sponsor</xsl:when>
      <xsl:when test="$role='spy'">second party</xsl:when>
      <xsl:when test="$role='srv'">surveyor</xsl:when>
      <xsl:when test="$role='std'">set designer</xsl:when>
      <xsl:when test="$role='stl'">storyteller</xsl:when>
      <xsl:when test="$role='stm'">stage manager</xsl:when>
      <xsl:when test="$role='stn'">standards body</xsl:when>
      <xsl:when test="$role='str'">stereotyper</xsl:when>
      <xsl:when test="$role='tcd'">technical director</xsl:when>
      <xsl:when test="$role='tch'">teacher</xsl:when>
      <xsl:when test="$role='ths'">thesis advisor</xsl:when>
      <xsl:when test="$role='trc'">transcriber</xsl:when>
      <xsl:when test="$role='trl'">translator</xsl:when>
      <xsl:when test="$role='tyd'">type designer</xsl:when>
      <xsl:when test="$role='tyg'">typographer</xsl:when>
      <xsl:when test="$role='uvp'">university place</xsl:when>
      <xsl:when test="$role='vdg'">videographer</xsl:when>
      <xsl:when test="$role='voc'">vocalist</xsl:when>
      <xsl:when test="$role='wam'">writer of accompanying material</xsl:when>
      <xsl:when test="$role='wdc'">woodcutter</xsl:when>
      <xsl:when test="$role='wde'">wood-engraver</xsl:when>
      <xsl:when test="$role='wit'">witness</xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="mods:roleTerm" mode="citeproc_default">
    <xsl:variable name="role">
      <xsl:choose>
        <xsl:when test=".[@authority='marcrelator'][@type='code']">
          <xsl:call-template name="translate_coded_marcrelator">
            <xsl:with-param name="role" select="text()"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="text()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="$role='original'">original-author</xsl:when>
      <xsl:otherwise><xsl:value-of select="$role"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>-/->
  
  <xsl:template name="getLongest">
    <xsl:param name="nodeset"/>
    <xsl:param name="current_longest"/>
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="field_name"/>
    
    <xsl:choose>
      <xsl:when test="$nodeset">
        <xsl:choose>
          <xsl:when test="string-length($nodeset[1]) &gt; string-length($current_longest)">
            <xsl:call-template name="getLongest">
              <xsl:with-param name="nodeset" select="$nodeset[position() &gt; 1]"/>
              <xsl:with-param name="current_longest" select="$nodeset[1]"/>
              <xsl:with-param name="prefix"><xsl:value-of select="$prefix"/></xsl:with-param>
              <xsl:with-param name="suffix"><xsl:value-of select="$suffix"/></xsl:with-param>
              <xsl:with-param name="field_name"><xsl:value-of select="$field_name"/></xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="getLongest">
              <xsl:with-param name="nodeset" select="$nodeset[position() &gt; 1]"/>
              <xsl:with-param name="current_longest" select="$current_longest"/>
              <xsl:with-param name="prefix"><xsl:value-of select="$prefix"/></xsl:with-param>
              <xsl:with-param name="suffix"><xsl:value-of select="$suffix"/></xsl:with-param>
              <xsl:with-param name="field_name"><xsl:value-of select="$field_name"/></xsl:with-param>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($prefix, $field_name, $suffix)"/>
          </xsl:attribute>
          <xsl:value-of select="$current_longest/text()"/>
        </field>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>-->
  
  <xsl:template match="rdf:RDF">
    <xsl:param name="prefix">rels_</xsl:param>
    <xsl:param name="suffix">_s</xsl:param>

    <xsl:for-each select=".//rdf:Description/*[@rdf:resource]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), '_uri', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="@rdf:resource"/>
      </field>
    </xsl:for-each>
    <xsl:for-each select=".//rdf:Description/*[not(@rdf:resource)][normalize-space(text())]">
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
