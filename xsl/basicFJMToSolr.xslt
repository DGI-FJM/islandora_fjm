<?xml version="1.0" encoding="UTF-8"?> 
<!-- TODO Reconsider how names are acquired:  If labels are set properly on change,
	going out to most metadata files could be avoided, as the labels are available
	from the Resource Index...  On the otherhnad, if the labels become desynced, 
	there could be problems...  Might make a script (run via cron) to check if the 
	label is correct, and index if it is not? -->
	
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"   
		xmlns:foxml="info:fedora/fedora-system:def/foxml#"
		xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		xmlns:m="http://www.loc.gov/mods/v3"
		xmlns:res="http://www.w3.org/2001/sw/DataAccess/rf1/result"
		xmlns:fds="http://www.fedora.info/definitions/1/0/access/"
		xmlns:ns="http://www.example.org/dummy#"
		xmlns:xalan="http://xml.apache.org/xalan"
		xmlns:exts="xalan://dk.defxws.fedoragsearch.server.GenericOperationsImpl"
    		exclude-result-prefixes="exts m rdf res fds ns xalan">
	<xsl:output method="xml" indent="yes" encoding="UTF-8"/>
	<!-- FIXME:  I figure relative URLs should work...  They didn't want to work, and absolute ones aren't nice (Xalan has this as an unresolved major bug since 2005.  See Apache's JIRA (XALANJ-2000 or so))...  This is currently relying on a minor (?) hack in Islandora. -->
	<xsl:include href="http://localhost/fedora/xml/xsl/url_util.xslt"/>
	
	<!-- FIXME:  Should probably get these as parameters, or sommat -->
	<xsl:param name="HOST" select="'localhost'"/>
	<xsl:param name="PORT" select="'8080'"/>
	<xsl:param name="PROT" select="'http'"/>
	<xsl:param name="URLBASE" select="concat($PROT, '://', $HOST, ':', $PORT)"/>
	<xsl:param name="REPOSITORYNAME" select="'fedora'"/>
	<xsl:param name="RISEARCH" select="concat($URLBASE, '/fedora/risearch',
		'?type=tuples&amp;flush=TRUE&amp;format=Sparql&amp;lang=itql&amp;query=')" />
	<!--<xsl:param name="FEDORAUSERNAME" select="'fedoraAdmin'"/>
	<xsl:param name="FEDORAPASSWORD" select="'fedoraAdmin'"/>-->
	<xsl:param name="FEDORAUSERNAME" select="''"/>
	<xsl:param name="FEDORAPASSWORD" select="''"/>
	<xsl:param name="NAMESPACE" select="'http://www.example.org/dummy#'"/>

	<xsl:template name="fjm-atm">
		<xsl:param name="pid" select="no_pid"/>
		<xsl:param name="previous_items" select="''"/>
		<!-- Index based on CModel -->
		<xsl:if test="not(contains($previous_items, $pid))">
			<xsl:for-each select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
					$HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/RELS-EXT/content'))/rdf:RDF/rdf:Description/*[local-name()='hasModel' and @rdf:resource]">
				<xsl:choose>
					<xsl:when test="@rdf:resource='info:fedora/atm:concertCModel'">
						
						<xsl:call-template name="atm_concert">
							<xsl:with-param name="pid" select="$pid"/>
						</xsl:call-template>
						<!-- index performances, lectures, and programs -->
						<xsl:variable name="ITEM_TF">
							<xsl:call-template name="perform_query">
								<xsl:with-param name="query" select="concat('
								select $item from &lt;#ri&gt;
								where $concert &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
								and $item &lt;fedora-rels-ext:isMemberOf&gt; $concert
								and $item &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
								')"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:for-each select="xalan:nodeset($ITEM_TF)/res:sparql/res:results/res:result/res:item">
							<xsl:call-template name="fjm-atm">
								<xsl:with-param name="pid" select="substring-after(@uri, '/')"/>
								<xsl:with-param name="previous_items" select="concat($previous_items, ' ', $pid)"/>
							</xsl:call-template>
						</xsl:for-each>
					</xsl:when>
					<xsl:when test="@rdf:resource='info:fedora/atm:performanceCModel'">
						<xsl:call-template name="atm_performance">
							<xsl:with-param name="pid" select="$pid"/>
						</xsl:call-template>
						<xsl:call-template name="atm_performer">
							<xsl:with-param name="performance" select="$pid"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:when test="@rdf:resource='info:fedora/atm:scoreCModel'">
						<!-- Index the score and then all concerts which contain a performances based on the score -->
						<xsl:call-template name="atm_score">
							<xsl:with-param name="pid" select="$pid"/>
						</xsl:call-template>
						<xsl:variable name="CONCERT_TF">
							<xsl:call-template name="perform_query">
								<xsl:with-param name="query" select="concat('
								select $concert from &lt;#ri&gt;
								where $performance &lt;', $NAMESPACE, 'basedOn&gt; &lt;fedora:', $pid, '&gt;
								and $performance &lt;fedora-rels-ext:isMemberOf&gt; $concert
								and $performance &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
								')"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:for-each select="xalan:nodeset($CONCERT_TF)/res:sparql/res:results/res:result/res:concert">
							<xsl:call-template name="fjm-atm">
								<xsl:with-param name="pid" select="substring-after(@uri, '/')"/>
								<xsl:with-param name="previous_items" select="concat($previous_items, ' ', $pid)"/>
							</xsl:call-template>
						</xsl:for-each>
					</xsl:when>
					<xsl:when test="@rdf:resource='info:fedora/atm:programCModel'">
						<xsl:call-template name="atm_program">
							<xsl:with-param name="pid" select="$pid"/>
						</xsl:call-template>
						
					</xsl:when>
					<xsl:when test="@rdf:resource='info:fedora/atm:personCModel'">
						<xsl:if test="count(../ns:composed) &gt; 0">
							<xsl:call-template name="atm_composer">
								<xsl:with-param name="pid" select="$pid"/>
							</xsl:call-template>
						</xsl:if>
						
						<!-- Get the list of all concerts in which this person has played and which doesn't contain 
							a performance based on a piece they have composed (not sure if this exclusion will work, 
							as I do not actually see this situation) and of all the scores they have composed and index them. -->
						<xsl:variable name="ITEM_TF">
							<xsl:call-template name="perform_query">
								<xsl:with-param name="query" select="concat('
									select $item from &lt;#ri&gt;
									where $person &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
									and 
									(
										(
											($person &lt;', $NAMESPACE, 'playedIn&gt; $performance
											and $performance &lt;fedora-rels-ext:isMemberOf&gt; $item)
											minus
											(
												$person &lt;', $NAMESPACE, 'composed&gt; $score
												and $performance &lt;', $NAMESPACE, 'basedOn&gt; $score
											)
										)
										or 
										(
											$person &lt;', $NAMESPACE, 'composed&gt; $item
										)
									)
								')"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:for-each select="xalan:nodeset($ITEM_TF)/res:sparql/res:results/res:result/res:item">
							<xsl:call-template name="fjm-atm">
								<xsl:with-param name="pid" select="substring-after(@uri, '/')"/>
								<xsl:with-param name="previous_items" select="concat($previous_items, ' ', $pid)"/>
							</xsl:call-template>
						</xsl:for-each>
					</xsl:when>
					<xsl:when test="@rdf:resource='info:fedora/atm:lectureCModel'">
						<xsl:call-template name="atm_lecture">
							<xsl:with-param name="pid" select="$pid"/>
						</xsl:call-template>
						<xsl:variable name="ITEM_TF">
							<xsl:call-template name="perform_query">
								<xsl:with-param name="query" select="concat('
									select $item from &lt;#ri&gt;
									where $lecture &lt;mulgara:is&gt; &lt;fedora:', $pid,'&gt;
									and $lecture &lt;fedora-rels-ext:isMemberOf&gt; $item
									and $item &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
								')"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:for-each select="xalan:nodeset($ITEM_TF)/res:sparql/res:results/res:result/res:item">
							<xsl:call-template name="fjm-atm">
								<xsl:with-param name="pid" select="substring-after(@uri, '/')"/>
								<xsl:with-param name="previous_items" select="concat($previous_items, ' ', $pid)"/>
							</xsl:call-template>
						</xsl:for-each>
					</xsl:when>
					<xsl:when test="@rdf:resource='info:fedora/atm:movementCModel'">
						<xsl:call-template name="atm_movement">
							<xsl:with-param name="pid" select="$pid"/>
						</xsl:call-template>
						<xsl:variable name="ITEM_TF">
							<xsl:call-template name="perform_query">
								<xsl:with-param name="query" select="concat('
									select $performance from &lt;#ri&gt;
									where $movement &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
									and $movement &lt;fedora-rels-ext:isMemberOf&gt; $performance
									and $performance &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
								')"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:for-each select="xalan:nodeset($ITEM_TF)/res:sparql/res:results/res:result/res:performance">
							<xsl:call-template name="fjm-atm">
								<xsl:with-param name="pid" select="substring-after(@uri, '/')"/>
								<xsl:with-param name="previous_items" select="concat($previous_items, ' ', $pid)"/>
							</xsl:call-template>
						</xsl:for-each>
					</xsl:when>
					<xsl:otherwise>
						<doc>
							<field name="PID">
								<xsl:value-of select="$pid"/>
							</field>
							<xsl:call-template name="rels_ext">
								<xsl:with-param name="pid" select="$pid"/>
							</xsl:call-template>
						</doc>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="atm_concert">
		<xsl:param name="pid" select="no_pid"/>
                
                <xsl:variable name="C_CUSTOM" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/CustomXML/content'))"/>
		<doc>
			<field name="PID">
				<xsl:value-of select="$pid"/>
			</field>
			<field name="atm_type_s">Concert</field>
			
			<xsl:call-template name="rels_ext">
				<xsl:with-param name="pid" select="$pid"/>
			</xsl:call-template>
		
			<xsl:variable name="SCORE_QUERY_TF">
				<xsl:call-template name="perform_query">
					<xsl:with-param name="query" select="concat('
					  select $score $performance $composer $concertTitle $composerName $pieceName $cycleName $program from &lt;#ri&gt;
					  where $concert &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
					  and $performance &lt;fedora-rels-ext:isMemberOf&gt; $concert
					  and $score &lt;fedora-model:label&gt; $pieceName
					  and $concert &lt;fedora-model:label&gt; $concertTitle
					  and $concert &lt;fedora-rels-ext:isMemberOf&gt; $concertCycle
					  and $program &lt;fedora-rels-ext:isMemberOf&gt; $concert
					  and $program &lt;fedora-model:hasModel&gt; &lt;fedora:atm:programCModel&gt;
					  and $concertCycle &lt;fedora-model:label&gt; $cycleName
					  and $performance &lt;http://www.example.org/dummy#basedOn&gt; $score
					  and $composer &lt;http://www.example.org/dummy#composed&gt; $score
					  and $composer &lt;fedora-model:label&gt; $composerName
					  and $score &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
					  and $performance &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
					  and $composer &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
					  ;
					  ')"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="SCORES" select="xalan:nodeset($SCORE_QUERY_TF)/res:sparql/res:results"/>
			
			<field name="atm_concert_title_s">
				<xsl:value-of select="normalize-space($SCORES/res:result[1]/res:concertTitle/text())"/>
			</field>
			<field name="atm_concert_cycle_s">
				<xsl:value-of select="normalize-space($SCORES/res:result[1]/res:cycleName/text())"/>
			</field>
		
			<!-- FIXME:  The date should be in MODS (and or somewhere else (DC?), and obtained from there), so the original XML need not be stored...
				Also, the whole "concat(..., 'Z')" seems a little flimsy-->
			<xsl:variable name="date" select="normalize-space(concat($C_CUSTOM/Concierto/FECHA/text(), 'Z'))"/>
			<field name="atm_concert_date_dt">
				<xsl:value-of select="$date"/>
			</field>
			<field name="atm_concert_year_s">
				<xsl:value-of select="substring($date, 1, 4)"/>
			</field>
			
			<xsl:variable name="TN_QUERY_TF">
				<xsl:call-template name="perform_query">
					<xsl:with-param name="query" select="concat('
					  select $image from &lt;#ri&gt;
					  where $image &lt;http://www.example.org/dummy#isIconOf&gt; &lt;fedora:', $pid, '&gt; 
					  and $image &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
					  ;
					  ')"/>
					 <xsl:with-param name="additional_params" select="'&amp;limit=1'"/>
				</xsl:call-template>
			</xsl:variable>
                        
			<xsl:variable name="LECT_TF">
				<xsl:call-template name="perform_query">
					<xsl:with-param name="query" select="concat('
					  select $lecture from &lt;#ri&gt;
					  where $lecture &lt;fedora-rels-ext:isMemberOf&gt; &lt;fedora:', $pid, '&gt;
					  and $lecture &lt;fedora-rels-ext:hasModel&gt; &lt;fedora:atm:lectureCModel&gt;
					  and $lecture &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
					  ;
					  ')"/>
				</xsl:call-template>
			</xsl:variable>
                        
			<xsl:for-each select='$SCORES/res:result'>
				<!-- TODO: blargh...  Logging in via the URL...  Would like to use the Xalan extensions, but they're (the ones for fedoragsearch anyway) a pain to debug...  Also, didn't seem to work for some API-M stuff I tried... -->
				<field name="atm_concert_piece_ms">
					<xsl:value-of select="normalize-space(res:pieceName/text())"/>
				</field>
			
				<!-- TODO assumed only one composer per piece (here and elsewhere)...  may need to change? ...  
					Should I get it from the label? -->
				<field name="atm_concert_composer_ms">
					<xsl:value-of select="normalize-space(res:composerName/text())"/>
				</field>
				
				<xsl:if test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', substring-after(res:score/@uri, '/') , '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='PDF']">
					<field name="atm_digital_objects_ms">Score PDF</field>
				</xsl:if>
				
				<xsl:variable name="PERSON_GROUP_MEMBERSHIP">
					<people><!-- Need a "root" element, so add one. -->
						<xsl:call-template name="atm_performer">
							<xsl:with-param name="performance" select="substring-after(res:performance/@uri, '/')"/>
						</xsl:call-template>
					</people>
				</xsl:variable>
				<xsl:for-each select="xalan:nodeset($PERSON_GROUP_MEMBERSHIP)/people/doc">
					<field name="atm_concert_group_ms">
						<xsl:value-of select="field[@name='atm_performer_group_s']/text()"/>
					</field>
					<field name="atm_concert_player_ms">
						<xsl:value-of select="field[@name='atm_performer_name_s']/text()"/>
					</field>
					<field name="atm_concert_instrument_ms">
						<xsl:value-of select="field[@name='atm_performer_instrument_s']/text()"/>
					</field>
				</xsl:for-each>
			</xsl:for-each>
			
			<field name="atm_concert_program_pdf_b">
				<xsl:choose>
					<xsl:when test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', substring-after($SCORES/res:result[1]/res:program/@uri, '/'), '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='PDF']">true</xsl:when>
					<xsl:otherwise>false</xsl:otherwise>
				</xsl:choose>
			</field>
                        
			<field name="atm_concert_lecture_b">
				<xsl:choose>
					<xsl:when test="count(xalan:nodeset($LECT_TF)/res:sparql/res:results/res:result) &gt; 0">true</xsl:when>
					<xsl:otherwise>false</xsl:otherwise>
				</xsl:choose>
			</field>
			
			<field name="atm_concert_program_titn_s">
				<xsl:value-of select="normalize-space($C_CUSTOM/Concierto/programa/titn_programa/text())"/>
			</field>
		
			<xsl:for-each select='xalan:nodeset($TN_QUERY_TF)/res:sparql/res:results/res:result'>
				<field name="atm_concert_iconpid_s">
					<xsl:value-of select="substring-after(res:image/@uri, '/')"/>
				</field>
			</xsl:for-each>
		</doc>
	</xsl:template>
	
	<!-- FIXME:  Assumed there was only one composer...  (Limited to one result returned, really...) -->
	<xsl:template name="atm_performance">
		<xsl:param name="pid" select="no_pid"/>
		
		<xsl:variable name="SCORE_TF">
			<xsl:call-template name="perform_query">
				<xsl:with-param name="query" select="concat('
						  select $concert $score $scoreName $composerName $composer $cycleName $concertName $order from &lt;#ri&gt;
						  where $performance &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
						  and $performance &lt;', $NAMESPACE, 'basedOn&gt; $score
						  and $performance &lt;fedora-rels-ext:isMemberOf&gt; $concert
						  and $performance &lt;', $NAMESPACE, 'concertOrder&gt; $order
						  and $concert &lt;fedora-rels-ext:isMemberOf&gt; $concertCycle
						  and $concertCycle &lt;fedora-model:label&gt; $cycleName
						  and $concert &lt;fedora-model:label&gt; $concertName
						  and $composer &lt;', $NAMESPACE, 'composed&gt; $score
						  and $score &lt;fedora-model:label&gt; $scoreName
						  and $composer &lt;fedora-model:label&gt; $composerName
						  and $score &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
						  and $composer &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
						  ;
						  ')"/>
				<xsl:with-param name="additional_params" select="'&amp;limit=1'"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="SCORES" select="xalan:nodeset($SCORE_TF)/res:sparql/res:results/res:result"/>
		
		<!-- Perform a query which grabs all players name and the name of the instrument they played, based on the label in Fedora -->
		<xsl:variable name="PLAYER_QUERY_TF">
			<people><!-- Need a "root" element... -->
				<xsl:call-template name="atm_performer">
					<xsl:with-param name="performance" select="$pid"/>
				</xsl:call-template>
			</people>
		</xsl:variable>
		<xsl:variable name="PLAYERS" select="xalan:nodeset($PLAYER_QUERY_TF)"/>
		
		<xsl:variable name="MOVEMENT_TF">
			<xsl:call-template name="perform_query">
				<xsl:with-param name="query" select="concat('
				select $movement_pid $order from &lt;#ri&gt;
				where $performance &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
				and $movement_pid &lt;fedora-rels-ext:isMemberOf&gt; $performance
				and $movement_pid &lt;' , $NAMESPACE, 'pieceOrder&gt; $order
				and $movement_pid &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
				order by $order asc
				')"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="MOVEMENTS" select="xalan:nodeset($MOVEMENT_TF)"/>

		<xsl:variable name="C_CUSTOM" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
				$HOST, ':', $PORT, '/fedora/objects/', substring-after($SCORES/res:concert/@uri, '/'), '/datastreams/CustomXML/content'))"/>
					
		<doc>
			<field name="PID">
				<xsl:value-of select="$pid"/>
			</field>
			
			<!-- FIXME:  Kinda sorta bad/hackish...  Should use the content model, if anything...
				Can't really, because the use there are not "performer" objects...
				Should probably create the "relationship" objects for performers... -->
			<field name="atm_type_s">Performance</field>
			
			<xsl:call-template name="rels_ext">
				<xsl:with-param name="pid" select="$pid"/>
			</xsl:call-template>
			
			<xsl:for-each select="$MOVEMENTS/res:sparql/res:results/res:result">
				<field name="atm_performance_movement_ms">
					<xsl:value-of select="substring-after(res:movement_pid/@uri, '/')"/>
				</field>
			</xsl:for-each>
			
			<!-- Use the retrieved metadatastreams -->
			<field name="atm_performance_piece_title_s">
				<xsl:value-of select="normalize-space($SCORES/res:scoreName/text())"/>
			</field>
			<field name="atm_performance_concert_name_s">
				<xsl:value-of select="normalize-space($SCORES/res:concertName/text())"/>
				<!--<xsl:value-of select="normalize-space($C_MODS/m:modsCollection/m:mods/m:titleInfo[@type='alternative'][1]/m:title/text())"/>-->
			</field>
			<field name="atm_performance_concert_cycle_s">
				<xsl:value-of select="normalize-space($SCORES/res:cycleName/text())"/>
				<!--<xsl:value-of select="normalize-space($C_MODS/m:modsCollection/m:mods/m:name[@type='conference']/m:namePart/text())"/>-->
			</field>
			<field name="atm_facet_concert_title_s">
				<xsl:value-of select="normalize-space($SCORES/res:concertName/text())"/>
				<!--<xsl:value-of select="normalize-space($C_MODS/m:modsCollection/m:mods/m:titleInfo[@type='alternative'][1]/m:title/text())"/>-->
			</field>
			<field name="atm_facet_concert_cycle_s">
				<xsl:value-of select="normalize-space($SCORES/res:cycleName/text())"/>
				<!--<xsl:value-of select="normalize-space($C_MODS/m:modsCollection/m:mods/m:name[@type='conference']/m:namePart/text())"/>-->
			</field>
			<xsl:variable name="date" select="normalize-space(concat($C_CUSTOM/Concierto/FECHA/text(), 'Z'))"/>
			<xsl:variable name="year" select="substring($date, 1, 4)"/>
			<field name="atm_audio_concert_date_dt">
				<xsl:value-of select="$date"/>
			</field>
			<field name="atm_audio_concert_year_s">
				<xsl:value-of select="$year"/>
			</field>
			<!-- TODO (minor): Determine if these other date fields are really necessary... -->
			<field name="atm_performance_concert_date_dt">
				<xsl:value-of select="$date"/>
			</field>
			<field name="atm_performance_year_s">
				<xsl:value-of select="$year"/>
			</field>
			<field name="atm_performance_composer_name_s">
				<xsl:value-of select="normalize-space($SCORES/res:composerName/text())"/>
			</field>
			<field name="atm_performance_composer_pid_s">
				<xsl:value-of select="substring-after($SCORES/res:composer/@uri, '/')"/>
			</field>
			
			<field name="atm_performance_order_i">
				<xsl:value-of select="normalize-space($SCORES/res:order/text())"/>
			</field>
			<!-- check if the score object has a PDF datastream -->
			<field name="atm_performance_score_pdf_b">
				<xsl:choose>
					<xsl:when test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD,
					'@', $HOST, ':', $PORT, '/fedora/objects/', substring-after($SCORES/res:score/@uri, 
					'/') , '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='PDF']"
					>true</xsl:when>
					<xsl:otherwise>false</xsl:otherwise>
				</xsl:choose>
			</field>
	
			<!-- check if there is an MP3 in this performance (otherwise, they have to be in the movements) -->
			<field name="atm_performance_mp3_b">
				<xsl:choose>
					<xsl:when test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD,
					'@', $HOST, ':', $PORT, '/fedora/objects/', $pid , '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='MP3']"
					>true</xsl:when>
					<xsl:otherwise>false</xsl:otherwise>
				</xsl:choose>
			</field>
			
			<!-- TODO:  Is this what they want? -->
			<xsl:if test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $pid , '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='MP3']">
				<field name="atm_digital_objects_ms">Concert Audio</field>
			</xsl:if>
			<xsl:if test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', substring-after($SCORES/res:score/@uri, '/') , '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='PDF']">
				<field name="atm_digital_objects_ms">Score PDF</field>
			</xsl:if>
	
			<xsl:for-each select="$PLAYERS/people/doc">
				<xsl:variable name="person_pid" select="normalize-space(field[@name='PID']/text())"/>
				<xsl:variable name="name" select="normalize-space(field[@name='atm_performer_name_s']/text())"/>
				<xsl:variable name="inst" select="normalize-space(field[@name='atm_performer_instrument_s']/text())"/>
				<xsl:variable name="class" select="normalize-space(field[@name='atm_performer_instrument_class_s']/text())"/>
				<field name="atm_performance_player_pid_ms">
					<xsl:value-of select="$person_pid"/>
				</field>
				<field name="atm_performance_player_ms">
					<xsl:value-of select="$name"/>
				</field>
				<field name="atm_performance_inst_ms">
					<xsl:value-of select="$inst"/>
				</field>
				<field name="atm_performance_inst_class_ms">
					<xsl:value-of select="$class"/>
				</field>
			</xsl:for-each>
		</doc>
	</xsl:template>
	
	
	<xsl:template name="atm_movement">
		<xsl:param name="pid"/>
		
		<doc>
			<field name="PID">
				<xsl:value-of select="$pid"/>
			</field>
			<xsl:call-template name="rels_ext">
				<xsl:with-param name="pid" select="$pid"/>
			</xsl:call-template>
			<field name="hasMP3_b">
				<xsl:choose>
					<xsl:when test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $pid , '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='MP3']">true</xsl:when>
					<xsl:otherwise>false</xsl:otherwise>
				</xsl:choose>
			</field>
			<xsl:variable name="ITEM_TF">
				<xsl:call-template name="perform_query">
					<xsl:with-param name="query" select="concat('
						select $name $cOrder $pOrder from &lt;#ri&gt;
						where $movement &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
						and $movement &lt;fedora-model:label&gt; $name
						and $movement &lt;fedora-rels-ext:isMemberOf&gt; $performance
						and $performance &lt;', $NAMESPACE, 'concertOrder&gt; $cOrder
						and $movement &lt;', $NAMESPACE, 'pieceOrder&gt; $pOrder
					')"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:for-each select="xalan:nodeset($ITEM_TF)/res:sparql/res:results/res:result">
				<field name="title_s">	
					<xsl:value-of select="normalize-space(res:name/text())"/>
				</field>
				<field name="cOrder_s">
					<xsl:value-of select="res:cOrder/text()"/>
				</field>
				<field name="pOrder_s">
					<xsl:value-of select="res:pOrder/text()"/>
				</field>
			</xsl:for-each>
		</doc>
	</xsl:template>
	
	<!-- get the title of the piece, composers name, titn id, and PDF status -->
	<xsl:template name="atm_score">
		<xsl:param name="pid" select="no_pid"/>
		
		<xsl:variable name="SCORE_RESULT_TF">
			<xsl:call-template name="perform_query">
				<xsl:with-param name="query" select="concat('
				select $title $composerName $composer from &lt;#ri&gt;
				where &lt;fedora:', $pid, '&gt; &lt;fedora-model:label&gt; $title
				and $composer &lt;http://www.example.org/dummy#composed&gt; &lt;fedora:', $pid, '&gt;
				and $composer &lt;fedora-model:label&gt; $composerName
				')"/>
				<xsl:with-param name="additional_params" select="'&amp;limit=1'"/>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="CONCERT_TF">
			<xsl:call-template name="perform_query">
				<xsl:with-param name="query" select="concat('
					select $performance $concert from &lt;#ri&gt;
					where $score &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
					and $performance &lt;', $NAMESPACE, 'basedOn&gt; $score
					and $performance &lt;fedora-rels-ext:isMemberOf&gt; $concert
					and $performance &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
				')"/>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="SCORE_RESULT" select="xalan:nodeset($SCORE_RESULT_TF)/res:sparql/res:results/res:result"/>
		<xsl:variable name="SCORE_XML" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
					$HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/OriginalXML/content'))"/>
		<xsl:variable name="SCORE_DATASTREAMS" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
					$HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams?format=xml'))"/>
		<doc>
			<field name="PID">
				<xsl:value-of select="$pid"/>
			</field>
			
			<xsl:call-template name="rels_ext">
				<xsl:with-param name="pid" select="$pid"/>
			</xsl:call-template>
			
			<field name="atm_type_s">Score</field>
			
			<field name="atm_score_composer_s">
				<xsl:value-of select="normalize-space($SCORE_RESULT/res:composerName/text())"/>
			</field>
			<field name="atm_score_composer_pid_s">
				<xsl:value-of select="substring-after($SCORE_RESULT/res:composer/@uri, '/')"/>
			</field>
			<field name="atm_score_title_s">
				<xsl:value-of select="normalize-space($SCORE_RESULT/res:title/text())"/>
			</field>
			<field name="atm_score_titn_s">
				<xsl:choose>
					<xsl:when test="not($SCORE_XML/Obra/titn_partitura)">
						<!-- FIXME:  Magic numbers?  Not too bad, I suppose... -->
						<xsl:value-of select="-1"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="normalize-space($SCORE_XML/Obra/titn_partitura/text())"/>
					</xsl:otherwise>
				</xsl:choose>
			</field>
			
			<xsl:for-each select="xalan:nodeset($CONCERT_TF)/res:sparql/res:results/res:result/res:performance">
				<xsl:variable name="PERFORMER_TF">
					<people>
						<xsl:call-template name="atm_performer">
							<xsl:with-param name="performance" select="substring-after(@uri, '/')"/>
						</xsl:call-template>
					</people>
				</xsl:variable>
				<xsl:for-each select="xalan:nodeset($PERFORMER_TF)/people/doc">
					<field name="atm_score_concert_pid_ms">
						<xsl:value-of select="field[@name='atm_performer_concert_pid_s']"/>
					</field>
					<field name="atm_score_concert_title_ms">
						<xsl:value-of select="field[@name='atm_performer_concert_title_s']"/>
					</field>
					<field name="atm_score_concert_cycle_ms">
						<xsl:value-of select="field[@name='atm_performer_concert_cycle_s']"/>
					</field>
					<field name="atm_score_perfomer_name_ms">
						<xsl:value-of select="field[@name='atm_performer_name_s']"/>
					</field>
					<field name="atm_score_performer_group_ms">
						<xsl:value-of select="field[@name='atm_performer_group_s']"/>
					</field>
				</xsl:for-each>
			</xsl:for-each>
			
			<xsl:choose>
				<xsl:when test="$SCORE_DATASTREAMS/fds:objectDatastreams/fds:datastream[@dsid='PDF']">
					<field name="atm_score_pdf_b">true</field>
					<field name="atm_digital_objects_ms">Score PDF</field>
				</xsl:when>
				<xsl:otherwise>
					<field name="atm_score_pdf_b">false</field>
				</xsl:otherwise>
			</xsl:choose>
			
		</doc>
	</xsl:template>
	
	<xsl:template name="atm_program">
		<xsl:param name="pid" select="no_pid"/>
		
		<doc>
			<field name="PID">
				<xsl:value-of select="$pid"/>
			</field>
			
			<field name="atm_type_s">Program</field>
			
			<xsl:variable name="CONCERT_QUERY_TF">
				<xsl:call-template name="perform_query">
					<xsl:with-param name="query" select="concat('
					select $concert $concertTitle $concertCycle from &lt;#ri&gt;
					where &lt;fedora:', $pid, '&gt; &lt;fedora-rels-ext:isMemberOf&gt; $concert
					and $concert &lt;fedora-rels-ext:isMemberOf&gt; $cycle
					and $cycle &lt;fedora-model:label&gt; $concertCycle
					and $concert &lt;fedora-model:label&gt; $concertTitle
					')"/>
					<xsl:with-param name="additional_params" select="'&amp;limit=1'"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="CONCERT_INFO" select="xalan:nodeset($CONCERT_QUERY_TF)/res:sparql/res:results/res:result"/>
			
			<field name="atm_program_concert_title_s">
				<xsl:value-of select="normalize-space($CONCERT_INFO/res:concertTitle/text())"/>
			</field>
			<field name="atm_program_concert_cycle_ms">
				<xsl:value-of select="normalize-space($CONCERT_INFO/res:concertCycle/text())"/>
			</field>
			
			<!-- FIXME: Titn is currently only in the concert level...  Perhaps during import it might be moved
				to a better space (i.e. inside the program object) -->
			<xsl:variable name="C_CUSTOM" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', substring-after($CONCERT_INFO/res:concert/@uri, '/'), '/datastreams/CustomXML/content'))"/>
			<field name="atm_program_titn_s">
				<xsl:value-of select="normalize-space($C_CUSTOM/Concierto/programa/titn_programa/text())"/>
			</field>
			
			<xsl:variable name="date" select="normalize-space(concat($C_CUSTOM/Concierto/FECHA/text(), 'Z'))"/>
			<field name="atm_program_date_dt">
				<xsl:value-of select="$date"/>
			</field>
			<field name="atm_program_year_s">
				<xsl:value-of select="substring($date, 1, 4)"/>
			</field>
			
			<!-- FIXME (major): Need to create EAC-CPF objects for authors and obtain from there!
				Also, trigger reindex when author object changes.
				Going to be creating "person" objects for each with EAC-CPF, and index from there.-->
			<field name="atm_program_author_s">
				<!--<xsl:value-of select="normalize-space()"/>-->
			</field>
			
			
			<xsl:choose>
				<xsl:when test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='PDF']">
					<field name="atm_program_pdf_b">true</field>
					<field name="atm_digital_objects_ms">Score PDF</field>
				</xsl:when>
				<xsl:otherwise>
					<field name="atm_program_pdf_b">false</field>
				</xsl:otherwise>
			</xsl:choose>
			
			
		</doc>
	</xsl:template>
	
	<xsl:template name="atm_lecture">
		<xsl:param name="pid" select="''"/>
		
		<doc>
			<field name="PID">
				<xsl:value-of select="$pid"/>
			</field>
			<xsl:variable name="LECT_TF">
				<xsl:call-template name="perform_query">
					<xsl:with-param name="query" select="concat('
						select $lectureTitle $concertTitle $concertCycle $concert $order from &lt;#ri&gt;
						where $lecture &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
						and $lecture &lt;fedora-rels-ext:isMemberOf&gt; $concert
						and $lecture &lt;fedora-model:label&gt; $lectureTitle
						and $concert &lt;fedora-model:label&gt; $concertTitle
						and $concert &lt;fedora-rels-ext:isMemberOf&gt; $cycle
						and $cycle &lt;fedora-model:label&gt; $concertCycle
						and $lecture &lt;', $NAMESPACE, 'concertOrder&gt; $order
						and $lecture &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
						and $concert &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
						;
						')"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="LECT" select="xalan:nodeset($LECT_TF)/res:sparql/res:results/res:result"/>
                        <xsl:variable name="C_CUSTOM" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
				$HOST, ':', $PORT, '/fedora/objects/', substring-after($LECT/res:concert/@uri, '/'), '/datastreams/CustomXML/content'))"/>
			<field name="atm_type_s">Lecture</field>
			<field name="atm_lecture_title_s">
				<xsl:value-of select="$LECT/res:lectureTitle/text()"/>
			</field>
			<field name="atm_lecture_concert_title_s">
				<xsl:value-of select="$LECT/res:concertTitle/text()"/>
			</field>
			<field name="atm_lecture_concert_cycle_s">
				<xsl:value-of select="$LECT/res:concertCycle/text()"/>
			</field>
			<field name="atm_audio_concert_name_s">
				<xsl:value-of select="normalize-space($LECT/res:concertTitle/text())"/>
				<!--<xsl:value-of select="normalize-space($C_MODS/m:modsCollection/m:mods/m:titleInfo[@type='alternative'][1]/m:title/text())"/>-->
			</field>
			<field name="atm_audio_concert_cycle_s">
				<xsl:value-of select="normalize-space($LECT/res:concertCycle/text())"/>
				<!--<xsl:value-of select="normalize-space($C_MODS/m:modsCollection/m:mods/m:name[@type='conference']/m:namePart/text())"/>-->
			</field>
			<xsl:variable name="date" select="normalize-space(concat($C_CUSTOM/Concierto/FECHA/text(), 'Z'))"/>
			<field name="atm_audio_concert_date_dt">
				<xsl:value-of select="$date"/>
			</field>
			<field name="atm_audio_concert_year_s">
				<xsl:value-of select="substring($date, 1, 4)"/>
			</field>
			<field name="atm_lecture_order_i">
				<xsl:value-of select="$LECT/res:order/text()"/>
			</field>
			<xsl:call-template name="rels_ext">
				<xsl:with-param name="pid" select="$pid"/>
			</xsl:call-template>
		</doc>
	</xsl:template>
	
	<xsl:template name="atm_composer">
		<xsl:param name="pid" select="'empty'"/>
		
		<xsl:variable name="COMPOSER_TF">
			<xsl:call-template name="perform_query">
				<xsl:with-param name="query" select="concat('
					select $icon $name from &lt;#ri&gt;
					where $person &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
					and $icon &lt;', $NAMESPACE, 'isIconOf&gt; $person
					and $person &lt;fedora-model:label&gt; $name
				')"/>
				<xsl:with-param name="additional_params" select="'&amp;limit=1'"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="CONCERT_TF">
			<xsl:call-template name="perform_query">
				<xsl:with-param name="query" select="concat('
					select $concert $concertName $concertCycle from &lt;#ri&gt;
					where $composer &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
					and $composer &lt;', $NAMESPACE, 'composed&gt; $score
					and $performance &lt;', $NAMESPACE, 'basedOn&gt; $score
					and $performance &lt;fedora-rels-ext:isMemberOf&gt; $concert
					and $concert &lt;fedora-rels-ext:isMemberOf&gt; $cycle
					and $concert &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
					and $performance &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
					and $concert &lt;fedora-model:label&gt; $concertName
					and $cycle &lt;fedora-model:label&gt; $concertCycle
					;
				')"/>
			</xsl:call-template>
		</xsl:variable>
		
		<doc>
			<field name="PID">
					<xsl:value-of select="$pid"/>
			</field>
			
			<xsl:for-each select="xalan:nodeset($COMPOSER_TF)/res:sparql/res:results/res:result">
				<field name="atm_type_s">Composer</field>
				<field name="atm_composer_name_s">
					<xsl:value-of select="normalize-space(res:name/text())"/>
				</field>
				<field name="atm_composer_icon_s">
					<xsl:value-of select="substring-after(res:icon/@uri, '/')"/>
				</field>
			</xsl:for-each>
			<xsl:for-each select="xalan:nodeset($CONCERT_TF)/res:sparql/res:results/res:result">
				<field name="atm_facet_concert_title_ms">
					<xsl:value-of select="res:concertName/text()"/>
				</field>
				<field name="atm_facet_concert_cycle_ms">
					<xsl:value-of select="res:concertCycle/text()"/>
				</field>
			</xsl:for-each>
			
			<xsl:call-template name="digital_objects">
				<xsl:with-param name="objectType" select="'performance'"/>
				<xsl:with-param name="performance"/>
			</xsl:call-template>

		</doc>
	</xsl:template>
	
	<xsl:template name="atm_performer">
		<xsl:param name="pid" select="'no'"/> <!-- based on "performer pid" -->
		<xsl:param name="performance" select="'no'"/> <!-- based on "performance pid", and so on -->
		<xsl:param name="person" select="'no'"/>
		
		<xsl:variable name="PERFORMER_TF">
			<xsl:call-template name="perform_query">
				<xsl:with-param name="query">
					<xsl:value-of select="'
						select $concert $performerObj $person $personName $instrumentName $instrumentClassName $groupName $concertTitle $cycleName $pieceName $concertOrder from &lt;#ri&gt;
						where
					'"/>
					<!-- choose the performer docs to create depending on the input parameters -->
					<xsl:choose>
						<xsl:when test="not($pid='no')">
							<xsl:value-of select="concat('
								$performerObj &lt;mulgara:is&gt; &lt;fedora:', $pid, '
							')"/>
						</xsl:when>
						<xsl:when test="not($performance='no')">
							<xsl:value-of select="concat('
								$performance &lt;mulgara:is&gt; &lt;fedora:', $performance, '&gt;
							')"/>
						</xsl:when>
						<xsl:when test="not($person='no')">
							<xsl:value-of select="concat('
								$person &lt;mulgara:is&gt; &lt;fedora:', $person, '&gt;
							')"/>
						</xsl:when>
					</xsl:choose>
					<xsl:value-of select="concat('
						and $performerObj &lt;', $NAMESPACE, 'performance&gt; $performance
						and $performerObj &lt;', $NAMESPACE, 'player&gt; $person
						and $performerObj &lt;', $NAMESPACE, 'played&gt; $instrument
						and $performerObj &lt;fedora-rels-ext:isMemberOf&gt; $group
						and $performance &lt;fedora-rels-ext:isMemberOf&gt; $concert
						and $performance &lt;', $NAMESPACE, 'concertOrder&gt; $concertOrder
						and $concert &lt;fedora-model:label&gt; $concertTitle
						and $concert &lt;fedora-rels-ext:isMemberOf&gt; $concertCycle
						and $concertCycle &lt;fedora-model:label&gt; $cycleName
						and $person &lt;fedora-model:label&gt; $personName
						and $instrument &lt;fedora-model:label&gt; $instrumentName
						and $instrument &lt;fedora-rels-ext:isMemberOf&gt; $instrumentClass
						and $instrumentClass &lt;fedora-model:label&gt; $instrumentClassName
						and $group &lt;fedora-model:label&gt; $groupName
						and $performance &lt;', $NAMESPACE, 'basedOn&gt; $score
						and $score &lt;fedora-model:label&gt; $pieceName
					')"/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:for-each select="xalan:nodeset($PERFORMER_TF)/res:sparql/res:results/res:result">
			<doc>
				<field name="PID">
					<xsl:value-of select="substring-after(res:performerObj/@uri, '/')"/>
				</field>
				<field name="atm_type_s">Performer</field>
			
				<field name="atm_performer_name_s">
					<xsl:value-of select="normalize-space(res:personName/text())"/>
				</field>
				<field name="atm_performer_concert_pid_s">
					<xsl:value-of select="substring-after(res:concert/@uri, '/')"/>
				</field>
				<field name="atm_performer_instrument_s">
					<xsl:value-of select="normalize-space(res:instrumentName/text())"/>
				</field>
				<field name="atm_performer_instrument_class_s">
					<xsl:value-of select="normalize-space(res:instrumentClassName/text())"/>
				</field>
				<field name="atm_performer_group_s">
					<xsl:value-of select="normalize-space(res:groupName/text())"/>
				</field>
				<field name="atm_performer_concert_title_s">
					<xsl:value-of select="normalize-space(res:concertTitle/text())"/>
				</field>
				<field name="atm_performer_concert_cycle_s">
					<xsl:value-of select="normalize-space(res:cycleName/text())"/>
				</field>
				<field name="atm_performer_piece_title_s">
					<xsl:value-of select="normalize-space(res:pieceName/text())"/>
				</field>
				<field name="atm_performer_concert_order_s">
					<xsl:value-of select="normalize-space(res:concertOrder/text())"/>
				</field>
				<field name="atm_facet_group_s">
					<xsl:value-of select="normalize-space(res:groupName/text())"/>
				</field>
				<field name="atm_facet_concert_title_s">
					<xsl:value-of select="normalize-space(res:concertTitle/text())"/>
				</field>
				<field name="atm_facet_concert_cycle_s">
					<xsl:value-of select="normalize-space(res:cycleName/text())"/>
				</field>
				<field name="atm_facet_piece_title_s">
					<xsl:value-of select="normalize-space(res:pieceName/text())"/>
				</field>
				<!-- TODO: get the concert date from somewhere... -->
				<xsl:variable name="date" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
				$HOST, ':', $PORT, '/fedora/objects/', substring-after(res:concert/@uri, '/'), '/datastreams/CustomXML/content'))/Concierto/FECHA/text()"/>
				<xsl:if test="$date">
					<field name="atm_performer_date_dt">
						<xsl:value-of select="concat($date, 'Z')"/>
					</field>
					
					<!-- FIXME (minor): Really, this should be done through the use of date faceting in solr, based on the _dt above (an actual date/time value)...  Same for other instances of similar code (grabbing the year from the date) -->
					<field name="atm_performer_year_s">
						<xsl:value-of select="substring($date, 1, 4)"/>
					</field>
					<field name="atm_facet_year_s">
						<xsl:value-of select="substring($date, 1, 4)"/>
					</field>
				</xsl:if>
				
				<xsl:call-template name="rels_ext">
					<xsl:with-param name="pid" select="substring-after(res:performerObj/@uri, '/')"/>
				</xsl:call-template>
			</doc>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="digital_objects">
		<xsl:param name="objectType"/>
		<xsl:param name="performance"/>
		<xsl:param name="concert"/>
		
		<xsl:choose>
			<xsl:when test="objectType='performance'">
				<xsl:variable name="PERFORMANCE_TF">
					<xsl:call-template name="perform_query">
						<xsl:with-param name="query" select="concat('
							select $performance $score from &lt;#ri&gt;
							where $performance &lt;mulgara:is&gt; &lt;fedora:', $performance, '&gt;
							and $composer &lt;', $NAMESPACE, 'composed&gt; $score
							and $performance &lt;', $NAMESPACE, 'basedOn&gt; $score
							and $performance &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
						')"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:for-each select="xalan:nodeset($PERFORMANCE_TF)/res:sparql/res:results/res:result">
					<xsl:choose>
						<xsl:when test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $performance, '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='MP3']">
							<field name="atm_digital_objects_ms">Concert MP3</field>
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="MOVEMENT_TF">
								<!-- Could limit to one result here? -->
								<xsl:call-template name="perform_query">
									<xsl:with-param name="query" select="concat('
										select $movement from &lt;#ri&gt;
										where $performance &lt;mulgara:is&gt; &lt;fedora:', $performance, '&gt;
										and $movement &lt;fedora-rels-ext:isMemberOf&gt; $performance
										and $performance &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
									')"/>
								</xsl:call-template>
							</xsl:variable>
							<xsl:variable name="movement" select="substring-after(xalan:nodeset($MOVEMENT_TF)/res:sparql/res:results/res:result/res:movement[1]/@uri, '/')"/>
							<xsl:if test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $movement, '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='MP3']">
								<field name="atm_facet_digital_objects_ms">Concert MP3</field>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
					
					<xsl:if test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', substring-after(res:score/@uri, '/'), '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='PDF']">
						<field name="atm_facet_digital_objects_ms">Score PDF</field>
					</xsl:if>
				</xsl:for-each>
			</xsl:when>
		</xsl:choose>
			
			
	</xsl:template>
	
	<xsl:template name="perform_query">
		<xsl:param name="query" select="no_query"/>
		<xsl:param name="additional_params" select="''"/>
		
		<xsl:variable name="encoded_query">
			<xsl:call-template name="url-encode">
				<xsl:with-param name="str" select="normalize-space($query)"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="full_query" select="document(concat($RISEARCH, $encoded_query, $additional_params))"/>
		<xsl:comment>
			<xsl:value-of select="$full_query"/>
		</xsl:comment>
		<xsl:copy-of select="$full_query"/>
	</xsl:template>
	
	<xsl:template name="rels_ext">
		<xsl:param name="pid" select="'no_pid'"/>
		
		<xsl:variable name="RELS_EXT" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
				$HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/RELS-EXT/content'))"/>
		<xsl:for-each select="$RELS_EXT/rdf:RDF/rdf:Description/*">
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('rels_', local-name(), '_ms')"/>
				</xsl:attribute>
				<xsl:choose>
					<xsl:when test="@rdf:resource">
						<xsl:value-of select="substring-after(@rdf:resource, '/')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="text()"/>
					</xsl:otherwise>
				</xsl:choose>
			</field>
		</xsl:for-each>
	</xsl:template>
	
	<!-- Get the value of the labels for all performers of the piece -->
	<xsl:template name="correlate_group_membership">
		<xsl:param name="pid" select="no_pid"/>

		<xsl:variable name="QUERIED">
			<xsl:call-template name="atm_performer">
				<xsl:with-param name="performance" select="$pid"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:copy-of select="xalan:nodeset($QUERIED)"/>
	</xsl:template>
</xsl:stylesheet>
