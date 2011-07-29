<?php

module_load_include('inc', 'islandora_solr_search', 'IslandoraSolrResults');

class SolrResults extends IslandoraSolrResults {

    function __construct() {
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
                    'data' => t('Concert Cycle'),
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
                    'data' => t('Concert Cycle'),
                    'name' => 'cycle'
                )
            ),
            'Lecture' => array(
                array(
                    'data' => t('Title'),
                    'name' => 'title'
                ),
                array(
                    'data' => t('Concert'),
                    'name' => 'concert'
                ),
                array(
                    'data' => t('Cycle'),
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
                    'data' => t('Cycle'),
                    'name' => 'cycle'
                ),
                array(
                    'data' => t('Author'),
                    'name' => 'author'
                ),
                array(
                    'data' => t('Find in library'),
                    'name' => 'titn_link'
                ),
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
         * @var $groups Used to translate from the keys to actual output strings.
         */
        $groups = array(
            'Composer' => t('Composers'),
            'Concert' => t('Concerts'),
            'Lecture' => t('Conferences'),
            'Performance' => t('Works'),
            'Performer' => t('Performers'),
            'Program' => t('Concert Programs'),
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
                                $cell .= l('<!-- placeholder -->', "fedora/repository/$audio/MP3", array('html' => true));
                            }
                            $cell .= "</div>";
                            $row['data'][] = $cell;
                            break;
                        case 'piece':
                            $cell = l($docu['piece'], $docu['concert_path']);
                            $row['data'][] = $cell;
                         break;
                        default:
                            $row['data'][] = $docu[$field['name']];
                    }
                }
            }

            //... otherwise, render it with the theme function, to be thrown into a cell.
            //FIXME (minor):	Kind of inefficient, as it is "preprocessed" twice, but anyway...
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

        //Render the table for each content type.
        foreach ($table as $key => $tab) {
            if (!empty($tab)) {
                /*$output .= "<h2>" . $groups[$key] . "</h2>";*/
                $output .= theme('table', (isset($headers[$key]) ? $headers[$key] : array()), $tab, array(), $groups[$key]);
            }
        }

        return $output;
    }

}
