class arc_ce::config::cluster (
  $cluster_alias           = 'MINIMAL Computing Element',
  $cluster_comment         = 'This is a minimal out-of-box CE setup',
  $cluster_cpudistribution = ['16cpu:12'],
  $cluster_description     = {
    'OSFamily'      => 'linux',
    'OSName'        => 'ScientificSL',
    'OSVersion'     => '6.4',
    'CPUVendor'     => 'AMD',
    'CPUClockSpeed' => '3100',
    'CPUModuel'     => 'AMD Opteron(tm) Processor 4386',
  }
  ,
  $cluster_is_homogenious  = true,
  $cluster_location        = 'Chilton, Oxfordshire, UK',
  $cluster_nodes_private   = true,
  $cluster_owner           = 'Bristol HEP',
  $cluster_support         = 'admin@site.ac.uk',
  $lrms                    = 'fork',) {
  concat::fragment { 'arc.conf_cluster':
    target  => '/etc/arc.conf',
    content => template("${module_name}/cluster.erb"),
    order   => 06,
  }
}