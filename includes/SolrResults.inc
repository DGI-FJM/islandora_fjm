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
        
		$fq = null;
		$type = null;
		if(is_array($results->responseHeader->params->fq)) {
			$fq = $results->responseHeader->params->fq;
		}
		else
		{
			$fq = array();
			$fq[] = $results->responseHeader->params->fq;
		}
		//dsm($results->responseHeader->params->fq);
		foreach($fq as $filter)
		{
			$type_string = 'atm_type_s:';
			$test = strpos($filter, $type_string);
			
			if($test !== false)
			{
				//$type_string was found somewhere.
				// +/- 1 to get rid of the double quotes.
				$type = strtolower(substr($filter, strlen($type_string) + 1, -1));
				break;
			}
			else
			{
				//might contain another restricting term...
				$prefix = 'atm_';
				$test = strpos($filter, $prefix);
				if($test !== false)
				{
					$type = strtolower(
						substr(
							$filter, 
							strlen($prefix), 
							strpos(
								substr(
									$filter, 
									strlen($prefix)
								),
								'_'
							)
						)
					);
					break;
				}
			}
		}
		$headers = array(
			'performance' => array(
				array(
					'data' =>  t('Piece'),
					'name' => 'title'
				),
				array(
					'data' => t('Composer'),
					'name' =>'composer'
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
					'data' => t('Audio'),
					'name' => 'audio'
				),
				array(
					'data' => t('Score'),
					'name' => 'score'
				)
			),
			'performer' => array(
				'data' => array(
					t('Name'),
					t('Piece'),
					t('Concert Title'),
					t('Concert Cycle')
				)
			)
		);
		dsm($type);
		$sommat = array();
		if(isset($type) && isset($headers[$type]))
		{
			switch($type)
			{
			case "Performance":
				//Setup audio stuff...
				module_load_include('inc', 'islandora_fjm', 'includes/callbacks');
				$output .= FJM::addPlayer();
			break;
			default:
				//Do nothing.
			}
		
			//Do table layout...
			foreach($results->response->docs as $doc)
			{
				$toPass = array(
					'item' => $doc
				);
				//Use the preprocess function to get everything into arrays...
				islandora_fjm_preprocess_islandora_fjm_solr_result($toPass);
				
				//The row to add to the table.
				$row = array();
				$row['data'] = array();
				
				//
				foreach($headers[$type] as $array)
				{
					switch($array['name'])
					{
					case 'audio':
						//Build the playlist...
						$cell = '<div class="atm_track">';
						foreach($toPass['item'][$array['name']] as $track)
						{
							$cell .= l('<!-- placeholder -->', "fedora/repository/$track/MP3", 
								array(
									'html' => true
								)
							);
						}
						$cell .= '</div>';
						$row['data'][] = $cell;
					break;
					case 'score':
						$row['data'][] = l('Score', "islandora/solr/search/ /PID:\"". $toPass['item'][$array['name']] ."\"");
					break;
					default:
					{
						$row['data'][] = $toPass['item'][$array['name']];
					}
					}
				}
				$sommat[] = $row;
			}
		}
		else
		{
			//Do "mixed" layout. (divs in table cells)
			foreach($results->response->docs as $doc)
			{
				$sommat[] = array(theme('islandora_fjm_solr_result', $doc));
			}
		}
		
		$output .= theme(
			'table', 
			(isset($type) && isset($headers[$type])) ? $headers[$type] : array(), 
			$sommat, 
			array('class' => 'atm_solr_results')
		);
        
		return $output;
    }
}
