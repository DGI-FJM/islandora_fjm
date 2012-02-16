<?php

/**
 * @file
 * @deprecated Use those in the module for the given collection.
 * Callbacks and a few utility functions used in the ATM collection.
 * Class containing functions and methods used in the collections at Fundacion Juan March
 */
class FJM {
  public $pid;
  
  function __construct($pid) {
      $this->pid = $pid;
  }
  
  /**
   * Pagenumber isn't really used...
   * Should I actually check the content model?
   * 
   * TODO:  Might want to make it verify the content model.
   * @deprecated
   */
  function showPerson($pagenumber = NULL) {
    return theme('fjm_clamor_person', $this->pid);
  }
  
  /**
   *
   * @param String $pagenumber Used as a bit of a hack to determine which song to start playing, if set.
   * @return string 
   */
  function showConcert($pagenumber = NULL) {
    return theme('fjm_clamor_concert', $this->pid, $pagenumber);
  }
  
  //TODO: Cleanup ((Rather) Bad variable names)
  //TODO:  Need to add link with Titn
  function showScore($pagenumber = NULL) {
    return theme('fjm_clamor_score', $this->pid);
  }
  
  function showProgram($pagenumber = NULL) {
    return theme('fjm_clamor_program', $this->pid);
  }
}
