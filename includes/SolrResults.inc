<?php
/**
 * @file
 * Extension of IslandoraSolrResults, which renders results differently dependant
 * on content type.
 */
module_load_include('inc', 'islandora_solr_search', 'IslandoraSolrResults');
function makeArray($in) {
    return is_array($in)?
        $in:
        (isset($in)?
            array($in):
            array()
        )
    ;
}

function filterComposer($var) {
    if (is_callable("dsm")) {
        dsm($var);
    }
    return !preg_match("/atm_composer_name_s:.\\*/", $var);
}
    
class SolrResults extends IslandoraSolrResults {

    function __construct() {
        parent::__construct();
        drupal_add_css(drupal_get_path("module", "islandora_fjm") . "/css/islandora_fjm_solrResults.css");
    }
    
    

    /**
     * Override the parent's "print" implementation
     * @param  $results
     * @var
     */
    function printResults($results) {
        $output = "";

        $items = array();
        $type = 'ol';
        $title = NULL;
        $recordStart = $results->response->start;
        $limitResults = variable_get('islandora_solr_search_limit_result_fields', 0);
        if (is_callable("dsm")) {
            //dsm(var_dump($results));
            dsm($results->responseHeader);
            dsm($results->response);
        }
        
        /**
         * @var array<array<array<string>>> Array of headers to use in drawing the tables.  Also contains a 
         * "name" field, which matches up against the key set in the preprocess
         * function
         */
        $headers = array(
            'Composer' => array(
                array(
                    'data' => t('Image'),
                    'name' => 'icon_image'
                ),
                array(
                    'data' => t('Name'),
                    'name' => 'name_link'
                )
            ),
            'Performance' => array(
                array(
                    'data' => t('Piece'),
                    'name' => 'piece'
                ),
                array(
                    'data' => t('Composer'),
                    'name' => 'composer'
                ),
                array(
                    'data' => t('Concert Title'),
                    'name' => 'concert'
                ),
                array(
                    'data' => t('Year'),
                    'name' => 'year'
                ),
                array(
                    'data' => t('Concert Series'),
                    'name' => 'cycle'
                ),
                array(
                    'data' => t('Score'),
                    'name' => 'score_link'
                ),
                array(
                    'data' => t('Audio'),
                    'name' => 'audio'
                )
            ),
            'Performer' => array(
                array(
                    'data' => t('Name'),
                    'name' => 'name'
                ),
                array(
                    'data' => t('Group'),
                    'name' => 'group'
                ),
                /*array(    //Not desired
                    'data' => t('Piece'),
                    'name' => 'piece'
                ),*/
                array(
                    'data' => t('Concert Title'),
                    'name' => 'concert'
                ),
                array(
                    'data' => t('Year'),
                    'name' => 'year'
                ),
                array(
                    'data' => t('Concert Series'),
                    'name' => 'cycle'
                )
            ),
            'Lecture' => array(
                array(
                    'data' => t('Description'),
                    'name' => 'description'
                ),
                array(
                    'data' => t('Concert'),
                    'name' => 'concert'
                ),
                array(
                    'data' => t('Series'),
                    'name' => 'cycle'
                ),
                array(
                    'data' => t('Audio'),
                    'name' => 'audio'
                )
            ),
            'Program' => array(
                array(
                    'data' => t('Concert'),
                    'name' => 'concert'
                ),
                array(
                    'data' => t('Year'),
                    'name' => 'year'
                ),
                array(
                    'data' => t('Series'),
                    'name' => 'cycle'
                ),
                array(
                    'data' => t('Author(s)'),
                    'name' => 'author'
                ),
                /*array( //Not desired.
                    'data' => t('Find in library'),
                    'name' => 'titn_link'
                ),*/
                array(
                    'data' => t('PDF'),
                    'name' => 'PDF_link'
                )
            ),
            'Score' => array(
                array(
                    'data' => t('Title'),
                    'name' => 'title'
                ),
                array(
                    'data' => t('Composer'),
                    'name' => 'composer'
                ),
                array(
                    'data' => t('Find in library'),
                    'name' => 'titn_link'
                ),
                array(
                    'data' => t('PDF'),
                    'name' => 'PDF_link'
                )
            )
        );

        /**
         * Accumulate the rows for each table
         * @var array<array>
         */
        $table = array(
            "Composer" => array(),
            "Concert" => array(),
            "Lecture" => array(),
            "Performance" => array(),
            "Performer" => array(),
            "Program" => array(),
            "Score" => array()
        );

        /**
         * Used to translate from the keys to "caption" strings.
         * @var array<string> 
         */
        $groups = array(
            'Composer' => t('Composers'),
            'Concert' => t('Concerts'),
            'Lecture' => t('Conferences'),
            'Performance' => t('Works'),
            'Performer' => t('Performers'),
            'Program' => t('Programs'),
            'Score' => t('Scores')
        );
        foreach ($results->response->docs as $doc) {
            //Setup to pass to preprocessor... (Something of a hack,
            //  using the preprocessor function in this way)
            $toPass = array();
            $toPass['item'] = $doc;

            //NOTE:  Pass by reference, so toPass is(/should be) modified!
            islandora_fjm_preprocess_islandora_fjm_solr_result($toPass);

            //Use preprocessed document...
            $type = $toPass['item']['type'];
            $docu = $toPass['item'];

            //Row to add to table
            $row = array('data' => array());

            //If its an acutal table we're to add to...
            if (isset($headers[$type])) {
                //...  put the stuff into the proper field...
                foreach ($headers[$type] as $field) {
                    switch ($field['name']) {
                        case 'audio':
                            $cell = "<div class='atm_track'>";
                            foreach ($docu['audio'] as $audio) {
                                $cell .= l('<!-- placeholder -->', "fedora/repository/$audio/MP3", array('html' => TRUE));
                            }
                            $cell .= "</div>";
                            $row['data'][] = $cell;
                            break;
                        case 'piece':
                            $cell = l($docu['piece'], $docu['concert_path']);
                            $row['data'][] = $cell;
                            break;
                        case 'author':
                            $cell = '<ul>';
                            foreach ($docu['author'] as $author) {
                                $cell .= '<li>' . $author . '</li>';
                            }
                            $cell .= '</ul>';
                            break;
                        default:
                            $row['data'][] = $docu[$field['name']];
                    }
                }
            }

            //... otherwise, render it with the theme function, to be thrown into a cell.
            //FIXME:	Kind of inefficient, as it is "preprocessed" twice, but anyway...
            else {
                $row['data'][] = theme('islandora_fjm_solr_result', $doc);
            }

            $table[$type][] = $row;
        }

        //Add a player if required by either Lectures or Performances
        //FIXME (minor):  This might be better if left up to a theme function?
        //  Would be a reasonable refactoring?
        if (!empty($table['Performance']) || !empty($table['Lecture'])) {
            module_load_include('inc', 'islandora_fjm', 'includes/callbacks');
            $output .= FJM::addPlayer();
        }
        
        //Add the accordion stuff to work in Concerts...
        if (!empty($table['Concert'])) {
            jquery_ui_add('ui.accordion');
            drupal_add_js('$(function() {
                $("div.concert_bottom").each(function(index) {
                    $(this).accordion({
                        active: false,
                        collapsible: true,
                        autoHeight: false,
                        header: "h3"
                    });
                })
            });', 'inline');
            drupal_add_css('sites/all/libraries/jquery.ui/themes/base/ui.theme.css', 'module');
            drupal_add_css('sites/all/libraries/jquery.ui/themes/base/ui.accordion.css', 'module');
        }

        //Render the table for each content type.
        foreach ($table as $key => $tab) {
            //Deliciously hack-ful...  Handle the composers differently, so as to make an 'A-Z' display...
            if ($key == "Composer" && strpos($results->responseHeader->params->q, 'atm_type_s:"Composer"') !== FALSE) {
                $output .= '<ul class="atm_solr_letterblock">';
                $fq_array = array_filter(makeArray($results->responseHeader->params->fq), "filterComposer");
                foreach (range('A', 'Z') as $letter) {
                    $output .= '<li>' . l($letter, "islandora/solr/search/" . 
                        $results->responseHeader->params->q . '/' .
                        implode('~', 
                            array_merge(
                                $fq_array, 
                                makeArray("atm_composer_name_s:$letter*")
                            )
                        )
                    ) . '</li>';
                }
                $output .= '</ul>';
            }
            
            if (!empty($tab)) {
                $output .= theme('table', (isset($headers[$key]) ? $headers[$key] : array()), $tab, array(), $groups[$key]);
            }
        }

        return $output;
    }

}
