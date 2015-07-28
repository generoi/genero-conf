<?php

// Set correct download directories
$command_specific['dl'] = array('destination' => 'sites/all/modules/contrib');
$command_specific['fe'] = array('destination' => 'sites/all/modules/features');

// Include the shared logic.
include_once __DIR__ . '/../lib/genero-conf/drush/drushrc.php';
