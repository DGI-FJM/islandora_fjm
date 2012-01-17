<?php //blah ?>
<table class="ceacs-recentdocs" caption="Latest Repository Additions" summary="This is a feed of the latest items added to the collection.">
  <caption><?php echo t('LATEST ADDITIONS');?></caption>
  <thead>
      <tr>
        <th id="itemcolumn" scope="col"><?php echo t('Type of Publication');?></th>
        <th id="col1" scope="col"><?php echo t('Author / Year / Title');?></th>
        <!--<th id="col2" scope="col"><?php //echo t('Access');?></th>-->
      </tr>
  </thead>
  <!--<tfoot>
    <tr>
      <td colspan="3">
        <ul class="legend type">
          <li><div class="type-articulo"></div><?php //echo t('ARTICLE');?></li>
          <li><div class="type-workingpaper"></div><?php //echo t('WORKING PAPER');?></li>
          <li><div class="type-thesis"></div><?php //echo t('THESES');?></li>
          <li><div class="type-book"></div><?php //echo t('BOOK/BOOK CHAPTER');?></li>
        </ul>
        <ul class="legend access">
          <li><div class="access-open"></div><?php //echo t('OPEN ACCESS');?></li>
          <li><div class="access-restricted"></div><?php //echo t('RESTRICTED');?></li>
          <li><div class="access-metadata"></div><?php //echo t('BIB. INFO');?></li>
        </ul>
      </td>
    </tr>
  </tfoot>-->
  <tbody>
    <?php foreach($solr_docs as $doc) {
      echo theme('islandora_fjm_recent_ir_doc', $doc);
    } ?>
    
    <!--<tr>
      <th id="row1" scope="row"><div class="icon type-articulo">&nbsp;</div></th>
      <td headers="itemcolumn col1"><a href="#">Falcó Gimeno, Albert and Jurado Nebreda Ignacio.	2011 
      Minority governments and budget deficits: The role of the opposition. European Journal of Political Economy</a></td>
      <td headers="itemcolumn col2"><div class="icon access-open">&nbsp;</div></td>
      </tr>
    <tr>
      <th id="row2" scope="row"><div class="icon type-thesis">&nbsp;</div></th>
      <td headers="itemcolumn col1"><a href="#">Martínez Pérez Alvaro. 	2011
      Couple relationships: the effect of education on gender equality. Thesis (Doctoral)</a></td>
      <td headers="itemcolumn col2"><div class="icon access-restricted">&nbsp;</div></td>
      </tr>-->
  </tbody>
</table>
