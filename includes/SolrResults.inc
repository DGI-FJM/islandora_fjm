<?php
/**
 * @file
 * Extension of IslandoraSolrResults, which renders results differently dependant
 * on content type.
 */
module_load_include('inc', 'islandora_solr_search', 'IslandoraSolrResults');

//FIXME (minor):  Should change local references to use the moved function.
function makeArray($in) {
  return IslandoraSolrResults::makeArray($in);
}

function filterComposer($var) {
    if (is_callable("dsm")) {
        //dsm($var);
    }
    return !preg_match("/eaccpf_name_surname_es:.\\*/", $var);
}
    
class SolrResults extends IslandoraSolrResults {

    function __construct() {
        parent::__construct();
        drupal_add_css(drupal_get_path("module", "islandora_fjm") . "/css/islandora_fjm_solrResults.css");
    }
    

    function displayFJMResults($solrQueryProcessor) {
      $apacheSolrResult = $solrQueryProcessor->solrResult;
      $total = (int) $apacheSolrResult->response->numFound;

      $end = min(($solrQueryProcessor->solrLimit + $solrQueryProcessor->solrStart), $total);

      // Initialize drupal-style pager
      islandora_solr_search_pager_init($total, $solrQueryProcessor->solrLimit);

      $output .= $this->addSecondaries();

      $field = 'atm_type_ms';
      $map = array(
        'Archivo de voz' => t('List of Voice Archives'),
        'Obras' => t('List of Works'),
        'Compositores' => t('List of Composers'), 
        'Intérpretes' => t('List of Performers'),
        'Programas de mano' => t('List of Programs'),
        'Partituras' => t('List of Scores'),
        'Conciertos' => t('List of Concerts')
      );
      $title = $map['Conciertos'];
      foreach (makeArray($solrQueryProcessor->solrParams['fq']) as $filter) {
        if(strpos($filter, $field) === 0) {
          //Assuming form of $field:"$title", gotta get rid of the field name and puctuation.
          $title = $map[substr($filter, strlen($field) + 2, -1)];
          break;
        }
      }
      
      
      //$title should have been translated, so I should be good.
      $output .= '<h2>'.t($title).'</h2>';
      $output .= '<div id="islandora_solr_result_count">(' . ($solrQueryProcessor->solrStart + ($total > 0?1:0)) . ' - ' . $end . ' of ' . $total . ')</div>';
      $output .= '<div class="content">';

  //    drupal_set_message(print_r($secondary_display_profiles,1));
      // Render Drupal pager (top of search results)
      $output .= theme('pager', NULL, $solrQueryProcessor->solrLimit, 0, NULL, 5);

      /*
       * Then, here, we need to build links to the current query under the secondary query display
       * profile for each such profile which uses the hook.
       *
       * The link should basically be $theCurrentURL with &proile=<profile_name> tacked on.
       *
       * Also, perhaps there's no difference between primary and secondary profiles?
       */
      $output .= $this->printResults($apacheSolrResult);
      if (variable_get('islandora_solr_search_debug_mode', FALSE)) {
          $output .= $this->printDebugOutput($apacheSolrResult);
      }

      // Render Drupal pager (bottom of search results)
      $output .= theme('pager', NULL, $solrQueryProcessor->solrLimit, 0, NULL, 5);


      $output .= "</div>"; // class = "content"
      return $output;
    }

    /**
     * Override the parent's "print" implementation
     * @param  $results
     * @var
     */
    function printResults($results) {
        global $base_url;
        $output = "";

        $items = array();
        $type = 'ol';
        $title = NULL;
        $recordStart = $results->response->start;
        $limitResults = variable_get('islandora_solr_search_limit_result_fields', 0);
        if (is_callable("dsm")) {
            /*dsm(var_dump($results));
            dsm($results);
            dsm($results->responseHeader);
            dsm($results->response);*/
        }
        
        /**
         * @var array<array<array<string>>> Array of headers to use in drawing the tables.  Also contains a 
         * "name" field, which matches up against the key set in the preprocess
         * function
         */
        $headers = array(
            'Compositores' => array(
                array(
                    'data' => t('Image'),
                    'name' => 'icon_image'
                ),
                array(
                    'data' => t('Name'),
                    'name' => 'name_link'
                )
            ),
            'Obras' => array(
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
                /*array(
                    'data' => t('Concert Series'),
                    'name' => 'cycle'
                ),*/
                array(
                    'data' => t('Score'),
                    'name' => 'score_link'
                ),
                array(
                    'data' => t('Audio'),
                    'name' => 'audio'
                )
            ),
            'Intérpretes' => array(
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
                /*array(
                    'data' => t('Concert Series'),
                    'name' => 'cycle'
                )*/
            ),
            'Archivo de voz' => array(
                array(
                    'data' => t('Year'),
                    'name' => 'year'
                ),
                array(
                    'data' => t('Description'),
                    'name' => 'description'
                ),
                array(
                    'data' => t('Concert'),
                    'name' => 'concert'
                ),
                /*array(
                    'data' => t('Series'),
                    'name' => 'cycle'
                ),*/
                array(
                    'data' => t('Audio'),
                    'name' => 'audio'
                )
            ),
            'Programas de mano' => array(
                array(
                    'data' => t('Concert'),
                    'name' => 'concert'
                ),
                array(
                    'data' => t('Year'),
                    'name' => 'year'
                ),
                /*array(
                    'data' => t('Series'),
                    'name' => 'cycle'
                ),*/
                array(
                    'data' => t('Author(s)'),
                    'name' => 'author'
                ),
                /*array( //Not desired.
                    'data' => t('Find in library'),
                    'name' => 'titn_link'
                ),*/
                array(
                    'data' => t('Program'),
                    'name' => 'PDF_link'
                )
            ),
            'Partituras' => array(
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
                    'data' => t('Score'),
                    'name' => 'PDF_link'
                )
            )
        );

        /**
         * Accumulate the rows for each table
         * @var array<array>
         */
        $table = array(
            "Compositores" => array(),
            "Conciertos" => array(),
            "Archivo de voz" => array(),
            "Obras" => array(),
            "Intérpretes" => array(),
            "Programas de mano" => array(),
            "Partituras" => array()
        );

        /**
         * Used to translate from the keys to "caption" strings.
         * @var array<string> 
         */
        $groups = array(
            'Compositores' => t('Composers'),
            'Conciertos' => t('Concerts'),
            'Archivo de voz' => t('Conferences'),
            'Obras' => t('Works'),
            'Intérpretes' => t('Performers'),
            'Programas de mano' => t('Programs'),
            'Partituras' => t('Scores')
        );
        $js_data = array('islandora_fjm' => array('piece' => array()));
        $docs = $results->response->docs;
        
        //Get the fq...
        $fq_type = '';
        foreach(makeArray($results->responseHeader->params->fq) as $filter) {
          $matches = array();
          if (preg_match('/atm_type_ms\\:"(.+)"/', $filter, $matches) === 1) {
            //dsm($matches);
            $fq_type = $matches[1];
            break;
          }
        }
        //dsm($fq_type);
        if(is_array($docs)) {
          foreach ($docs as $doc) {
              //Setup to pass to preprocessor... (Something of a hack,
              //  using the preprocessor function in this way)
              $toPass = array();
              $toPass['item'] = $doc;
              $toPass['fq_type'] = $fq_type;

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

                              $playlist = array();
                              $aud = 0;
                              foreach ($docu['audio'] as $audio) {
                                  $entry = array();
                                  $entry["url"] = "$base_url/fedora/repository/$audio/MP3";
                                  if($type === 'Obras') {
                                    $entry['title'] = $docu['piece'];
                                    $entry['title'] .= (!empty($docu['movement'][$aud])? ' - ' . $docu['movement'][$aud]:"");
                                    $entry['now_playing'] = theme('islandora_fjm_atm_now_playing', $docu['piece'], $docu['players']);
                                    $aud++;
                                  }
                                  else { //$type === Conferencia
                                    $entry['title'] = substr($docu['description'], 0, 100);
                                    $entry['now_playing'] = '<p>' . $docu['description'] . '</p>';
                                  }
                                  $playlist[] = $entry;
                              }

                              $index = count($js_data['islandora_fjm']['audio']);
                              $js_data['islandora_fjm']['audio'][] = $playlist;

                              $cell .= "<a onClick='Drupal.settings.islandora_fjm.play(&quot;audio&quot;, $index, 0);'></a>";
                              $cell .= "</div>";
                              $row['data'][]['data'] = $cell;
                              break;
                          case 'piece':
                              $cell = l($docu['piece'], $docu['concert_path']);
                              $row['data'][]['data'] = $cell;
                              break;
                          case 'author':
                              $cell = '<ul>';
                              foreach ($docu['author'] as $author) {
                                  $cell .= '<li>' . $author . '</li>';
                              }
                              $cell .= '</ul>';
                              $row['data'][]['data'] = $cell;
                              break;
                          default:
                              $row['data'][]['data'] = $docu[$field['name']];
                      }
                  }
              }

              //... otherwise, render it with the theme function, to be thrown into a cell.
              //FIXME:	Kind of inefficient, as it is "preprocessed" twice, but anyway...
              else {
                  $row['data'][]['data'] = theme('islandora_fjm_solr_result', $doc);
              }

              $table[$type][] = $row;
          }
        }

        //Add a player if required by either Lectures or Performances
        //FIXME (minor):  This might be better if left up to a theme function?
        //  Would be a reasonable refactoring?
        if (!empty($table['Obras']) || !empty($table['Archivo de voz'])) {
            module_load_include('inc', 'islandora_fjm', 'includes/callbacks');
            //$output .= FJM::addPlayer();
            drupal_add_js($js_data, 'setting');
            $output .= theme('islandora_fjm_atm_flowplayer');   
        }
        
        //Add the accordion stuff to work in Concerts...
        if (!empty($table['Conciertos'])) {
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

        $people = array('Compositores', 'Intérpretes');
        //Render the table for each content type.
        foreach ($table as $key => $tab) {
            //Deliciously hack-ful...  Handle the people differently, so as to make an 'A-Z' display...
            if (array_search($key, $people) !== FALSE && array_search("atm_type_ms:\"$key\"", makeArray($results->responseHeader->params->fq)) !== FALSE) {
                $output .= '<ul class="atm_solr_letterblock">';
                $fq_array = array_filter(makeArray($results->responseHeader->params->fq), "filterComposer");
                $query = $results->responseHeader->params->q;
                $output .= '<li>'. l(t('ALL'), 'islandora/solr/search/'. $query .'/'. implode('~', $fq_array)) .'</li>';
                foreach (range('A', 'Z') as $letter) {
                    $output .= '<li>'. l($letter, 'islandora/solr/search/' . 
                        $query .'/'. implode('~', array_merge(
                                $fq_array, 
                                makeArray("eaccpf_name_surname_es:$letter*")
                            )
                        )
                    ) .'</li>';
                }
                $output .= '</ul>';
            }
            
            if (!empty($tab)) {              
              foreach($tab as &$contents) {
                $count = count($contents['data']);
                //dsm($contents);
                if ($count > 0) {
                  $contents['data'][0]['class'] .= ' col-first';
                  $contents['data'][$count - 1]['class'] .= ' col-last';
                }
                //dsm($contents);
              }
                $output .= theme('table', (isset($headers[$key]) ? $headers[$key] : array()), $tab, array('class' => "atm_browse_table atm_$key"), $groups[$key]);
              
            }
        }

        return $output;
    }

}
