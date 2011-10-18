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
     * Performs the given RI query.
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
    static function __performRIQuery($query, $type = 'itql', $limit = -1, $offset = 0) {
        FJM::userAgentHack();
        $queryUrl = variable_get('fedora_repository_url', 'http://localhost:8080/fedora/risearch');
        $queryUrl .= "?type=tuples&flush=TRUE&format=Sparql" . (($limit > 0)?("&limit=$limit"):("")) . "&offset=$offset&lang=$type&query=" . urlencode($query);
        $doc = DOMDocument::loadXML(do_curl($queryUrl));
        if(is_callable('dsm'))
            dsm($query);
        return ((!$doc)?(new DOMDocument()):($doc));
    }
    static function performItqlQuery($query, $limit = -1, $offset = 0) {
        return FJM::__performRIQuery($query, 'itql', $limit, $offset);
    }  
    static function performSparqlQuery($query, $limit = -1, $offset = 0) {
        return FJM::__performRIQuery($query, 'sparql', $limit, $offset);
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
        //$hostname = 'http://' . $_SERVER['HTTP_HOST'];
        global $base_url;
        $hostname = $base_url;
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
                    progressClass: "atm_buffering",
                    manual: true
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

        $queryResult = FJM::performSparqlQuery('
            PREFIX atm-rel: <http://digital.march.es/atmusica#>
            PREFIX dc: <http://purl.org/dc/elements/1.1/>
            SELECT $label $icon
            FROM <#ri>
            WHERE {
                {
                    $icon atm-rel:isIconOf $obj
                }
                UNION
                {
                    $icon atm-rel:isImageOf $obj
                }
                FILTER(sameterm($obj, <info:fedora/' . $pid . '>))
                OPTIONAL{$icon dc:description $label}
            }
        ');
        
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
    
    static function getTitnAddr($titn) {
        $url = 'http://www.march.es/abnopac/abnetcl.exe?ACC=DOSEARCH&xsqf01=';
        $end = '.titn.';
        return $url . $titn . $end;
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
        return theme('islandora_fjm_atm_concert', $this->pid, $pagenumber);
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
