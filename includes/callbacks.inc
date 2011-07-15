<?php

/**
 * Class containing functions and methods used in the collections at Fundacion Juan March
 */
class FJM {
    public $pid;
    
    function __construct($pid)
    {
        $this->pid = $pid;
        
        //A little hack to allow the datastream to be loaded directly
        {
            $opts = array(
                'http' => array(
                    'user_agent' => 'PHP libxml agent',
                )
            );

            $context = stream_context_create($opts);
            libxml_set_streams_context($context);
        }
    }
    
    /**
     * Performs the given ITQL query.
     * Might be duplicating code from the Fedora API (I seem to recall something
     *   but with a weird name).
     * 
     * FIXME: Could probably made more fail-safe (avoiding passing directly from the curl call to loadXML, for example.)
     *
     * @param String $query
     * @param Integer $limit
     * @param Integer $offset
     * @return DOMDocument 
     */
    static function performItqlQuery($query, $limit = -1, $offset = 0) {
        $queryUrl = variable_get('fedora_repository_url', 'http://localhost:8080/fedora/risearch');
        $queryUrl .= "?type=tuples&flush=TRUE&format=Sparql" . (($limit > 0)?("&limit=$limit"):("")) . "&offset=$offset&lang=itql&stream=on&query=" . urlencode($query);
        $doc = DOMDocument::loadXML(do_curl($queryUrl));
        return ((!$doc)?(new DOMDocument()):($doc));
    }
    
    /**
     *  May need a great deal more work...  Performs a basic solr query...
     *    Should probably pass in built arrays.
     * @param type $type
     * @param type $query
     * @param type $fields
     * @param type $type_field
     * @return type 
     */
    static function performSolrQuery($type, $query = "", $fields = "PID", $otherParams = array(), $type_field = "atm_type_s")
    {
        $solrUrl = variable_get('fedora_solr_search_url', 'http://localhost:8080/solr') . '/select?q=';
        $solrUrl .= urlencode($query) . '&fl=' . urlencode($fields);
        if(isset($otherParams['fq']))
        {
            $otherParams['fq'] = $otherParams['fq'] . " $type_field:\"$type\"";
        }
        foreach ($otherParams as $key => $value) {
            $solrUrl .= "&$key=" . urlencode($value);
        }
        if(is_callable("dsm"))
        {
            dsm($solrUrl);
        }
        $doc = DOMDocument::loadXML(do_curl($solrUrl));
        return ((!$doc)?(new DOMDocument()):($doc));
    }
    
    /**
     * Create a small "gallery viewer", with a large version of the image shown
     *   above, and a "filmstrip" of thumbnails of those images in the gallery
     *   shown below.
     * When clicked, the image in the thumbnail should be made to occupy where 
     *   the large one is, and if the large image is clicked, the image should 
     *   open in lightbox.
     * 
     * @param Array $image (Uses 'path', 'thumbnail' and 'alt' keys...)
     */
    static function showImageGallery($images, $attributes = array())
    {
        $first = TRUE;
        $output = '<div class="image_strip_group"';
        foreach($attributes as $attribute => $value)
        {
            $output .= $attribute . "=\"" . $value . "\"";
        }
        $output .= '>';
        
        foreach ($images as $image) {
            //Fill/create the large image on top with the first image.
            if($first) {
                $first = FALSE;
                $output .= '  <a href="' . $image['path'] .'" rel="lightbox" id="image_strip_link">
                        <img id="image_strip_big" src="' . $image['path'] . '"
                            alt="' . $image['alt'] . '"/>
                      </a>';
                $output .= '  <ul class="image_strip">';
            }
            
            //Add the image to the list of images.
            $output .= '<li>
                <img src="' . $image['thumbnail'] . '" alt="' . 
                $image['alt'] . '" path="' . $image['path'] . '"/>
                </li>';
        }
        $output .= '  </ul>';
        $output .= '</div>';
        
        //Jquery to make images in the "filmstrip" populate the large box on top when clicked
        $output .= '<script type="text/javascript">';
        $output .= '  $("ul.image_strip > li > img").click(function () {
                        $("#image_strip_big").attr("src", $(this).attr("path"));
                        $("#image_strip_big").attr("alt", $(this).attr("alt"));
                        $("#image_strip_link").attr("href", $(this).attr("path"));
                      });';
        $output .= '</script>';
        
        //Make the filmstrip and lightbox work.
        jcarousel_add("image_strip", array('start' =>  "1", 'wrap' => "both", 'visible' => 3, 'vertical' => FALSE, 'itemFallbackDimension' => 300));
        lightbox2_add_files();
        
        return $output;
    }
    
    /**
     * Finds the images which are related to the current PID. (used to populate
     *   the "filmstrip" in the image gallery)
     * @param Array $defaultImage ('path' => "path_to_image", 'alt' => "alt_text", 'thumbnail' => "path_to_thumbnail
     * @return Array (Similar format to the input)
     */
    function getRelatedImages($defaultImage = NULL)
    {
        $fedoraPath = variable_get('fedora_base_url', 'http://localhost:8080/fedora');
        $iconQuery = ''
            . 'select $label $icon from <#ri>'
            . 'where ($icon <http://www.example.org/dummy#isIconOf> <fedora:' . $this->pid . '>'
            . ' or $icon <http://www.example.org/dummy#isImageOf> <fedora:' . $this->pid . '>)'
            . 'and $icon <fedora-model:label> $label;';
        $queryResult = FJM::performItqlQuery($iconQuery);
        
        //Get all the result elements, and iterate through them.
        $elements = $queryResult->getElementsByTagName('result');
        $images = array();
        if($elements->length > 0) {
        for($i=0; $i < $elements->length; $i++) {
                //Get the icon element from the search results
                $resultElement = $elements->item($i);
                $iconElement = $resultElement->getElementsByTagName('icon')->item(0);
                $altElement = $resultElement->getElementsByTagName('label')->item(0);

                //Get the PID from the icon element, and the alttext similarly
                $imagePid = substr($iconElement->attributes->getNamedItem('uri')->textContent, 12);
                $altText = $altElement->textContent;
                if(!empty($imagePid))
                {
                    $images[] = array(
                        'path' => url("fedora/repository/$imagePid/JPG"),
                        'thumbnail' => url("fedora/repository/$imagePid/TN"),
                        'alt' => ($altText)
                    );
                }
            }
        }
        elseif(isset($defaultImage)) {
            $images[] = $defaultImage;
        }
        
        return $images;
    }
    
    /**
     * Pagenumber isn't really used...
     * Should I actually check the content model?
     * 
     * TODO:  Make it language aware (Select different fields from the EAC-CPF based on language)
     * TODO:  Might want to make it verify the content model.
     */
    function showPerson($pagenumber = NULL) {
        $output = '';
        $fedoraPath = variable_get('fedora_base_url', 'http://localhost:8080/fedora');

        $eacdoc = DOMDocument::load("$fedoraPath/objects/"
          . $this->pid . "/datastreams/EAC-CPF/content");
        $eaccpf = new DOMXPath($eacdoc);
      
        $name = $eaccpf->evaluate('string(/eac-cpf/cpfDescription/identity/nameEntry/part[@localType="first"])')
                . ' ' . $eaccpf->evaluate('string(/eac-cpf/cpfDescription/identity/nameEntry/part[@localType="last"])');
        $date_birth = $eaccpf->evaluate('string(/eac-cpf/cpfDescription/description/existDates/dateRange/fromDate/@standardDate)');
        $date_death = $eaccpf->evaluate('string(/eac-cpf/cpfDescription/description/existDates/dateRange/toDate/@standardDate');
        $daterange = ((!empty($date_birth) || $date_death !== FALSE) ? ($date_birth) : ('unknown'))
                . ' - ' . ((!empty($date_death) || $date_death !== FALSE) ? ($date_death) : ('present/unknown'));
        
        //TODO:  The XPath return the full text (including child tags) to maintain biography formatting...  Really, should probably run an XSLT
        $bioNode = $eaccpf->evaluate('/eac-cpf/cpfDescription/description/biogHist')->item(0);

        $biography = ((empty($bioNode))?(t('No biography entered')):($eacdoc->saveXML($bioNode)));
       
        $output .= FJM::showImageGallery($this->getRelatedImages(), array('style'=>"float: left;"));
        
        $output .= '<div class="fjm_person_header">';
        $output .= t('<div class="fjm_person_name">@name</div> ', array('@name' => $name));
        $output .= t('<div class="fjm_person_dates">(@daterange)</div>', array('@daterange' => $daterange));
        $output .= "</div>";
        
        //$biography, if properly valid XML should only contain a few different element types, as defined in the EAC-CPF schema...
        $output .= '<div class="fjm_person_bio">';
        $output .= t('!biography', array('!biography' => $biography));
        $output .= '</div>';
        
        $output .= '<div class="fjm_piece_list">';
        $output .=   'Build a "playable" list of pieces...?';
        $output .= '</div>';
        
        return $output;
    }
    
    /**
     *
     * @param type $pagenumber
     * @return string 
     */
    function showConcert($pagenumber = NULL) {
        $ouput = '';
        $fedoraPath = variable_get("fedora_base_url", 'http://localhost:8080/fedora');
        $islandoraPath = drupal_get_path("module", "islandora_fjm");
        $base = $islandoraPath . "/flowplayer";
        drupal_add_js("$base/flowplayer-3.2.6.min.js");
        drupal_add_js("$base/flowplayer.playlist-3.0.8.js");
        drupal_add_css("$islandoraPath/css/islandora_fjm_playlist.css");
        
        $concertTitle = "This is a concert...";
        $concertCycle = "Awesome concerts by awesome people";
        //$concertDate = "tomorrow?";
        $concertDescription = "Description goes here... Lorem ipsum dolor sit amet,
            consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore
            et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation 
            ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure 
            dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat 
            nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt 
            in culpa qui officia deserunt mollit anim id est laborum.";
        $concertProgram = "the pid"; //To make a link to the program.
        $concertResults = FJM::performSolrQuery("Concert", "", 
                "PID,atm_concert_title_s,atm_concert_cycle_s,atm_concert_date_dt", 
                array('fq' => "PID:\"$this->pid\""));
        /*$concertResults = FJM::performItqlQuery('
            select $concertTitle $cycleName from <#ri>
            where $concert <mulgara:is> <fedora:' . $this->pid .'>
            and $concert <fedora-model:label> $concertTitle
            and $concert <fedora-rels-ext:isMemberOf> $cycle
            and $cycle <fedora-model:label> $cycleName
        ', 1);*/
        $concert_xpath = new DOMXPath($concertResults);
        
        $concertTitle = $concert_xpath->evaluate("string(normalize-space(/response/result[@name='response']/doc/str[@name='atm_concert_title_s']/text()))");
        $concertCycle = $concert_xpath->evaluate("string(normalize-space(/response/result[@name='response']/doc/str[@name='atm_concert_cycle_s']/text()))");
        
        $concertDate = new DateTime($concert_xpath->evaluate("string(normalize-space(/response/result[@name='response']/doc/date[@name='atm_concert_date_dt']/text()))"));
        /*$performanceResults = FJM::performItqlQuery('
            select $performance $pieceName $composerName $porder
              subquery(
                select $movement $order from <#ri>
                where $movement <fedora-rels-ext:isMemberOf> $performance
                and $movement <http://www.example.org/dummy#pieceOrder> $order
                order by $order asc
              )
            from <#ri>
            where $performance <fedora-rels-ext:isMemberOf> <fedora:' . $this->pid . '>
            and $performance <fedora-model:hasModel> <fedora:atm:performanceCModel>
            and $performance <http://www.example.org/dummy#basedOn> $score
            and $score <fedora-model:label> $pieceName
            and $composer <http://www.example.org/dummy#composed> $score
            and $composer <fedora-model:label> $composerName
            and $performance <fedora-model:state> <fedora-model:Active>
            and $performance <http://www.example.org/dummy#concertOrder> $porder
            order by $porder asc
        ');*/
        $performanceResults = FJM::performSolrQuery("Performance", "", 
                "PID,atm_performance_piece_title_s,atm_performance_composer_name_s,atm_performance_score_pdf_b,atm_performance_mp3_b,rels_basedOn_ms,atm_performance_movement_ms",
                array('fq' => "rels_isMemberOf_ms:\"$this->pid\""));
        $lectureResults = FJM::performItqlQuery('
            select $lecture $title from <#ri>
            where $lecture <fedora-rels-ext:isMemberOf> <fedora:' . $this->pid . '>
            and $lecture <fedora-model:label> $title
            and $lecture <fedora-model:hasModel> <fedora:atm:lectureCModel>
            and $lecture <fedora-model:state> <fedora-model:Active>');
        $performance_xpath = new DOMXPath($performanceResults);
        $lect_xpath = new DOMXPath($lectureResults);
        $lect_xpath->registerNamespace("r", "http://www.w3.org/2001/sw/DataAccess/rf1/result");
        $performance_array = array();
        $lecture_array = array();
        foreach($performance_xpath->query("/response/result[@name='response']/doc") as $node)
        {
            $pid = $performance_xpath->evaluate("string(str[@name='PID']/text())", $node);
            $pieceName = $performance_xpath->evaluate("string(str[@name='atm_performance_piece_title_s']/text())", $node);
            $composerName = $performance_xpath->evaluate("string(str[@name='atm_performance_composer_name_s']/text())", $node);
            $localscore = $performance_xpath->evaluate("string(str[@name='rels_basedOn_s'])", $node);
            $localpdfscore = (($performance_xpath->evaluate("string(bool[@name='atm_performance_score_pdf_b']/text())", $node) == 'true')?($localscore):(false));
            //TODO: Solr query could could be expensive...  Might be well off making in only perform one additional query...
            $q2 = FJM::performSolrQuery("Score", "", "atm_score_titn_s,PID", array('fq' => "PID:\"" . $localscore ."\""));
            $s_results = new DOMXPath($q2);
            $libraryscore = $s_results->evaluate("string(/response/result[@name='response']/doc/str[@name='atm_score_titn_s'])");
            
            $mp3_stat = ($performance_xpath->evaluate("string(bool[@name='atm_performance_mp3_b']/text())", $node) == 'true');
            $performance_array[] = array(
                'data' => array(
                    $pieceName,
                    $composerName,
                    //TODO: Should probably make the URLs easier to change...  The drupal/fedora 
                    //  beginning should be obtained from the module, and the titn base address
                    //  should be configurable
                    (($localpdfscore)?(l("Score", "fedora/repository/" . $localpdfscore)):("")),
                    (($libraryscore != "-1")?(l("Score in library", "http://www.march.es/abnopac/abnetcl.exe?ACC=DOSEARCH&xsqf01=" . $libraryscore)):("")),
                    array(
                        'data' => (($mp3_stat)?
                            ('<div class="atm_track">' . l("<!-- placeholder -->", "fedora/repository/$pid/MP3", array("html" => true)) . '</div>'):
                            ("<!-- MP3 should be in movements -->")),
                        'style' => 'float:right;'
                    )
                )
            );
            
            //FIXME:  Assumption is made that if an MP3 exists at the performance level, then
            //  the movements will not contain an MP3 (and vice-versa)
            foreach($performance_xpath->query("arr[@name='atm_performance_movement_ms']/str", $node) as $mov_node)
            {
                $mov_pid = $performance_xpath->evaluate("string(text())", $mov_node);
                $mov_results = new DOMXPath(FJM::performItqlQuery('
                        select $name from <#ri>
                        where $movement <mulgara:is> <fedora:' . $mov_pid .'>
                        and $movement <fedora-model:label> $name;
                ', 1));
                $mov_results->registerNamespace("r", "http://www.w3.org/2001/sw/DataAccess/rf1/result");
                //Add the movements.
                $performance_array[] = array(
                    array(
                        'data' => $mov_results->evaluate("string(/r:sparql/r:results/r:result/r:name/text())"),
                        'colspan' => '4'
                    ),
                    array(
                        'data' => (($mp3_stat)?
                                ("<!-- MP3 should be in performance -->"):
                                ('<div class="atm_track">' . l("<!-- placeholder -->", "fedora/repository/$mov_pid/MP3", array("html" => true)) . '</div>'))
                    )
                );
            }
        }
        foreach($lect_xpath->query("/r:sparql/r:results/r:result") as $node)
        {
            $pid = $lect_xpath->evaluate("substring-after(r:lecture/@uri, '/')", $node);
            $title = $lect_xpath->evaluate("string(r:title/text())", $node);
            $lecture_array[] = array(
                $title,
                array(
                    'data' => ('<div class="atm_track">' . l("<!-- placeholder -->", "fedora/repository/$pid/MP3", array("html" => true)) . '</div>'),
                    'style' => 'float:right;'
                )
            );
        }
        $perf_header = array(
            array(
                'data' => t("Piece")
            ),
            array(
                'data' => t("Composer")
            ),
            array(
                'data' => t("Score")
            ), //Score in Fedora Repo
            array(
                'data' => t("Biblio")
            ),   //Score in Library
            array(
                //Playable track...
                'data' => "",
            )
        );
        $lect_header = array(
            array(
                'data' => t("Title")
            ),
            array(
                'data' => ""
            )
        );
        
        
        $output .= '<div class="atm_concert_title">' . $concertTitle . '</div>';
        $output .= '<div class="atm_concert_top">';
        $output .=   FJM::showImageGallery($this->getRelatedImages(), array('style'=>"float: left; margin: 10px;"));
        $output .=   '<div class="atm_concert_top_right">';
        $output .=     '<div class="atm_concert_cycle">' . $concertCycle . '</div>';
        $output .=     '<div class="atm_concert_date">' . ($concertDate->format("Y/m/d")) . '</div>';
        $output .=     '<div class="atm_concert_description">' . $concertDescription . '</div>';
        $output .=   '</div><!--atm_con_top_right -->';
        $output .= '</div><!--atm_con_top -->';
        $output .= '<div class="atm_concert_bottom">';
        $output .=  '<div class="atm_concert_bottom_left">';
        if(sizeof($performance_array) > 0)
            $output .= theme('table', $perf_header, $performance_array, array('class' => 'atm_concert_performance_table'));
        if(sizeof($lecture_array) > 0)
            $output .= theme('table', $lect_header, $lecture_array, array('class' => 'atm_concert_lecture_table'));
        $output .=  '</div><!--bottom left-->';

        $output .= '
            <a class="player" id="atm_player"><!--FlowPlayer goes here --></a>';
        
        //TODO: Get the protocol automatically; this would break if SSL were required...
        //  Then again, is this really required?
        $hostname = 'http://' . $_SERVER['HTTP_HOST'];
        $output .= '
            <script type="text/javascript">
                $(function() {
                    $f("atm_player", "/' . $base . '/flowplayer-3.2.7.swf", {
                        plugins: {
                            controls: {
                                all: false,
                                autoHide: false,
                                scrubber: true,
                                time: true,
                                height: 30
                            }
                        },
                        clip: {
                            baseUrl: "'. $hostname .'",
                            autoPlay: false
                        }
                    }).playlist("div.atm_track", {
                        loop: true,
                        playingClass: "atm_playing",
                        pausedClass: "atm_paused",
                        progressClass: "atm_buffering"
                    });
                });
            </script>';
        $output .= '</div><!-- bottom -->';
        
        return $output;
    }
}
