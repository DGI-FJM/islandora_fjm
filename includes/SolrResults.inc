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
		dsm($results->responseHeader->params->fq);
		foreach($fq as $filter)
		{
			$type_string = 'atm_type_s:';
			$test = strpos($filter, $type_string);
			if($test !== false)
			{
				//$type_string was found somewhere.
				// +/- 1 to get rid of the double quotes.
				//$type = substr($filter, strlen($type_string) + 1, -1);
				break;
			}
		}
		$headers = array(
			'Performance' => array(
				t('Piece'),
				t('Composer'),
				t('Concert Title'),
				t('Concert Cycle')
			),
			'Performer' => array(
				t('Name'),
				t('Piece'),
				t('Concert Title'),
				t('Concert Cycle')
			)
		);
		dsm($type);
		$sommat = array();
		if(isset($type) && isset($headers[$type]))
		{
			//Do table layout...
			foreach($results->response->docs as $doc)
			{
				$toPass = array(
					'item' => $doc
				);
				islandora_fjm_preprocess_islandora_fjm_solr_result($toPass);

				$sommat[] = $toPass['item'];
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
