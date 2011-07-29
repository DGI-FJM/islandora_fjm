<?php

/**
 * @file
 * Callbacks and a few utility functions used in the ATM collection.
 * Class containing functions and methods used in the collections at Fundacion Juan March
 */
class FJM {
    public $pid;
    
    function __construct($pid) {
        $this->pid = $pid;
        FJM::userAgentHack();
    }
    
    /**
     * A little hack to allow the datastream to be loaded directly
     */
    static function userAgentHack() {
        static $hacked = FALSE;
        if (!$hacked) {
            $opts = array(
                'http' => array(
                    'user_agent' => 'PHP libxml agent',
                )
            );

            $context = stream_context_create($opts);
            libxml_set_streams_context($context);
            $hacked = TRUE;
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
        FJM::userAgentHack();
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
     * @return DOMDocument 
     */
    static function performSolrQuery($type, $query = "", $fields = "PID", $otherParams = array(), $type_field = "atm_type_s") {
        FJM::userAgentHack();
        $solrUrl = variable_get('fedora_solr_search_url', 'http://localhost:8080/solr') . '/select?q=';
        $solrUrl .= urlencode($query) . '&fl=' . urlencode($fields);
        if (isset($otherParams['fq'])) {
            $otherParams['fq'] = $otherParams['fq'] . " $type_field:\"$type\"";
        }
        foreach ($otherParams as $key => $value) {
            $solrUrl .= "&$key=" . urlencode($value);
        }
        $doc = DOMDocument::loadXML(do_curl($solrUrl));
        if (is_callable("dsm")) {
            dsm($solrUrl);
            $error = error_get_last();
            if (!empty($error)) {
                dsm($error);
            }
        }
        return ((!$doc)?(new DOMDocument()):($doc));
    }
    
    //Version getting rid of the "type" stuff...  Got a little too specific.
    static function performSolrQ($query, $fields = "PID",
            $otherParams = array()) {
        FJM::userAgentHack();
        $solrUrl = variable_get('fedora_solr_search_url', 'http://localhost:8080/solr') . '/select?q=';
        $solrUrl .= urlencode($query) . '&fl=' . urlencode($fields);
        foreach ($otherParams as $key => $value) {
            $solrUrl .= "&$key=" . urlencode($value);
        }
        $doc = DOMDocument::loadXML(do_curl($solrUrl));
        if (is_callable("dsm")) {
            dsm($solrUrl);
            $error = error_get_last();
            if (!empty($error)) {
                dsm($error);
            }
        }
        
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
    static function showImageGallery($images, $attributes = array()) {
        //FJM::userAgentHack();
        $first = TRUE;
        $output = '<div class="image_strip_group"';
        foreach ($attributes as $attribute => $value) {
            $output .= $attribute . "=\"" . $value . "\"";
        }
        $output .= '>';
        
        foreach ($images as $image) {
            //Fill/create the large image on top with the first image.
            if ($first) {
                $first = FALSE;
                $output .= '  <a href="' . $image['path'] .'" rel="lightbox" id="image_strip_link">
                        <img id="image_strip_big" src="' . $image['path'] . '"
                            alt="' . $image['alt'] . '"/>
                      </a>';
                $output .= '  <ul class="image_strip">';
            }
            
            //Add the image to the list of images.
            if (sizeof($images) > 1) {
                $output .= '<li>
                    <img src="' . $image['thumbnail'] . '" alt="' . 
                    $image['alt'] . '" path="' . $image['path'] . '"/>
                    </li>';
            }
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
        if (sizeof($images) > 1)
            jcarousel_add("image_strip", array('start' =>  "1", 'wrap' => "both", 'visible' => 3, 'vertical' => FALSE, 'itemFallbackDimension' => 300));
        lightbox2_add_files();
        
        return $output;
    }
    
    static function addPlayer($selector = 'div.atm_track') {
        //FJM::userAgentHack();
        $islandoraPath = drupal_get_path("module", "islandora_fjm");
        $base = $islandoraPath . "/flowplayer";
        drupal_add_js("$base/flowplayer-3.2.6.min.js");
        drupal_add_js("$base/flowplayer.playlist-3.0.8.js");
        $toReturn = '
        <a class="player" id="atm_player"></a>';

        //TODO: Get the protocol automatically; this would break if SSL were required...
        //  Then again, is this really required?
        $hostname = 'http://' . $_SERVER['HTTP_HOST'];
        $toReturn .= '<script type="text/javascript">
            $(function() {
                $f("atm_player", "/' . $base . '/flowplayer-3.2.7.swf", {
                    plugins: {
                        controls: {
                            all: false,
                            //Play button here is a Bad Idea (also happens to avoid a bug:
                            //  When the player\' play button was clicked first, 
                            //  the CSS was not being changed, and as such the icons 
                            //  for tracks were not changing; however, if the track icon was
                            //  clicked first, then the button in the player would
                            //  work to change the CSS)
                            //play: true,
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
                }).playlist("' . $selector . '", {
                    loop: true,
                    playingClass: "atm_playing",
                    pausedClass: "atm_paused",
                    progressClass: "atm_buffering"
                });
            });
        </script>';

        return $toReturn;
    }
    
    function addViewer($dsid = 'SWF') {
        $base = drupal_get_path("module", "islandora_fjm") . '/flexpaper';
        drupal_add_js("$base/js/flexpaper_flash.js");
        $output = '<div id="flexpaper">
            <a id="viewer" style="width: 700px; height: 400px; display: block;"></a>
            <script type="text/javascript">
                var fp = new FlexPaperViewer(
                    "/' . $base .'/FlexPaperViewer",
                    "viewer",
                    {
                        config : {
                            SwfFile: "http://' . $_SERVER['HTTP_HOST'] . url("fedora/repository/$this->pid/$dsid") . '",
                            Scale : 0.6,
                            ZoomTransition : "easeOut",
                            ZoomTime : 0.5,
                            ZoomInterval : 0.1,
                            FitPageOnLoad : false,
                            FitWidthOnLoad : true,
                            PrintEnabled : false,
                            FullScreenAsMaxWindow : true,
                            ProgressiveLoading : true,
                            MinZoomSize : 0.2,
                            MaxZoomSize : 5,
                            SearchMatchAll : false,
                            InitViewMode : \'Portrait\',

                            ViewModeToolsVisible : true,
                            ZoomToolsVisible : true,
                            NavToolsVisible : true,
                            CursorToolsVisible : true,
                            SearchToolsVisible : true,

                            localeChain : "en_US"

                        }
                    }
                );
            </script>
        </div>';
        return $output;
    }
    
    static function getRelatedImagesByPid($pid, $defaultImage = NULL, $dsid = 'JPG', $tndsid = 'TN') {
        $fedoraPath = variable_get('fedora_base_url', 'http://localhost:8080/fedora');

        $queryResult = FJM::performItqlQuery('
            select $label $icon from <#ri>
            where (
                $icon <http://www.example.org/dummy#isIconOf> <fedora:' . $pid . '>
                or $icon <http://www.example.org/dummy#isImageOf> <fedora:' . $pid . '>
            )
            and $icon <fedora-model:label> $label
        ;');
        
        //Get all the result elements, and iterate through them.
        $elements = $queryResult->getElementsByTagName('result');
        $images = array();
        if ($elements->length > 0) {
            for ($i=0; $i < $elements->length; $i++) {
                //Get the icon element from the search results
                $resultElement = $elements->item($i);
                $iconElement = $resultElement->getElementsByTagName('icon')->item(0);
                $altElement = $resultElement->getElementsByTagName('label')->item(0);

                //Get the PID from the icon element, and the alttext similarly
                $imagePid = substr($iconElement->attributes->getNamedItem('uri')->textContent, 12);
                $altText = $altElement->textContent;
                if (!empty($imagePid)) {
                    $images[] = array(
                        'path' => url("fedora/repository/$imagePid/$dsid"),
                        'thumbnail' => url("fedora/repository/$imagePid/$tndsid"),
                        'alt' => ($altText)
                    );
                }
            }
        }
        elseif (isset($defaultImage)) {
            $images[] = array(
                'path' => "$defaultImage/$dsid",
                'thumbnail' => "$defaultImage/$tndsid",
                'alt' => t("Default Image")
            );
        }
        
        return $images;
    }

    /**
     * Finds the images which are related to the current PID. (used to populate
     *   the "filmstrip" in the image gallery)
     * @deprecated Shouldn't have to call this with the use of theme functions.
     * @param Array $defaultImage ('path' => "path_to_image", 'alt' => "alt_text", 'thumbnail' => "path_to_thumbnail
     * @return Array (Similar format to the input)
     */
    function getRelatedImages($defaultImage = NULL) {
        return FJM::getRelatedImagesByPid($this->pid, $defaultImage);
    }
    
    /**
     * Pagenumber isn't really used...
     * Should I actually check the content model?
     * 
     * TODO:  Make it language aware (Select different fields from the EAC-CPF based on language)
     * TODO:  Might want to make it verify the content model.
     */
    function showPerson($pagenumber = NULL) {
        /*$output = '';
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
        
        return $output;*/
        return theme('islandora_fjm_atm_person', $this->pid);
    }
    
    /**
     *
     * @param String $pagenumber Used as a bit of a hack to determine which song to start playing, if set.
     * @return string 
     */
    function showConcert($pagenumber = NULL) {
        if (is_callable("dsm"))
            dsm($pagenumber);
        //$ouput = theme('islandora_fjm_atm_concert', $this->pid);
        //*
        $output = '';
        $fedoraPath = variable_get("fedora_base_url", 'http://localhost:8080/fedora');
        $islandoraPath = drupal_get_path("module", "islandora_fjm");
        $base = $islandoraPath . "/flowplayer";
        drupal_add_css("$islandoraPath/css/islandora_fjm_playlist.css");
        
        $concertTitle = "This is a concert...";
        $concertCycle = "Awesome concerts by awesome people";
        $concertDescription = "Description goes here... Lorem ipsum dolor sit amet,
            consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore
            et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation 
            ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure 
            dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat 
            nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt 
            in culpa qui officia deserunt mollit anim id est laborum.";
        $concertProgram = "the pid"; //To make a link to the program.
        $concertResults = FJM::performSolrQuery("Concert", "PID:\"$this->pid\"", 
                "PID,atm_concert_title_s,atm_concert_cycle_s,atm_concert_date_dt", 
                array());
        $concert_xpath = new DOMXPath($concertResults);

        $performanceResults = FJM::performSolrQuery("Performance", "rels_isMemberOf_ms:\"$this->pid\"+atm_type_s:\"Performance\"", 
                "PID,atm_performance_piece_title_s,atm_performance_composer_name_s,atm_performance_score_pdf_b,atm_performance_mp3_b,rels_basedOn_ms,atm_performance_movement_ms,atm_performance_composer_pid_s,rels_concertOrder_ms",
                array());
        $lectureResults = FJM::performItqlQuery('
            select $lecture $title $order from <#ri>
            where $lecture <fedora-rels-ext:isMemberOf> <fedora:' . $this->pid . '>
            and $lecture <fedora-model:label> $title
            and $lecture <fedora-model:hasModel> <fedora:atm:lectureCModel>
            and $lecture <fedora-model:state> <fedora-model:Active>
            and $lecture <http://www.example.org/dummy#concertOrder> $order
            order by $order asc
        ');
        $performance_xpath = new DOMXPath($performanceResults);
        $lect_xpath = new DOMXPath($lectureResults);
        $lect_xpath->registerNamespace("r", "http://www.w3.org/2001/sw/DataAccess/rf1/result");
        
        $concertTitle = $concert_xpath->evaluate("string(normalize-space(/response/result[@name='response']/doc/str[@name='atm_concert_title_s']/text()))");
        $concertCycle = $concert_xpath->evaluate("string(normalize-space(/response/result[@name='response']/doc/str[@name='atm_concert_cycle_s']/text()))");
        $concertDate = new DateTime($concert_xpath->evaluate("string(normalize-space(/response/result[@name='response']/doc/date[@name='atm_concert_date_dt']/text()))"));
        
        $performance_array = array();
        $lecture_array = array();
        foreach ($performance_xpath->query("/response/result[@name='response']/doc") as $node) {
            $pid = $performance_xpath->evaluate("string(str[@name='PID']/text())", $node);
            $pieceName = $performance_xpath->evaluate("string(str[@name='atm_performance_piece_title_s']/text())", $node);
            $composerPid = $performance_xpath->evaluate("string(str[@name='atm_performance_composer_pid_s']/text())", $node);
            $composerName = $performance_xpath->evaluate("string(str[@name='atm_performance_composer_name_s']/text())", $node);
            $localscore = $performance_xpath->evaluate("string(arr[@name='rels_basedOn_ms']/str/text())", $node);
            $localpdfscore = (($performance_xpath->evaluate("string(bool[@name='atm_performance_score_pdf_b']/text())", $node) == 'true')?($localscore):(false));
            $concertOrder = $performance_xpath->evaluate("string(arr[@name='rels_concertOrder_ms']/str[1]/text())", $node);

            //TODO: Solr query could could be expensive...  Might be well off 
            //  making in only perform one additional query...  Or, make it a
            //  subquery in Solr?
            $q2 = FJM::performSolrQuery("Score", "PID:\"" . $localscore ."\"", "atm_score_titn_s,PID", array());
            $s_results = new DOMXPath($q2);
            $libraryscore = $s_results->evaluate("string(/response/result[@name='response']/doc/str[@name='atm_score_titn_s']/text())");
            $mp3_stat = ($performance_xpath->evaluate("string(bool[@name='atm_performance_mp3_b']/text())", $node) == 'true');
            $performance_array[] = array(
                array(
                    'data' => $pieceName,
                    'colspan' => '2'    //
                ),
                array(
                    'data' => l($composerName, "fedora/repository/$composerPid")
                ),
                //TODO: Should probably make the URLs easier to change...  
                //  the titn base address should be configurable
                array(
                    'data' => (($localpdfscore)?(l("PDF", "fedora/repository/" . $localpdfscore)):(t("N/A")))
                ),
                array(
                    'data' => (($libraryscore != "-1")?(l(t("Go"), "http://www.march.es/abnopac/abnetcl.exe?ACC=DOSEARCH&xsqf01=" . $libraryscore . ".titn.")):(t("N/A")))
                ),
                array(
                    'data' => (($mp3_stat)?
                        ('<div class="atm_track concertOrder_' . $concertOrder . '">' . l("<!-- placeholder -->", "fedora/repository/$pid/MP3", array("html" => TRUE)) . '</div>'):
                        ("<!-- MP3 should be in movements -->"))
                )
            );
            
            $movements = new DOMXPath(FJM::performItqlQuery('
                select $movement $name $concertOrder $pOrder from <#ri>
                where $performance <mulgara:is> <fedora:' . $pid . '>
                and $movement <fedora-rels-ext:isMemberOf> $performance
                and $movement <fedora-model:label> $name
                and $performance <http://www.example.org/dummy#concertOrder> $concertOrder
                and $movement <http://www.example.org/dummy#pieceOrder> $pOrder
                order by $concertOrder asc $pOrder asc
            '));
            $movements->registerNamespace("r", "http://www.w3.org/2001/sw/DataAccess/rf1/result");
            
            //FIXME:  Assumption is made that if an MP3 exists at the performance level, then
            //  the movements will not contain an MP3 (and vice-versa)
            //FIXME:  Assumption is made that the results in the field will be in order...  May nt be the case.
            foreach ($movements->query("/r:sparql/r:results/r:result") as $mov_node) {
                $mov_pid = $movements->evaluate("substring-after(r:movement/@uri, '/')", $mov_node);
                
                //Add the movements.
                $performance_array[] = array(
                    array(  //Empty cell to enforce indentation
                        'data' => ""
                    ),
                    array(
                        'data' => $movements->evaluate("string(r:name/text())", $mov_node),
                        'colspan' => "4"
                    ),
                    array(
                        'data' => (($mp3_stat)?
                            ("<!-- MP3 should be in performance -->"):
                            ('<div class="atm_track concertOrder_' . $concertOrder . '">' . l("<!-- placeholder -->", "fedora/repository/$mov_pid/MP3", array("html" => TRUE)) . '</div>'))
                    )
                );
            }
        }
        
        foreach ($lect_xpath->query("/r:sparql/r:results/r:result") as $node) {
            $pid = $lect_xpath->evaluate("substring-after(r:lecture/@uri, '/')", $node);
            $title = $lect_xpath->evaluate("string(r:title/text())", $node);
            $concertOrder = $lect_xpath->evaluate("string(r:order/text())", $node);
            $lecture_array[] = array(
                $title,
                array(
                    'data' => ('<div class="atm_track concertOrder_' . $concertOrder . '">' . l("<!-- placeholder -->", "fedora/repository/$pid/MP3", array("html" => TRUE)) . '</div>'),
                    'style' => 'float:right;'
                )
            );
        }
        $perf_header = array(
            array(
                'data' => t("Piece")   
            ),
            array(  //To allow indentation "enforcement" for movements...
                'data' => "",
                'width' => '75'
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
        
        
        $output .= '<h2 class="atm_concert_title">' . $concertTitle . '</h2>';
        $output .= '<div class="atm_concert_top">';
        $output .=   FJM::showImageGallery($this->getRelatedImages(), array('style' => "float: left; margin: 10px;"));
        $output .=   '<div class="atm_concert_top_right">';
        $output .=     '<h3 class="atm_concert_cycle">' . $concertCycle . '</h3>';
        $output .=     '<div class="atm_concert_date">' . ($concertDate->format("Y/m/d")) . '</div>';
        $output .=     '<p class="atm_concert_description">' . $concertDescription . '</p>';
        $output .=   '</div><!--atm_con_top_right -->';
        $output .= '</div><!--atm_con_top -->';
        $output .= '<div class="atm_concert_bottom">';
        $output .=  '<div class="atm_concert_bottom_left">';
        if (sizeof($performance_array) > 0)
            $output .= theme('table', $perf_header, $performance_array, array('class' => 'atm_concert_performance_table'));
        if (sizeof($lecture_array) > 0)
            $output .= theme('table', $lect_header, $lecture_array, array('class' => 'atm_concert_lecture_table'));
        if (sizeof($performance_array) + sizeof($lecture_array) > 0)
            $output .= FJM::addPlayer('div.atm_track');
        
        $output .=  '</div><!--bottom left-->';

        
        if (isset($pagenumber) && $pagenumber > 0) {
            $output .= '
                <script type="text/javascript">
                    $(function() {$(".concertOrder_' . $pagenumber . ':first > a").click()});
                </script>
            ';
        }
        
        $output .= '</div><!-- bottom -->';
        //*/
        
        return $output;
    }
    
    //TODO: Cleanup ((Rather) Bad variable names)
    //TODO:  Need to add link with Titn
    function showScore($pagenumber = NULL) {
        return theme('islandora_fjm_atm_score', $this->pid);
    }
    
    function showProgram($pagenumber = NULL) {
        return theme('islandora_fjm_atm_program', $this->pid);
    }
}
