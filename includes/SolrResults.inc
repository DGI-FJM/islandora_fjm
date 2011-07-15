<?php

module_load_include('inc', 'islandora_solr_search', 'IslandoraSolrResults');

class SolrResults extends IslandoraSolrResults
{
    function __construct()
    {
        parent::__construct();
        drupal_add_css(drupal_get_path("module", "islandora_fjm") . "/css/islandora_fjm_solrResults.css");
    }
    
    /**
     * Override the parent's "print" implementation
     * @param  $results 
     */
    function printResults($results) {
        $output = "";
        
        $items = array();
        $type = 'ol';
        $title = null;
        $recordStart = $results->response->start;
        $limitResults = variable_get('islandora_solr_search_limit_result_fields', 0);
        
        foreach($results->response->docs as $doc)
        {
            //$items[] = $this->buildResult($doc);
            $output .= $this->buildResult($doc);
        }
        
        return $output;
    }
    
    function buildResult($result)
    {
        $toReturn = "<div class='atm_solr_result'>";
        switch($result->atm_type_s)
        {
            case "Composer":
                $toReturn .= l("
                    <div class='atm_solr_composer'>
                        <div class='atm_solr_composer_tn'><img src='" . url("fedora/repository/" . $result->atm_composer_icon_s . "/TN") . "'></img></div>
                        <div class='atm_solr_composer_name'>" . $result->atm_composer_name_s ."</div>
                    </div>", "fedora/repository/$result->PID", array('html' => true));
                break;
            case "Concert":
                $toReturn .= "Make a concert";
                break;
            case "Performance":
                $toReturn .= "Make a performance";
                break;
            case "Lecture":
                $toReturn .= "Make a lecture";
                break;
            case "Performer":
                $toReturn .= "Make a performer";
                break;
            case "Program":
                $toReturn .= "
                    <div class='atm_solr_program'>
                        Make a program
                    </div><!-- program -->";
                break;
            case "Score":
                $toReturn .= "Make a score";
                break;
            default:
                $toReturn .= "Unknown type!";
        }
        $toReturn .= "</div><!-- result -->";
        return $toReturn;
    }
}
